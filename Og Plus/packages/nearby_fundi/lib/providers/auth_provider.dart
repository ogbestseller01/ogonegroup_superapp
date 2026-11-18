// lib/providers/auth_provider.dart
//
// Single source of truth for the authenticated session.
//
// Debug: every Google sign-in step is tagged [GOOGLE n/8] so you can
// isolate the failing stage via:
//   flutter logs | grep GOOGLE
//
// Steps:
//   1/8  entry (loading/terms already handled by UI)
//   2/8  GoogleAuthService.getIdToken()  ← picker + native auth
//   3/8  FCM token fetch (non-fatal)
//   4/8  ApiService.loginWithGoogle()    ← server call
//   5/8  server response validation
//   6/8  GoogleAuthResult parse
//   7/8  _saveSession (persist token + user + FCM)
//   8/8  success / cancelled / failed resolved

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart'
    show GoogleSignInException, GoogleSignInExceptionCode;

import '../models/google_auth_result.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/fcm_service.dart';
import '../services/google_auth_service.dart';
import '../services/storage_service.dart';

enum GoogleLoginOutcome { success, cancelled, failed }

class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  User? _user;
  String? _token;
  bool _isLoading = false;
  bool _disposed = false;
  String? _error;
  bool _lastGoogleWasNew = false;

  User? get user => _user;
  String? get token => _token;
  bool get isLoggedIn => _token != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _error;
  bool get lastGoogleWasNew => _lastGoogleWasNew;

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

  // ─── Google login (picker → ID token → server) ───────────────
  Future<GoogleLoginOutcome> signInWithGoogle() async {
    debugPrint('[GOOGLE 1/8] signInWithGoogle() entered');

    _setLoading(true);
    try {
      // ── 2/8: native picker + ID token ────────────────────────
      debugPrint('[GOOGLE 2/8] requesting Google ID token...');
      final String idToken;
      try {
        idToken = await GoogleAuthService.getIdToken();
      } on GoogleSignInCancelled catch (c) {
        // Closed almost instantly = Google rejected the app config,
        // not a real user cancel.
        if (c.looksLikeConfigError) {
          debugPrint('[GOOGLE 2/8] closed after ${c.elapsed.inMilliseconds}ms '
              '-> Android OAuth client (package + SHA-1) problem');
          _error = 'Google sign-in closed immediately. '
              'Check the Android OAuth client (package name and SHA-1).';
          return GoogleLoginOutcome.failed;
        }
        debugPrint('[GOOGLE 2/8] user cancelled the Google picker');
        return GoogleLoginOutcome.cancelled;
      } on GoogleSignInException catch (e) {
        // v7 surfaces all real failures here.
        debugPrint('[GOOGLE 2/8] GoogleSignInException '
            'code=${e.code} details=${e.details}');
        _error = _googleErrorFor(e.code);
        return GoogleLoginOutcome.failed;
      } catch (e, st) {
        debugPrint('[GOOGLE 2/8] unexpected error getting ID token: $e');
        debugPrint('$st');
        _error = 'Google sign-in failed. Please try again.';
        return GoogleLoginOutcome.failed;
      }

      debugPrint('[GOOGLE 2/8] ID token received '
          '(length=${idToken.length}, '
          'preview=${idToken.substring(0, idToken.length < 16 ? idToken.length : 16)}...)');

      // ── 3/8: FCM token (never fatal) ─────────────────────────
      String? fcmToken;
      try {
        fcmToken = await FcmService.getToken();
        debugPrint('[GOOGLE 3/8] FCM token: '
            '${fcmToken == null ? "null" : "ok"}');
      } catch (e) {
        debugPrint('[GOOGLE 3/8] FCM token fetch failed (non-fatal): $e');
      }

      // ── 4/8: server exchange ─────────────────────────────────
      debugPrint('[GOOGLE 4/8] calling /auth/google ...');
      final res = await _api.loginWithGoogle(idToken, fcmToken: fcmToken);

      debugPrint('[GOOGLE 5/8] server response: '
          'success=${res.success} '
          'message=${res.message} '
          'hasData=${res.data != null}');

      if (!res.success || res.data == null) {
        debugPrint('[GOOGLE 5/8] server rejected Google login '
            'message=${res.message}');
        // res.message is non-nullable String
        _error = res.message.isNotEmpty
            ? res.message
            : 'Google sign-in failed. Please try again.';
        return GoogleLoginOutcome.failed;
      }

      // ── 6/8: parse GoogleAuthResult ──────────────────────────
      final map = Map<String, dynamic>.from(res.data as Map);
      final result = GoogleAuthResult.fromJson(map);
      _lastGoogleWasNew = result.isNewUser;
      debugPrint('[GOOGLE 6/8] parsed GoogleAuthResult: '
          'isNewUser=$_lastGoogleWasNew '
          'userId=${result.user.id} '
          'email=${result.user.email}');

      // ── 7/8: persist session ─────────────────────────────────
      debugPrint('[GOOGLE 7/8] saving session...');
      await _saveSession(map);

      // ── 8/8: done ────────────────────────────────────────────
      debugPrint('[GOOGLE 8/8] Google login SUCCESS '
          '(isNewUser=$_lastGoogleWasNew)');
      _error = null;
      return GoogleLoginOutcome.success;
    } catch (e, st) {
      // Catch-all for anything not already handled above
      debugPrint('[GOOGLE 8/8] unexpected failure: $e');
      debugPrint('$st');
      _error = 'Google sign-in failed. Please try again.';
      return GoogleLoginOutcome.failed;
    } finally {
      _setLoading(false);
    }
  }

  // Human-readable messages for GoogleSignInException codes.
  String _googleErrorFor(GoogleSignInExceptionCode? code) {
    switch (code) {
      case GoogleSignInExceptionCode.canceled:
      // Handled before this is called, but keep for safety.
        return 'Google sign-in was cancelled.';
      case GoogleSignInExceptionCode.clientConfigurationError:
        return 'Google sign-in is misconfigured (serverClientId / SHA-1).';
      case GoogleSignInExceptionCode.providerConfigurationError:
        return 'Google provider is misconfigured on this device.';
      case GoogleSignInExceptionCode.uiUnavailable:
        return 'Google sign-in UI is unavailable. Try again.';
      case GoogleSignInExceptionCode.userMismatch:
        return 'A different Google account is already signed in.';
      case GoogleSignInExceptionCode.unknownError:
        return 'Google sign-in failed. Please try again.';
      default:
        return 'Google sign-in failed. Please try again.';
    }
  }

  // ─── Apple login ──────────────────────────────────────────────
  Future<bool> loginWithApple({
    required String identityToken,
    String? nonce,
    String? name,
  }) async {
    _setLoading(true);
    try {
      final fcmToken = await FcmService.getToken().catchError((_) => null);
      final res = await _api.loginWithApple(
        identityToken: identityToken,
        nonce: nonce,
        name: name,
        fcmToken: fcmToken,
      );
      if (res.success && res.data != null) {
        await _saveSession(res.data);
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
    if (_token == null) return;

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
  Future<void> logout() async {
    try {
      await GoogleAuthService.signOut();
      await _api.logout().timeout(const Duration(seconds: 5));
    } catch (_) {}
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
        unawaited(_refreshProfileQuietly());
      } catch (_) {
        await _clearSession();
      }
    } else {
      await _fetchAndSaveUser(storedToken);
    }
  }

  Future<void> _refreshProfileQuietly() async {
    try {
      final res = await _api.getProfile();
      if (res.success && res.data != null) {
        final userData = res.data['user'] ?? res.data;
        _user = User.fromJson(userData, _token!);
        await _storeUser();
        _safeNotify();
      }
    } catch (_) {}
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
      throw StateError('Login response did not include a token.');
    }

    final parsedUser = User.fromJson(userData, token);
    _token = token;
    _user = parsedUser;

    await StorageService.saveToken(token);
    await _storeUser();
    await _registerFcmQuietly();
    _safeNotify();
  }

  Future<void> _clearSession() async {
    await GoogleAuthService.signOut();
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