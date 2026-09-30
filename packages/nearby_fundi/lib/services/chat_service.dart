// lib/services/chat_service.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import '../models/chat_conversation.dart';
import '../models/chat_message.dart';
import '../models/chat_user.dart';
import 'api_service.dart';

class ChatService {
  static const int MAX_RECONNECT_ATTEMPTS = 5;
  static const Duration RECONNECT_DELAY = Duration(seconds: 3);
  static const Duration PING_INTERVAL = Duration(seconds: 30);

  final ApiService _apiService = ApiService();

  // ================================================================
  // STATE NOTIFIERS
  // ================================================================

  final ValueNotifier<List<ChatConversation>> conversations =
  ValueNotifier<List<ChatConversation>>([]);

  final ValueNotifier<List<ChatMessage>> currentMessages =
  ValueNotifier<List<ChatMessage>>([]);

  final ValueNotifier<int> totalUnreadCount = ValueNotifier<int>(0);

  final ValueNotifier<bool> isTyping = ValueNotifier<bool>(false);

  final ValueNotifier<bool> isConnected = ValueNotifier<bool>(false);

  final ValueNotifier<bool> isConnecting = ValueNotifier<bool>(false);

  // ================================================================
  // PRIVATE STATE
  // ================================================================

  ChatUser? _currentUser;
  String? _token;
  WebSocketChannel? _channel;
  int _reconnectAttempts = 0;
  bool _isReconnecting = false;
  bool _isDisposed = false;
  final Set<int> _subscribedUsers = {};
  Timer? _pingTimer;

  // ================================================================
  // GETTERS
  // ================================================================

  ChatUser? get currentUser => _currentUser;
  bool get isWebSocketConnected => _channel != null && isConnected.value;

  // ================================================================
  // INITIALIZATION
  // ================================================================

  void initialize({
    required String token,
    required ChatUser currentUser,
  }) {
    if (_isDisposed) return;

    _token = token;
    _currentUser = currentUser;
    _apiService.onSessionExpired = _handleSessionExpired;

    _loadInitialData();
  }

  void _loadInitialData() async {
    await loadConversations();
    await loadUnreadCount();
  }

  void _handleSessionExpired() {
    _clearState();
  }

  // ================================================================
  // WEB SOCKET
  // ================================================================

