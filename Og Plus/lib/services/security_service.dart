import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class SecurityService {
  SecurityService._();
  static final SecurityService instance = SecurityService._();

  static const _channel = MethodChannel('og.one.security');

  /// MASTER SWITCH: false = security postponed, true = all protection ON.
  static const bool securityEnabled = false;

  static const bool _reviewFlag = bool.fromEnvironment('REVIEW_BUILD');

  /// True when protection must be skipped (postponed or review build).
  static bool get reviewBuild => !securityEnabled || _reviewFlag;

  Future<void> init() async {
    if (kIsWeb || reviewBuild) return;

    try {
      if (Platform.isAndroid) {
        await _channel.invokeMethod('enableSecureFlag');
      }
    } catch (_) {}
  }

  Future<bool> isDebugModeEnabled() async {
    if (kIsWeb || reviewBuild || kDebugMode) return false;

    try {
      final result = await _channel.invokeMethod<bool>('isDeveloperMode');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }
}