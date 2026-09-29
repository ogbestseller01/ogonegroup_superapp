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

  User? _user;
  String? _token;
  bool _isLoading = false;
  String? _error;

  // ── Public getters ────────────────────────────────────────────────────────
  User? get user => _user;
  String? get token => _token;
  bool get isLoggedIn => _token != null && _user != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _error;

  /// Expose API for registration steps (legacy)
  ApiService get api => _api;

  AuthProvider({GlobalKey<NavigatorState>? navigatorKey}) {
    _api.onSessionExpired = () async {
      await _clearSession();
      navigatorKey?.currentState?.pushNamedAndRemoveUntil(
        '/login',
            (_) => false,
      );
    };
    _loadStoredSession();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ── Register (customer) ───────────────────────────────────────────────────
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

    _setLoading(false);

    if (res.success == true) {
      return true;
    }

    _error = res.message;
    notifyListeners();
    return false;
  }

  // ── Register Fundi (legacy) ───────────────────────────────────────────────
  Future<bool> registerFundi(Map<String, dynamic> data) async {
    _setLoading(true);

    final res = await _api.registerFundi(data);

    _setLoading(false);

    if (res.success == true) {
      return true;
    }

    _error = res.message;
    notifyListeners();
    return false;
  }

  // ── Login (email OR phone) ────────────────────────────────────────────────
  Future<bool> login(String identifier, String password) async {
    _setLoading(true);

    final res = await _api.login(identifier, password);

    if (res.success == true && res.data != null) {
      await _saveSession(Map<String, dynamic>.from(res.data as Map));
      _setLoading(false);
      return true;
    }

    _error = res.message;
    _setLoading(false);
    return false;
  }

  // ── Verify OTP ────────────────────────────────────────────────────────────
  Future<bool> verifyOtp(String email, String otp) async {
    _setLoading(true);

    String? fcmToken;
    try {
      fcmToken = await FcmService.getToken();
    } catch (_) {
      fcmToken = null;
    }

    final res = await _api.verifyOtp(email, otp, fcmToken: fcmToken);

    if (res.success == true && res.data != null) {
      await _saveSession(Map<String, dynamic>.from(res.data as Map));
      _setLoading(false);
      return true;
    }

    _error = res.message;
    _setLoading(false);
    return false;
  }

  // ── Forgot Password ───────────────────────────────────────────────────────
  Future<bool> forgotPassword(String email) async {
    _setLoading(true);

    final res = await _api.forgotPassword(email);

    _setLoading(false);

    if (res.success == true) {
      return true;
    }

    _error = res.message;
    notifyListeners();
    return false;
  }

  // ── Reset Password ────────────────────────────────────────────────────────
  Future<bool> resetPassword(
      String email,
      String otp,
      String password,
      ) async {
    _setLoading(true);

    final res = await _api.resetPassword(
      email: email,
      otp: otp,
      password: password,
    );

    _setLoading(false);

    if (res.success == true) {
      return true;
    }

    _error = res.message;
    notifyListeners();
    return false;
  }

  // ── Update Profile ────────────────────────────────────────────────────────
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

  // ── Change Password ───────────────────────────────────────────────────────
  Future<bool> changePassword(String current, String newPwd) async {
    _setLoading(true);

    final res = await _api.changePassword(
      currentPassword: current,
      newPassword: newPwd,
    );

    _setLoading(false);

    if (res.success == true) {
      return true;
    }

    _error = res.message;
    notifyListeners();
    return false;
  }

  // ── Update Locale ─────────────────────────────────────────────────────────
  Future<bool> updateLocale(String locale) async {
    _setLoading(true);

    final res = await _api.updateLocale(locale);
    final currentUser = _user;
    final currentToken = _token;

    if (res.success == true &&
        currentUser != null &&
        currentToken != null) {
      _user = User(
        id: currentUser.id,
        name: currentUser.name,
        email: currentUser.email,
        phone: currentUser.phone,
        nida: currentUser.nida,
        locale: locale,
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

  // ── Resend OTP ────────────────────────────────────────────────────────────
  Future<bool> resendOtp(String email) async {
    _setLoading(true);

    final res = await _api.resendOtp(email);

    _setLoading(false);

    if (res.success == true) {
      return true;
    }

    _error = res.message;
    notifyListeners();
    return false;
  }

  // ── Delete Account ────────────────────────────────────────────────────────
  Future<bool> deleteAccount() async {
    _setLoading(true);

    final res = await _api.deleteAccount();

    _setLoading(false);

    if (res.success == true) {
      await logout();
      return true;
    }

    _error = res.message;
    notifyListeners();
    return false;
  }

  // ── Logout ────────────────────────────────────────────────────────────────
  Future<void> logout() async {
    try {
      await _api.logout();
    } catch (_) {
      // Still clear local session even if API fails
    }
    await _clearSession();
  }

  // ── Registration step (resume) ────────────────────────────────────────────
  Future<int?> getRegistrationStep(int technicianId) async {
    final res = await _api.getRegistrationStatus(technicianId);

    if (res.success != true || res.data == null) {
      return null;
    }

    final data = Map<String, dynamic>.from(res.data as Map);

    if (data['registration_completed'] == true) {
      return null; // already completed → user should login
    }

    final step = data['registration_step'];
    if (step is int) return step;
    if (step is num) return step.toInt();
    return null;
  }

  // ── 4-step Fundi registration ─────────────────────────────────────────────

  /// Step 1: Personal information → returns technicianId or null
  Future<int?> registerTechnicianStep1(Map<String, dynamic> data) async {
    _setLoading(true);

    final res = await _api.registerTechnicianStep1(data);

    _setLoading(false);

    if (res.success == true && res.data != null) {
      final id = (res.data as Map)['technician_id'];
      if (id is int) return id;
      if (id is num) return id.toInt();
      return null;
    }

    _error = res.message;
    notifyListeners();
    return null;
  }

  /// Step 2: Identification
  Future<bool> registerTechnicianStep2({
    required int technicianId,
    required String nida,
    required String idDocumentType,
    required File idDocumentImage,
  }) async {
    _setLoading(true);

    final res = await _api.registerTechnicianStep2(
      technicianId: technicianId,
      nida: nida,
      idDocumentType: idDocumentType,
      idDocumentImage: idDocumentImage,
    );

    _setLoading(false);

    if (res.success == true) {
      return true;
    }

    _error = res.message;
    notifyListeners();
    return false;
  }

  /// Step 3: Working area
  Future<bool> registerTechnicianStep3({
    required int technicianId,
    required String area,
    double? latitude,
    double? longitude,
  }) async {
    _setLoading(true);

    final res = await _api.registerTechnicianStep3(
      technicianId: technicianId,
      area: area,
      latitude: latitude,
      longitude: longitude,
    );

    _setLoading(false);

    if (res.success == true) {
      return true;
    }

    _error = res.message;
    notifyListeners();
    return false;
  }

  /// Step 4: Services & pricing
  Future<bool> registerTechnicianStep4({
    required int technicianId,
    required List<Map<String, dynamic>> services,
  }) async {
    _setLoading(true);

    final res = await _api.registerTechnicianStep4(
      technicianId: technicianId,
      services: services,
    );

    _setLoading(false);

    if (res.success == true) {
      return true;
    }

    _error = res.message;
    notifyListeners();
    return false;
  }

  /// Submit final registration
  Future<bool> submitTechnicianRegistration(int technicianId) async {
    _setLoading(true);

    final res = await _api.submitTechnicianRegistration(technicianId);

    _setLoading(false);

    if (res.success == true) {
      return true;
    }

    _error = res.message;
    notifyListeners();
    return false;
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  Future<void> _loadStoredSession() async {
    final storedToken = await StorageService.getToken();
    if (storedToken == null || storedToken.isEmpty) {
      return;
    }

    final userJson = await StorageService.getUserJson();

    if (userJson != null && userJson.isNotEmpty) {
      try {
        final Map<String, dynamic> userMap =
        Map<String, dynamic>.from(jsonDecode(userJson) as Map);
        _token = storedToken;
        _user = User.fromJson(userMap, storedToken);
        notifyListeners();
        _refreshProfile();
      } catch (e) {
        debugPrint('Failed to restore user session: $e');
        await _clearSession();
      }
    } else {
      await _fetchAndSaveUser(storedToken);
    }
  }

  Future<void> _refreshProfile() async {
    final currentToken = _token;
    if (currentToken == null) return;

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
  }

  Future<void> _fetchAndSaveUser(String token) async {
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
    } else {
      await _clearSession();
    }
  }

  Future<void> _saveSession(Map<String, dynamic> data) async {
    if (data['user'] == null || data['token'] == null) {
      return;
    }

    final token = data['token'].toString();
    final userMap = Map<String, dynamic>.from(data['user'] as Map);

    _token = token;
    _user = User.fromJson(userMap, token);

    await StorageService.saveToken(token);
    await _storeUser();
    await _registerFcm();
    notifyListeners();
  }

  Future<void> _clearSession() async {
    _token = null;
    _user = null;
    await StorageService.clearAll();
    notifyListeners();
  }

  Future<void> _storeUser() async {
    final currentUser = _user;
    if (currentUser != null) {
      await StorageService.saveUserJson(jsonEncode(currentUser.toJson()));
    }
  }

  Future<void> _registerFcm() async {
    try {
      final fcmToken = await FcmService.getToken();
      if (fcmToken == null || fcmToken.isEmpty) {
        debugPrint('⚠️ FCM token unavailable');
        return;
      }

      final res = await _api.updateDeviceToken(fcmToken);
      if (res.success != true) {
        debugPrint('⚠️ Failed to push FCM token: ${res.message}');
      }
    } catch (e) {
      debugPrint('⚠️ FCM registration error: $e');
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    if (value == true) {
      _error = null;
    }
    notifyListeners();
  }
}