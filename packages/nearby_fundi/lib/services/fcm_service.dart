import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_navigator.dart';
import '../main.dart';
import '../providers/notification_provider.dart';

/// Top-level entry point handler for background messages on Android/iOS
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('📩 FCM Background message received: ${message.messageId}');
}

class FcmService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  // ==================== INITIALIZE FCM ====================
  static Future<void> initialize() async {
    try {
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('⚠️ User declined FCM notification permissions');
        return;
      }

      debugPrint('✅ FCM Permission Granted: ${settings.authorizationStatus}');

      await _firebaseMessaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      _configureMessageHandlers();

      RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }

      debugPrint('✅ FCM Service Initialized Successfully');
    } catch (e, stackTrace) {
      debugPrint('❌ Failed to initialize FCM Service: $e');
      debugPrint('$stackTrace');
    }
  }

  // ==================== GET TOKEN ====================
  static Future<String?> getToken() async {
    try {
      if (Platform.isIOS) {
        String? apnsToken = await _firebaseMessaging.getAPNSToken();
        if (apnsToken == null) {
          await Future.delayed(const Duration(seconds: 2));
          apnsToken = await _firebaseMessaging.getAPNSToken();
        }
      }

      String? token = await _firebaseMessaging.getToken();
      debugPrint('🔑 FCM Device Token: $token');
      return token;
    } catch (e) {
      debugPrint('❌ Failed to retrieve FCM Token: $e');
      return null;
    }
  }

  // ==================== MESSAGE HANDLERS ====================
  static void _configureMessageHandlers() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('📩 Foreground FCM Message Received: ${message.messageId}');
      _processIncomingMessage(message, isForeground: true);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('👆 App opened via FCM notification tap');
      _handleNotificationTap(message);
    });

    _firebaseMessaging.onTokenRefresh.listen((String newToken) {
      debugPrint('🔄 FCM Token Refreshed: $newToken');
    });
  }

  /// Returns trimmed text if non-empty and not a bare number, else null.
  static String? _validText(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return null;
    if (double.tryParse(text) != null) return null;
    return text;
  }

  // ==================== PROCESS MESSAGE ====================
  static void _processIncomingMessage(
      RemoteMessage message, {
        required bool isForeground,
      }) {
    final BuildContext? context = navigatorKey.currentContext;
    if (context == null) return;

    final Map<String, dynamic> data = message.data;
    final String type = data['type']?.toString() ?? 'general';

    final notificationProvider =
    Provider.of<NotificationProvider>(context, listen: false);

    // Silent chat: update unread state, no tray banner.
    if (type == 'chat_message') {
      debugPrint('💬 Chat notification received. Suppressing local banner.');
      notificationProvider.refreshUnreadCount();
      return;
    }

    final String? title = _validText(
      message.notification?.title ?? data['title']?.toString(),
    );
    final String? body = _validText(
      message.notification?.body ?? data['body']?.toString(),
    );

    if (title == null || body == null) {
      debugPrint(
        '⚠️ FCM message dropped — invalid title/body '
            '(id: ${message.messageId}, type: $type, '
            'title: "${data['title']}", body: "${data['body']}")',
      );
      return;
    }

    if (isForeground) {
      if (message.notification == null) {
        notificationProvider.showLocalNotification(
          title: title,
          body: body,
          payload: type,
        );
      }

      notificationProvider.addLocalNotification({
        'id': data['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        'title': title,
        'body': body,
        'type': type,
        'data': data,
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      });
    }
  }

  // ==================== TAP HANDLER ====================
  static void _handleNotificationTap(RemoteMessage message) {
    try {
      final Map<String, dynamic> data = message.data;
      final String type = data['type']?.toString() ?? '';

      final context = navigatorKey.currentContext;
      if (context == null) return;

      if (type == 'chat_message') {
        navigatorKey.currentState?.pushNamed('/chat', arguments: data);
      } else {
        navigatorKey.currentState?.pushNamed('/notifications');
      }
    } catch (e) {
      debugPrint('❌ FCM Navigation Error: $e');
    }
  }
}