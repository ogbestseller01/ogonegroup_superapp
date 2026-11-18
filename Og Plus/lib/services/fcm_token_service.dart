// lib/services/fcm_token_service.dart
//
// Registers the device token anonymously via /v1/device-token.
// No auth required — works at boot, before login.

import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';

class FcmTokenService {
  FcmTokenService._();

  static const String _app = 'og_one_super';
  static const String _kDeviceId = 'device_id';
  static StreamSubscription<String>? _refreshSub;

  static Future<void> register() async {
    try {
      final messaging = FirebaseMessaging.instance;

      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('FcmTokenService: permission denied.');
        return;
      }

      // 1. Always attach the refresh listener FIRST.
      // On iOS, if the APNs token arrives slightly after boot, Firebase
      // will automatically emit the new FCM token through this stream.
      await _refreshSub?.cancel();
      _refreshSub = messaging.onTokenRefresh.listen(
            (newToken) => _send(newToken),
        onError: (e) => debugPrint('FcmTokenService.onTokenRefresh error: $e'),
      );

      // 2. On iOS, ensure the APNs token is available before calling getToken()
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final apnsReady = await _waitForApnsToken(messaging);
        if (!apnsReady) {
          debugPrint(
            'FcmTokenService: APNs token not ready yet (normal on iOS Simulator '
                'or slow network). Waiting for onTokenRefresh...',
          );
          return;
        }
      }

      // 3. Safely fetch and send the current FCM token
      final token = await messaging.getToken();
      if (token == null || token.isEmpty) {
        debugPrint('FcmTokenService: no token yet.');
        return;
      }

      await _send(token);
    } catch (e, st) {
      debugPrint('FcmTokenService.register error: $e\n$st');
    }
  }

  /// Polls `getAPNSToken()` briefly (up to ~3 seconds) so iOS has time
  /// to complete the asynchronous APNs handshake on physical devices.
  static Future<bool> _waitForApnsToken(FirebaseMessaging messaging) async {
    for (int i = 0; i < 6; i++) {
      final apnsToken = await messaging.getAPNSToken();
      if (apnsToken != null && apnsToken.isNotEmpty) {
        return true;
      }
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
    return false;
  }

  static Future<void> _send(String token) async {
    final platform =
    defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';
    final deviceId = await _deviceId();

    final res = await ApiService.instance.registerDeviceToken(
      token: token,
      platform: platform,
      app: _app,
      deviceId: deviceId,
    );
    debugPrint(
      'FcmTokenService → app=$_app platform=$platform '
          'device=$deviceId result=${res.success} ${res.message}',
    );
  }

  static Future<String> _deviceId() async {
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString(_kDeviceId);
    if (id == null || id.isEmpty) {
      id = '${DateTime.now().microsecondsSinceEpoch}-'
          '${(1000 + (DateTime.now().millisecondsSinceEpoch % 9000))}';
      await prefs.setString(_kDeviceId, id);
    }
    return id;
  }
}