// lib/services/social_auth_service.dart
//
// APPLE ONLY. Google lives in google_auth_service.dart so that
// GoogleSignIn.instance.initialize() runs from exactly one place.

import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, debugPrint;
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

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

  static Future<bool> appleAvailable() async {
    if (defaultTargetPlatform != TargetPlatform.iOS &&
        defaultTargetPlatform != TargetPlatform.macOS) {
      return false;
    }
    return SignInWithApple.isAvailable();
  }

  static Future<SocialCredential> apple() async {
    final rawNonce = _randomNonce();
    final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

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

      final fullName = [cred.givenName, cred.familyName]
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

  static String _randomNonce([int length = 32]) {
    const chars =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => chars[random.nextInt(chars.length)])
        .join();
  }
}