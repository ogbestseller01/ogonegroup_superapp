// lib/services/chat_service.dart

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import '../models/chat_user.dart';
import '../models/chat_message.dart';
import '../models/chat_conversation.dart';
import 'websocket_service.dart';
import 'api_service.dart';
import 'storage_service.dart';
import '../utils/badge_helper.dart'; // 👈 ADD THIS

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  // Dependencies
  late ApiService _apiService;
  WebSocketService? _webSocketService;

  // State
  final ValueNotifier<List<ChatConversation>> conversations = ValueNotifier([]);
  final ValueNotifier<List<ChatMessage>> currentMessages = ValueNotifier([]);
  final ValueNotifier<int> totalUnreadCount = ValueNotifier(0);
  final ValueNotifier<bool> isTyping = ValueNotifier(false);
  final ValueNotifier<bool> _isConnected = ValueNotifier(false);

  // Current user
  ChatUser? _currentUser;
  String? _token;

  // Getters
  bool get isConnected => _isConnected.value;
  ChatUser? get currentUser => _currentUser;

  // ============================================
  // INITIALIZATION
  // ============================================

  void initialize({required String token, required ChatUser currentUser}) {
    _token = token;
    _currentUser = currentUser;
    _apiService = ApiService();

    _webSocketService = WebSocketService(
      token: token,
      userId: currentUser.id,
      onNewMessage: _handleNewMessage,
      onMessageRead: _handleMessageRead,
      onUserTyping: _handleUserTyping,
      onConnected: _handleConnected,
      onDisconnected: _handleDisconnected,
    );

    loadConversations();
    loadUnreadCount();
  }

  // ============================================
  // CONVERSATIONS
  // ============================================

  Future<ChatConversation> getOrCreateConversation({
    required int customerId,
    required int fundiId,
  }) async {
    try {
      final response = await _apiService.getOrCreateConversation(
        customerId: customerId,
        fundiId: fundiId,
      );

      if (response.success) {
        final conversation = ChatConversation.fromJson(response.data);
        await loadConversations();
        return conversation;
      }
      throw Exception(response.message);
    } catch (e) {
      throw Exception('Failed to create conversation: $e');
    }
  }

  Future<void> loadConversations() async {
    try {
      final response = await _apiService.getConversations();

      if (response.success) {
        final data = response.data;
        List<dynamic> conversationsData;

        if (data is List) {
          conversationsData = data;
        } else if (data is Map && data.containsKey('data')) {
          conversationsData = data['data'] as List? ?? [];
        } else {
          conversationsData = [];
        }

        final List<ChatConversation> loaded = conversationsData
            .map((item) => ChatConversation.fromJson(item))
            .toList();

        conversations.value = loaded;

        for (var conv in loaded) {
          _webSocketService?.subscribeToTyping(conv.id);
        }
      }
    } catch (e) {
      debugPrint('Failed to load conversations: $e');
    }
  }

  Future<void> refreshConversations() async {
    await loadConversations();
  }

  ChatConversation? getConversationById(int id) {
    try {
      return conversations.value.firstWhere((conv) => conv.id == id);
    } catch (e) {
      return null;
    }
  }

  // ============================================
  // MESSAGES
  // ============================================

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

      if (response.success) {
        final data = response.data;
        List<dynamic> messagesData;

        if (data is Map) {
          messagesData = data['messages'] as List? ?? [];
        } else if (data is List) {
          messagesData = data;
        } else {
          messagesData = [];
        }

        final List<ChatMessage> messages = messagesData
            .map((item) => ChatMessage.fromJson(item))
            .toList();

        if (offset == 0) {
          currentMessages.value = messages;
        } else {
          currentMessages.value = [...messages, ...currentMessages.value];
        }

        return messages;
      }
      return [];
    } catch (e) {
      debugPrint('Failed to get messages: $e');
      return [];
    }
  }

  Future<List<ChatMessage>> loadMoreMessages({
    required int conversationId,
    int limit = 50,
  }) async {
    final currentCount = currentMessages.value.length;
    return await getMessages(
      conversationId: conversationId,
      limit: limit,
      offset: currentCount,
    );
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

      if (response.success) {
        final messageData = response.data['message'] ?? response.data;
        final message = ChatMessage.fromJson(messageData);

        final currentList = currentMessages.value;
        if (!currentList.any((m) => m.id == message.id)) {
          currentMessages.value = [...currentList, message];
        }

        await loadConversations();
        return message;
      }
      throw Exception(response.message);
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  /// Send multiple messages (text + files)
  Future<List<ChatMessage>> sendMultipleMessages({
    required int conversationId,
    List<File>? files,
    String? content,
    String messageType = 'image',
  }) async {
    final List<ChatMessage> sentMessages = [];

    if (content != null && content.isNotEmpty) {
      final textMessage = await sendMessage(
        conversationId: conversationId,
        content: content,
        messageType: 'text',
      );
      sentMessages.add(textMessage);
    }

    if (files != null) {
      for (final file in files) {
        try {
          final message = await sendMessage(
            conversationId: conversationId,
            file: file,
            messageType: messageType,
            content: messageType == 'image' ? '📷 Image' : '📎 File',
          );
          sentMessages.add(message);
        } catch (e) {
          debugPrint('Failed to send file: $e');
        }
      }
    }

    return sentMessages;
  }

  Future<void> markMessageAsRead(int messageId) async {
    try {
      await _apiService.markMessageAsRead(messageId);
      final messages = currentMessages.value.map((m) {
        if (m.id == messageId) {
          return ChatMessage(
            id: m.id,
            conversationId: m.conversationId,
            senderId: m.senderId,
            senderName: m.senderName,
            senderType: m.senderType,
            receiverId: m.receiverId,
            messageType: m.messageType,
            content: m.content,
            isRead: true,
            readAt: DateTime.now().toIso8601String(),
            isDelivered: m.isDelivered,
            deliveredAt: m.deliveredAt,
            createdAt: m.createdAt,
            file: m.file,
            voiceDuration: m.voiceDuration,
          );
        }
        return m;
      }).toList();
      currentMessages.value = messages;
    } catch (e) {
      debugPrint('Failed to mark message as read: $e');
    }
  }

  Future<void> markConversationAsRead(int conversationId) async {
    try {
      await _apiService.markConversationAsRead(conversationId);
      await loadConversations();
      await loadUnreadCount();
      // ✅ Update badge after unread count changes
      BadgeHelper.updateBadge(totalUnreadCount.value);
    } catch (e) {
      debugPrint('Failed to mark conversation as read: $e');
    }
  }

  Future<void> deleteMessage(int messageId) async {
    try {
      await _apiService.deleteMessage(messageId);
      await loadConversations();
      currentMessages.value = currentMessages.value
          .where((m) => m.id != messageId)
          .toList();
    } catch (e) {
      debugPrint('Failed to delete message: $e');
    }
  }

  Future<void> addReaction(int messageId, String reaction) async {
    try {
      await _apiService.addReaction(messageId, reaction);
    } catch (e) {
      debugPrint('Failed to add reaction: $e');
    }
  }

  Future<void> removeReaction(int messageId) async {
    try {
      await _apiService.removeReaction(messageId);
    } catch (e) {
      debugPrint('Failed to remove reaction: $e');
    }
  }

  // ============================================
  // FILE OPERATIONS
  // ============================================

  /// Download a file from a message to a local path.
  Future<String?> downloadFile(int messageId, String savePath) async {
    try {
      return await _apiService.downloadChatFileToPath(messageId, savePath);
    } catch (e) {
      debugPrint('Failed to download file: $e');
      return null;
    }
  }

  /// Download file using message URL from local messages (alternate method)
  Future<String?> downloadFileFromUrl(int messageId, String savePath) async {
    try {
      final message = currentMessages.value.firstWhere((m) => m.id == messageId);
      if (message.file?.url == null) return null;

      final url = message.file!.url!;
      final dio = Dio();
      await dio.download(url, savePath);
      return savePath;
    } catch (e) {
      debugPrint('Failed to download file: $e');
      return null;
    }
  }

  /// Get file info (metadata)
  Future<Map<String, dynamic>?> getFileInfo(int messageId) async {
    try {
      final response = await _apiService.getFileInfo(messageId);
      if (response.success) {
        return response.data;
      }
      return null;
    } catch (e) {
      debugPrint('Failed to get file info: $e');
      return null;
    }
  }

  /// Delete file from message
  Future<bool> deleteFile(int messageId) async {
    try {
      final response = await _apiService.deleteFile(messageId);
      if (response.success) {
        // Update local message
        final messages = currentMessages.value.map((m) {
          if (m.id == messageId) {
            return ChatMessage(
              id: m.id,
              conversationId: m.conversationId,
              senderId: m.senderId,
              senderName: m.senderName,
              senderType: m.senderType,
              receiverId: m.receiverId,
              messageType: 'text',
              content: m.content ?? 'File removed',
              isRead: m.isRead,
              readAt: m.readAt,
              isDelivered: m.isDelivered,
              deliveredAt: m.deliveredAt,
              createdAt: m.createdAt,
              file: null,
              voiceDuration: m.voiceDuration,
            );
          }
          return m;
        }).toList();
        currentMessages.value = messages;
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Failed to delete file: $e');
      return false;
    }
  }

  /// Upload a file separately (for composing messages)
  Future<Map<String, dynamic>?> uploadFile(File file) async {
    try {
      final response = await _apiService.uploadChatFile(file);
      if (response.success) {
        return response.data;
      }
      return null;
    } catch (e) {
      debugPrint('Failed to upload file: $e');
      return null;
    }
  }

  /// Delete entire conversation
  Future<bool> deleteConversation(int conversationId) async {
    try {
      final response = await _apiService.deleteConversation(conversationId);
      if (response.success) {
        conversations.value = conversations.value
            .where((conv) => conv.id != conversationId)
            .toList();
        final currentConvId = currentMessages.value.isNotEmpty
            ? currentMessages.value.first.conversationId
            : null;
        if (currentConvId == conversationId) {
          currentMessages.value = [];
        }
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Failed to delete conversation: $e');
      return false;
    }
  }

  // ============================================
  // TYPING INDICATOR
  // ============================================

  Future<void> sendTypingStatus({
    required int conversationId,
    required bool typing,
  }) async {
    try {
      await _apiService.sendTypingStatus(
        conversationId: conversationId,
        isTyping: typing,
      );
      _webSocketService?.sendTypingStatus(conversationId, typing);
    } catch (e) {
      debugPrint('Failed to send typing status: $e');
    }
  }

  // ============================================
  // UNREAD COUNTS
  // ============================================

  Future<void> loadUnreadCount() async {
    try {
      final response = await _apiService.getUnreadCount();
      if (response.success) {
        totalUnreadCount.value = response.data?['total_unread'] ?? 0;
        // ✅ Update badge after loading unread count
        BadgeHelper.updateBadge(totalUnreadCount.value);
      }
    } catch (e) {
      debugPrint('Failed to load unread count: $e');
    }
  }

  int getUnreadCountForConversation(int conversationId) {
    final conv = getConversationById(conversationId);
    return conv?.unreadCount ?? 0;
  }

  // ============================================
  // WEBSOCKET HANDLERS
  // ============================================

  void _handleNewMessage(Map<String, dynamic> data) {
    try {
      final message = ChatMessage.fromJson(data);
      final currentIds = currentMessages.value.map((m) => m.id).toList();
      if (!currentIds.contains(message.id)) {
        currentMessages.value = [...currentMessages.value, message];
      }
      loadConversations();
      loadUnreadCount().then((_) {
        // ✅ Ensure badge is updated after unread count is refreshed
        BadgeHelper.updateBadge(totalUnreadCount.value);
      });
    } catch (e) {
      debugPrint('Failed to handle new message: $e');
    }
  }

  void _handleMessageRead(Map<String, dynamic> data) {
    try {
      final messageId = data['message_id']?.toString();
      if (messageId == null) return;

      final messages = currentMessages.value.map((m) {
        if (m.id.toString() == messageId) {
          return ChatMessage(
            id: m.id,
            conversationId: m.conversationId,
            senderId: m.senderId,
            senderName: m.senderName,
            senderType: m.senderType,
            receiverId: m.receiverId,
            messageType: m.messageType,
            content: m.content,
            isRead: true,
            readAt: DateTime.now().toIso8601String(),
            isDelivered: m.isDelivered,
            deliveredAt: m.deliveredAt,
            createdAt: m.createdAt,
            file: m.file,
            voiceDuration: m.voiceDuration,
          );
        }
        return m;
      }).toList();
      currentMessages.value = messages;
    } catch (e) {
      debugPrint('Failed to handle message read: $e');
    }
  }

  void _handleUserTyping(Map<String, dynamic> data) {
    try {
      final userId = data['user_id']?.toString();
      final typing = data['is_typing'] == true;
      if (userId != null && userId != _currentUser?.id.toString()) {
        isTyping.value = typing;
      }
    } catch (e) {
      debugPrint('Failed to handle typing: $e');
    }
  }

  void _handleConnected() {
    _isConnected.value = true;
    debugPrint('WebSocket connected');
  }

  void _handleDisconnected() {
    _isConnected.value = false;
    debugPrint('WebSocket disconnected');
  }

  // ============================================
  // WEBSOCKET MANAGEMENT
  // ============================================

  void connectWebSocket() {
    _webSocketService?.connect();
  }

  void disconnectWebSocket() {
    _webSocketService?.disconnect();
  }

  void subscribeToUser(int userId) {
    _webSocketService?.subscribeToUser(userId);
  }

  void unsubscribeFromUser(int userId) {
    _webSocketService?.unsubscribeFromUser(userId);
  }

  Future<void> reconnectWebSocket() async {
    disconnectWebSocket();
    await Future.delayed(const Duration(seconds: 1));
    connectWebSocket();
  }

  // ============================================
  // UTILITY METHODS
  // ============================================

  void clearMessages() {
    currentMessages.value = [];
  }

  ChatUser? getOtherParty(int conversationId) {
    final conv = getConversationById(conversationId);
    return conv?.otherParty;
  }

  bool conversationExists(int conversationId) {
    return getConversationById(conversationId) != null;
  }

  // ============================================
  // CLEANUP
  // ============================================

  void dispose() {
    conversations.dispose();
    currentMessages.dispose();
    totalUnreadCount.dispose();
    isTyping.dispose();
    _isConnected.dispose();
    disconnectWebSocket();
  }
}