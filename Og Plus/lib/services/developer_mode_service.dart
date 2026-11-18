import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class DeveloperModeService {
  DeveloperModeService._();

  static const MethodChannel _channel = MethodChannel('og.one.security');

  /// Set to true while you develop so your own phone isn't locked out.
  /// Release builds always enforce the check.
  static const bool bypassInDebug = true;

  /// True when the app must be blocked: real Android device + developer mode / USB debugging on.
  static Future<bool> shouldBlock() async {
    if (!Platform.isAndroid) return false;
    if (kDebugMode && bypassInDebug) return false;

    try {
      final devMode =
          await _channel.invokeMethod<bool>('isDeveloperMode') ?? false;
      if (!devMode) return false;

      final emulator = await _channel.invokeMethod<bool>('isEmulator') ?? false;
      return !emulator;
    } on PlatformException {
      return false; // fail-open so a channel error never locks out every user
    } on MissingPluginException {
      return false;
    }
  }

  static Future<void> openDeveloperSettings() async {
    try {
      await _channel.invokeMethod('openDeveloperSettings');
    } catch (_) {}
  }
}