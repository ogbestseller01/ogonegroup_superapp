// lib/services/fcm_token_service.dart
import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart' show FirebaseException;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'api_service.dart';

class FcmTokenService {
  static bool _registered = false;

  /// Registers this device for FCM push. Safe to call multiple times.
  /// Call after Firebase.initializeApp() and after login (if auth is used).
  static Future<void> register({bool force = false}) async {
    if (_registered && !force) return;

    try {
      final messaging = FirebaseMessaging.instance;

      // 1) Ask permission (no-op on Android <13, required on iOS).
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('[FCM] permission denied by user');
        return;
      }

      // 2) iOS only: wait for APNs token without throwing.
      //    getAPNSToken() can throw FirebaseException(apns-token-not-set)
      //    until iOS registers with APNs (takes 1–5 s after launch).
      if (!kIsWeb && Platform.isIOS) {
        final apnsReady = await _waitForApnsToken(messaging);
        if (!apnsReady) {
          debugPrint(
            '[FCM] APNs token never arrived. '
                'Likely causes: (a) running on iOS Simulator, '
                '(b) missing aps-environment entitlement, '
                '(c) missing Push Notifications capability in Xcode.',
          );
          return;
        }
      }

      // 3) Fetch FCM token.
      String? token;
      try {
        token = await messaging.getToken();
      } on FirebaseException catch (e) {
        debugPrint('[FCM] getToken failed: ${e.code} — ${e.message}');
        return;
      }

      if (token == null || token.isEmpty) {
        debugPrint('[FCM] FCM token unavailable');
        return;
      }

      // 4) Upload to backend.
      final res = await ApiService.instance.registerDeviceToken(
        token: token,
        platform: _platform(),
      );
      _registered = res.success;
      debugPrint(
        res.success
            ? '[FCM] token registered: ${token.substring(0, 12)}…'
            : '[FCM] token upload failed: ${res.message}',
      );

      // 5) Handle token rotation.
      messaging.onTokenRefresh.listen((newToken) async {
        if (newToken.isEmpty) return;
        await ApiService.instance.registerDeviceToken(
          token: newToken,
          platform: _platform(),
        );
      });
    } catch (e, st) {
      debugPrint('[FCM] register failed: $e\n$st');
    }
  }

  /// Polls `getAPNSToken()` up to 10 seconds.
  /// Returns true when the token is available.
  static Future<bool> _waitForApnsToken(
      FirebaseMessaging messaging,
      ) async {
    for (var i = 0; i < 20; i++) {
      try {
        final apns = await messaging.getAPNSToken();
        if (apns != null && apns.isNotEmpty) {
          debugPrint('[FCM] APNs token ready: ${apns.substring(0, 12)}…');
          return true;
        }
      } on FirebaseException catch (e) {
        // apns-token-not-set is EXPECTED on the first calls.
        if (i == 0) {
          debugPrint('[FCM] waiting for APNs token (${e.code})…');
        }
      } catch (e) {
        if (i == 0) {
          debugPrint('[FCM] getAPNSToken error: $e');
        }
      }
      await Future.delayed(const Duration(milliseconds: 500));
    }
    return false;
  }

  static String _platform() {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.macOS:
        return 'macos';
      default:
        return 'unknown';
    }
  }
}