// lib/services/google_auth_service.dart
//
// Single place that talks to Google. Works with google_sign_in 7.x.
// Returns a Google ID token; the Laravel API (POST /v1/auth/google) verifies it.

import 'package:flutter/foundation.dart'
    show TargetPlatform, debugPrint, defaultTargetPlatform;
import 'package:google_sign_in/google_sign_in.dart';

import '../config/google_config.dart';

/// User closed the picker, OR Google refused instantly because the Android
/// OAuth client (package name / SHA-1) is wrong. [looksLikeConfigError]
/// tells the two apart.
class GoogleSignInCancelled implements Exception {
  final bool looksLikeConfigError;
  final String? details;

  const GoogleSignInCancelled({
    this.looksLikeConfigError = false,
    this.details,
  });

  @override
  String toString() => 'GoogleSignInCancelled(config=$looksLikeConfigError, $details)';
}

class GoogleAuthService {
  GoogleAuthService._();

  static final GoogleSignIn _google = GoogleSignIn.instance;
  static Future<void>? _init;

  /// initialize() may only run once per app run. Safe to call repeatedly.
  static Future<void> _ensureInitialized() {
    return _init ??= _doInit();
  }

  static Future<void> _doInit() async {
    try {
      await _google.initialize(
        serverClientId: GoogleConfig.webClientId,
        clientId: defaultTargetPlatform == TargetPlatform.iOS
            ? GoogleConfig.iosClientId
            : null,
      );
    } catch (e) {
      _init = null; // allow retry
      rethrow;
    }
  }

  /// Opens the Google account picker and returns the ID token.
  /// Throws [GoogleSignInCancelled] or [GoogleSignInException] on failure.
  static Future<String> getIdToken() async {
    await _ensureInitialized();

    // Forget the previous account so the picker always shows.
    try {
      await _google.signOut();
    } catch (_) {}

    final watch = Stopwatch()..start();

    try {
      final account = await _google.authenticate(
        scopeHint: const ['email', 'profile'],
      );

      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw Exception('Google did not return an ID token.');
      }
      return idToken;
    } on GoogleSignInException catch (e) {
      debugPrint('[GOOGLE] code=${e.code} desc=${e.description} '
          'after=${watch.elapsedMilliseconds}ms');

      if (e.code == GoogleSignInExceptionCode.canceled) {
        final text = '${e.description ?? ''} ${e.details ?? ''}'.toLowerCase();
        final configHint = text.contains('[16]') ||
            text.contains('matching credential') ||
            text.contains('no credential') ||
            watch.elapsedMilliseconds < 700; // no human closes it that fast
        throw GoogleSignInCancelled(
          looksLikeConfigError: configHint,
          details: e.description,
        );
      }
      rethrow;
    }
  }

  static Future<void> signOut() async {
    try {
      await _ensureInitialized();
      await _google.signOut();
    } catch (_) {}
  }
}