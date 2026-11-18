// lib/providers/chat_provider.dart

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import '../models/chat_conversation.dart';
import '../models/chat_message.dart';
import '../models/chat_update.dart';
import '../models/chat_user.dart';
import '../services/chat_service.dart';

class ChatProvider extends ChangeNotifier {
  final ChatService _service = ChatService();

  /// How often the conversation list / unread badge is checked.
  static const Duration _pollInterval = Duration(seconds: 3);

  bool _disposed = false;
  bool _notifyScheduled = false;
  String? _initKey;

  Timer? _pollTimer;
  bool _polling = false; // guards overlapping poll ticks
  int? _openConversationId; // while a chat is open, its own loop is in charge

  bool isLoading = false;
  bool isLoadingMessages = false;
  String? _error;

  ChatProvider() {
    _service.conversations.addListener(_safeNotify);
    _service.messages.addListener(_safeNotify);
    _service.pins.addListener(_safeNotify);
    _service.totalUnread.addListener(_safeNotify);
  }

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
  bool get isPolling => _pollTimer?.isActive ?? false;

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
    stopPolling();
    _openConversationId = null;
    _service.reset();
    _initKey = null;
  }

  // ── Auto check for new chats (every few seconds) ───────

  /// Safe to call repeatedly; only one timer ever runs. Does nothing until
  /// [initialize] has been called for the current user.
  void startPolling() {
    if (_disposed || _initKey == null || isPolling) return;
    _pollTimer = Timer.periodic(_pollInterval, (_) => _pollTick());
    debugPrint('⏱️ Chat polling started');
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _pollTick() async {
    // Skip when: a check is still running, logged out, or a chat is open
    // (an open chat keeps itself up to date).
    if (_polling || _disposed || _initKey == null) return;
    if (_openConversationId != null) return;

    _polling = true;
    try {
      await _service.loadConversations();
    } catch (e) {
      debugPrint('❌ Chat poll error: $e');
    } finally {
      _polling = false;
    }
  }

  // ── Conversations ──────────────────────────────────────

  /// [silent] = true updates the list and unread badge without toggling
  /// [isLoading], so no spinner appears (used by auto refresh).
  Future<void> refreshConversations({bool silent = false}) async {
    if (!silent) {
      isLoading = true;
      _error = null;
      _safeNotify();
    }
    try {
      await _service.loadConversations();
    } finally {
      if (!silent) {
        isLoading = false;
        _safeNotify();
      }
    }
  }

  Future<ChatConversation> createConversation({
    required int customerId,
    required int fundiId,
  }) =>
      _service.createConversation(customerId: customerId, fundiId: fundiId);

  Future<void> markConversationAsRead(int conversationId) =>
      _service.markConversationAsRead(conversationId);

  // ── Tabs / filters ─────────────────────────────────────
  List<ChatConversation> get activeChats =>
      conversations.where((c) => !c.isArchived).toList();

  List<ChatConversation> get archivedChats =>
      conversations.where((c) => c.isArchived).toList();

  int get unreadChats => activeChats.where((c) => c.unreadCount > 0).length;

  bool get hasNewUpdates => conversations.any((c) => c.hasNewPost);

  Future<void> setConversationState(
      int id, {
        bool? pinned,
        bool? archived,
      }) =>
      _service.setConversationState(id, pinned: pinned, archived: archived);

  Future<bool> deleteConversation(int id) => _service.deleteConversation(id);

  // ── Updates / status ───────────────────────────────────
  Future<void> markStatusSeen(int technicianId) =>
      _service.markStatusSeen(technicianId);

  Future<List<ChatUpdate>> fetchUpdates() => _service.fetchUpdates();

  // ── Open chat ──────────────────────────────────────────
  Future<void> openConversation(int id) async {
    _openConversationId = id;
    isLoadingMessages = true;
    _safeNotify();
    try {
      await _service.openConversation(id);
    } finally {
      isLoadingMessages = false;
      _safeNotify();
    }
  }

  void closeConversation() {
    _openConversationId = null;
    _service.closeConversation();
    // Catch anything that arrived while the chat was open.
    unawaited(refreshConversations(silent: true));
  }

  Future<void> loadOlder() => _service.loadOlder();

  /// Loads history up to [messageId] so the screen can jump to it.
  Future<bool> loadUntil(int messageId) => _service.loadUntil(messageId);

  // ── Media ──────────────────────────────────────────────
  Future<(List<ChatMessage>, bool)> fetchMedia(
      int conversationId,
      String tab, {
        int? beforeId,
      }) =>
      _service.fetchMedia(conversationId, tab, beforeId: beforeId);

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

  Future<void> deleteMessage(int messageId) =>
      _service.deleteMessage(messageId);

  /// Returns the ids really deleted. [forEveryone] = false => "delete for me".
  Future<List<int>> deleteMessages(
      List<int> ids, {
        required bool forEveryone,
      }) =>
      _service.deleteMessages(ids, forEveryone: forEveryone);

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
    _pollTimer?.cancel();
    _service.conversations.removeListener(_safeNotify);
    _service.messages.removeListener(_safeNotify);
    _service.pins.removeListener(_safeNotify);
    _service.totalUnread.removeListener(_safeNotify);
    _service.dispose();
    super.dispose();
  }
}