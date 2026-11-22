// lib/services/security_service.dart

import 'package:flutter/services.dart';

class SecurityService {
  // Must match MainActivity SECURITY_CHANNEL
  static const MethodChannel _channel = MethodChannel('com.fundapp.security');

  /// REVIEW BUILD SWITCH
  /// ------------------------------------------------------------
  /// App Review / demo video (screenshots and recording ALLOWED):
  ///   flutter build ipa --dart-define=REVIEW_BUILD=true
  ///
  /// Normal production build (screenshots and recording BLOCKED):
  ///   flutter build ipa
  ///
  /// Default (no flag) = protection ON, exactly as before.
  static const bool reviewBuild = bool.fromEnvironment('REVIEW_BUILD');

  /// Prevent screenshots / screen recording (Android FLAG_SECURE)
  static Future<void> enableSecureScreen() async {
    // Review build: never enable, and make sure it is off.
    if (reviewBuild) {
      await disableSecureScreen();
      return;
    }

    try {
      await _channel.invokeMethod('enableSecureScreen');
    } catch (_) {
      // Platform channel missing (e.g. iOS / web) — no-op
    }
  }

  /// Allow screenshots again
  static Future<void> disableSecureScreen() async {
    try {
      await _channel.invokeMethod('disableSecureScreen');
    } catch (_) {
      // no-op
    }
  }

  /// Whether FLAG_SECURE is currently set
  static Future<bool> isSecureScreenEnabled() async {
    // Review build: report as disabled.
    if (reviewBuild) return false;

    try {
      final result = await _channel.invokeMethod<bool>('isSecureScreenEnabled');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }
}