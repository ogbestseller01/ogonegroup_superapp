import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app_badger_plus/flutter_app_badger.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../app_navigator.dart';
import '../main.dart';
import '../services/api_service.dart';

class NotificationProvider extends ChangeNotifier {
  final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  static const String _channelId = 'fundi_channel';
  static const String _channelName = 'NearbyFundi Notifications';

  /// Native badge channel — implemented by MainActivity.java.
  /// On Android, this only persists the count locally; the launcher
  /// badge is set automatically by flutter_local_notifications.
  static const MethodChannel _badgeChannel =
  MethodChannel('com.nearbyfundi/badge');

  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = false;
  String? _error;
  int _unreadCount = 0;

  // ==================== GETTERS ====================
  List<Map<String, dynamic>> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get unreadCount => _unreadCount;

  int get localUnreadCount {
    return _notifications.where((n) => _isUnread(n['is_read'])).length;
  }

  // ==================== CONSTRUCTOR ====================
  NotificationProvider() {
    _init();
  }

  // ==================== INITIALIZATION ====================
  Future<void> _init() async {
    try {
      const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings iosSettings =
      DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings settings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        settings,
        onDidReceiveNotificationResponse: _onNotificationTap,
        onDidReceiveBackgroundNotificationResponse:
        _onBackgroundNotificationTap,
      );

      await _createNotificationChannel();
      debugPrint('✅ NotificationProvider initialized');
    } catch (e, stackTrace) {
      debugPrint('❌ NotificationProvider initialization failed: $e');
      debugPrint('$stackTrace');
    }
  }

  @pragma('vm:entry-point')
  static void _onBackgroundNotificationTap(NotificationResponse response) {
    debugPrint('👆 Background notification tapped');
  }

  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'Notifications from NearbyFundi',
      importance: Importance.max,
      enableVibration: true,
      playSound: true,
      enableLights: true,
      showBadge: true,
    );

    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
    _localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(channel);
  }

  // ==================== NOTIFICATION TAP ====================
  void _onNotificationTap(NotificationResponse response) {
    try {
      final String? payload = response.payload;
      debugPrint('👆 Notification tapped with payload: $payload');

      final context = navigatorKey.currentContext;
      if (context == null) return;

      navigatorKey.currentState?.pushNamed('/notifications');
    } catch (e) {
      debugPrint('❌ Notification navigation error: $e');
    }
  }

  // ==================== SHOW LOCAL NOTIFICATION ====================
  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    // Suppress system tray banner for chat messages.
    if (payload == 'chat_message') return;

    final String? safeTitle = _validText(title);
    final String? safeBody = _validText(body);

    if (safeTitle == null || safeBody == null) {
      debugPrint(
        '⚠️ Local notification skipped — invalid title/body '
            '(title: "$title", body: "$body", payload: $payload)',
      );
      return;
    }

    debugPrint(
      '🔔 Showing local notification — '
          'title: "$safeTitle", body: "$safeBody", payload: $payload',
    );

    try {
      final AndroidNotificationDetails androidDetails =
      AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: 'Notifications from NearbyFundi',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        playSound: true,
        enableVibration: true,
        icon: '@mipmap/ic_launcher',
        channelShowBadge: true,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final int notificationId =
      DateTime.now().millisecondsSinceEpoch.remainder(2147483647);

      await _localNotifications.show(
        notificationId,
        safeTitle,
        safeBody,
        notificationDetails,
        payload: payload,
      );
    } catch (e) {
      debugPrint('❌ Failed to show local notification: $e');
    }
  }

  // ==================== HELPERS ====================
  String? _validText(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return null;
    if (double.tryParse(text) != null) return null;
    return text;
  }

  bool _isUnread(dynamic value) {
    if (value == null) return true;
    if (value is bool) return value == false;
    if (value is num) return value == 0;
    if (value is String) {
      final String normalized = value.toLowerCase().trim();
      return normalized == '0' || normalized == 'false' || normalized.isEmpty;
    }
    return false;
  }

  bool isRead(Map<String, dynamic> notification) {
    return !_isUnread(notification['is_read']);
  }

  // ==================== BADGE UPDATE ====================
  Future<void> _updateAppBadge() async {
    try {
      if (Platform.isIOS) {
        // iOS: official badge API.
        final bool isSupported = await FlutterAppBadger.isAppBadgeSupported();
        if (!isSupported) {
          debugPrint('ℹ️ iOS badge not supported on this device');
          return;
        }

        if (_unreadCount > 0) {
          await FlutterAppBadger.updateBadgeCount(_unreadCount);
        } else {
          await FlutterAppBadger.removeBadge();
        }
        debugPrint('🔴 iOS badge set to $_unreadCount');
      } else if (Platform.isAndroid) {
        // Android 8+ shows launcher badges automatically when
        // flutter_local_notifications posts a notification. We still
        // persist the count locally via the native channel, but it does
        // NOT create or remove a tray notification.
        if (_unreadCount > 0) {
          await _badgeChannel.invokeMethod(
            'setBadgeCount',
            {'count': _unreadCount},
          );
        } else {
          await _badgeChannel.invokeMethod('removeBadge');
        }
        debugPrint('🤖 Android badge count persisted: $_unreadCount');
      }
    } catch (e) {
      debugPrint('❌ Failed to update app badge: $e');
    }
  }

  // ==================== LOAD NOTIFICATIONS ====================
  Future<void> loadNotifications() async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final ApiService api = ApiService();
      final response = await api.getNotifications(excludeType: 'chat_message');

      if (response.success && response.data != null) {
        final dynamic rawData = response.data;
        List items = [];

        if (rawData is Map && rawData.containsKey('data')) {
          items = rawData['data'] ?? [];
        } else if (rawData is List) {
          items = rawData;
        }

        _notifications = items.map<Map<String, dynamic>>((item) {
          final Map<String, dynamic> notification =
          Map<String, dynamic>.from(item);

          final String rawTitle =
          (notification['title']?.toString() ?? '').trim();
          final String rawBody =
          (notification['body']?.toString() ?? '').trim();

          if (rawTitle.isEmpty ||
              rawBody.isEmpty ||
              double.tryParse(rawTitle) != null ||
              double.tryParse(rawBody) != null) {
            debugPrint(
              '⚠️ Notification #${notification['id']} has invalid '
                  'title/body from API (title: "$rawTitle", body: "$rawBody")',
            );
          }

          notification['title'] = rawTitle;
          notification['body'] = rawBody;

          debugPrint(
            '📥 Loaded notification #${notification['id']} — '
                'title: "$rawTitle", body: "$rawBody"',
          );

          if (notification['data'] is String) {
            try {
              notification['data'] = jsonDecode(notification['data']);
            } catch (_) {}
          }
          return notification;
        }).toList();
      } else {
        _error = response.message;
      }

      await refreshUnreadCount();
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Error loading notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==================== UNREAD COUNT ====================
  Future<void> refreshUnreadCount() async {
    try {
      final ApiService api = ApiService();
      final response =
      await api.getUnreadNotificationCount(excludeType: 'chat_message');

      if (response.success && response.data != null) {
        final dynamic count = response.data['count'];

        if (count is int) {
          _unreadCount = count;
        } else {
          _unreadCount = int.tryParse(count.toString()) ?? localUnreadCount;
        }
      } else {
        _unreadCount = localUnreadCount;
      }
    } catch (e) {
      debugPrint('❌ Error refreshing unread count: $e');
      _unreadCount = localUnreadCount;
    }

    await _updateAppBadge();
    notifyListeners();
  }

  // ==================== MARK AS READ ====================
  Future<void> markAsRead(String notificationId) async {
    try {
      final ApiService api = ApiService();
      final response = await api.markNotificationAsRead(notificationId);

      if (!response.success) return;

      final int index = _notifications.indexWhere(
            (n) => n['id'].toString() == notificationId.toString(),
      );

      if (index != -1) {
        _notifications[index]['is_read'] = true;
        _notifications[index]['read_at'] = DateTime.now().toIso8601String();
      }

      await refreshUnreadCount();
    } catch (e) {
      debugPrint('❌ Error marking notification as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final ApiService api = ApiService();
      final response =
      await api.markAllNotificationsAsRead(excludeType: 'chat_message');

      if (!response.success) return;

      final String readAt = DateTime.now().toIso8601String();
      for (final notification in _notifications) {
        notification['is_read'] = true;
        notification['read_at'] = readAt;
      }

      _unreadCount = 0;
      await _updateAppBadge();
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error marking all notifications as read: $e');
    }
  }

  // ==================== DELETE SINGLE NOTIFICATION ====================
  Future<void> deleteNotification(String notificationId) async {
    try {
      final ApiService api = ApiService();
      final response = await api.deleteNotification(notificationId);

      if (!response.success) return;

      _notifications.removeWhere(
            (n) => n['id'].toString() == notificationId.toString(),
      );

      await refreshUnreadCount();
    } catch (e) {
      debugPrint('❌ Error deleting notification: $e');
    }
  }

  // ==================== ADD LOCAL NOTIFICATION ====================
  void addLocalNotification(Map<String, dynamic> notification) {
    if (notification['type']?.toString() == 'chat_message') return;

    notification['is_read'] ??= false;
    notification['title'] = (notification['title']?.toString() ?? '').trim();
    notification['body'] = (notification['body']?.toString() ?? '').trim();

    debugPrint(
      '➕ Added local notification — '
          'title: "${notification['title']}", '
          'body: "${notification['body']}", '
          'type: ${notification['type']}',
    );

    _notifications.insert(0, notification);
    _unreadCount++;
    _updateAppBadge();
    notifyListeners();
  }

  // ==================== CLEAR ALL ====================
  Future<void> clearAll() async {
    try {
      final ApiService api = ApiService();
      final response =
      await api.clearNotifications(excludeType: 'chat_message');

      if (!response.success) return;

      _notifications.clear();
      _unreadCount = 0;
      await _updateAppBadge();
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error clearing notifications: $e');
    }
  }
}