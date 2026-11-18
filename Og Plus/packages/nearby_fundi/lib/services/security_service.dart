// lib/services/security_service.dart
import 'package:flutter/services.dart';

class SecurityService {
  static const MethodChannel _channel = MethodChannel('com.nearbyfundi/security');

  /// Enable secure screen (prevent screenshots)
  static Future<void> enableSecureScreen() async {
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
    try {
      final result = await _channel.invokeMethod('isSecureScreenEnabled');
      return result ?? true;
    } catch (e) {
      return true;
    }
  }
}