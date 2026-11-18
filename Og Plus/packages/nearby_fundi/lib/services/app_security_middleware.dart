import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AppSecurityMiddleware {
  static const MethodChannel _channel = MethodChannel('com.nearbyfundi.security/core');

  /// Executes all-encompassing security checks at app startup.
  static Future<void> initialize() async {
    if (kDebugMode) {
      // Allow debugging during local development, but log warnings
      debugPrint('[SecurityMiddleware] Running in Debug Mode. Strict checks bypassed.');
      return;
    }

    // 1. Check for active debuggers attached to the process
    if (await _isDebuggerAttached()) {
      _terminateApp('Security Alert: Active debugger detected.');
    }

    // 2. Check for Root / Jailbreak status
    if (await _isDeviceCompromised()) {
      _terminateApp('Security Alert: Device integrity compromised (Root/Jailbreak).');
    }

    // 3. Check for app tampering / signature verification (Android/iOS)
    if (await _isAppTampered()) {
      _terminateApp('Security Alert: App signature or binary modified.');
    }

    // 4. Emulator / Simulator restriction (optional based on your app's policy)
    if (Platform.isAndroid && await _isEmulator()) {
      _terminateApp('Security Alert: Running on an unauthorized emulator environment.');
    }
  }

  static Future<bool> _isDebuggerAttached() async {
    try {
      return await _channel.invokeMethod<bool>('isDebuggerAttached') ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> _isDeviceCompromised() async {
    try {
      return await _channel.invokeMethod<bool>('isDeviceCompromised') ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> _isAppTampered() async {
    try {
      return await _channel.invokeMethod<bool>('isAppTampered') ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> _isEmulator() async {
    try {
      return await _channel.invokeMethod<bool>('isEmulator') ?? false;
    } catch (_) {
      return false;
    }
  }

  static void _terminateApp(String reason) {
    debugPrint('[CRITICAL SECURITY VIOLATION]: $reason');
    try {
      SystemChannels.platform.invokeMethod('SystemNavigator.pop');
    } catch (_) {}
    exit(0);
  }
}