import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Security layer for Android & iOS
/// - Android: blocks screenshots + detects USB Debugging / Developer Options
/// - iOS: detects debugger attachment
/// - While developing (kDebugMode) the alert is disabled so the emulator works
class SecurityService {
  SecurityService._();
  static final SecurityService instance = SecurityService._();

  static const _channel = MethodChannel('og.one.security');

  Future<void> init() async {
    if (kIsWeb) return;
    try {
      if (Platform.isAndroid) {
        await _channel.invokeMethod('enableSecureFlag');
      }
    } catch (_) {}
  }

  /// Returns true only when the device is in debug/developer mode
  /// AND we are running a release build.
  Future<bool> isDebugModeEnabled() async {
    if (kIsWeb) return false;

    // Allow normal use while developing (emulator / flutter run)
    if (kDebugMode) return false;

    try {
      final result = await _channel.invokeMethod<bool>('isDeveloperMode');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }
}