// lib/providers/auth_provider.dart
//
// Single source of truth for the authenticated session.
//
// • Every async entry point routes through _setLoading / _safeNotify so
//   listeners never see a half-set state (_token set + _user null).
// • _saveSession sets _token and _user together BEFORE notifying.
// • _disposed guards all notifyListeners() after dispose().
// • logout() has a bounded network call so offline logout returns fast.
// • deleteAccount() skips the redundant API logout on success.
// • _error is cleared on every successful write.
// • loadUser() is a no-op when there is no token.

import 'dart:async';
import 'dart:convert';

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
  bool _disposed = false;
  String? _error;

  User? get user => _user;
  String? get token => _token;
  bool get isLoggedIn => _token != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _error;

  AuthProvider({GlobalKey<NavigatorState>? navigatorKey}) {
    _api.onSessionExpired = () async {
      await _clearSession();
      navigatorKey?.currentState
          ?.pushNamedAndRemoveUntil('/login', (_) => false);
    };
    _loadStoredSession();
  }

  // ==============================================================
  // PUBLIC API
  // ==============================================================

  void clearError() {
    if (_error == null) return;
    _error = null;
    _safeNotify();
  }

  // ─── Register Customer ────────────────────────────────────────
  Future<bool> register(
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
      if (res.success) {
        _error = null;
        return true;
      }
      _error = res.message;
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ─── Register Fundi ───────────────────────────────────────────
  Future<bool> registerFundi(Map<String, dynamic> data) async {
    _setLoading(true);
    try {
      final res = await _api.registerFundi(data);
      if (res.success) {
        _error = null;
        return true;
      }
      _error = res.message;
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ─── Login (email or phone) ───────────────────────────────────
  Future<bool> login(String identifier, String password) async {
    _setLoading(true);
    try {
      final res = await _api.login(identifier.trim(), password);
      if (res.success && res.data != null) {
        await _saveSession(res.data);
        _error = null;
        return true;
      }
      _error = res.message;
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ─── Google login ─────────────────────────────────────────────
  Future<bool> loginWithGoogle(String idToken) async {
    _setLoading(true);
    try {
      final fcmToken =
      await FcmService.getToken().catchError((_) => null);
      final res = await _api.loginWithGoogle(idToken, fcmToken: fcmToken);
      if (res.success && res.data != null) {
        await _saveSession(res.data);
        _error = null;
        return true;
      }
      _error = res.message;
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ─── Verify OTP ───────────────────────────────────────────────
  Future<bool> verifyOtp(String email, String otp) async {
    _setLoading(true);
    try {
      final fcmToken =
      await FcmService.getToken().catchError((_) => null);
      final res = await _api.verifyOtp(email, otp, fcmToken: fcmToken);
      if (res.success && res.data != null) {
        await _saveSession(res.data);
        _error = null;
        return true;
      }
      _error = res.message;
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ─── Forgot password ──────────────────────────────────────────
  Future<bool> forgotPassword(String email) async {
    _setLoading(true);
    try {
      final res = await _api.forgotPassword(email);
      if (res.success) {
        _error = null;
        return true;
      }
      _error = res.message;
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ─── Reset password ───────────────────────────────────────────
  Future<bool> resetPassword(
      String email, String otp, String password) async {
    _setLoading(true);
    try {
      final res = await _api.resetPassword(
        email: email,
        otp: otp,
        password: password,
      );
      if (res.success) {
        _error = null;
        return true;
      }
      _error = res.message;
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ─── Update profile ───────────────────────────────────────────
  Future<bool> updateProfile(Map<String, dynamic> data) async {
    _setLoading(true);
    try {
      final res = await _api.updateProfile(data);
      if (res.success && res.data != null) {
        final userData = res.data['user'] ?? res.data;
        _user = User.fromJson(userData, _token!);
        await _storeUser();
        _error = null;
        return true;
      }
      _error = res.message;
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ─── Change password ──────────────────────────────────────────
  Future<bool> changePassword(String current, String newPwd) async {
    _setLoading(true);
    try {
      final res = await _api.changePassword(
        currentPassword: current,
        newPassword: newPwd,
      );
      if (res.success) {
        _error = null;
        return true;
      }
      _error = res.message;
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ─── Update locale ────────────────────────────────────────────
  Future<bool> updateLocale(String locale) async {
    _setLoading(true);
    try {
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

  // ─── Resend OTP ───────────────────────────────────────────────
  Future<bool> resendOtp(String email) async {
    _setLoading(true);
    try {
      final res = await _api.resendOtp(email);
      if (res.success) {
        _error = null;
        return true;
      }
      _error = res.message;
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ─── Delete account ───────────────────────────────────────────
  // We deliberately skip _api.logout() here: the account is gone, so
  // the call would 401. Just wipe the local session.
  Future<bool> deleteAccount() async {
    _setLoading(true);
    try {
      final res = await _api.deleteAccount();
      if (res.success) {
        await _clearSession();
        return true;
      }
      _error = res.message;
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ─── Load / refresh user ──────────────────────────────────────
  Future<void> loadUser() async {
    if (_token == null) return; // Not signed in — nothing to load.

    _setLoading(true);
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
    } finally {
      _setLoading(false);
    }
  }

  // ─── Logout ───────────────────────────────────────────────────
  // Bounded network call so offline logout returns in ≤5s.
  Future<void> logout() async {
    try {
      await _api.logout().timeout(const Duration(seconds: 5));
    } catch (_) {
      // Ignore — network, timeout, 401, all irrelevant to the user.
    }
    await _clearSession();
  }

  // ==============================================================
  // PRIVATE
  // ==============================================================

  Future<void> _loadStoredSession() async {
    final storedToken = await StorageService.getToken();
    if (storedToken == null) return;

    final userJson = await StorageService.getUserJson();
    if (userJson != null) {
      try {
        final Map<String, dynamic> userMap = jsonDecode(userJson);
        _token = storedToken;
        _user = User.fromJson(userMap, storedToken);
        _safeNotify();
        // Refresh in the background — no spinner, no error surface.
        unawaited(_refreshProfileQuietly());
      } catch (_) {
        await _clearSession();
      }
    } else {
      await _fetchAndSaveUser(storedToken);
    }
  }

  /// Silent refresh used at boot. Never sets _isLoading or _error so the
  /// splash screen isn't disrupted by a transient network error.
  Future<void> _refreshProfileQuietly() async {
    try {
      final res = await _api.getProfile();
      if (res.success && res.data != null) {
        final userData = res.data['user'] ?? res.data;
        _user = User.fromJson(userData, _token!);
        await _storeUser();
        _safeNotify();
      }
    } catch (_) {
      // Ignore — the stored user is still valid for the rest of the session.
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
      await _registerFcmQuietly();
      _safeNotify();
    } else {
      await _clearSession();
    }
  }

  Future<void> _saveSession(Map<String, dynamic> data) async {
    final userData = data['user'] ?? data;
    final token = data['token']?.toString();
    if (token == null || token.isEmpty) {
      // A "success" with no token is a broken server response. Treat it
      // as a failed login instead of crashing on _token!.
      throw StateError('Login response did not include a token.');
    }

    // Build both first, then commit together so listeners never see a
    // half-set state (token set, user null).
    final parsedUser = User.fromJson(userData, token);
    _token = token;
    _user = parsedUser;

    await StorageService.saveToken(token);
    await _storeUser();
    await _registerFcmQuietly();
    _safeNotify();
  }

  Future<void> _clearSession() async {
    _token = null;
    _user = null;
    _isLoading = false;
    _error = null;
    await StorageService.clearAll();
    _safeNotify();
  }

  Future<void> _storeUser() async {
    if (_user == null) return;
    await StorageService.saveUserJson(jsonEncode(_user!.toJson()));
  }

  Future<void> _registerFcmQuietly() async {
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
    super.dispose();
  }
}