import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app_badger_plus/flutter_app_badger.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../app_navigator.dart'; // must define navigatorKey
import '../services/api_service.dart';

class NotificationProvider extends ChangeNotifier {
  NotificationProvider({ApiService? api}) : _api = api ?? ApiService() {
    _init();
  }

  final ApiService _api;
  final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  static const String _channelId = 'fundi_channel';
  static const String _channelName = 'NearbyFundi Notifications';
  static const String _channelDescription = 'Notifications from NearbyFundi';
  static const String _chatType = 'chat_message';
  static const Duration _pollInterval = Duration(seconds: 2);

  static const MethodChannel _badgeChannel =
  MethodChannel('com.nearbyfundi/badge');

  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = false;
  bool _fetching = false; // guards overlapping list loads
  bool _polling = false; // guards overlapping poll ticks
  bool _disposed = false;
  String? _error;
  int _unreadCount = 0;
  Timer? _pollTimer;

  // ==================== GETTERS ====================
  List<Map<String, dynamic>> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get unreadCount => _unreadCount;
  bool get isPolling => _pollTimer?.isActive ?? false;

  int get localUnreadCount =>
      _notifications.where((n) => _isUnread(n['is_read'])).length;

  // ==================== INITIALIZATION ====================
  Future<void> _init() async {
    try {
      const settings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        ),
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
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.max,
      enableVibration: true,
      playSound: true,
      enableLights: true,
      showBadge: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // ==================== AUTO REFRESH (every 2 seconds) ====================

  /// Safe to call repeatedly; only one timer ever runs.
  void startPolling() {
    if (_disposed || isPolling) return;
    _pollTimer = Timer.periodic(_pollInterval, (_) => _poll());
    debugPrint('⏱️ Notification polling started');
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
    debugPrint('⏹️ Notification polling stopped');
  }

  Future<void> _poll() async {
    if (_polling || _fetching || _disposed) return;
    _polling = true;
    try {
      final count = await _fetchUnreadCount();
      if (count == null) return; // request failed or session expired

      // Only reload the full list when something actually changed.
      if (count != _unreadCount) {
        await loadNotifications(silent: true);
      }
    } finally {
      _polling = false;
    }
  }

  /// Returns the server unread count, or null on failure.
  /// Stops polling if the session has expired.
  Future<int?> _fetchUnreadCount() async {
    try {
      final response =
      await _api.getUnreadNotificationCount(excludeType: _chatType);

      if (response.sessionExpired) {
        stopPolling();
        return null;
      }
      if (!response.success || response.data == null) return null;

      final dynamic raw = response.data['count'];
      return raw is int ? raw : int.tryParse(raw.toString());
    } catch (e) {
      debugPrint('❌ Error fetching unread count: $e');
      return null;
    }
  }

  // ==================== NOTIFICATION TAP ====================
  void _onNotificationTap(NotificationResponse response) {
    debugPrint('👆 Notification tapped with payload: ${response.payload}');
    // Land on Home, where the bell opens the notifications sheet.
    navigatorKey.currentState?.popUntil((route) => route.isFirst);
  }

  // ==================== SHOW LOCAL NOTIFICATION ====================
  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    // Suppress system tray banner for chat messages.
    if (payload == _chatType) return;

    final safeTitle = _validText(title);
    final safeBody = _validText(body);

    if (safeTitle == null || safeBody == null) {
      debugPrint(
        '⚠️ Local notification skipped — invalid title/body '
            '(title: "$title", body: "$body", payload: $payload)',
      );
      return;
    }

    try {
      const androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        playSound: true,
        enableVibration: true,
        icon: '@mipmap/ic_launcher',
        channelShowBadge: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final id = DateTime.now().millisecondsSinceEpoch.remainder(2147483647);

      await _localNotifications.show(
        id,
        safeTitle,
        safeBody,
        const NotificationDetails(android: androidDetails, iOS: iosDetails),
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
      final normalized = value.toLowerCase().trim();
      return normalized == '0' || normalized == 'false' || normalized.isEmpty;
    }
    return false;
  }

  bool isRead(Map<String, dynamic> notification) =>
      !_isUnread(notification['is_read']);

  Future<void> _applyUnreadCount(int count) async {
    _unreadCount = count < 0 ? 0 : count;
    await _updateAppBadge();
    if (!_disposed) notifyListeners();
  }

  // ==================== BADGE UPDATE ====================
  Future<void> _updateAppBadge() async {
    try {
      if (Platform.isIOS) {
        if (!await FlutterAppBadger.isAppBadgeSupported()) return;
        if (_unreadCount > 0) {
          await FlutterAppBadger.updateBadgeCount(_unreadCount);
        } else {
          await FlutterAppBadger.removeBadge();
        }
      } else if (Platform.isAndroid) {
        if (_unreadCount > 0) {
          await _badgeChannel
              .invokeMethod('setBadgeCount', {'count': _unreadCount});
        } else {
          await _badgeChannel.invokeMethod('removeBadge');
        }
      }
    } on MissingPluginException {
      // Native handler not registered in this host; launcher badge is automatic.
    } catch (e) {
      debugPrint('❌ Failed to update app badge: $e');
    }
  }

  // ==================== LOAD NOTIFICATIONS ====================

  /// [silent] = true keeps the current list on screen (no spinner), used by
  /// pull-to-refresh and the 2-second auto refresh.
  Future<void> loadNotifications({bool silent = false}) async {
    if (_fetching) return;
    _fetching = true;

    if (!silent) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      final response = await _api.getNotifications(excludeType: _chatType);

      if (response.sessionExpired) {
        stopPolling();
        return;
      }

      if (response.success && response.data != null) {
        final dynamic rawData = response.data;
        List items = [];

        if (rawData is Map && rawData.containsKey('data')) {
          items = rawData['data'] ?? [];
        } else if (rawData is List) {
          items = rawData;
        }

        _notifications = items.map<Map<String, dynamic>>((item) {
          final notification = Map<String, dynamic>.from(item);

          final rawTitle = (notification['title']?.toString() ?? '').trim();
          final rawBody = (notification['body']?.toString() ?? '').trim();

          notification['title'] = rawTitle;
          notification['body'] = rawBody;

          if (notification['data'] is String) {
            try {
              notification['data'] = jsonDecode(notification['data']);
            } catch (_) {}
          }
          return notification;
        }).toList();

        _error = null;
      } else {
        _error = response.message;
      }

      await refreshUnreadCount();
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Error loading notifications: $e');
    } finally {
      _fetching = false;
      _isLoading = false;
      if (!_disposed) notifyListeners();
    }
  }

