// lib/providers/auth_provider.dart

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/user.dart';
import '../services/api_service.dart';
import '../services/fcm_service.dart';
import '../services/storage_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  final GlobalKey<NavigatorState>? _navigatorKey;

  User? _user;
  String? _token;
  bool _isLoading = false;
  String? _error;

  // ── Pending registration state ────────────────────────────
  int? _draftId;
  String? _registrationToken;

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

  bool get isPendingApproval => _user?.isPendingApproval ?? false;

  int? get draftId => _draftId;

  String? get registrationToken => _registrationToken;

  bool get hasRegistrationToken =>
      _registrationToken != null && _registrationToken!.isNotEmpty;

  ApiService get api => _api;

  AuthProvider({GlobalKey<NavigatorState>? navigatorKey})
      : _navigatorKey = navigatorKey {
    _api.onSessionExpired = _onSessionExpired;
    _loadStoredSession();
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
          ?.pushNamedAndRemoveUntil('/login', (_) => false);
    } finally {
      _handlingSessionExpiry = false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
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
    _error = res.message;
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
    _error = res.message;
    _setLoading(false);
    return false;
  }

  Future<bool> login(String identifier, String password) async {
    _setLoading(true);
    final res = await _api.login(identifier, password);
    if (res.success == true && res.data != null) {
      final ok = await _saveSession(
        Map<String, dynamic>.from(res.data as Map),
      );
      if (ok) {
        _setLoading(false);
        return true;
      }
    }
    _error = res.message ?? 'Login failed';
    _setLoading(false);
    return false;
  }

  Future<bool> verifyOtp(String identifier, String otp) async {
    _setLoading(true);
    String? fcmToken;
    try {
      fcmToken = await FcmService.getToken();
    } catch (_) {
      fcmToken = null;
    }
    final res = await _api.verifyOtp(identifier, otp, fcmToken: fcmToken);
    if (res.success == true && res.data != null) {
      final ok = await _saveSession(
        Map<String, dynamic>.from(res.data as Map),
        fcmToken: fcmToken,
      );
      if (ok) {
        _setLoading(false);
        return true;
      }
    }
    _error = res.message;
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
      _registrationToken = map['registration_token']?.toString();
      final rawDraftId = map['draft_id'] ?? _draftId;
      _draftId = rawDraftId is int
          ? rawDraftId
          : (rawDraftId is num ? rawDraftId.toInt() : int.tryParse('$rawDraftId'));

      if (_draftId != null) {
        await StorageService.saveTechnicianId(_draftId!);
      }
      if (_registrationToken != null && _registrationToken!.isNotEmpty) {
        await StorageService.saveRegistrationToken(_registrationToken!);
      }

      _setLoading(false);
      return true;
    }
    _error = res.message;
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
      _setLoading(false);
      return true;
    }
    _error = res.message;
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
    _error = res.message;
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
      _setLoading(false);
      return true;
    }
    _error = res.message;
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
        _error = 'Session expired';
        _setLoading(false);
        return false;
      }

      _user = User.fromJson(userData, currentToken);
      await _storeUser();
      _setLoading(false);
      notifyListeners();
      return true;
    }
    _error = res.message;
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
    _error = res.message;
    _setLoading(false);
    return false;
  }

  Future<bool> updateLocale(String locale) async {
    _setLoading(true);
    final res = await _api.updateLocale(locale);
    final currentUser = _user;
    final currentToken = _token;

    if (res.success == true && currentUser != null && currentToken != null) {
      _user = User(
        id: currentUser.id,
        name: currentUser.name,
        email: currentUser.email,
        phone: currentUser.phone,
        nida: currentUser.nida,
        locale: locale,
        status: currentUser.status,
        isActive: currentUser.isActive,
        token: currentToken,
      );
      await _storeUser();
      await StorageService.saveLocale(locale);
      _setLoading(false);
      notifyListeners();
      return true;
    }
    _error = res.message;
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
    _error = res.message;
    _setLoading(false);
    return false;
  }

  Future<bool> deleteAccount() async {
    _setLoading(true);
    final res = await _api.deleteAccount();
    if (res.success == true) {
      await logout();
      _setLoading(false);
      return true;
    }
    _error = res.message;
    _setLoading(false);
    return false;
  }

  Future<void> logout() async {
    try {
      await _api.logout();
    } catch (_) {}
    await _clearSession();
    _registrationToken = null;
    notifyListeners();
  }

  // ══════════════════════════════════════════════════════════
  // 6-STEP DRAFT-BASED REGISTRATION
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
      final rawId = map['draft_id'];
      _draftId = rawId is int
          ? rawId
          : (rawId is num ? rawId.toInt() : null);
      if (_draftId != null) {
        await StorageService.saveTechnicianId(_draftId!);
      }
      _setLoading(false);
      return _draftId;
    }
    _error = res.message;
    _setLoading(false);
    return null;
  }

  bool _ensureDraftToken() {
    if (_registrationToken == null || _registrationToken!.isEmpty) {
      _error = 'Registration session expired. Please start over.';
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
    _error = res.message;
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
    _error = res.message;
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
    _error = res.message;
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
    _error = res.message;
    notifyListeners();
    return false;
  }

  Future<bool> submitTechnicianRegistration() async {
    if (!_ensureDraftToken()) return false;
    _setLoading(true);

    String? fcmToken;
    try {
      fcmToken = await FcmService.getToken();
    } catch (e) {
      debugPrint('⚠️ FCM token unavailable at step 6: $e');
    }

    final res = await _api.submitTechnicianRegistration(
      registrationToken: _registrationToken!,
      fcmDeviceToken: fcmToken,
    );

    if (res.success == true && res.data is Map) {
      final map = Map<String, dynamic>.from(res.data as Map);
      final ok = await _saveSession(map, fcmToken: fcmToken);
      if (ok) {
        _registrationToken = null;
        _draftId = null;
        await StorageService.clearTechnicianData();
      }
      _setLoading(false);
      return ok;
    }

    _error = res.message;
    _setLoading(false);
    return false;
  }

  Future<void> abandonDraft() async {
    _registrationToken = null;
    _draftId = null;
    await StorageService.clearTechnicianData();
    notifyListeners();
  }

  // ══════════════════════════════════════════════════════════
  // BOOTSTRAP + PRIVATE HELPERS
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
          res.data != null &&
          res.data is Map &&
          (res.data as Map)['user'] != null) {
        final userMap =
        Map<String, dynamic>.from((res.data as Map)['user'] as Map);
        _user = User.fromJson(userMap, currentToken);
        await _storeUser();
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
          res.data != null &&
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

  Future<bool> _saveSession(
      Map<String, dynamic> data, {
        String? fcmToken,
      }) async {
    final rawUser = data['user'];
    final rawToken = data['token'];
    if (rawUser is! Map || rawToken == null) return false;

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

  Future<void> _clearSession() async {
    final hadSession = _token != null || _user != null;
    _token = null;
    _user = null;
    await StorageService.clearAuth();
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
      final fcmToken = providedToken ?? await FcmService.getToken();
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

  void _setLoading(bool value) {
    _isLoading = value;
    if (value) _error = null;
    notifyListeners();
  }
}