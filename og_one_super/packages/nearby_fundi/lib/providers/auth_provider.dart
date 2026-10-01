// lib/providers/auth_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/fcm_service.dart';
import '../models/user.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  User? _user;
  String? _token;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  String? get token => _token;
  bool get isLoggedIn => _token != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _error;

  AuthProvider({GlobalKey<NavigatorState>? navigatorKey}) {
    _api.onSessionExpired = () async {
      await _clearSession();
      navigatorKey?.currentState?.pushNamedAndRemoveUntil('/login', (_) => false);
    };
    _loadStoredSession();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ─── Register Customer ─────────────────────────────────────────────
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

    if (res.success) return true;

    _error = res.message;
    notifyListeners();
    return false;
  }

  // ─── Register Fundi ────────────────────────────────────────────────
  Future<bool> registerFundi(Map<String, dynamic> data) async {
    _setLoading(true);
    final res = await _api.registerFundi(data);
    _setLoading(false);

    if (res.success) return true;

    _error = res.message;
    notifyListeners();
    return false;
  }

  // ─── Login (Email or Phone) ────────────────────────────────────────
  Future<bool> login(String identifier, String password) async {
    _setLoading(true);
    final res = await _api.login(identifier.trim(), password);

    if (res.success && res.data != null) {
      await _saveSession(res.data);
      _setLoading(false);
      return true;
    }

    _error = res.message;
    _setLoading(false);
    return false;
  }

  // ─── Google Login ──────────────────────────────────────────────────
  Future<bool> loginWithGoogle(String idToken) async {
    _setLoading(true);
    final fcmToken = await FcmService.getToken().catchError((_) => null);

    final res = await _api.loginWithGoogle(idToken, fcmToken: fcmToken);
    _setLoading(false);

    if (res.success && res.data != null) {
      await _saveSession(res.data);
      return true;
    }

    _error = res.message;
    notifyListeners();
    return false;
  }

  // ─── Verify OTP ────────────────────────────────────────────────────
  Future<bool> verifyOtp(String email, String otp) async {
    _setLoading(true);
    final fcmToken = await FcmService.getToken().catchError((_) => null);

    final res = await _api.verifyOtp(email, otp, fcmToken: fcmToken);

    if (res.success && res.data != null) {
      await _saveSession(res.data);
      _setLoading(false);
      return true;
    }

    _error = res.message;
    _setLoading(false);
    return false;
  }

  // ─── Forgot Password ───────────────────────────────────────────────
  Future<bool> forgotPassword(String email) async {
    _setLoading(true);
    final res = await _api.forgotPassword(email);
    _setLoading(false);

    if (res.success) return true;

    _error = res.message;
    notifyListeners();
    return false;
  }

  // ─── Reset Password ────────────────────────────────────────────────
  Future<bool> resetPassword(String email, String otp, String password) async {
    _setLoading(true);
    final res = await _api.resetPassword(
      email: email,
      otp: otp,
      password: password,
    );
    _setLoading(false);

    if (res.success) return true;

    _error = res.message;
    notifyListeners();
    return false;
  }

  // ─── Update Profile ────────────────────────────────────────────────
  Future<bool> updateProfile(Map<String, dynamic> data) async {
    _setLoading(true);
    final res = await _api.updateProfile(data);

    if (res.success && res.data != null) {
      final userData = res.data['user'] ?? res.data;
      _user = User.fromJson(userData, _token!);
      await _storeUser();
      _setLoading(false);
      notifyListeners();
      return true;
    }

    _error = res.message;
    _setLoading(false);
    return false;
  }

  // ─── Change Password ───────────────────────────────────────────────
  Future<bool> changePassword(String current, String newPwd) async {
    _setLoading(true);
    final res = await _api.changePassword(
      currentPassword: current,
      newPassword: newPwd,
    );
    _setLoading(false);

    if (res.success) return true;

    _error = res.message;
    notifyListeners();
    return false;
  }

  // ─── Update Locale ─────────────────────────────────────────────────
  Future<bool> updateLocale(String locale) async {
    _setLoading(true);
    final res = await _api.updateLocale(locale);

    if (res.success && _user != null) {
      _user = _user!.copyWith(locale: locale);
      await _storeUser();
      await StorageService.saveLocale(locale);
      _setLoading(false);
      return true;
    }

    _error = res.message;
    _setLoading(false);
    return false;
  }

  // ─── Resend OTP ────────────────────────────────────────────────────
  Future<bool> resendOtp(String email) async {
    _setLoading(true);
    final res = await _api.resendOtp(email);
    _setLoading(false);

    if (res.success) return true;

    _error = res.message;
    notifyListeners();
    return false;
  }

  // ─── Delete Account ────────────────────────────────────────────────
  Future<bool> deleteAccount() async {
    _setLoading(true);
    final res = await _api.deleteAccount();
    _setLoading(false);

    if (res.success) {
      await logout();
      return true;
    }

    _error = res.message;
    notifyListeners();
    return false;
  }

  // ─── Load User (refresh profile) ───────────────────────────────────
  Future<void> loadUser() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _api.getProfile();
      if (res.success && res.data != null) {
        final userData = res.data['user'] ?? res.data;
        _user = User.fromJson(userData, _token!);
        await _storeUser();
        _error = null;
      } else {
        _error = res.message;
      }
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  // ─── Logout ────────────────────────────────────────────────────────
  Future<void> logout() async {
    try {
      await _api.logout();
    } catch (_) {
      // Ignore network errors on logout
    }
    await _clearSession();
  }

  // ==================== PRIVATE HELPERS ====================

  Future<void> _loadStoredSession() async {
    final storedToken = await StorageService.getToken();
    if (storedToken == null) return;

    final userJson = await StorageService.getUserJson();
    if (userJson != null) {
      try {
        final Map<String, dynamic> userMap = jsonDecode(userJson);
        _token = storedToken;
        _user = User.fromJson(userMap, storedToken);
        notifyListeners();
        _refreshProfile();
      } catch (_) {
        await _clearSession();
      }
    } else {
      await _fetchAndSaveUser(storedToken);
    }
  }

  Future<void> _refreshProfile() async {
    final res = await _api.getProfile();
    if (res.success && res.data != null) {
      final userData = res.data['user'] ?? res.data;
      _user = User.fromJson(userData, _token!);
      await _storeUser();
      notifyListeners();
    }
  }

  Future<void> _fetchAndSaveUser(String token) async {
    final res = await _api.getProfile();
    if (res.success && res.data != null) {
      final userData = res.data['user'] ?? res.data;
      _token = token;
      _user = User.fromJson(userData, token);
      await StorageService.saveToken(token);
      await _storeUser();
      await _registerFcm();
      notifyListeners();
    } else {
      await _clearSession();
    }
  }

  Future<void> _saveSession(Map<String, dynamic> data) async {
    final userData = data['user'] ?? data;
    _token = data['token'];
    _user = User.fromJson(userData, _token!);
    await StorageService.saveToken(_token!);
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
    if (_user != null) {
      await StorageService.saveUserJson(jsonEncode(_user!.toJson()));
    }
  }

  Future<void> _registerFcm() async {
    try {
      final fcmToken = await FcmService.getToken();
      if (fcmToken == null) return;

      final res = await _api.updateDeviceToken(fcmToken);
      if (!res.success) {
        debugPrint('⚠️ Failed to push FCM token: ${res.message}');
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