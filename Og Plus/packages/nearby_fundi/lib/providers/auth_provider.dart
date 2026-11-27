// lib/providers/auth_provider.dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart'
    show GoogleSignInException, GoogleSignInExceptionCode;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_routes.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/fcm_service.dart';
import '../services/google_auth_service.dart';
import '../services/storage_service.dart';

enum GoogleLoginOutcome { success, cancelled, failed }

/// Result of POST /v1/auth/register.
class RegisterResult {
  final bool success;
  final String message;

  /// true when the backend managed to deliver the OTP (SMS or email).
  final bool otpSent;

  /// 'sms' | 'email' | 'none'
  final String? channel;

  /// The phone / email the code was sent to.
  final String? sentTo;

  const RegisterResult({
    required this.success,
    this.message = '',
    this.otpSent = false,
    this.channel,
    this.sentTo,
  });
}

class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  final GlobalKey<NavigatorState>? _navigatorKey;

  /// SharedPreferences key prefixes that belong to ONE user and must be
  /// wiped on logout / account switch. Add new per-user keys here.
  static const List<String> _userScopedPrefPrefixes = [
    'location_search_history',
  ];

  User? _user;
  String? _token;
  bool _isLoading = false;
  bool _disposed = false;
  bool _ending = false;
  String? _error;
  bool _lastGoogleWasNew = false;

  /// Saved account for the one-tap "Continue as [User]" button.
  RememberedAccount? _remembered;
  bool _rememberedLoaded = false;

  /// Bumps on every logout / expiry / user switch. Per-user providers and
  /// async work compare against it to avoid cross-session leaks.
  int _sessionEpoch = 0;

  User? get user => _user;
  String? get token => _token;
  bool get isLoggedIn => _token != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _error;
  bool get lastGoogleWasNew => _lastGoogleWasNew;
  int get sessionEpoch => _sessionEpoch;

  /// Non-null when a one-tap login is available.
  RememberedAccount? get remembered => _remembered;
  bool get rememberedLoaded => _rememberedLoaded;

  AuthProvider({GlobalKey<NavigatorState>? navigatorKey})
      : _navigatorKey = navigatorKey {
    // Any ApiService (not just ours) reports an expired LIVE session here.
    ApiService.onGlobalSessionExpired = () => _endSession(redirect: true);
    _api.onSessionExpired = () => _endSession(redirect: true);
    _loadStoredSession();
    unawaited(_loadRemembered());
  }

  void clearError() {
    if (_error == null) return;
    _error = null;
    _safeNotify();
  }

  /// FCM token that can NEVER hang or throw. A stuck push-token request must
  /// not freeze registration / OTP verification / login.
  Future<String?> _fcmTokenSafe() async {
    try {
      return await FcmService.getToken().timeout(const Duration(seconds: 3));
    } catch (_) {
      return null;
    }
  }

  // ─── Register (customer) ─────────────────────────────────────
  Future<RegisterResult> register(
      String name,
      String email,
      String password,
      String confirmPassword, {
        String? phone,
      }) async {
    _setLoading(true);
    try {
      final res = await _api.register({
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': confirmPassword,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      });

      if (!res.success) {
        _error = res.message;
        return RegisterResult(success: false, message: res.message);
      }

      _error = null;
      final d = res.data is Map
          ? Map<String, dynamic>.from(res.data as Map)
          : <String, dynamic>{};

      return RegisterResult(
        success: true,
        message: res.message,
        otpSent: d['otp_sent'] == true,
        channel: d['otp_channel']?.toString(),
        sentTo: d['sent_to']?.toString(),
      );
    } catch (e) {
      debugPrint('register error: $e');
      _error = 'Registration failed. Please try again.';
      return RegisterResult(success: false, message: _error!);
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> registerFundi(Map<String, dynamic> data) async {
    _setLoading(true);
    try {
      final res = await _api.registerFundi(data);
      _error = res.success ? null : res.message;
      return res.success;
    } finally {
      _setLoading(false);
    }
  }

  // ─── Password login ──────────────────────────────────────────
  /// [rememberMe] = true asks the server for a long-lived remember token
  /// (30 days) that is stored securely for one-tap login.
  Future<bool> login(String identifier, String password,
      {bool rememberMe = false}) async {
    _setLoading(true);
    try {
      final res =
      await _api.login(identifier.trim(), password, rememberMe: rememberMe);
      if (res.success && res.data != null) {
        final map = Map<String, dynamic>.from(res.data as Map);
        await _saveSession(map);

        final remember = map['remember_token']?.toString();
        if (rememberMe && remember != null && remember.isNotEmpty) {
          await _persistRemembered(map, remember);
        }

        _error = null;
        return true;
      }
      _error = res.message;
      return false;
    } catch (e) {
      debugPrint('login error: $e');
      _error = 'Login failed. Please try again.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ─── One-tap login ("Continue as [User]") ────────────────────
  /// Exchanges the saved remember token for a fresh session token. The server
  /// rotates the remember token, and the new one is stored here.
  Future<bool> quickLogin() async {
    if (_remembered == null) return false;

    _setLoading(true);
    try {
      final rememberToken = await StorageService.getRememberToken();
      if (rememberToken == null || rememberToken.isEmpty) {
        await _clearRemembered();
        _error = 'Saved login is no longer valid. Please sign in again.';
        return false;
      }

      final fcmToken = await _fcmTokenSafe();
      final res = await _api.quickLogin(rememberToken, fcmToken: fcmToken);

      if (res.success && res.data != null) {
        final map = Map<String, dynamic>.from(res.data as Map);
        await _saveSession(map);

        final newRemember = map['remember_token']?.toString();
        if (newRemember != null && newRemember.isNotEmpty) {
          await _persistRemembered(map, newRemember);
        }

        _error = null;
        return true;
      }

      // 401 = token expired / revoked / password changed -> forget it.
      // Other errors (locked, inactive, offline) keep the saved account.
      if (res.statusCode == 401) {
        await _clearRemembered();
      }
      _error = res.message;
      return false;
    } catch (e) {
      debugPrint('quickLogin error: $e');
      _error = 'Login failed. Please try again.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// "Use another account": removes the saved login (server + device).
  Future<void> forgetRemembered() async {
    final token = await StorageService.getRememberToken();
    await _clearRemembered();
    if (token != null && token.isNotEmpty) {
      unawaited(_api.forgetRemembered(token));
    }
  }

  // ─── Google login (with detailed logs) ───────────────────────
  Future<GoogleLoginOutcome> signInWithGoogle() async {
    _setLoading(true);
    try {
      debugPrint('[GOOGLE] ===== Starting Google Sign-In =====');

      // 1) Get a Google ID token from the device.
      final String idToken;
      try {
        idToken = await GoogleAuthService.getIdToken();
        debugPrint('[GOOGLE] Successfully got ID Token (length: ${idToken.length})');
      } on GoogleSignInCancelled catch (c) {
        debugPrint('[GOOGLE] Cancelled. looksLikeConfigError=${c.looksLikeConfigError}');
        if (c.looksLikeConfigError) {
          _error = 'Google sign-in closed immediately. '
              'Check the Android OAuth client (package name and SHA-1).';
          return GoogleLoginOutcome.failed;
        }
        return GoogleLoginOutcome.cancelled;
      } on GoogleSignInException catch (e) {
        debugPrint('[GOOGLE] GoogleSignInException');
        debugPrint('  code    : ${e.code}');
        debugPrint('  details : ${e.details}');
        debugPrint('  message : ${e.toString()}');
        _error = _googleErrorFor(e.code);
        return GoogleLoginOutcome.failed;
      } catch (e, st) {
        debugPrint('[GOOGLE] Unexpected error while getting token:');
        debugPrint('  $e');
        debugPrint('  $st');
        _error = 'Google sign-in failed. Please try again.';
        return GoogleLoginOutcome.failed;
      }

      // 2) Optional push token (never blocks sign-in).
      final String? fcmToken = await _fcmTokenSafe();
      debugPrint('[GOOGLE] FCM token: ${fcmToken != null ? "received" : "null"}');

      // 3) Exchange the ID token with the server.
      debugPrint('[GOOGLE] Sending ID token to backend...');
      final res = await _api.loginWithGoogle(idToken, fcmToken: fcmToken);

      debugPrint('[GOOGLE] Backend response → success=${res.success}, message=${res.message}');

      if (!res.success || res.data == null) {
        _error = res.message.isNotEmpty
            ? res.message
            : 'Google sign-in failed. Please try again.';
        return GoogleLoginOutcome.failed;
      }

      final map = Map<String, dynamic>.from(res.data as Map);
      _lastGoogleWasNew = map['is_new_user'] == true;
      await _saveSession(map);
      _error = null;

      debugPrint('[GOOGLE] Login successful. is_new_user=$_lastGoogleWasNew');
      return GoogleLoginOutcome.success;
    } catch (e, st) {
      debugPrint('[GOOGLE] Unexpected top-level error:');
      debugPrint('  $e');
      debugPrint('  $st');
      _error = 'Google sign-in failed. Please try again.';
      return GoogleLoginOutcome.failed;
    } finally {
      _setLoading(false);
    }
  }

  String _googleErrorFor(GoogleSignInExceptionCode? code) {
    switch (code) {
      case GoogleSignInExceptionCode.canceled:
        return 'Google sign-in was cancelled.';
      case GoogleSignInExceptionCode.clientConfigurationError:
        return 'Google sign-in is misconfigured (serverClientId / SHA-1).';
      case GoogleSignInExceptionCode.providerConfigurationError:
        return 'Google provider is misconfigured on this device.';
      case GoogleSignInExceptionCode.uiUnavailable:
        return 'Google sign-in UI is unavailable. Try again.';
      case GoogleSignInExceptionCode.userMismatch:
        return 'A different Google account is already signed in.';
      default:
        return 'Google sign-in failed. Please try again.';
    }
  }

  // ─── Apple login ─────────────────────────────────────────────
  Future<bool> loginWithApple({
    required String identityToken,
    String? nonce,
    String? name,
  }) async {
    _setLoading(true);
    try {
      final fcmToken = await _fcmTokenSafe();
      final res = await _api.loginWithApple(
        identityToken: identityToken,
        nonce: nonce,
        name: name,
        fcmToken: fcmToken,
      );
      if (res.success && res.data != null) {
        await _saveSession(Map<String, dynamic>.from(res.data as Map));
        _error = null;
        return true;
      }
      _error = res.message;
      return false;
    } catch (e) {
      debugPrint('Apple login error: $e');
      _error = 'Apple sign-in failed. Please try again.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ─── OTP / password flows ────────────────────────────────────
  /// Verifies the registration OTP. On success the backend returns a token,
  /// which is saved here, so the user is logged in afterwards.
  Future<bool> verifyOtp(String email, String otp) async {
    _setLoading(true);
    try {
      final fcmToken = await _fcmTokenSafe();
      final res = await _api.verifyOtp(email, otp, fcmToken: fcmToken);
      if (res.success && res.data != null) {
        await _saveSession(Map<String, dynamic>.from(res.data as Map));
        _error = null;
        return true;
      }
      _error = res.message;
      return false;
    } catch (e) {
      debugPrint('verifyOtp error: $e');
      _error = 'Verification failed. Please try again.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> forgotPassword(String email) =>
      _simple(() => _api.forgotPassword(email));

  Future<bool> resetPassword(String email, String otp, String password) =>
      _simple(() =>
          _api.resetPassword(email: email, otp: otp, password: password));

  Future<bool> changePassword(String current, String newPwd) => _simple(
          () => _api.changePassword(currentPassword: current, newPassword: newPwd));

  Future<bool> resendOtp(String email) => _simple(() => _api.resendOtp(email));

  Future<bool> _simple(Future<ApiResponse> Function() call) async {
    _setLoading(true);
    try {
      final res = await call();
      _error = res.success ? null : res.message;
      return res.success;
    } finally {
      _setLoading(false);
    }
  }

  // ─── Profile ─────────────────────────────────────────────────
  Future<bool> updateProfile(Map<String, dynamic> data) async {
    _setLoading(true);
    final epoch = _sessionEpoch;
    try {
      final res = await _api.updateProfile(data);
      if (epoch != _sessionEpoch) return false;
      if (res.success && res.data != null && _token != null) {
        final userData = res.data['user'] ?? res.data;
        _user = User.fromJson(userData, _token!);
        await _storeUser();
        unawaited(_syncRememberedProfile(_user!));
        _error = null;
        return true;
      }
      _error = res.message;
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateLocale(String locale) async {
    _setLoading(true);
    try {
      // Guests have no server profile; only persist locally.
      if (_user == null) {
        await StorageService.saveLocale(locale);
        return true;
      }
      final res = await _api.updateLocale(locale);
      if (res.success && _user != null) {
        _user = _user!.copyWith(locale: locale);
        await _storeUser();
        await StorageService.saveLocale(locale);
        _error = null;
        return true;
      }
      _error = res.message;
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteAccount() async {
    _setLoading(true);
    try {
      final token = _token;
      final res = await _api.deleteAccount();
      if (res.success) {
        // The account no longer exists: its saved one-tap login must go too.
        await _clearRemembered();
        await _endSession(redirect: true);
        if (token != null) unawaited(_revokeRemote(token, null));
        return true;
      }
      _error = res.message;
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadUser() async {
    if (_token == null) return;
    final epoch = _sessionEpoch;
    final tokenAtStart = _token;
    _setLoading(true);
    try {
      final res = await _api.getProfile();
      if (epoch != _sessionEpoch || tokenAtStart != _token) return;
      if (res.success && res.data != null) {
        final userData = res.data['user'] ?? res.data;
        final fresh = User.fromJson(userData, _token!);
        if (_user != null && fresh.id != _user!.id) {
          await _endSession(redirect: true);
          return;
        }
        _user = fresh;
        await _storeUser();
        unawaited(_syncRememberedProfile(fresh));
        _error = null;
      } else {
        _error = res.message;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // ─── Logout ──────────────────────────────────────────────────
  /// Local logout is immediate and complete. Server revocation (Sanctum token
  /// + FCM token) runs afterwards with an explicit token, with a retry.
  /// The remembered account is KEPT so the login screen can offer
  /// "Continue as [User]".
  Future<void> logout() async {
    final token = _token;
    String? fcm;
    try {
      fcm = await FcmService.getToken().timeout(const Duration(seconds: 2));
    } catch (_) {}

    await _endSession(redirect: true);

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

  // ==============================================================
  // PRIVATE
  // ==============================================================

  // ─── Remember-me helpers ─────────────────────────────────────
  Future<void> _loadRemembered() async {
    _remembered = await StorageService.getRememberedAccount();
    _rememberedLoaded = true;
    _safeNotify();
  }

  Future<void> _persistRemembered(
      Map<String, dynamic> data, String rememberToken) async {
    try {
      final userData = data['user'] is Map
          ? Map<String, dynamic>.from(data['user'] as Map)
          : <String, dynamic>{};
      final u = User.fromJson(userData, '');
      if (u.id == 0) return;

      final keepPhoto = (_remembered?.id == u.id) ? _remembered?.photo : null;

      final account = RememberedAccount(
        id: u.id,
        name: u.name,
        email: u.email,
        photo: u.profilePhoto ?? keepPhoto,
      );

      await StorageService.saveRememberToken(rememberToken);
      await StorageService.saveRememberedAccount(account);
      _remembered = account;
      _rememberedLoaded = true;
      _safeNotify();
    } catch (e) {
      debugPrint('persist remembered failed: $e');
    }
  }

  /// Keeps the saved name / photo fresh (e.g. the Google photo that /me returns).
  Future<void> _syncRememberedProfile(User u) async {
    final r = _remembered;
    if (r == null || r.id != u.id) return;
    if (r.name == u.name && r.email == u.email && r.photo == u.profilePhoto) {
      return;
    }
    final updated = r.copyWith(
      name: u.name,
      email: u.email.isNotEmpty ? u.email : null,
      photo: u.profilePhoto,
    );
    _remembered = updated;
    await StorageService.saveRememberedAccount(updated);
    _safeNotify();
  }

  Future<void> _clearRemembered() async {
    await StorageService.clearRemembered();
    _remembered = null;
    _rememberedLoaded = true;
    _safeNotify();
  }

  /// Single place where a session ends (logout, expiry, user switch).
  Future<void> _endSession({required bool redirect}) async {
    if (_ending) return;
    _ending = true;
    try {
      _token = null;
      _user = null;
      _isLoading = false;
      _error = null;
      _lastGoogleWasNew = false;
      _sessionEpoch++; // <- every per-session provider is rebuilt
      _safeNotify();

      try {
        await StorageService.clearAll(); // does NOT touch the remembered account
      } catch (e) {
        debugPrint('clearAll failed: $e');
      }
      try {
        await GoogleAuthService.signOut();
      } catch (_) {}
      await _wipeUserScopedPrefs();

      if (redirect) _redirectToLogin();
    } finally {
      _ending = false;
    }
  }

  Future<void> _wipeUserScopedPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final key in prefs.getKeys().toList()) {
        if (_userScopedPrefPrefixes.any(key.startsWith)) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      debugPrint('wipe prefs failed: $e');
    }
  }

  /// Runs AFTER the frame in which providers were rebuilt, so the new
  /// HomeScreen/LoginScreen reads the fresh providers.
  void _redirectToLogin() {
    final nav = _navigatorKey;
    if (nav == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      nav.currentState
          ?.pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
    });
  }

  Future<void> _loadStoredSession() async {
    final storedToken = await StorageService.getToken();
    if (storedToken == null) return;

    final userJson = await StorageService.getUserJson();
    if (userJson != null) {
      try {
        final map = jsonDecode(userJson) as Map<String, dynamic>;
        _token = storedToken;
        _user = User.fromJson(map, storedToken);
        _safeNotify();
        unawaited(_refreshProfileQuietly());
      } catch (_) {
        await _endSession(redirect: false);
      }
    } else {
      await _fetchAndSaveUser(storedToken);
    }
  }

  Future<void> _refreshProfileQuietly() async {
    final epoch = _sessionEpoch;
    final tokenAtStart = _token;
    try {
      final res = await _api.getProfile();
      if (epoch != _sessionEpoch || tokenAtStart != _token) return;
      if (res.success && res.data != null) {
        final userData = res.data['user'] ?? res.data;
        final fresh = User.fromJson(userData, _token!);
        // Stored user doesn't match the token's owner -> corrupted/stale.
        if (_user != null && fresh.id != _user!.id) {
          await _endSession(redirect: true);
          return;
        }
        _user = fresh;
        await _storeUser();
        unawaited(_syncRememberedProfile(fresh));
        _safeNotify();
      }
    } catch (_) {}
  }

  Future<void> _fetchAndSaveUser(String token) async {
    final epoch = _sessionEpoch;
    final res = await _api.getProfile();
    if (epoch != _sessionEpoch) return;
    if (res.success && res.data != null) {
      final userData = res.data['user'] ?? res.data;
      _token = token;
      _user = User.fromJson(userData, token);
      await StorageService.saveToken(token);
      await _storeUser();
      await _registerFcmQuietly();
      _safeNotify();
    } else {
      await _endSession(redirect: false);
    }
  }

  Future<void> _saveSession(Map<String, dynamic> data) async {
    final userData = data['user'] ?? data;
    final token = data['token']?.toString();
    if (token == null || token.isEmpty) {
      throw StateError('Login response did not include a token.');
    }

    final parsed = User.fromJson(userData, token);

    // Logging in as someone else while a session exists: fully isolate.
    if (_user != null && _user!.id != parsed.id) {
      final oldToken = _token;
      _sessionEpoch++;
      await _wipeUserScopedPrefs();
      if (oldToken != null) unawaited(_revokeRemote(oldToken, null));
    }

    _token = token;
    _user = parsed;

    await StorageService.saveToken(token);
    await _storeUser();
    _safeNotify();
    unawaited(_registerFcmQuietly());
  }

  Future<void> _storeUser() async {
    if (_user == null) return;
    await StorageService.saveUserJson(jsonEncode(_user!.toJson()));
  }

  Future<void> _registerFcmQuietly() async {
    final epoch = _sessionEpoch;
    try {
      final fcmToken = await _fcmTokenSafe();
      if (fcmToken == null || epoch != _sessionEpoch) return;
      final res = await _api.updateDeviceToken(fcmToken);
      if (!res.success) debugPrint('FCM push failed: ${res.message}');
    } catch (e) {
      debugPrint('FCM registration error: $e');
    }
  }

  void _setLoading(bool value) {
    if (_isLoading == value) return;
    _isLoading = value;
    if (value) _error = null;
    _safeNotify();
  }

  void _safeNotify() {
    if (_disposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    ApiService.onGlobalSessionExpired = null;
    super.dispose();
  }
}