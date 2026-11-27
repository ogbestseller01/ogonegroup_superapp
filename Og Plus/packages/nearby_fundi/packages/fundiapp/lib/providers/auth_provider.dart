// lib/providers/auth_provider.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../config/app_routes.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/fcm_service.dart';
import '../services/fundi_remember_store.dart';
import '../services/storage_service.dart';

/// Client-side error codes. The UI turns these into localized text
/// (see auth_issue_text.dart), so the provider never holds UI language.
enum AuthIssue {
  loginFailed,
  network,
  notFundiAccount,
  savedLoginInvalid,
  sessionExpired,
  registrationExpired,
  phoneTaken,
  phoneDeleted,
  emailTaken,
  idTaken,
  stepsIncomplete,
  submitFailed,
}

class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  final GlobalKey<NavigatorState>? _navigatorKey;

  User? _user;
  String? _token;
  bool _isLoading = false;
  String? _error;
  AuthIssue? _issue;

  // ── Remember me / one-tap login ───────────────────────────
  RememberedAccount? _remembered;
  bool _rememberedLoaded = false;

  // ── Pending registration state ────────────────────────────
  int? _draftId;
  String? _registrationToken;

  // ── OTP delivery info (from Step 1 / resend response) ────
  String? _otpChannel; // 'sms' | 'email' | 'failed' | 'none'
  String? _otpSentTo; // phone or email

  // Startup / session-expiry guards
  bool _isInitialized = false;
  bool _isBootstrapping = false;
  bool _sessionExpiredWhileBootstrapping = false;
  bool _handlingSessionExpiry = false;

  User? get user => _user;
  String? get token => _token;
  bool get isLoggedIn => _token != null && _user != null;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _error;
  AuthIssue? get issue => _issue;

  RememberedAccount? get remembered => _remembered;
  bool get rememberedLoaded => _rememberedLoaded;

  bool get isPendingApproval => _user?.isPendingApproval ?? false;

  int? get draftId => _draftId;
  String? get registrationToken => _registrationToken;
  bool get hasRegistrationToken =>
      _registrationToken != null && _registrationToken!.isNotEmpty;

  // ── OTP delivery getters ─────────────────────────────────
  String? get otpChannel => _otpChannel;
  String? get otpSentTo => _otpSentTo;
  bool get otpSentBySms => _otpChannel == 'sms';
  bool get otpSentByEmail => _otpChannel == 'email';
  bool get otpDeliveryFailed =>
      _otpChannel == null || _otpChannel == 'none' || _otpChannel == 'failed';

  ApiService get api => _api;

  AuthProvider({GlobalKey<NavigatorState>? navigatorKey})
      : _navigatorKey = navigatorKey {
    _api.onSessionExpired = _onSessionExpired;
    _loadStoredSession();
    unawaited(_loadRemembered());
  }

  Future<void> _onSessionExpired() async {
    if (_isBootstrapping) {
      _sessionExpiredWhileBootstrapping = true;
      return;
    }
    if (_handlingSessionExpiry) return;
    _handlingSessionExpiry = true;
    try {
      await _clearSession();
      _navigatorKey?.currentState
          ?.pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
    } finally {
      _handlingSessionExpiry = false;
    }
  }

  void clearError() {
    _error = null;
    _issue = null;
    notifyListeners();
  }

  /// Turns a failed [ApiResponse] into error state.
  /// No status code means the request never got an HTTP answer (network).
  void _fail(ApiResponse res) {
    _error = res.message;
    _issue = (res.statusCode == null) ? AuthIssue.network : null;
  }

  /// FCM token that can NEVER hang or throw. A stuck push-token request
  /// must not freeze login / OTP / registration.
  Future<String?> _fcmTokenSafe() async {
    try {
      return await FcmService.getToken().timeout(const Duration(seconds: 3));
    } catch (_) {
      return null;
    }
  }

  // ══════════════════════════════════════════════════════════
  // AUTHENTICATION
  // ══════════════════════════════════════════════════════════

  Future<bool> register(
      String name,
      String email,
      String password,
      String confirmPassword, {
        String? phone,
      }) async {
    _setLoading(true);
    final res = await _api.register({
      'name': name,
      'email': email,
      'password': password,
      'password_confirmation': confirmPassword,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
    });
    if (res.success == true) {
      _setLoading(false);
      return true;
    }
    _fail(res);
    _setLoading(false);
    return false;
  }

  Future<bool> registerFundi(Map<String, dynamic> data) async {
    _setLoading(true);
    final res = await _api.registerFundi(data);
    if (res.success == true) {
      _setLoading(false);
      return true;
    }
    _fail(res);
    _setLoading(false);
    return false;
  }

  /// Password login. [rememberMe] asks the server for a 30-day remember
  /// token that is stored securely for one-tap login.
  Future<bool> login(
      String identifier,
      String password, {
        bool rememberMe = false,
      }) async {
    _setLoading(true);
    try {
      final res = await _api.login(
        identifier.trim(),
        password,
        rememberMe: rememberMe,
      );

      if (res.success == true && res.data is Map) {
        final map = Map<String, dynamic>.from(res.data as Map);
        final remember = map['remember_token']?.toString();

        final ok = await _saveSession(map);
        if (!ok) {
          await _discardRejectedLogin(map, remember);
          return false;
        }

        if (rememberMe && remember != null && remember.isNotEmpty) {
          await _persistRemembered(map, remember);
        }

        _error = null;
        _issue = null;
        return true;
      }

      _fail(res);
      return false;
    } catch (e) {
      debugPrint('login error: $e');
      _issue = AuthIssue.loginFailed;
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// One-tap login ("Continue as [User]"). Exchanges the saved remember
  /// token for a fresh session token; the server rotates the remember token.
  Future<bool> quickLogin() async {
    if (_remembered == null) return false;

    _setLoading(true);
    try {
      final rememberToken = await FundiRememberStore.getToken();
      if (rememberToken == null || rememberToken.isEmpty) {
        await _clearRemembered();
        _issue = AuthIssue.savedLoginInvalid;
        return false;
      }

      final fcmToken = await _fcmTokenSafe();
      final res = await _api.quickLogin(rememberToken, fcmToken: fcmToken);

      if (res.success == true && res.data is Map) {
        final map = Map<String, dynamic>.from(res.data as Map);
        final newRemember = map['remember_token']?.toString();

        final ok = await _saveSession(map, fcmToken: fcmToken);
        if (!ok) {
          await _discardRejectedLogin(map, newRemember);
          await _clearRemembered();
          return false;
        }

        if (newRemember != null && newRemember.isNotEmpty) {
          await _persistRemembered(map, newRemember);
        }

        _error = null;
        _issue = null;
        return true;
      }

      // 401 = expired / revoked / password changed -> forget it.
      // Other errors (locked, not approved, offline) keep the saved account.
      if (res.statusCode == 401) {
        await _clearRemembered();
        _issue = AuthIssue.savedLoginInvalid;
        _error = res.message;
      } else {
        _fail(res);
      }
      return false;
    } catch (e) {
      debugPrint('quickLogin error: $e');
      _issue = AuthIssue.loginFailed;
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// "Use another account": removes the saved login (device + server).
  Future<void> forgetRemembered() async {
    final token = await FundiRememberStore.getToken();
    await _clearRemembered();
    if (token != null && token.isNotEmpty) {
      unawaited(_api.forgetRemembered(token));
    }
  }

  Future<bool> verifyOtp(String identifier, String otp) async {
    _setLoading(true);
    final fcmToken = await _fcmTokenSafe();
    final res = await _api.verifyOtp(identifier, otp, fcmToken: fcmToken);
    if (res.success == true && res.data is Map) {
      final ok = await _saveSession(
        Map<String, dynamic>.from(res.data as Map),
        fcmToken: fcmToken,
      );
      if (ok) {
        _setLoading(false);
        return true;
      }
    } else {
      _fail(res);
    }
    _setLoading(false);
    return false;
  }

  Future<bool> verifyDraftOtp(String identifier, String otp) async {
    _setLoading(true);
    final res = await _api.verifyDraftOtp(
      identifier: identifier,
      otp: otp,
      draftId: _draftId,
    );
    if (res.success == true && res.data is Map) {
      final map = Map<String, dynamic>.from(res.data as Map);
      final token = map['registration_token']?.toString();
      if (token != null && token.isNotEmpty) {
        _registrationToken = token;
        await StorageService.saveRegistrationToken(token);
      }

      final rawDraftId = map['draft_id'] ?? _draftId;
      _draftId = rawDraftId is int
          ? rawDraftId
          : (rawDraftId is num
          ? rawDraftId.toInt()
          : int.tryParse('$rawDraftId'));

      if (_draftId != null) {
        await StorageService.saveTechnicianId(_draftId!);
      }

      _setLoading(false);
      return true;
    }
    _fail(res);
    _setLoading(false);
    return false;
  }

  Future<bool> resendDraftOtp(String identifier) async {
    _setLoading(true);
    final res = await _api.resendDraftOtp(
      identifier: identifier,
      draftId: _draftId,
    );
    if (res.success == true) {
      final data = res.data;
      if (data is Map) {
        final map = Map<String, dynamic>.from(data);
        final ch = map['otp_channel']?.toString();
        final to = map['sent_to']?.toString();
        if (ch != null && ch.isNotEmpty) _otpChannel = ch;
        if (to != null && to.isNotEmpty) _otpSentTo = to;
      }
      _setLoading(false);
      return true;
    }
    _fail(res);
    _setLoading(false);
    return false;
  }

  // ══════════════════════════════════════════════════════════
  // PASSWORD / PROFILE
  // ══════════════════════════════════════════════════════════

  Future<bool> forgotPassword(String email) async {
    _setLoading(true);
    final res = await _api.forgotPassword(email);
    if (res.success == true) {
      _setLoading(false);
      return true;
    }
    _fail(res);
    _setLoading(false);
    return false;
  }

  Future<bool> resetPassword(String email, String otp, String password) async {
    _setLoading(true);
    final res = await _api.resetPassword(
      email: email,
      otp: otp,
      password: password,
    );
    if (res.success == true) {
      // The server revoked every token, including the remember token.
      await _clearRemembered();
      _setLoading(false);
      return true;
    }
    _fail(res);
    _setLoading(false);
    return false;
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    _setLoading(true);
    final res = await _api.updateProfile(data);
    if (res.success == true && res.data != null) {
      final raw = res.data;
      final userData = (raw is Map && raw['user'] != null)
          ? Map<String, dynamic>.from(raw['user'] as Map)
          : Map<String, dynamic>.from(raw as Map);

      final currentToken = _token;
      if (currentToken == null) {
        _issue = AuthIssue.sessionExpired;
        _setLoading(false);
        return false;
      }

      // Keep fields this endpoint does not return (photo, status, nida).
      final previous = _user;
      var fresh = User.fromJson(userData, currentToken);
      if (previous != null) {
        fresh = fresh.copyWith(
          profilePhoto: fresh.profilePhoto ?? previous.profilePhoto,
          nida: fresh.nida ?? previous.nida,
        );
      }
      _user = fresh;
      await _storeUser();
      unawaited(_syncRememberedProfile(fresh));
      _setLoading(false);
      notifyListeners();
      return true;
    }
    _fail(res);
    _setLoading(false);
    return false;
  }

  Future<bool> changePassword(String current, String newPwd) async {
    _setLoading(true);
    final res = await _api.changePassword(
      currentPassword: current,
      newPassword: newPwd,
    );
    if (res.success == true) {
      _setLoading(false);
      return true;
    }
    _fail(res);
    _setLoading(false);
    return false;
  }

  Future<bool> updateLocale(String locale) async {
    _setLoading(true);
    final res = await _api.updateLocale(locale);
    final currentUser = _user;

    if (res.success == true && currentUser != null && _token != null) {
      _user = currentUser.copyWith(locale: locale);
      await _storeUser();
      await StorageService.saveLocale(locale);
      _setLoading(false);
      notifyListeners();
      return true;
    }
    _fail(res);
    _setLoading(false);
    return false;
  }

  Future<bool> resendOtp(String email) async {
    _setLoading(true);
    final res = await _api.resendOtp(email);
    if (res.success == true) {
      _setLoading(false);
      return true;
    }
    _fail(res);
    _setLoading(false);
    return false;
  }

  Future<bool> deleteAccount() async {
    _setLoading(true);
    final res = await _api.deleteAccount();
    if (res.success == true) {
      // The account no longer exists: its saved one-tap login must go too.
      await _clearRemembered();
      await logout();
      _setLoading(false);
      return true;
    }
    _fail(res);
    _setLoading(false);
    return false;
  }

  /// Local logout is immediate. Server revocation runs afterwards with an
  /// explicit token (+ retry). The remembered account is KEPT, so the login
  /// screen can offer "Continue as [User]".
  Future<void> logout() async {
    final token = _token;
    String? fcm;
    try {
      fcm = await FcmService.getToken().timeout(const Duration(seconds: 2));
    } catch (_) {}

    await _clearSession();
    _registrationToken = null;
    _draftId = null;
    _otpChannel = null;
    _otpSentTo = null;
    notifyListeners();

    if (token != null) unawaited(_revokeRemote(token, fcm));
  }

  Future<void> _revokeRemote(String token, String? fcmToken) async {
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final res = await _api
            .logoutWithToken(token, fcmToken: fcmToken)
            .timeout(const Duration(seconds: 8));
        // sessionExpired == token already invalid server-side: also done.
        if (res.success || res.sessionExpired) return;
      } catch (_) {}
      await Future<void>.delayed(const Duration(seconds: 2));
    }
    debugPrint('Remote logout failed; token will expire server-side.');
  }

  // ══════════════════════════════════════════════════════════
  // DRAFT-BASED REGISTRATION
  // ══════════════════════════════════════════════════════════

  Future<int?> getRegistrationStep(int id) async {
    final res = await _api.getRegistrationStatus(id);
    if (res.success != true || res.data == null) return null;
    final data = Map<String, dynamic>.from(res.data as Map);
    if (data['registration_completed'] == true) return null;
    final step = data['registration_step'];
    if (step is int) return step;
    if (step is num) return step.toInt();
    return null;
  }

  Future<int?> registerTechnicianStep1(Map<String, dynamic> data) async {
    _setLoading(true);
    final res = await _api.registerTechnicianStep1(data);

    if (res.success == true && res.data is Map) {
      final map = Map<String, dynamic>.from(res.data as Map);

      _otpChannel = map['otp_channel']?.toString();
      _otpSentTo = map['sent_to']?.toString() ?? data['phone']?.toString();

      final rawId = map['draft_id'];
      _draftId = rawId is int
          ? rawId
          : (rawId is num ? rawId.toInt() : int.tryParse('$rawId'));

      final token = map['registration_token']?.toString();
      if (token != null && token.isNotEmpty) {
        _registrationToken = token;
        await StorageService.saveRegistrationToken(token);
      }

      if (_draftId != null) {
        await StorageService.saveTechnicianId(_draftId!);
      }

      _setLoading(false);
      return _draftId;
    }

    _fail(res);
    _setLoading(false);
    return null;
  }

  bool _ensureDraftToken() {
    if (_registrationToken == null || _registrationToken!.isEmpty) {
      _error = 'Registration session expired. Please start over.';
      _issue = AuthIssue.registrationExpired;
      notifyListeners();
      return false;
    }
    return true;
  }

  Future<bool> registerTechnicianStep2({
    required String nida,
    required String idDocumentType,
    File? idDocumentImage,
  }) async {
    if (!_ensureDraftToken()) return false;
    _setLoading(true);
    final res = await _api.registerTechnicianStep2(
      registrationToken: _registrationToken!,
      nida: nida,
      idDocumentType: idDocumentType,
      idDocumentImage: idDocumentImage,
    );
    _setLoading(false);
    if (res.success == true) return true;
    _fail(res);
    notifyListeners();
    return false;
  }

  Future<bool> registerTechnicianStep3({
    required String fingerprintData,
  }) async {
    if (!_ensureDraftToken()) return false;
    _setLoading(true);
    final res = await _api.registerTechnicianStep3(
      registrationToken: _registrationToken!,
      fingerprintData: fingerprintData,
    );
    _setLoading(false);
    if (res.success == true) return true;
    _fail(res);
    notifyListeners();
    return false;
  }

  Future<bool> registerTechnicianStep4({
    required String faceData,
  }) async {
    if (!_ensureDraftToken()) return false;
    _setLoading(true);
    final res = await _api.registerTechnicianStep4(
      registrationToken: _registrationToken!,
      faceData: faceData,
    );
    _setLoading(false);
    if (res.success == true) return true;
    _fail(res);
    notifyListeners();
    return false;
  }

  Future<bool> registerTechnicianStep5({
    required String nextOfKinName,
    required String nextOfKinPhone,
    required String nextOfKinRelationship,
  }) async {
    if (!_ensureDraftToken()) return false;
    _setLoading(true);
    final res = await _api.registerTechnicianStep5(
      registrationToken: _registrationToken!,
      nextOfKinName: nextOfKinName,
      nextOfKinPhone: nextOfKinPhone,
      nextOfKinRelationship: nextOfKinRelationship,
    );
    _setLoading(false);
    if (res.success == true) return true;
    _fail(res);
    notifyListeners();
    return false;
  }

  Future<bool> submitTechnicianRegistration() async {
    if (!_ensureDraftToken()) return false;
    _setLoading(true);

    final fcmToken = await _fcmTokenSafe();

    final res = await _api.submitTechnicianRegistration(
      registrationToken: _registrationToken!,
      fcmDeviceToken: fcmToken,
    );

    if (res.success == true && res.data is Map) {
      final map = Map<String, dynamic>.from(res.data as Map);

      // FIX: step 6 intentionally returns NO token (pending fundi). That is
      // a successful submit, not a failure. Revert these 3 lines if your UI
      // relied on the old behaviour.
      final hasToken = (map['token']?.toString() ?? '').isNotEmpty;
      final ok = hasToken ? await _saveSession(map, fcmToken: fcmToken) : true;

      if (ok) {
        _registrationToken = null;
        _draftId = null;
        _otpChannel = null;
        _otpSentTo = null;
        await StorageService.clearTechnicianData();
      }
      _setLoading(false);
      return ok;
    }

    _error = _humanizeSubmitError(res.message);
    _issue = res.statusCode == null ? AuthIssue.network : _issueForSubmit(res.message);
    _setLoading(false);
    return false;
  }

  Future<void> abandonDraft() async {
    _registrationToken = null;
    _draftId = null;
    _otpChannel = null;
    _otpSentTo = null;
    await StorageService.clearTechnicianData();
    notifyListeners();
  }

  // ══════════════════════════════════════════════════════════
  // PRIVATE: bootstrap
  // ══════════════════════════════════════════════════════════

  Future<void> _loadStoredSession() async {
    try {
      _draftId = await StorageService.getTechnicianId();
      _registrationToken = await StorageService.getRegistrationToken();

      final storedToken = await StorageService.getToken();
      if (storedToken != null && storedToken.isNotEmpty) {
        _isBootstrapping = true;

        final userJson = await StorageService.getUserJson();
        if (userJson != null && userJson.isNotEmpty) {
          try {
            final userMap =
            Map<String, dynamic>.from(jsonDecode(userJson) as Map);
            _token = storedToken;
            _user = User.fromJson(userMap, storedToken);
            notifyListeners();
            await _refreshProfile();
          } catch (e) {
            debugPrint('Failed to restore user session: $e');
            await _clearSession();
          }
        } else {
          await _fetchAndSaveUser(storedToken);
        }
      }
    } catch (e) {
      debugPrint('Failed to load stored session: $e');
    } finally {
      _isBootstrapping = false;
      if (_sessionExpiredWhileBootstrapping) {
        _sessionExpiredWhileBootstrapping = false;
        await _clearSession();
      }
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> _refreshProfile() async {
    final currentToken = _token;
    if (currentToken == null) return;
    try {
      final res = await _api.getProfile();
      if (res.success == true &&
          res.data is Map &&
          (res.data as Map)['user'] != null) {
        final userMap =
        Map<String, dynamic>.from((res.data as Map)['user'] as Map);
        final fresh = User.fromJson(userMap, currentToken);
        _user = fresh;
        await _storeUser();
        unawaited(_syncRememberedProfile(fresh));
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Profile refresh failed (kept local session): $e');
    }
  }

  Future<void> _fetchAndSaveUser(String token) async {
    try {
      final res = await _api.getProfile();
      if (res.success == true &&
          res.data is Map &&
          (res.data as Map)['user'] != null) {
        final userMap =
        Map<String, dynamic>.from((res.data as Map)['user'] as Map);
        _token = token;
        _user = User.fromJson(userMap, token);
        await StorageService.saveToken(token);
        await _storeUser();
        await _registerFcm();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to fetch user for stored token: $e');
    }
  }

  // ══════════════════════════════════════════════════════════
  // PRIVATE: session
  // ══════════════════════════════════════════════════════════

  /// True when the response says the account has the FUNDI role.
  /// If the response carries no role info at all, it is allowed.
  bool _hasFundiRole(Map<String, dynamic> data) {
    final names = <String>[];
    void collect(dynamic v) {
      if (v is! List) return;
      for (final r in v) {
        names.add(r is Map ? '${r['name']}' : '$r');
      }
    }

    collect(data['roles']);
    final u = data['user'];
    if (u is Map) collect(u['roles']);

    if (names.isEmpty) return true;
    return names.any((n) => n.toUpperCase() == 'FUNDI');
  }

  Future<bool> _saveSession(
      Map<String, dynamic> data, {
        String? fcmToken,
      }) async {
    final rawUser = data['user'];
    final rawToken = data['token'];
    if (rawUser is! Map || rawToken == null) {
      _issue = AuthIssue.loginFailed;
      return false;
    }

    // A customer account must never sign in to the fundi app.
    if (!_hasFundiRole(data)) {
      _issue = AuthIssue.notFundiAccount;
      return false;
    }

    final token = rawToken.toString();
    final userMap = Map<String, dynamic>.from(rawUser);
    _token = token;
    _user = User.fromJson(userMap, token);
    await StorageService.saveToken(token);
    await _storeUser();
    await _registerFcm(fcmToken);
    notifyListeners();
    return true;
  }

  /// A login the server accepted but the app refuses (wrong role): revoke
  /// the tokens the server just issued so nothing is left dangling.
  Future<void> _discardRejectedLogin(
      Map<String, dynamic> data,
      String? rememberToken,
      ) async {
    final t = data['token']?.toString();
    if (t != null && t.isNotEmpty) unawaited(_revokeRemote(t, null));
    if (rememberToken != null && rememberToken.isNotEmpty) {
      unawaited(_api.forgetRemembered(rememberToken));
    }
  }

  Future<void> _clearSession() async {
    final hadSession = _token != null || _user != null;
    _token = null;
    _user = null;
    await StorageService.clearAuth(); // does NOT touch the remember store
    if (hadSession) notifyListeners();
  }

  Future<void> _storeUser() async {
    final currentUser = _user;
    if (currentUser != null) {
      await StorageService.saveUserJson(jsonEncode(currentUser.toJson()));
    }
  }

  Future<void> _registerFcm([String? providedToken]) async {
    try {
      final fcmToken = providedToken ?? await _fcmTokenSafe();
      if (fcmToken == null || fcmToken.isEmpty) {
        debugPrint('⚠️ FCM token unavailable');
        return;
      }

      final res = await _api.updateFcmDeviceToken(fcmToken);
      if (res.success != true) {
        debugPrint('⚠️ Failed to push FCM token: ${res.message}');
      } else {
        debugPrint('✅ FCM token registered');
      }
    } catch (e) {
      debugPrint('⚠️ FCM registration error: $e');
    }
  }

  // ══════════════════════════════════════════════════════════
  // PRIVATE: remember me
  // ══════════════════════════════════════════════════════════

  Future<void> _loadRemembered() async {
    _remembered = await FundiRememberStore.getAccount();
    _rememberedLoaded = true;
    notifyListeners();
  }

  Future<void> _persistRemembered(
      Map<String, dynamic> data,
      String rememberToken,
      ) async {
    try {
      final raw = data['user'];
      final u = User.fromJson(
        raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{},
        '',
      );
      if (!u.isValid) return;

      final keepPhoto = (_remembered?.id == u.id) ? _remembered?.photo : null;

      final account = RememberedAccount(
        id: u.id,
        name: u.name,
        email: u.email ?? '',
        phone: u.phone ?? '',
        photo: u.profilePhoto ?? keepPhoto,
      );

      await FundiRememberStore.saveToken(rememberToken);
      await FundiRememberStore.saveAccount(account);
      _remembered = account;
      _rememberedLoaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('persist remembered failed: $e');
    }
  }

  /// Keeps the saved name / photo fresh after a profile refresh.
  Future<void> _syncRememberedProfile(User u) async {
    final r = _remembered;
    if (r == null || r.id != u.id) return;

    final updated = RememberedAccount(
      id: u.id,
      name: u.name,
      email: u.email ?? '',
      phone: u.phone ?? '',
      photo: u.profilePhoto,
    );

    if (r.name == updated.name &&
        r.email == updated.email &&
        r.phone == updated.phone &&
        r.photo == updated.photo) {
      return;
    }

    _remembered = updated;
    await FundiRememberStore.saveAccount(updated);
    notifyListeners();
  }

  Future<void> _clearRemembered() async {
    await FundiRememberStore.clear();
    _remembered = null;
    _rememberedLoaded = true;
    notifyListeners();
  }

  // ══════════════════════════════════════════════════════════
  // PRIVATE: error helpers
  // ══════════════════════════════════════════════════════════

  AuthIssue _issueForSubmit(String? raw) {
    final lower = (raw ?? '').toLowerCase();

    if (lower.contains('phone number is already registered') ||
        lower.contains('phone number already registered')) {
      return AuthIssue.phoneTaken;
    }
    if (lower.contains('previously deleted account')) {
      return AuthIssue.phoneDeleted;
    }
    if (lower.contains('email is already registered') ||
        lower.contains('email already registered')) {
      return AuthIssue.emailTaken;
    }
    if (lower.contains('id number has already been registered')) {
      return AuthIssue.idTaken;
    }
    if (lower.contains('biometrics incomplete') ||
        lower.contains('complete all registration steps')) {
      return AuthIssue.stepsIncomplete;
    }
    return AuthIssue.submitFailed;
  }

  /// English fallback text for screens that do not use [issue] yet.
  String _humanizeSubmitError(String? raw) {
    final msg = (raw ?? '').trim();
    switch (_issueForSubmit(raw)) {
      case AuthIssue.phoneTaken:
        return 'This phone number is already registered. '
            'Please log in or use a different number. '
            'If you believe this is a mistake, contact support.';
      case AuthIssue.phoneDeleted:
        return 'This phone number belongs to a deleted account. '
            'Please contact support to restore it, or use a different number.';
      case AuthIssue.emailTaken:
        return 'This email is already registered. '
            'Please log in or use a different email.';
      case AuthIssue.idTaken:
        return 'This ID number has already been registered. '
            'Contact support if you believe this is a mistake.';
      case AuthIssue.stepsIncomplete:
        return 'Some registration steps are incomplete. '
            'Please go back and complete them before submitting.';
      default:
        return msg.isEmpty
            ? 'Registration submission failed. Please try again.'
            : msg;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    if (value) {
      _error = null;
      _issue = null;
    }
    notifyListeners();
  }
}