// lib/providers/chat_provider.dart

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import '../models/chat_conversation.dart';
import '../models/chat_message.dart';
import '../models/chat_user.dart';
import '../services/chat_service.dart';

class ChatProvider extends ChangeNotifier {
  final ChatService _service = ChatService();

  bool _disposed = false;
  bool _notifyScheduled = false;
  String? _initKey;

  bool isLoading = false;
  bool isLoadingMessages = false;
  String? _error;

  // ── Getters ────────────────────────────────────────────
  List<ChatConversation> get conversations => _service.conversations.value;
  List<ChatMessage> get messages => _service.messages.value;
  List<ChatMessage> get pins => _service.pins.value;

  /// Alias kept for older screens.
  List<ChatMessage> get currentMessages => messages;

  int get totalUnread => _service.totalUnread.value;
  bool get hasMoreOlder => _service.hasMoreOlder;
  ChatUser? get currentUser => _service.currentUser;
  Map<String, String> get authHeaders => _service.authHeaders;
  ValueListenable<bool> get peerTyping => _service.peerTyping;
  String? get error => _error ?? _service.listError;

  ChatProvider() {
    _service.conversations.addListener(_safeNotify);
    _service.messages.addListener(_safeNotify);
    _service.pins.addListener(_safeNotify);
    _service.totalUnread.addListener(_safeNotify);
  }

  /// Never notifies while the widget tree is building or after dispose.
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

  // ── Setup ──────────────────────────────────────────────
  /// Safe to call many times: repeat calls for the same user are ignored.
  void initialize({required String token, required ChatUser currentUser}) {
    final key = '${currentUser.id}:$token';
    if (_initKey == key) return;
    _initKey = key;
    _service.initialize(token: token, currentUser: currentUser);
  }

  /// Compatibility: older code called these. Chat now uses polling.
  void connectWebSocket() {}

  /// Call on logout: stops polling and clears all chat data.
  void disconnectWebSocket() {
    _service.reset();
    _initKey = null;
  }

  // ── Conversations ──────────────────────────────────────
  Future<void> refreshConversations() async {
    isLoading = true;
    _error = null;
    _safeNotify();
    try {
      await _service.loadConversations();
    } finally {
      isLoading = false;
      _safeNotify();
    }
  }

  Future<ChatConversation> createConversation({
    required int customerId,
    required int fundiId,
  }) =>
      _service.createConversation(customerId: customerId, fundiId: fundiId);

  Future<void> markConversationAsRead(int conversationId) =>
      _service.markConversationAsRead(conversationId);

  // ── Open chat ──────────────────────────────────────────
  Future<void> openConversation(int id) async {
    isLoadingMessages = true;
    _safeNotify();
    try {
      await _service.openConversation(id);
    } finally {
      isLoadingMessages = false;
      _safeNotify();
    }
  }

  void closeConversation() => _service.closeConversation();

  Future<void> loadOlder() => _service.loadOlder();

  /// Loads history up to [messageId] so the screen can jump to it.
  Future<bool> loadUntil(int messageId) => _service.loadUntil(messageId);

  // ── Send / retry / delete / view ───────────────────────
  /// Optimistic: returns immediately, the bubble shows its own sending state.
  void send({
    required int conversationId,
    String? content,
    File? file,
    ReplyRef? replyTo,
  }) =>
      _service.send(
        conversationId: conversationId,
        content: content,
        file: file,
        replyTo: replyTo,
      );

  void retry(int tempId) => _service.retry(tempId);
  void discardPending(int tempId) => _service.discardPending(tempId);
  Future<void> sendTyping(int conversationId) =>
      _service.sendTyping(conversationId);

  Future<void> deleteMessage(int messageId) => _service.deleteMessage(messageId);

  Future<File> fetchForViewing(ChatMessage message) =>
      _service.fetchForViewing(message);

  // ── WhatsApp-style actions ─────────────────────────────
  Future<void> react(int messageId, String? emoji) =>
      _service.react(messageId, emoji);

  Future<bool> toggleStar(int messageId) => _service.toggleStar(messageId);

  Future<bool> togglePin(int messageId) => _service.togglePin(messageId);

  Future<void> forward({
    required List<int> messageIds,
    required List<int> conversationIds,
  }) =>
      _service.forward(messageIds: messageIds, conversationIds: conversationIds);

  Future<MessageInfo> fetchInfo(int messageId) => _service.fetchInfo(messageId);

  Future<List<ChatMessage>> fetchStarred(int conversationId) =>
      _service.fetchStarred(conversationId);

  @override
  void dispose() {
    _disposed = true;
    _service.conversations.removeListener(_safeNotify);
    _service.messages.removeListener(_safeNotify);
    _service.pins.removeListener(_safeNotify);
    _service.totalUnread.removeListener(_safeNotify);
    _service.dispose();
    super.dispose();
  }
}
