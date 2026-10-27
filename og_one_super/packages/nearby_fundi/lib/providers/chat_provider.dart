// lib/providers/chat_provider.dart

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import '../models/chat_conversation.dart';
import '../models/chat_message.dart';
import '../models/chat_user.dart';
import '../services/chat_service.dart';

class ChatProvider extends ChangeNotifier {
  final ChatService _chatService = ChatService();

  bool _disposed = false;
  bool _notifyScheduled = false;

  /// Remembers which user/token is already initialized, so calling
  /// initialize() again (HomeScreen + ChatListScreen) does nothing.
  String? _initKey;

  // ============================================================
  // GETTERS
  // ============================================================

  List<ChatConversation> get conversations =>
      _chatService.conversations.value;

  List<ChatMessage> get currentMessages =>
      _chatService.currentMessages.value;

  int get totalUnread => _chatService.totalUnreadCount.value;

  bool get isTyping => _chatService.isTyping.value;

  bool get isConnected => _chatService.isConnected.value;

  ChatUser? get currentUser => _chatService.currentUser;

  bool isLoading = false;

  String? _error;

  String? get error => _error;

  // ============================================================
  // CONSTRUCTOR
  // ============================================================

  ChatProvider() {
    _chatService.conversations.addListener(_safeNotify);
    _chatService.currentMessages.addListener(_safeNotify);
    _chatService.totalUnreadCount.addListener(_safeNotify);
    _chatService.isTyping.addListener(_safeNotify);
    _chatService.isConnected.addListener(_safeNotify);
  }

  // ============================================================
  // SAFE NOTIFY
  // ============================================================

  /// Never notifies while the widget tree is building or after dispose.
  /// If a frame is in progress, the notification is sent after the frame.
  void _safeNotify() {
    if (_disposed) return;

    final phase = SchedulerBinding.instance.schedulerPhase;
    final building = phase == SchedulerPhase.persistentCallbacks ||
        phase == SchedulerPhase.transientCallbacks ||
        phase == SchedulerPhase.midFrameMicrotasks;

    if (!building) {
      notifyListeners();
      return;
    }

    if (_notifyScheduled) return;
    _notifyScheduled = true;

    SchedulerBinding.instance.addPostFrameCallback((_) {
      _notifyScheduled = false;
      if (!_disposed) notifyListeners();
    });
  }

  // ============================================================
  // INITIALIZATION
  // ============================================================

  void initialize({
    required String token,
    required ChatUser currentUser,
  }) {
    final key = '${currentUser.id}:$token';
    if (_initKey == key) return; // already initialized
    _initKey = key;

    _chatService.initialize(
      token: token,
      currentUser: currentUser,
    );

    _chatService.connectWebSocket();
  }

  // ============================================================
  // CONVERSATIONS
  // ============================================================

  Future<void> refreshConversations() async {
    isLoading = true;
    _error = null;
    _safeNotify();

    try {
      await _chatService.loadConversations();
    } catch (e) {
      _error = e.toString();
    } finally {
      isLoading = false;
      _safeNotify();
    }
  }

  Future<ChatConversation> createConversation({
    required int customerId,
    required int fundiId,
  }) async {
    try {
      _error = null;

      return await _chatService.createConversation(
        customerId: customerId,
        fundiId: fundiId,
      );
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }

  // ============================================================
  // MESSAGES
  // ============================================================

  Future<List<ChatMessage>> getMessages({
    required int conversationId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      _error = null;
      isLoading = true;
      _safeNotify();

      return await _chatService.getMessages(
        conversationId: conversationId,
        limit: limit,
        offset: offset,
      );
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      isLoading = false;
      _safeNotify();
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
      _error = null;

      return await _chatService.sendMessage(
        conversationId: conversationId,
        content: content,
        file: file,
        messageType: messageType,
        voiceDuration: voiceDuration,
      );
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }

  Future<void> markConversationAsRead(int conversationId) async {
    try {
      _error = null;

      await _chatService.markConversationAsRead(conversationId);
    } catch (e) {
      _error = e.toString();
    }
  }

  Future<void> deleteMessage(int messageId) async {
    try {
      _error = null;

      await _chatService.deleteMessage(messageId);
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }

  Future<void> addReaction(
      int messageId,
      String reaction,
      ) async {
    try {
      _error = null;

      await _chatService.addReaction(
        messageId,
        reaction,
      );
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }

  // ============================================================
  // TYPING
  // ============================================================

  Future<void> sendTypingStatus({
    required int conversationId,
    required bool typing,
  }) async {
    try {
      // ChatService.sendTypingStatus() is synchronous.
      _chatService.sendTypingStatus(
        conversationId: conversationId,
        typing: typing,
      );
    } catch (e) {
      // Typing status should not interrupt the chat.
      debugPrint('Typing status error: $e');
    }
  }

  // ============================================================
  // USER SUBSCRIPTIONS
  // ============================================================

  void subscribeToUser(int userId) {
    _chatService.subscribeToUser(userId);
  }

  void unsubscribeFromUser(int userId) {
    _chatService.unsubscribeFromUser(userId);
  }

  // ============================================================
  // WEBSOCKET
  // ============================================================

  void connectWebSocket() {
    _chatService.connectWebSocket();
  }

  void disconnectWebSocket() {
    _chatService.disconnectWebSocket();
    // Allow initialize() to run again after the next login.
    _initKey = null;
  }

  // ============================================================
  // HELPERS
  // ============================================================

  bool isCurrentUserMessage(ChatMessage message) {
    return message.senderId == _chatService.currentUser?.id;
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _disposed = true;

    _chatService.conversations.removeListener(_safeNotify);
    _chatService.currentMessages.removeListener(_safeNotify);
    _chatService.totalUnreadCount.removeListener(_safeNotify);
    _chatService.isTyping.removeListener(_safeNotify);
    _chatService.isConnected.removeListener(_safeNotify);

    // dispose() returns void.
    // Do NOT await it or use its return value.
    _chatService.dispose();

    super.dispose();
  }
}