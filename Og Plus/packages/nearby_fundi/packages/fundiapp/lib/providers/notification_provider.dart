// lib/providers/notification_provider.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app_badger_plus/flutter_app_badger_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../app_navigator.dart';
import '../config/app_routes.dart';
import '../services/api_service.dart';
import '../services/fcm_event_bus.dart';

class NotificationProvider extends ChangeNotifier {
  NotificationProvider({ApiService? api}) : _apiService = api ?? ApiService() {
    _init();
  }

  final ApiService _apiService;
  final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  static const String _chatType = 'chat_message';

  /// How often the server unread count is polled while the app is
  /// in the foreground. 15s is a good balance for a REST bell badge.
  static const Duration _pollInterval = Duration(seconds: 15);

  /// Primary native badge channel (matches MainActivity.kt package com.fundapp).
  static const MethodChannel _badgeChannel =
  MethodChannel('com.fundapp/badge');

  /// Fallback for older native builds still using the old applicationId.
  static const MethodChannel _legacyBadgeChannel =
  MethodChannel('com.nearbyfundi/badge');

  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = false;
  bool _fetching = false;
  bool _polling = false;
  bool _disposed = false;
  bool _isInitialized = false;
  String? _error;
  StreamSubscription? _fcmSub;
  Timer? _pollTimer;
  Timer? _reloadTimer;
  bool _pulseBadge = false;
  int _unreadCount = 0;

  // ============================================================
  // GETTERS
  // ============================================================
  List<Map<String, dynamic>> get notifications => _notifications;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get error => _error;
  bool get pulseBadge => _pulseBadge;
  int get unreadCount => _unreadCount;
  bool get hasUnread => unreadCount > 0;
  bool get hasNotifications => _notifications.isNotEmpty;
  bool get isPolling => _pollTimer?.isActive ?? false;

  int get localUnreadCount => _notifications.where((n) => !_isRead(n)).length;

  // ============================================================
  // HELPERS
  // ============================================================

  String _idToString(dynamic id) => id?.toString() ?? '';

