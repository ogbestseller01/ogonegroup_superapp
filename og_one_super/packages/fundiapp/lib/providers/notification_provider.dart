import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../app_navigator.dart';
import '../config/app_routes.dart';
import '../services/api_service.dart';
import '../services/fcm_event_bus.dart';

class NotificationProvider extends ChangeNotifier {
  final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();
  final ApiService _apiService = ApiService();

  // ignore: spell_checker
  static const MethodChannel _badgeChannel =
  MethodChannel('com.nearbyfundi/badge');

  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _error;
  StreamSubscription? _fcmSub;
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
    return false;
  }

  /// NOTE: returns TRUE when the notification is UNREAD (kept as-is so
  /// existing UI code that calls it does not change behaviour).
  bool isRead(Map<String, dynamic> notification) => !_isRead(notification);

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

  // ============================================================
  // CONSTRUCTOR + INIT
  // ============================================================

  NotificationProvider() {
    _init();
  }

  Future<void> _init() async {
    try {
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const ios = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const settings = InitializationSettings(android: android, iOS: ios);

      // flutter_local_notifications 19.x: POSITIONAL settings argument
      await _localNotifications.initialize(
        settings,
        onDidReceiveNotificationResponse: _onNotificationTap,
      );

      await _createNotificationChannel();

      _isInitialized = true;
      await loadNotifications();
      await refreshUnreadCount();

      _fcmSub = FcmEventBus.instance.stream.listen(_onFcmEvent);
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

  // ============================================================
  // FCM EVENT HANDLER
  // ============================================================

  void _onFcmEvent(Map<String, dynamic> event) {
    final type = event['type']?.toString() ?? 'general';

    if (type == 'chat_message') {
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

    addLocalNotification({
      'id': 'local_${DateTime.now().millisecondsSinceEpoch}',
      'title': title,
      'body': body,
      'type': type,
      'is_read': false,
      'created_at': event['received_at'] ?? DateTime.now().toIso8601String(),
    });

    _pulseBadge = true;
    notifyListeners();
    _updateAppBadge();
    Future.delayed(const Duration(seconds: 2), loadNotifications);
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
        final supported = await AppBadgePlus.isSupported();
        if (!supported) {
          debugPrint('ℹ️ iOS badge not supported on this device');
          return;
        }
        await AppBadgePlus.updateBadge(_unreadCount); // 0 clears
        debugPrint('🔴 iOS badge set to $_unreadCount');
      } else if (Platform.isAndroid) {
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

    // Correctly parse JSON payload to check for chat_message
    if (payload != null) {
      try {
        final data = jsonDecode(payload);
        if (data is Map && data['type'] == 'chat_message') {
          return;
        }
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

      // flutter_local_notifications 19.x: POSITIONAL id, title, body, details
      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch.remainder(2147483647),
        safeTitle,
        safeBody,
        const NotificationDetails(
          android: androidDetails,
          iOS: iosDetails,
        ),
        payload: payload,
      );
    } catch (e) {
      debugPrint('❌ Failed to show notification: $e');
    }
  }

  // ============================================================
  // LOAD / REFRESH
  // ============================================================

  Future<void> loadNotifications() async {
    if (_isLoading) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.getNotifications(
        excludeType: 'chat_message',
      );

      if (response.success && response.data != null) {
        final items = _extractList(response.data);
        _notifications = items.map((item) {
          final n = Map<String, dynamic>.from(item);

          final rawTitle = (n['title']?.toString() ?? '').trim();
          final rawBody = (n['body']?.toString() ?? '').trim();

          if (rawTitle.isEmpty ||
              rawBody.isEmpty ||
              double.tryParse(rawTitle) != null ||
              double.tryParse(rawBody) != null) {
            debugPrint(
              '⚠️ Notification #${n['id']} has invalid title/body '
                  '(title: "$rawTitle", body: "$rawBody")',
            );
          }

          n['title'] = rawTitle;
          n['body'] = rawBody;

          if (n['data'] is String) {
            try {
              n['data'] = jsonDecode(n['data']);
            } catch (_) {}
          }
          return n;
        }).toList();
      } else {
        // `response.message` is non-nullable in ApiResponse, so a `??`
        // fallback here triggered the "left operand can't be null" warning.
        final msg = response.message;
        _error = msg.isNotEmpty ? msg : 'Failed to load notifications';
        _notifications = [];
      }

      await refreshUnreadCount();
    } catch (e) {
      _error = 'Error loading notifications: $e';
      _notifications = [];
      debugPrint('❌ Load notifications error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async => loadNotifications();

  Future<void> refreshUnreadCount() async {
    try {
      final response = await _apiService.getUnreadNotificationCount(
        excludeType: 'chat_message',
      );

      if (response.success && response.data != null) {
        final dynamic count =
        response.data is Map ? response.data['count'] : response.data;
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
        excludeType: 'chat_message',
      );
      if (response.success) {
        final readAt = DateTime.now().toIso8601String();
        for (final n in _notifications) {
          n['is_read'] = true;
          n['read_at'] = readAt;
        }
        _unreadCount = 0;
        await _updateAppBadge();
        notifyListeners();
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
        excludeType: 'chat_message',
      );
      if (response.success) {
        _notifications.clear();
        _unreadCount = 0;
        await _updateAppBadge();
        notifyListeners();
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
    if (notification['type']?.toString() == 'chat_message') return;

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
    _unreadCount++;
    _updateAppBadge();
    notifyListeners();
  }

  // ============================================================
  // UTILITIES
  // ============================================================

  void clearError() {
    _error = null;
    notifyListeners();
  }

  String getFormattedTime(String? timestamp) {
    if (timestamp == null) return '';
    try {
      final parsed = DateTime.parse(timestamp);
      final diff = DateTime.now().difference(parsed);
      if (diff.inDays > 0) return '${diff.inDays}d ago';
      if (diff.inHours > 0) return '${diff.inHours}h ago';
      if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
      return 'Just now';
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
    _fcmSub?.cancel();
    _localNotifications.cancelAll();
    super.dispose();
  }
}