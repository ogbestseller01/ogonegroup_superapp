import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../config/google_config.dart';

/// Thrown when Google reports "canceled".
/// On Android, a missing/wrong OAuth client also comes back as "canceled",
/// but it happens very fast and the picker never shows.
class GoogleSignInCancelled implements Exception {
  final Duration elapsed;
  GoogleSignInCancelled(this.elapsed);

  bool get looksLikeConfigError => elapsed.inMilliseconds < 2500;
}

class GoogleAuthService {
  static final GoogleSignIn _google = GoogleSignIn.instance;
  static bool _initialized = false;

  static Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await _google.initialize(
      serverClientId: GoogleConfig.webClientId,
    );
    _initialized = true;
  }

  /// Opens the Google account picker and returns a Google ID token.
  static Future<String> getIdToken() async {
    await _ensureInitialized();

    if (!_google.supportsAuthenticate()) {
      throw Exception('Google authenticate() is not supported on this platform.');
    }

    final sw = Stopwatch()..start();

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
      debugPrint('[GOOGLE] code=${e.code} '
          'description=${e.description} '
          'details=${e.details} '
          'elapsed=${sw.elapsedMilliseconds}ms');

      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw GoogleSignInCancelled(sw.elapsed);
      }
      rethrow;
    }
  }

  static Future<void> signOut() async {
    try {
      await _google.signOut();
    } catch (_) {}
  }
}