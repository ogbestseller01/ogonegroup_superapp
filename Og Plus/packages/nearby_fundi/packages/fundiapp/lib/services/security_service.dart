// lib/services/security_service.dart

import 'package:flutter/services.dart';

class SecurityService {
  // Must match MainActivity SECURITY_CHANNEL
  static const MethodChannel _channel = MethodChannel('com.fundapp.security');

  /// Prevent screenshots / screen recording (Android FLAG_SECURE)
  static Future<void> enableSecureScreen() async {
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
    try {
      final result = await _channel.invokeMethod<bool>('isSecureScreenEnabled');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }
}