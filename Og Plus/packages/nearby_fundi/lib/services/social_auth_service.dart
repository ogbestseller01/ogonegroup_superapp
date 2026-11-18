
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, debugPrint;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

// Web OAuth client ID.
// Must match GOOGLE_CLIENT_IDS in the Laravel backend .env.
const String kGoogleServerClientId =
    '217153819583-i53f9rsb46uiid53ikuiv6r68o93qe4s.apps.googleusercontent.com';

class SocialCredential {
  final String token;
  final String? nonce;
  final String? name;

  const SocialCredential({
    required this.token,
    this.nonce,
    this.name,
  });
}

class SocialAuthCancelled implements Exception {
  const SocialAuthCancelled();

  @override
  String toString() => 'Social sign-in was cancelled.';
}

class SocialAuthService {
  SocialAuthService._();

  // Google Sign-In 7.x singleton.
  static final GoogleSignIn _google = GoogleSignIn.instance;

  // Initialize Google only once.
  static Future<void>? _googleInitialization;

  static Future<void> _initializeGoogle() {
    return _googleInitialization ??= _google.initialize(
      serverClientId: kGoogleServerClientId,
    );
  }

  // ─────────────────────────────────────────────
  // GOOGLE SIGN-IN
  // ─────────────────────────────────────────────

  static Future<SocialCredential> google() async {
    try {
      await _initializeGoogle();

      // Clear previous session to show account selection.
      await _google.signOut();

      // Google Sign-In 7.x authentication API.
      final account = await _google.authenticate(
        scopeHint: const ['email', 'profile'],
      );

      // Retrieve Google ID token.
      final auth = account.authentication;
      final idToken = auth.idToken;

      if (idToken == null || idToken.isEmpty) {
        throw Exception('Google did not return an ID token.');
      }

      return SocialCredential(token: idToken);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw const SocialAuthCancelled();
      }

      debugPrint('Google Sign-In error: ${e.code} ${e.description}');
      rethrow;
    } catch (e) {
      debugPrint('Google authentication failed: $e');
      rethrow;
    }
  }

  // ─────────────────────────────────────────────
  // APPLE SIGN-IN
  // ─────────────────────────────────────────────

  static Future<bool> appleAvailable() async {
    if (defaultTargetPlatform != TargetPlatform.iOS &&
        defaultTargetPlatform != TargetPlatform.macOS) {
      return false;
    }

    return SignInWithApple.isAvailable();
  }

  static Future<SocialCredential> apple() async {
    final rawNonce = _randomNonce();
    final hashedNonce =
    sha256.convert(utf8.encode(rawNonce)).toString();

    try {
      final cred = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );

      final idToken = cred.identityToken;

      if (idToken == null || idToken.isEmpty) {
        throw Exception('Apple did not return an identity token.');
      }

      final fullName = [
        cred.givenName,
        cred.familyName,
      ]
          .where((s) => s != null && s.trim().isNotEmpty)
          .join(' ')
          .trim();

      return SocialCredential(
        token: idToken,
        nonce: rawNonce,
        name: fullName.isEmpty ? null : fullName,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        throw const SocialAuthCancelled();
      }

      debugPrint('Apple Sign-In error: ${e.code} ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Apple authentication failed: $e');
      rethrow;
    }
  }

  // ─────────────────────────────────────────────
  // SECURE NONCE GENERATOR
  // ─────────────────────────────────────────────

  static String _randomNonce([int length = 32]) {
    const chars =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._';

    final random = Random.secure();

    return List.generate(
      length,
          (_) => chars[random.nextInt(chars.length)],
    ).join();
  }
}
