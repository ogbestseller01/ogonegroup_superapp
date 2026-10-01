import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../app_navigator.dart';
import '../config/app_routes.dart';
import 'fcm_event_bus.dart';

class FcmService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _notifications =
  FlutterLocalNotificationsPlugin();

  static const String _channelId = 'fundi_channel';
  static const String _channelName = 'NearbyFundi Notifications';

  static GlobalKey<NavigatorState> get navKey => navigatorKey;

  @pragma('vm:entry-point')
  static Future<void> onBackgroundMessage(RemoteMessage message) async {
    debugPrint('📩 Background message: ${message.messageId}');
  }

  static Future<void> init() async {
    try {
      final settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus != AuthorizationStatus.authorized &&
          settings.authorizationStatus != AuthorizationStatus.provisional) {
        debugPrint('❌ FCM permission denied');
        return;
      }

      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const ios = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const initSettings = InitializationSettings(android: android, iOS: ios);

      // FIXED: `initialize` expects a positional argument for settings.
      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _handleNotificationTapFromLocal,
      );

      const channel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: 'Notifications from NearbyFundi',
        importance: Importance.max,
        showBadge: true,
        enableVibration: true,
        playSound: true,
      );

      await _notifications
          .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      await _fcm.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      FirebaseMessaging.onMessage.listen(_showForegroundNotification);

      final initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTapFromRemote(initialMessage);
      }

      FirebaseMessaging.onMessageOpenedApp
          .listen(_handleNotificationTapFromRemote);

      debugPrint('✅ FCM initialized');
    } catch (e) {
      debugPrint('❌ FCM init error: $e');
    }
  }

  // ============================================================
  // SANITIZATION
  // ============================================================

  /// Returns the trimmed text if it's non-empty and not a bare number.
  /// Returns null otherwise — no placeholder fallback.
  static String? _sanitize(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return null;
    if (double.tryParse(text) != null) return null;
    return text;
  }

  // ============================================================
  // FOREGROUND HANDLER
  // ============================================================

  static void _showForegroundNotification(RemoteMessage message) {
    try {
      final type = message.data['type']?.toString() ?? 'general';

      // ─────────────────────────────────────────────
      // Chat: completely silent, no tray banner
      // ─────────────────────────────────────────────
      if (type == 'chat_message') {
        debugPrint('💬 Chat push received in foreground — silent');
        FcmEventBus.instance.emit({
          'title': message.notification?.title ?? message.data['title'] ?? '',
          'body': message.notification?.body ?? message.data['body'] ?? '',
          'type': type,
          'data': message.data,
          'received_at': DateTime.now().toIso8601String(),
        });
        return;
      }

      // ─────────────────────────────────────────────
      // Non-chat: sanitize title/body, skip if invalid
      // ─────────────────────────────────────────────
      final title = _sanitize(
        message.notification?.title ?? message.data['title']?.toString(),
      );
      final body = _sanitize(
        message.notification?.body ?? message.data['body']?.toString(),
      );

      if (title == null || body == null) {
        debugPrint(
          '⚠️ Foreground push skipped — invalid title/body '
              '(title: "${message.notification?.title}", '
              'body: "${message.notification?.body}", '
              'data.title: "${message.data['title']}", '
              'data.body: "${message.data['body']}")',
        );
        return;
      }

      debugPrint('🔔 Foreground push — title: "$title", body: "$body"');

      const android = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: 'Notifications from NearbyFundi',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        channelShowBadge: true,
        showWhen: true,
        playSound: true,
        enableVibration: true,
      );

      const platform = NotificationDetails(android: android);

      // FIXED: `show` expects positional arguments for id, title, body, and details.
      _notifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        platform,
        payload: message.data.isNotEmpty ? json.encode(message.data) : null,
      );

      FcmEventBus.instance.emit({
        'title': title,
        'body': body,
        'type': type,
        'data': message.data,
        'received_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('❌ Show foreground notification error: $e');
    }
  }

  // ============================================================
  // TAP HANDLERS
  // ============================================================

  static void _handleNotificationTapFromLocal(NotificationResponse response) {
    if (response.payload == null) return;
    try {
      final data = Map<String, dynamic>.from(
        json.decode(response.payload!) as Map<String, dynamic>,
      );
      _navigateBasedOnType(data);
    } catch (_) {
      _navigateToHome();
    }
  }

  static void _handleNotificationTapFromRemote(RemoteMessage message) {
    try {
      _navigateBasedOnType(message.data);
    } catch (_) {
      _navigateToHome();
    }
  }

  static void _navigateBasedOnType(Map<String, dynamic> data) {
    final type = data['type']?.toString() ?? '';
    final conversationId = data['conversation_id'];

    switch (type) {
      case 'chat_message':
        if (conversationId != null) {
          navigatorKey.currentState?.pushNamed(
            AppRoutes.chat,
            arguments: {
              'conversationId': int.tryParse(conversationId.toString()) ?? 0,
            },
          );
        } else {
          _navigateToHome();
        }
        break;
      case 'new_request':
      case 'request_accepted':
      case 'request_rejected':
      case 'request_in_progress':
      case 'request_completed':
      case 'request_on_the_way':
      case 'request_arrived':
      case 'request_cancelled':
        navigatorKey.currentState?.pushNamed(AppRoutes.requests);
        break;
      case 'post_comment':
      case 'post_like':
      case 'new_post':
        navigatorKey.currentState?.pushNamed(AppRoutes.blog);
        break;
      case 'profile_update':
        navigatorKey.currentState?.pushNamed(AppRoutes.profile);
        break;
      default:
        navigatorKey.currentState?.pushNamed(AppRoutes.notifications);
    }
  }

  static void _navigateToHome() {
    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      AppRoutes.home,
          (_) => false,
    );
  }

  static Future<String?> getToken() async {
    try {
      return await _fcm.getToken();
    } catch (e) {
      debugPrint('❌ FCM getToken error: $e');
      return null;
    }
  }
}