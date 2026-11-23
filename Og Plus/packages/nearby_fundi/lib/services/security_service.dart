// lib/services/security_service.dart
import 'package:flutter/services.dart';

class SecurityService {
  static const MethodChannel _channel = MethodChannel('com.nearbyfundi/security');

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
  static const bool reviewBuild = !securityEnabled || _reviewFlag;

  /// Enable secure screen (prevent screenshots)
  static Future<void> enableSecureScreen() async {
    // Postponed / review build: never enable, and make sure it is off.
    if (reviewBuild) {
      await disableSecureScreen();
      return;
    }

    try {
      await _channel.invokeMethod('enableSecureScreen');
    } catch (e) {
      // If native method not implemented, fallback
    }
  }

  /// Disable secure screen (allow screenshots)
  static Future<void> disableSecureScreen() async {
    try {
      await _channel.invokeMethod('disableSecureScreen');
    } catch (e) {
      // Fallback
    }
  }

  /// Check if secure screen is enabled
  static Future<bool> isSecureScreenEnabled() async {
    // Postponed / review build: report as disabled.
    if (reviewBuild) return false;

    try {
      final result = await _channel.invokeMethod('isSecureScreenEnabled');
      return result ?? true;
    } catch (e) {
      return true;
    }
  }
}