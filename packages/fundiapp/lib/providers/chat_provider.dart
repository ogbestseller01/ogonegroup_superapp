// lib/providers/chat_provider.dart

import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/chat_conversation.dart';
import '../models/chat_message.dart';
import '../models/chat_user.dart';
import '../services/chat_service.dart';

class ChatProvider extends ChangeNotifier {
  final ChatService _chatService = ChatService();

  // ── State exposed to UI ───────────────────────────────────────────────────
  List<ChatConversation> get conversations => _chatService.conversations.value;
  List<ChatMessage> get currentMessages => _chatService.currentMessages.value;
  int get totalUnread => _chatService.totalUnreadCount.value;
  bool get isTyping => _chatService.isTyping.value;
  ChatUser? get currentUser => _chatService.currentUser;
  bool get isConnected => _chatService.isConnected;

  bool isLoading = false;

  ChatProvider() {
    _chatService.conversations.addListener(_notify);
    _chatService.currentMessages.addListener(_notify);
    _chatService.totalUnreadCount.addListener(_notify);
    _chatService.isTyping.addListener(_notify);
  }

  void _notify() => notifyListeners();

  // ── Init ──────────────────────────────────────────────────────────────────
  void initialize({
    required String token,
    required ChatUser currentUser,
  }) {
    _chatService.initialize(token: token, currentUser: currentUser);
    _chatService.connectWebSocket();
  }

  // ── Conversations ─────────────────────────────────────────────────────────
  Future<void> refreshConversations() async {
    isLoading = true;
    notifyListeners();
    try {
      await _chatService.loadConversations();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<ChatConversation> getOrCreateConversation({
    required int customerId,
    required int fundiId,
  }) {
    return _chatService.getOrCreateConversation(
      customerId: customerId,
      fundiId: fundiId,
    );
  }

  // ── Messages ──────────────────────────────────────────────────────────────
  Future<List<ChatMessage>> getMessages({
    required int conversationId,
    int limit = 50,
    int offset = 0,
  }) {
    return _chatService.getMessages(
      conversationId: conversationId,
      limit: limit,
      offset: offset,
    );
  }

  Future<ChatMessage> sendMessage({
    required int conversationId,
    String? content,
    File? file,
    String messageType = 'text',
    int? voiceDuration,
  }) {
    return _chatService.sendMessage(
      conversationId: conversationId,
      content: content,
      file: file,
      messageType: messageType,
      voiceDuration: voiceDuration,
    );
  }

  Future<void> markConversationAsRead(int conversationId) {
    return _chatService.markConversationAsRead(conversationId);
  }

  Future<void> deleteMessage(int messageId) {
    return _chatService.deleteMessage(messageId);
  }

  Future<void> addReaction(int messageId, String reaction) {
    return _chatService.addReaction(messageId, reaction);
  }

  // ── Typing ────────────────────────────────────────────────────────────────
  Future<void> sendTypingStatus({
    required int conversationId,
    required bool typing,
  }) {
    return _chatService.sendTypingStatus(
      conversationId: conversationId,
      typing: typing,
    );
  }

  // ── WebSocket subscriptions ───────────────────────────────────────────────
  void subscribeToUser(int userId) {
    _chatService.subscribeToUser(userId);
  }

  void unsubscribeFromUser(int userId) {
    _chatService.unsubscribeFromUser(userId);
  }

  // ── File operations ───────────────────────────────────────────────────────
  Future<String?> downloadFile(int messageId, String savePath) {
    return _chatService.downloadFile(messageId, savePath);
  }

  Future<Map<String, dynamic>?> getFileInfo(int messageId) {
    return _chatService.getFileInfo(messageId);
  }

  Future<bool> deleteFile(int messageId) {
    return _chatService.deleteFile(messageId);
  }

  Future<bool> deleteConversation(int conversationId) {
    return _chatService.deleteConversation(conversationId);
  }

  // ── Helpers for UI ────────────────────────────────────────────────────────
  /// Use this for bubble ownership: message.isFromMe(currentUserId)
  int get currentUserId => currentUser?.id ?? 0;

  @override
  void dispose() {
    _chatService.conversations.removeListener(_notify);
    _chatService.currentMessages.removeListener(_notify);
    _chatService.totalUnreadCount.removeListener(_notify);
    _chatService.isTyping.removeListener(_notify);
    _chatService.dispose();
    super.dispose();
  }
}