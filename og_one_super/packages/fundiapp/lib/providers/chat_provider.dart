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

  List<ChatConversation> get conversations => _service.conversations.value;
  List<ChatMessage> get messages => _service.messages.value;
  List<ChatMessage> get currentMessages => messages; // alias
  int get totalUnread => _service.totalUnread.value;
  bool get hasMoreOlder => _service.hasMoreOlder;
  ChatUser? get currentUser => _service.currentUser;
  Map<String, String> get authHeaders => _service.authHeaders;
  ValueListenable<double?> get uploadProgress => _service.uploadProgress;
  String? get error => _error ?? _service.listError;

  ChatProvider() {
    _service.conversations.addListener(_safeNotify);
    _service.messages.addListener(_safeNotify);
    _service.totalUnread.addListener(_safeNotify);
  }

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

  void initialize({required String token, required ChatUser currentUser}) {
    final key = '${currentUser.id}:$token';
    if (_initKey == key) return;
    _initKey = key;
    _service.initialize(token: token, currentUser: currentUser);
  }

  void disconnect() {
    _service.reset();
    _initKey = null;
  }

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

  /// Alias for createConversation (used by FundiRequestsScreen)
  Future<ChatConversation> getOrCreateConversation({
    required int customerId,
    required int fundiId,
  }) =>
      createConversation(customerId: customerId, fundiId: fundiId);

  Future<void> markConversationAsRead(int conversationId) =>
      _service.markConversationAsRead(conversationId);

  Future<bool> deleteConversation(int conversationId) =>
      _service.deleteConversation(conversationId);

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

  Future<ChatMessage> sendMessage({
    required int conversationId,
    String? content,
    File? file,
  }) =>
      _service.sendMessage(
        conversationId: conversationId,
        content: content,
        file: file,
      );

  Future<void> deleteMessage(int messageId) => _service.deleteMessage(messageId);

  Future<File> fetchForViewing(ChatMessage message) =>
      _service.fetchForViewing(message);

  @override
  void dispose() {
    _disposed = true;
    _service.conversations.removeListener(_safeNotify);
    _service.messages.removeListener(_safeNotify);
    _service.totalUnread.removeListener(_safeNotify);
    _service.dispose();
    super.dispose();
  }
}