  bool _isRead(Map<String, dynamic> n) {
    final value = n['is_read'];
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      return value == '1' || value.toLowerCase() == 'true';
    }
    return n['read_at'] != null;
  }

  /// NOTE: returns TRUE when the notification is UNREAD (kept for
  /// backwards-compatibility with existing UI code).
  bool isRead(Map<String, dynamic> notification) => !_isRead(notification);

  /// TRUE when the notification has been read.
  bool isNotificationRead(Map notification) =>
      _isRead(Map<String, dynamic>.from(notification));

  String? _validText(dynamic value) {
    final text = (value?.toString() ?? '').trim();
    if (text.isEmpty) return null;
    if (double.tryParse(text) != null) return null;
    return text;
  }

  List<Map<String, dynamic>> _extractList(dynamic raw) {
    if (raw == null) return [];
    if (raw is List) {
      return raw
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    }
    if (raw is Map) {
      final inner = raw['data'];
      if (inner is List) {
        return inner
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
      }
      if (inner is Map && inner['data'] is List) {
        return (inner['data'] as List)
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
      }
    }
    return [];
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  // ============================================================
  // INIT
  // ============================================================

  Future<void> _init() async {
    try {
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const ios = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const settings = InitializationSettings(android: android, iOS: ios);

      await _localNotifications.initialize(
        settings,
        onDidReceiveNotificationResponse: _onNotificationTap,
      );

      await _createNotificationChannel();
      await _requestNotificationPermission();

      _isInitialized = true;
      await loadNotifications();

      _fcmSub = FcmEventBus.instance.stream.listen(_onFcmEvent);

      // Kick off the periodic auto-check immediately.
      startPolling();

      debugPrint('✅ NotificationProvider initialized');
    } catch (e) {
      debugPrint('❌ Notification init error: $e');
      _error = 'Failed to initialize notifications';
    }
  }

  Future<void> _createNotificationChannel() async {
    const channel = AndroidNotificationChannel(
      'fundi_channel',
      'NearbyFundi Notifications',
      description: 'Notifications from NearbyFundi',
      importance: Importance.max,
      enableVibration: true,
      playSound: true,
      showBadge: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// Android 13+ requires runtime POST_NOTIFICATIONS permission.
  Future<void> _requestNotificationPermission() async {
    if (!Platform.isAndroid) return;
    try {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } catch (e) {
      debugPrint('⚠️ Notification permission request failed: $e');
    }
  }

  // ============================================================
  // APP LIFECYCLE HOOKS
  // Call these from a WidgetsBindingObserver in your root widget.
  // ============================================================

  /// Resume the auto-check and immediately sync when the app returns
  /// to the foreground.
  void onAppResumed() {
    if (_disposed) return;
    startPolling();
    loadNotifications(silent: true);
    refreshUnreadCount();
  }

  /// Stop the auto-check while the app is backgrounded. FCM will still
  /// deliver system notifications in the background.
  void onAppPaused() {
    stopPolling();
  }

  // ============================================================
  // AUTO CHECK
  // ============================================================

  /// Safe to call repeatedly; only one timer ever runs.
  void startPolling() {
    if (_disposed || isPolling) return;
    _pollTimer = Timer.periodic(_pollInterval, (_) => _poll());
    debugPrint('⏱️ Notification polling started');
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
    debugPrint('⏸️ Notification polling stopped');
  }

  Future<void> _poll() async {
    if (_polling || _fetching || _disposed) return;
    _polling = true;
    try {
      final count = await _fetchUnreadCount();
      debugPrint('🔄 poll → server=$count local=$_unreadCount');
      if (count == null) return;

      if (count != _unreadCount) {
        if (count > _unreadCount) _pulseBadge = true;
        await loadNotifications(silent: true);
      }
    } finally {
      _polling = false;
    }
  }

  Future<int?> _fetchUnreadCount() async {
    try {
      final response = await _apiService.getUnreadNotificationCount(
        excludeType: _chatType,
      );

      if (response.sessionExpired) {
        stopPolling();
        return null;
      }
      if (!response.success || response.data == null) return null;

      final dynamic raw =
      response.data is Map ? response.data['count'] : response.data;
      return raw is int ? raw : int.tryParse(raw.toString());
    } catch (e) {
      debugPrint('❌ Error fetching unread count: $e');
      return null;
    }
  }

  // ============================================================
  // FCM EVENT HANDLER
  // ============================================================

  void _onFcmEvent(Map<String, dynamic> event) {
    final type = event['type']?.toString() ?? 'general';

    if (type == _chatType) {
      refreshUnreadCount();
      return;
    }

    final title = _validText(event['title']);
    final body = _validText(event['body']);

    if (title == null || body == null) {
      debugPrint(
        '⚠️ FCM event skipped — invalid title/body '
            '(title: "${event['title']}", body: "${event['body']}", type: $type)',
      );
      return;
    }

    final payload = jsonEncode({
      'type': type,
      'conversation_id': event['conversation_id'],
      'data': event['data'],
    });

    // In-app list entry (also refreshes badge via _applyUnreadCount).
    addLocalNotification({
      'id': 'local_${DateTime.now().millisecondsSinceEpoch}',
      'title': title,
      'body': body,
      'type': type,
      'is_read': false,
      'created_at': event['received_at'] ?? DateTime.now().toIso8601String(),
    });

    // Foreground tray notification (system won't show one automatically).
    showLocalNotification(title: title, body: body, payload: payload);

    _pulseBadge = true;
    _notify();

    _reloadTimer?.cancel();
    _reloadTimer = Timer(
      const Duration(seconds: 2),
          () => loadNotifications(silent: true),
    );
  }

  void consumePulse() {
    _pulseBadge = false;
  }

  // ============================================================
  // APP BADGE
  // ============================================================

  Future<void> _updateAppBadge() async {
    try {
      if (Platform.isIOS) {
        final supported = await FlutterAppBadger.isAppBadgeSupported();
        if (!supported) return;

        if (_unreadCount > 0) {
          await FlutterAppBadger.updateBadgeCount(_unreadCount);
        } else {
          await FlutterAppBadger.removeBadge();
        }
      } else if (Platform.isAndroid) {
        final method = _unreadCount > 0 ? 'setBadgeCount' : 'removeBadge';
        final args =
        _unreadCount > 0 ? <String, dynamic>{'count': _unreadCount} : null;

        try {
          await _badgeChannel.invokeMethod(method, args);
        } on MissingPluginException {
          // Older native builds only register the legacy channel.
          await _legacyBadgeChannel.invokeMethod(method, args);
        }
      }
    } on MissingPluginException {
      // Native handler not registered at all — the launcher badge on Android
      // is driven by posted notifications anyway.
    } catch (e) {
      debugPrint('❌ Failed to update app badge: $e');
    }
  }

  Future<void> _applyUnreadCount(int count) async {
    final next = count < 0 ? 0 : count;
    if (next == _unreadCount) {
      _notify();
      return;
    }
    _unreadCount = next;
    await _updateAppBadge();
    _notify();
  }

  // ============================================================
  // NOTIFICATION TAP
  // ============================================================

  void _onNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null) return;

    try {
      final data = Map<String, dynamic>.from(json.decode(payload) as Map);
      _handleNavigation(data);
    } catch (e) {
      debugPrint('⚠️ Invalid notification payload: $e');
      navigatorKey.currentState?.pushNamed(AppRoutes.home);
    }
  }

  void _handleNavigation(Map<String, dynamic> data) {
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

  // ============================================================
  // LOCAL NOTIFICATIONS
  // ============================================================

  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isInitialized) return;

    if (payload != null) {
      try {
        final data = jsonDecode(payload);
        if (data is Map && data['type'] == _chatType) return;
      } catch (_) {
        // Ignore invalid JSON
      }
    }

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
        'fundi_channel',
        'NearbyFundi Notifications',
        channelDescription: 'Notifications from NearbyFundi',
        importance: Importance.max,
        priority: Priority.high,
        channelShowBadge: true,
        showWhen: true,
        playSound: true,
        enableVibration: true,
        icon: '@mipmap/ic_launcher',
        autoCancel: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch.remainder(2147483647),
        safeTitle,
        safeBody,
        const NotificationDetails(android: androidDetails, iOS: iosDetails),
        payload: payload,
      );
    } catch (e) {
      debugPrint('❌ Failed to show notification: $e');
    }
  }

  // ============================================================
  // LOAD / REFRESH
  // ============================================================

  Future<void> loadNotifications({bool silent = false}) async {
    if (_disposed || _fetching) return;
    _fetching = true;

    if (!silent) {
      _isLoading = true;
      _error = null;
      _notify();
    }

    try {
      final response = await _apiService.getNotifications(
        excludeType: _chatType,
      );

      if (response.sessionExpired) {
        stopPolling();
        return;
      }

      if (response.success && response.data != null) {
        final items = _extractList(response.data);
        _notifications = items.map((item) {
          final n = Map<String, dynamic>.from(item);

          n['title'] = (n['title']?.toString() ?? '').trim();
          n['body'] = (n['body']?.toString() ?? '').trim();

          if (n['data'] is String) {
            try {
              n['data'] = jsonDecode(n['data']);
            } catch (_) {}
          }
          return n;
        }).toList();
        _error = null;
      } else if (!silent) {
        final msg = response.message;
        _error = msg.isNotEmpty ? msg : 'Failed to load notifications';
        _notifications = [];
      }

      await refreshUnreadCount();
    } catch (e) {
      if (!silent) {
        _error = 'Error loading notifications: $e';
        _notifications = [];
      }
      debugPrint('❌ Load notifications error: $e');
    } finally {
      _fetching = false;
      if (!_disposed) {
        _isLoading = false;
        _notify();
      }
    }
  }

  Future<void> refresh() async => loadNotifications();

  Future<void> refreshUnreadCount() async {
    final count = await _fetchUnreadCount();
    await _applyUnreadCount(count ?? localUnreadCount);
  }

  // ============================================================
  // MARK AS READ / DELETE / CLEAR
  // ============================================================

  Future<bool> markAsRead(dynamic notificationId) async {
    final id = _idToString(notificationId);
    if (id.isEmpty) return false;
    try {
      final response = await _apiService.markNotificationAsRead(id);
      if (response.success) {
        final index =
        _notifications.indexWhere((n) => _idToString(n['id']) == id);
        if (index != -1) {
          _notifications[index]['is_read'] = true;
          _notifications[index]['read_at'] = DateTime.now().toIso8601String();
        }
        await refreshUnreadCount();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Mark as read error: $e');
      return false;
    }
  }

  Future<bool> markAllAsRead() async {
    try {
      final response = await _apiService.markAllNotificationsAsRead(
        excludeType: _chatType,
      );
      if (response.success) {
        final readAt = DateTime.now().toIso8601String();
        for (final n in _notifications) {
          n['is_read'] = true;
          n['read_at'] = readAt;
        }
        await _applyUnreadCount(0);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Mark all as read error: $e');
      return false;
    }
  }

  Future<bool> clearAll() async {
    try {
      final response = await _apiService.clearNotifications(
        excludeType: _chatType,
      );
      if (response.success) {
        _notifications.clear();
        await _applyUnreadCount(0);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Clear notifications error: $e');
      return false;
    }
  }

  Future<bool> deleteNotification(dynamic notificationId) async {
    final id = _idToString(notificationId);
    if (id.isEmpty) return false;
    try {
      final response = await _apiService.deleteNotification(id);
      if (response.success) {
        _notifications.removeWhere((n) => _idToString(n['id']) == id);
        await refreshUnreadCount();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Delete notification error: $e');
      return false;
    }
  }

  // ============================================================
  // ADD LOCAL NOTIFICATION (used by FCM listener)
  // ============================================================

  void addLocalNotification(Map<String, dynamic> notification) {
    if (notification['type']?.toString() == _chatType) return;

    final title = _validText(notification['title']);
    final body = _validText(notification['body']);

    if (title == null || body == null) {
      debugPrint(
        '⚠️ addLocalNotification skipped — invalid title/body '
            '(title: "${notification['title']}", body: "${notification['body']}")',
      );
      return;
    }

    notification['title'] = title;
    notification['body'] = body;

    final id = _idToString(notification['id']);
    if (_notifications.any((n) => _idToString(n['id']) == id)) return;

    _notifications.insert(0, notification);
    _applyUnreadCount(_unreadCount + 1);
  }

  // ============================================================
  // UTILITIES
  // ============================================================

  void clearError() {
    _error = null;
    _notify();
  }

  /// Relative time, English or Swahili (`locale` = 'sw').
  String getFormattedTime(String? timestamp, {String locale = 'en'}) {
    if (timestamp == null) return '';
    final sw = locale == 'sw';
    try {
      var parsed = DateTime.parse(timestamp);
      if (parsed.isUtc) parsed = parsed.toLocal();
      final diff = DateTime.now().difference(parsed);
      if (diff.inDays > 0) {
        return sw ? 'Siku ${diff.inDays} zilizopita' : '${diff.inDays}d ago';
      }
      if (diff.inHours > 0) {
        return sw ? 'Saa ${diff.inHours} zilizopita' : '${diff.inHours}h ago';
      }
      if (diff.inMinutes > 0) {
        return sw
            ? 'Dakika ${diff.inMinutes} zilizopita'
            : '${diff.inMinutes}m ago';
      }
      return sw ? 'Sasa hivi' : 'Just now';
    } catch (_) {
      return '';
    }
  }

  IconData getNotificationIcon(String type) {
    switch (type) {
      case 'chat_message':
        return Icons.chat_bubble_outline_rounded;
      case 'new_request':
        return Icons.request_page_outlined;
      case 'request_accepted':
        return Icons.check_circle_outline_rounded;
      case 'request_rejected':
      case 'request_cancelled':
        return Icons.cancel_outlined;
      case 'request_in_progress':
        return Icons.hourglass_top_rounded;
      case 'request_on_the_way':
        return Icons.local_shipping_outlined;
      case 'request_arrived':
        return Icons.pin_drop_outlined;
      case 'request_completed':
        return Icons.task_alt_rounded;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color getNotificationColor(String type) {
    switch (type) {
      case 'new_request':
        return Colors.orange;
      case 'request_accepted':
      case 'request_completed':
        return Colors.green;
      case 'request_rejected':
      case 'request_cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _pollTimer?.cancel();
    _reloadTimer?.cancel();
    _fcmSub?.cancel();
    _localNotifications.cancelAll();
    super.dispose();
  }
}