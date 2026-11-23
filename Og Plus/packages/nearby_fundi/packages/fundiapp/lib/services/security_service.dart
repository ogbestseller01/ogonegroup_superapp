// lib/services/security_service.dart

import 'package:flutter/services.dart';

class SecurityService {
  // Must match MainActivity SECURITY_CHANNEL
  static const MethodChannel _channel = MethodChannel('com.fundapp.security');

  /// MASTER SWITCH
  /// ------------------------------------------------------------
  /// false = security POSTPONED (screenshots / screen recording ALLOWED)
  /// true  = all protection ON
  ///
  /// TODO: set to true when the security logic is ready to come back.
  static const bool securityEnabled = false;

  /// REVIEW BUILD SWITCH
  /// ------------------------------------------------------------
  /// App Review / demo video (screenshots and recording ALLOWED):
  ///   flutter build ipa --dart-define=REVIEW_BUILD=true
  static const bool _reviewFlag = bool.fromEnvironment('REVIEW_BUILD');

  /// True when protection must be skipped (security postponed OR review build).
  /// main.dart already uses this name, so no change is needed there.
  static const bool reviewBuild = !securityEnabled || _reviewFlag;

  /// Prevent screenshots / screen recording (Android FLAG_SECURE)
  static Future<void> enableSecureScreen() async {
    // Postponed / review build: never enable, and make sure it is off.
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
    // Postponed / review build: report as disabled.
    if (reviewBuild) return false;

    try {
      final result = await _channel.invokeMethod<bool>('isSecureScreenEnabled');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }
}