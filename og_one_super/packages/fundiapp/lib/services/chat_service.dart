// lib/services/chat_service.dart
import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../models/chat_conversation.dart';
import '../models/chat_message.dart';
import '../models/chat_user.dart';
import 'api_service.dart';
import 'storage_service.dart';

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  final ApiService _api = ApiService();

  // ── State ──────────────────────────────────────────────────────────────
  final ValueNotifier<List<ChatConversation>> conversations = ValueNotifier([]);
  final ValueNotifier<List<ChatMessage>> messages = ValueNotifier([]);
  final ValueNotifier<int> totalUnread = ValueNotifier(0);
  final ValueNotifier<double?> uploadProgress = ValueNotifier(null);

  ChatUser? currentUser;
  String? _token;
  int? _openConversationId;
  bool _hasMoreOlder = true;
  String? listError;

  Timer? _pollTimer;
  bool _isSending = false; // prevents concurrent sends

  // ── Getters ────────────────────────────────────────────────────────────
  bool get hasMoreOlder => _hasMoreOlder;
  List<ChatMessage> get currentMessages => messages.value;

  Map<String, String> get authHeaders {
    final t = _token;
    return t == null || t.isEmpty
        ? {'Accept': 'application/json'}
        : {
      'Authorization': 'Bearer $t',
      'Accept': 'application/json',
    };
  }

  // ── Init / Reset ───────────────────────────────────────────────────────
  void initialize({required String token, required ChatUser currentUser}) {
    _token = token;
    this.currentUser = currentUser;
  }

  void reset() {
    _stopPolling();
    conversations.value = [];
    messages.value = [];
    totalUnread.value = 0;
    uploadProgress.value = null;
    _openConversationId = null;
    currentUser = null;
    _token = null;
    listError = null;
    _hasMoreOlder = true;
    _isSending = false;
  }

  // ── Conversations ──────────────────────────────────────────────────────
  Future<void> loadConversations() async {
    listError = null;
    try {
      final res = await _api.getConversations();
      if (!res.success) {
        listError = res.message;
        return;
      }

      final raw = res.data;
      final List list = raw is List
          ? raw
          : (raw is Map && raw['data'] is List)
          ? raw['data']
          : [];

      final loaded = list
          .map((e) => ChatConversation.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      conversations.value = loaded;
      totalUnread.value = loaded.fold(0, (sum, c) => sum + c.unreadCount);
    } catch (e) {
      listError = e.toString();
      debugPrint('loadConversations error: $e');
    }
  }

  Future<ChatConversation> createConversation({
    required int customerId,
    required int fundiId,
  }) async {
    final res = await _api.getOrCreateConversation(
      customerId: customerId,
      fundiId: fundiId,
    );
    if (!res.success) throw Exception(res.message);

    final conv = ChatConversation.fromJson(Map<String, dynamic>.from(res.data));
    await loadConversations();
    return conv;
  }

  Future<void> markConversationAsRead(int conversationId) async {
    try {
      await _api.markConversationAsRead(conversationId);

      conversations.value = conversations.value.map((c) {
        if (c.id == conversationId) return c.copyWith(unreadCount: 0);
        return c;
      }).toList();

      totalUnread.value =
          conversations.value.fold(0, (sum, c) => sum + c.unreadCount);
    } catch (e) {
      debugPrint('markConversationAsRead error: $e');
    }
  }

  Future<bool> deleteConversation(int conversationId) async {
    try {
      final res = await _api.deleteConversation(conversationId);
      if (!res.success) return false;

      conversations.value =
          conversations.value.where((c) => c.id != conversationId).toList();
      totalUnread.value =
          conversations.value.fold(0, (sum, c) => sum + c.unreadCount);

      if (_openConversationId == conversationId) {
        closeConversation();
      }
      return true;
    } catch (e) {
      debugPrint('deleteConversation error: $e');
      return false;
    }
  }

  // ── Open / Close conversation ──────────────────────────────────────────
  Future<void> openConversation(int conversationId) async {
    _openConversationId = conversationId;
    _hasMoreOlder = true;
    messages.value = [];
    await _loadLatest(conversationId);
    _startPolling(conversationId);
  }

  void closeConversation() {
    _stopPolling();
    _openConversationId = null;
    messages.value = [];
  }

  Future<void> _loadLatest(int conversationId) async {
    final res = await _api.getMessages(
      conversationId: conversationId,
      limit: 40,
    );
    if (!res.success) return;

    final data = res.data is Map ? res.data as Map : {};
    final list = (data['messages'] as List? ?? [])
        .map((e) => ChatMessage.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    _hasMoreOlder = data['has_more'] == true;
    messages.value = list;
  }

  Future<void> loadOlder() async {
    if (!_hasMoreOlder || messages.value.isEmpty || _openConversationId == null) {
      return;
    }

    final oldestId = messages.value.first.id;
    final res = await _api.getMessages(
      conversationId: _openConversationId!,
      limit: 30,
      beforeId: oldestId,
    );
    if (!res.success) return;

    final data = res.data is Map ? res.data as Map : {};
    final older = (data['messages'] as List? ?? [])
        .map((e) => ChatMessage.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    _hasMoreOlder = data['has_more'] == true;
    if (older.isEmpty) return;

    messages.value = [...older, ...messages.value];
  }

  // ── Send ───────────────────────────────────────────────────────────────
  Future<ChatMessage> sendMessage({
    required int conversationId,
    String? content,
    File? file,
  }) async {
    // Prevent concurrent / double sends
    if (_isSending) {
      throw Exception('Already sending a message');
    }
    _isSending = true;
    uploadProgress.value = file != null ? 0.0 : null;

    try {
      final res = await _api.sendMessage(
        conversationId: conversationId,
        content: content,
        filePath: file?.path,
        onSendProgress: file == null
            ? null
            : (sent, total) {
          if (total > 0) {
            uploadProgress.value = sent / total;
          }
        },
      );

      uploadProgress.value = null;

      if (!res.success) throw Exception(res.message);

      final raw = res.data is Map ? (res.data['message'] ?? res.data) : null;
      if (raw == null) throw Exception('Invalid response from server');

      final msg = ChatMessage.fromJson(Map<String, dynamic>.from(raw));

      // Safe append (deduplicated)
      if (_openConversationId == conversationId) {
        _appendMessages([msg]);
      }

      await loadConversations();
      return msg;
    } catch (e) {
      uploadProgress.value = null;
      rethrow;
    } finally {
      _isSending = false;
    }
  }

  Future<void> deleteMessage(int messageId) async {
    final res = await _api.deleteMessage(messageId);
    if (!res.success) throw Exception(res.message);

    messages.value = messages.value.where((m) => m.id != messageId).toList();
    await loadConversations();
  }

  // ── Private file fetch ─────────────────────────────────────────────────
  Future<File> fetchForViewing(ChatMessage message) async {
    final url = message.file?.url;
    if (url == null || url.isEmpty) {
      throw Exception('No file URL');
    }

    final dir = await getTemporaryDirectory();
    final ext = message.file?.extension ?? 'bin';
    final local = File('${dir.path}/chat_${message.id}.$ext');

    if (await local.exists()) return local;

    final token = await StorageService.getToken();
    final dio = Dio();

    await dio.download(
      url,
      local.path,
      options: Options(
        headers: {
          if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
          'Accept': '*/*',
        },
        responseType: ResponseType.bytes,
      ),
    );

    return local;
  }

  // ── Polling ────────────────────────────────────────────────────────────
  void _startPolling(int conversationId) {
    _stopPolling();
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
      if (_openConversationId != conversationId) return;
      await _pollNewMessages(conversationId);
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _pollNewMessages(int conversationId) async {
    if (messages.value.isEmpty) return;

    final lastId = messages.value.last.id;
    final res = await _api.getMessages(
      conversationId: conversationId,
      afterId: lastId,
    );
    if (!res.success) return;

    final data = res.data is Map ? res.data as Map : {};
    final newer = (data['messages'] as List? ?? [])
        .map((e) => ChatMessage.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    if (newer.isEmpty) return;

    // Critical: deduplicate so the same message is never shown twice
    _appendMessages(newer);
    await loadConversations();
  }

  /// Safely append messages without duplicates
  void _appendMessages(List<ChatMessage> incoming) {
    if (incoming.isEmpty) return;

    final existingIds = messages.value.map((m) => m.id).toSet();
    final unique = incoming.where((m) => !existingIds.contains(m.id)).toList();

    if (unique.isEmpty) return;

    messages.value = [...messages.value, ...unique];
  }

  // ── Cleanup ────────────────────────────────────────────────────────────
  void dispose() {
    _stopPolling();
  }
}