  void connectWebSocket() {
    if (_isDisposed) return;
    if (_channel != null) {
      debugPrint('⚠️ WebSocket already connected');
      return;
    }
    if (_token == null || _token!.isEmpty) {
      debugPrint('⚠️ Cannot connect WebSocket: No token');
      return;
    }
    if (isConnecting.value) {
      debugPrint('⚠️ WebSocket connection already in progress');
      return;
    }

    isConnecting.value = true;
    debugPrint('🔌 Connecting WebSocket...');

    try {
      final wsUrl = _buildWebSocketUrl();
      _channel = IOWebSocketChannel.connect(
        Uri.parse(wsUrl),
        pingInterval: PING_INTERVAL,
      );

      _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDone,
      );

      isConnected.value = true;
      isConnecting.value = false;
      _reconnectAttempts = 0;
      _startPingTimer();

      debugPrint('✅ WebSocket connected');
    } catch (e) {
      isConnecting.value = false;
      debugPrint('❌ WebSocket connection failed: $e');
      _attemptReconnect();
    }
  }

  String _buildWebSocketUrl() {
    String baseUrl;
    try {
      baseUrl = _apiService.dio.options.baseUrl;
    } catch (e) {
      baseUrl = 'http://localhost:8000/api';
    }

    final wsBase = baseUrl
        .replaceFirst('http://', 'ws://')
        .replaceFirst('https://', 'wss://')
        .replaceFirst('/api', '');

    return '$wsBase/chat/ws?token=$_token';
  }

  void disconnectWebSocket() {
    _stopPingTimer();
    _channel?.sink.close();
    _channel = null;
    isConnected.value = false;
    debugPrint('🔌 WebSocket disconnected manually');
  }

  void _attemptReconnect() {
    if (_isDisposed) return;
    if (_isReconnecting) return;
    if (_reconnectAttempts >= MAX_RECONNECT_ATTEMPTS) {
      debugPrint('❌ Max reconnect attempts reached');
      return;
    }

    _isReconnecting = true;
    _reconnectAttempts++;

    debugPrint(
        '🔄 Reconnect attempt $_reconnectAttempts/$MAX_RECONNECT_ATTEMPTS');

    Future.delayed(RECONNECT_DELAY * _reconnectAttempts, () {
      _isReconnecting = false;
      if (!_isDisposed && !isConnected.value) {
        connectWebSocket();
      }
    });
  }

  void _startPingTimer() {
    _stopPingTimer();
    _pingTimer = Timer.periodic(PING_INTERVAL, (_) {
      if (_channel != null && isConnected.value) {
        try {
          _channel!.sink.add(jsonEncode({'event': 'ping'}));
        } catch (e) {
          debugPrint('⚠️ Ping failed: $e');
        }
      }
    });
  }

  void _stopPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = null;
  }

  // ================================================================
  // WEB SOCKET HANDLERS
  // ================================================================

  void _handleMessage(dynamic message) {
    try {
      final data = _parseMessage(message);
      if (data == null) return;

      final event = data['event'] as String?;
      final payload = data['data'];

      switch (event) {
        case 'new_message':
          _handleNewMessage(payload);
          break;
        case 'message_read':
          _handleMessageRead(payload);
          break;
        case 'user_typing':
          _handleUserTyping(payload);
          break;
        case 'user_online':
          _handleUserOnline(payload);
          break;
        case 'user_offline':
          _handleUserOffline(payload);
          break;
        case 'conversation_updated':
          _handleConversationUpdated(payload);
          break;
        case 'pong':
          break;
        default:
          if (kDebugMode) {
            debugPrint('📨 Unknown WebSocket event: $event');
          }
      }
    } catch (e) {
      debugPrint('⚠️ Error handling WebSocket message: $e');
    }
  }

  // ✅ FIXED: Convert message to string before decoding
  Map<String, dynamic>? _parseMessage(dynamic message) {
    if (message == null) return null;
    try {
      return jsonDecode(message.toString()) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('⚠️ Failed to parse WebSocket message: $e');
      return null;
    }
  }

  void _handleError(dynamic error) {
    debugPrint('⚠️ WebSocket error: $error');
    isConnected.value = false;
    _attemptReconnect();
  }

  void _handleDone() {
    debugPrint('🔌 WebSocket disconnected');
    isConnected.value = false;
    _channel = null;
    _attemptReconnect();
  }

  // ================================================================
  // WEB SOCKET MESSAGE HANDLERS
  // ================================================================

  void _handleNewMessage(dynamic data) {
    try {
      final message = ChatMessage.fromJson(data);
      if (message.id == 0) return;

      final messages = List<ChatMessage>.from(currentMessages.value);
      if (!messages.any((m) => m.id == message.id)) {
        if (messages.isNotEmpty &&
            messages.first.conversationId == message.conversationId) {
          messages.insert(0, message);
        } else {
          messages.add(message);
        }
        currentMessages.value = messages;
      }

      _updateConversationWithMessage(message);

      if (message.receiverId == _currentUser?.id) {
        totalUnreadCount.value++;
      }

      debugPrint('📩 New message received: ${message.id}');
    } catch (e) {
      debugPrint('⚠️ Error handling new message: $e');
    }
  }

  void _handleMessageRead(dynamic data) {
    try {
      final messageId = data['message_id'] as int?;
      if (messageId == null) return;

      final messages = List<ChatMessage>.from(currentMessages.value);
      final index = messages.indexWhere((m) => m.id == messageId);
      if (index != -1) {
        messages[index] = messages[index].copyWith(
          isRead: true,
          readAt: data['read_at'],
        );
        currentMessages.value = messages;
      }

      loadUnreadCount();
    } catch (e) {
      debugPrint('⚠️ Error handling message read: $e');
    }
  }

  void _handleUserTyping(dynamic data) {
    try {
      final userId = data['user_id'] as int?;
      final isTypingValue = data['is_typing'] as bool? ?? false;
      if (userId == null) return;

      final messages = currentMessages.value;
      if (messages.isNotEmpty) {
        final conversationId = messages.first.conversationId;

        ChatConversation? conversation;
        for (final conv in conversations.value) {
          if (conv.id == conversationId) {
            conversation = conv;
            break;
          }
        }

        if (conversation != null && conversation.otherParty.id == userId) {
          isTyping.value = isTypingValue;
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error handling typing status: $e');
    }
  }

  void _handleUserOnline(dynamic data) {
    final userId = data['user_id'] as int?;
    if (userId == null) return;
    _updateUserOnlineStatus(userId, true);
  }

  void _handleUserOffline(dynamic data) {
    final userId = data['user_id'] as int?;
    if (userId == null) return;
    _updateUserOnlineStatus(userId, false, data['last_seen']);
  }

  void _updateUserOnlineStatus(int userId, bool isOnline, [String? lastSeen]) {
    final convs = List<ChatConversation>.from(conversations.value);
    bool updated = false;

    for (var i = 0; i < convs.length; i++) {
      if (convs[i].otherParty.id == userId) {
        final party = convs[i].otherParty;
        convs[i] = convs[i].copyWith(
          otherParty: ChatUser(
            id: party.id,
            name: party.name,
            email: party.email,
            phone: party.phone,
            avatar: party.avatar,
            isOnline: isOnline,
            lastSeen: lastSeen ?? party.lastSeen,
            fcmToken: party.fcmToken,
          ),
        );
        updated = true;
      }
    }

    if (updated) {
      conversations.value = convs;
    }
  }

  void _handleConversationUpdated(dynamic data) {
    try {
      final conversation = ChatConversation.fromJson(data);
      final convs = List<ChatConversation>.from(conversations.value);
      final index = convs.indexWhere((c) => c.id == conversation.id);

      if (index != -1) {
        convs[index] = conversation;
        conversations.value = convs;
      }
    } catch (e) {
      debugPrint('⚠️ Error handling conversation update: $e');
    }
  }

  void _updateConversationWithMessage(ChatMessage message) {
    final convs = List<ChatConversation>.from(conversations.value);
    final index = convs.indexWhere((c) => c.id == message.conversationId);

    if (index != -1) {
      final conv = convs[index];
      final unreadCount = message.receiverId == _currentUser?.id
          ? conv.unreadCount + 1
          : conv.unreadCount;

      convs[index] = conv.copyWith(
        lastMessage: message,
        unreadCount: unreadCount,
        lastMessageAt: message.createdAt ?? conv.lastMessageAt,
      );

      final updated = convs.removeAt(index);
      convs.insert(0, updated);
      conversations.value = convs;
    } else {
      loadConversations();
    }
  }

  // ================================================================
  // WEB SOCKET SEND METHODS
  // ================================================================

  void _sendWebSocketMessage(Map<String, dynamic> message) {
    if (_channel == null || !isConnected.value) {
      debugPrint('⚠️ Cannot send WebSocket message: Not connected');
      return;
    }

    try {
      _channel!.sink.add(jsonEncode(message));
    } catch (e) {
      debugPrint('⚠️ Failed to send WebSocket message: $e');
    }
  }

  void sendTypingStatus({
    required int conversationId,
    required bool typing,
  }) {
    _sendWebSocketMessage({
      'event': 'typing',
      'data': {
        'conversation_id': conversationId,
        'is_typing': typing,
      },
    });
  }

  void sendReadReceipt({
    required int messageId,
    required int senderId,
  }) {
    _sendWebSocketMessage({
      'event': 'read',
      'data': {
        'message_id': messageId,
        'sender_id': senderId,
      },
    });
  }

  void subscribeToUser(int userId) {
    if (_subscribedUsers.contains(userId)) return;
    _subscribedUsers.add(userId);
    _sendWebSocketMessage({
      'event': 'subscribe',
      'data': {'user_id': userId},
    });
  }

  void unsubscribeFromUser(int userId) {
    if (!_subscribedUsers.contains(userId)) return;
    _subscribedUsers.remove(userId);
    _sendWebSocketMessage({
      'event': 'unsubscribe',
      'data': {'user_id': userId},
    });
  }

  // ================================================================
  // API METHODS
  // ================================================================

  Future<ChatConversation> createConversation({
    required int customerId,
    required int fundiId,
  }) async {
    try {
      final response = await _apiService.getOrCreateConversation(
        customerId: customerId,
        fundiId: fundiId,
      );

      if (response.success && response.data != null) {
        final conversation = ChatConversation.fromJson(response.data);
        final convs = List<ChatConversation>.from(conversations.value);

        if (!convs.any((c) => c.id == conversation.id)) {
          convs.insert(0, conversation);
          conversations.value = convs;
        }

        return conversation;
      } else {
        throw Exception(response.message ?? 'Failed to create conversation');
      }
    } catch (e) {
      debugPrint('❌ Create conversation error: $e');
      rethrow;
    }
  }

  Future<void> loadConversations() async {
    try {
      final response = await _apiService.getConversations();

      if (response.success && response.data != null) {
        final data = response.data as List;
        final loaded = data
            .map((item) => ChatConversation.fromJson(item))
            .where((c) => c.id > 0)
            .toList();

        conversations.value = loaded;
        await loadUnreadCount();

        debugPrint('📋 Loaded ${loaded.length} conversations');
      } else {
        debugPrint('⚠️ Failed to load conversations: ${response.message}');
      }
    } catch (e) {
      debugPrint('❌ Error loading conversations: $e');
    }
  }

  Future<List<ChatMessage>> getMessages({
    required int conversationId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _apiService.getMessages(
        conversationId: conversationId,
        limit: limit,
        offset: offset,
      );

      if (response.success && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final messagesList = data['messages'] as List? ?? [];
        final messages = messagesList
            .map((item) => ChatMessage.fromJson(item))
            .where((m) => m.id > 0)
            .toList();

        if (offset == 0) {
          currentMessages.value = messages;
        } else {
          final existing = List<ChatMessage>.from(currentMessages.value);
          existing.addAll(messages);
          currentMessages.value = existing;
        }

        final markedCount = data['unread_marked_count'] as int? ?? 0;
        if (markedCount > 0) {
          await loadUnreadCount();
        }

        return messages;
      } else {
        throw Exception(response.message ?? 'Failed to load messages');
      }
    } catch (e) {
      debugPrint('❌ Get messages error: $e');
      rethrow;
    }
  }

  Future<ChatMessage> sendMessage({
    required int conversationId,
    String? content,
    File? file,
    String messageType = 'text',
    int? voiceDuration,
  }) async {
    try {
      final response = await _apiService.sendMessage(
        conversationId: conversationId,
        content: content,
        filePath: file?.path,
        messageType: messageType,
        voiceDuration: voiceDuration,
      );

      if (response.success && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final message = ChatMessage.fromJson(data['message'] ?? data);

        final messages = List<ChatMessage>.from(currentMessages.value);
        if (!messages.any((m) => m.id == message.id)) {
          messages.insert(0, message);
          currentMessages.value = messages;
        }

        _updateConversationWithMessage(message);

        return message;
      } else {
        throw Exception(response.message ?? 'Failed to send message');
      }
    } catch (e) {
      debugPrint('❌ Send message error: $e');
      rethrow;
    }
  }

  Future<void> markConversationAsRead(int conversationId) async {
    try {
      final response = await _apiService.markConversationAsRead(conversationId);

      if (response.success) {
        final convs = List<ChatConversation>.from(conversations.value);
        final index = convs.indexWhere((c) => c.id == conversationId);
        if (index != -1) {
          convs[index] = convs[index].copyWith(unreadCount: 0);
          conversations.value = convs;
        }

        final messages = List<ChatMessage>.from(currentMessages.value);
        for (var i = 0; i < messages.length; i++) {
          if (messages[i].conversationId == conversationId &&
              !messages[i].isRead) {
            messages[i] = messages[i].copyWith(
              isRead: true,
              readAt: DateTime.now().toIso8601String(),
            );
          }
        }
        currentMessages.value = messages;

        await loadUnreadCount();

        debugPrint('✅ Marked conversation $conversationId as read');
      }
    } catch (e) {
      debugPrint('⚠️ Error marking conversation as read: $e');
    }
  }

  Future<void> deleteMessage(int messageId) async {
    try {
      final response = await _apiService.deleteMessage(messageId);

      if (response.success) {
        final messages = List<ChatMessage>.from(currentMessages.value);
        messages.removeWhere((m) => m.id == messageId);
        currentMessages.value = messages;

        await loadConversations();

        debugPrint('✅ Deleted message $messageId');
      }
    } catch (e) {
      debugPrint('❌ Delete message error: $e');
      rethrow;
    }
  }

  Future<void> addReaction(int messageId, String reaction) async {
    try {
      final response = await _apiService.addReaction(messageId, reaction);
      if (!response.success) {
        debugPrint('⚠️ Failed to add reaction: ${response.message}');
      }
    } catch (e) {
      debugPrint('⚠️ Add reaction error: $e');
    }
  }

  Future<void> loadUnreadCount() async {
    try {
      final response = await _apiService.getUnreadCount();

      if (response.success && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final total = data['total_unread'] as int? ?? 0;
        totalUnreadCount.value = total;
      }
    } catch (e) {
      debugPrint('⚠️ Error loading unread count: $e');
    }
  }

  Future<void> refreshConversations() async {
    await loadConversations();
  }

  // ================================================================
  // HELPERS
  // ================================================================

  bool isCurrentUserMessage(ChatMessage message) {
    return message.senderId == _currentUser?.id;
  }

  void _clearState() {
    conversations.value = [];
    currentMessages.value = [];
    totalUnreadCount.value = 0;
    isTyping.value = false;
  }

  // ================================================================
  // DISPOSAL
  // ================================================================

  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;

    _stopPingTimer();
    disconnectWebSocket();

    conversations.dispose();
    currentMessages.dispose();
    totalUnreadCount.dispose();
    isTyping.dispose();
    isConnected.dispose();
    isConnecting.dispose();

    _subscribedUsers.clear();
    _currentUser = null;
    _token = null;

    debugPrint('🗑️ ChatService disposed');
  }
}