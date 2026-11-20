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

  AuthProvider({GlobalKey<NavigatorState>? navigatorKey})
      : _navigatorKey = navigatorKey {
    // Any ApiService (not just ours) reports an expired LIVE session here.
    ApiService.onGlobalSessionExpired = () => _endSession(redirect: true);
    _api.onSessionExpired = () => _endSession(redirect: true);
    _loadStoredSession();
  }

  void clearError() {
    if (_error == null) return;
    _error = null;
    _safeNotify();
  }

  // ─── Register ────────────────────────────────────────────────
  Future<bool> register(String name, String email, String password,
      String confirmPassword,
      {String? phone}) async {
    _setLoading(true);
    try {
      final res = await _api.register({
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': confirmPassword,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      });
      _error = res.success ? null : res.message;
      return res.success;
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
  Future<bool> login(String identifier, String password) async {
    _setLoading(true);
    try {
      final res = await _api.login(identifier.trim(), password);
      if (res.success && res.data != null) {
        await _saveSession(Map<String, dynamic>.from(res.data as Map));
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

      // 2) Optional push token.
      String? fcmToken;
      try {
        fcmToken = await FcmService.getToken();
        debugPrint('[GOOGLE] FCM token: ${fcmToken != null ? "received" : "null"}');
      } catch (e) {
        debugPrint('[GOOGLE] FCM error (ignored): $e');
      }

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
      final fcmToken = await FcmService.getToken().catchError((_) => null);
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
  Future<bool> verifyOtp(String email, String otp) async {
    _setLoading(true);
    try {
      final fcmToken = await FcmService.getToken().catchError((_) => null);
      final res = await _api.verifyOtp(email, otp, fcmToken: fcmToken);
      if (res.success && res.data != null) {
        await _saveSession(Map<String, dynamic>.from(res.data as Map));
        _error = null;
        return true;
      }
      _error = res.message;
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
        await StorageService.clearAll();
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
      final fcmToken = await FcmService.getToken();
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