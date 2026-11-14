// lib/services/fcm_token_service.dart
//
// Optional: only needed if you re-enable Firebase in the super app.
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
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('FcmTokenService: permission denied.');
        return;
      }

      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) {
        debugPrint('FcmTokenService: no token yet.');
        return;
      }

      await _send(token);

      await _refreshSub?.cancel();
      _refreshSub = FirebaseMessaging.instance.onTokenRefresh.listen(
            (newToken) => _send(newToken),
        onError: (e) => debugPrint('FcmTokenService.onTokenRefresh error: $e'),
      );
    } catch (e, st) {
      debugPrint('FcmTokenService.register error: $e\n$st');
    }
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