  // ==================== UNREAD COUNT ====================
  Future<void> refreshUnreadCount() async {
    final count = await _fetchUnreadCount();
    await _applyUnreadCount(count ?? localUnreadCount);
  }

  // ==================== MARK AS READ ====================
  Future<void> markAsRead(String notificationId) async {
    try {
      final response = await _api.markNotificationAsRead(notificationId);
      if (!response.success) return;

      final index = _notifications
          .indexWhere((n) => n['id'].toString() == notificationId);

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
      final response =
      await _api.markAllNotificationsAsRead(excludeType: _chatType);
      if (!response.success) return;

      final readAt = DateTime.now().toIso8601String();
      for (final notification in _notifications) {
        notification['is_read'] = true;
        notification['read_at'] = readAt;
      }

      await _applyUnreadCount(0);
    } catch (e) {
      debugPrint('❌ Error marking all notifications as read: $e');
    }
  }

  // ==================== DELETE SINGLE NOTIFICATION ====================
  Future<void> deleteNotification(String notificationId) async {
    try {
      final response = await _api.deleteNotification(notificationId);
      if (!response.success) return;

      _notifications.removeWhere((n) => n['id'].toString() == notificationId);

      await refreshUnreadCount();
    } catch (e) {
      debugPrint('❌ Error deleting notification: $e');
    }
  }

  // ==================== ADD LOCAL NOTIFICATION ====================
  void addLocalNotification(Map<String, dynamic> notification) {
    if (notification['type']?.toString() == _chatType) return;

    notification['is_read'] ??= false;
    notification['title'] = (notification['title']?.toString() ?? '').trim();
    notification['body'] = (notification['body']?.toString() ?? '').trim();

    _notifications.insert(0, notification);
    _applyUnreadCount(_unreadCount + 1);
  }

  // ==================== CLEAR ALL ====================
  Future<void> clearAll() async {
    try {
      final response = await _api.clearNotifications(excludeType: _chatType);
      if (!response.success) return;

      _notifications.clear();
      await _applyUnreadCount(0);
    } catch (e) {
      debugPrint('❌ Error clearing notifications: $e');
    }
  }

  // ==================== DISPOSE ====================
  @override
  void dispose() {
    _disposed = true;
    _pollTimer?.cancel();
    super.dispose();
  }
}