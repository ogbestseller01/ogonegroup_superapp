// lib/services/chat_service.dart
import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../models/chat_conversation.dart';
import '../models/chat_message.dart';
import '../models/chat_update.dart';
import '../models/chat_user.dart';
import 'api_service.dart';
import 'storage_service.dart';

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  final ApiService _api = ApiService();

  final ValueNotifier<List<ChatConversation>> conversations = ValueNotifier([]);
  final ValueNotifier<List<ChatMessage>> messages = ValueNotifier([]);
  final ValueNotifier<List<ChatMessage>> pins = ValueNotifier([]);
  final ValueNotifier<int> totalUnread = ValueNotifier(0);
  final ValueNotifier<double?> uploadProgress = ValueNotifier(null);
  final ValueNotifier<bool> peerTyping = ValueNotifier(false);

  ChatUser? currentUser;
  String? _token;
  int? _openConversationId;
  bool _hasMoreOlder = true;
  String? listError;
  String? _lastServerTime;

  Timer? _pollTimer;
  bool _loadingOlder = false;

  bool get hasMoreOlder => _hasMoreOlder;

  Map<String, String> get authHeaders {
    final t = _token;
    return t == null || t.isEmpty
        ? {'Accept': 'application/json'}
        : {
      'Authorization': 'Bearer $t',
      'Accept': 'application/json',
    };
  }

  void initialize({required String token, required ChatUser currentUser}) {
    _token = token;
    this.currentUser = currentUser;
  }

  void reset() {
    _stopPolling();
    conversations.value = [];
    messages.value = [];
    pins.value = [];
    totalUnread.value = 0;
    uploadProgress.value = null;
    peerTyping.value = false;
    _openConversationId = null;
    currentUser = null;
    _token = null;
    listError = null;
    _hasMoreOlder = true;
  }

  // ── Conversations ─────────────────────────────────────
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
      totalUnread.value = loaded.fold(0, (s, c) => s + c.unreadCount);
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
        return c.id == conversationId ? c.copyWith(unreadCount: 0) : c;
      }).toList();
      totalUnread.value = conversations.value.fold(0, (s, c) => s + c.unreadCount);
    } catch (e) {
      debugPrint('markConversationAsRead error: $e');
    }
  }

  Future<bool> deleteConversation(int conversationId) async {
    try {
      final res = await _api.deleteConversation(conversationId);
      if (!res.success) return false;
      conversations.value = conversations.value.where((c) => c.id != conversationId).toList();
      totalUnread.value = conversations.value.fold(0, (s, c) => s + c.unreadCount);
      if (_openConversationId == conversationId) closeConversation();
      return true;
    } catch (e) {
      debugPrint('deleteConversation error: $e');
      return false;
    }
  }

  Future<void> setConversationState(
      int id, {
        bool? pinned,
        bool? archived,
      }) async {
    final res = await _api.setConversationState(id, pinned: pinned, archived: archived);
    if (!res.success) throw Exception(res.message);
    await loadConversations();
  }

  // ── Open/close ────────────────────────────────────────
  Future<void> openConversation(int conversationId) async {
    _openConversationId = conversationId;
    _hasMoreOlder = true;
    messages.value = [];
    pins.value = [];
    await _loadLatest(conversationId);
    _startPolling(conversationId);
  }

  void closeConversation() {
    _stopPolling();
    _openConversationId = null;
    messages.value = [];
    pins.value = [];
    peerTyping.value = false;
  }

  Future<void> _loadLatest(int conversationId) async {
    final res = await _api.getMessages(conversationId: conversationId, limit: 40);
    if (!res.success) return;
    final data = res.data is Map ? res.data as Map : {};
    final list = (data['messages'] as List? ?? [])
        .map((e) => ChatMessage.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    _hasMoreOlder = data['has_more'] == true;
    messages.value = list;
    pins.value = (data['pins'] as List? ?? [])
        .map((e) => ChatMessage.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    peerTyping.value = data['peer_typing'] == true;
  }

  Future<void> loadOlder() async {
    if (_loadingOlder || !_hasMoreOlder || messages.value.isEmpty || _openConversationId == null) {
      return;
    }
    _loadingOlder = true;
    try {
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
    } finally {
      _loadingOlder = false;
    }
  }

  /// Loads history backwards until [messageId] is in memory. Used by "jump to reply".
  Future<bool> loadUntil(int messageId) async {
    if (_openConversationId == null) return false;
    if (messages.value.any((m) => m.id == messageId)) return true;

    for (var i = 0; i < 10; i++) {
      if (messages.value.isEmpty || !_hasMoreOlder) return false;
      final oldestId = messages.value.first.id;
      final res = await _api.getMessages(
        conversationId: _openConversationId!,
        limit: 100,
        beforeId: oldestId,
        untilId: messageId,
      );
      if (!res.success) return false;
      final data = res.data is Map ? res.data as Map : {};
      final older = (data['messages'] as List? ?? [])
          .map((e) => ChatMessage.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      _hasMoreOlder = data['has_more'] == true;
      if (older.isEmpty) break;
      messages.value = [...older, ...messages.value];
      if (messages.value.any((m) => m.id == messageId)) return true;
    }
    return messages.value.any((m) => m.id == messageId);
  }

  // ── Send ──────────────────────────────────────────────
  void send({
    required int conversationId,
    String? content,
    File? file,
    ReplyRef? replyTo,
  }) {
    // Optimistic: push a pending bubble, then upload in the background.
    final me = currentUser;
    if (me == null) return;
    final tempId = -DateTime.now().microsecondsSinceEpoch;
    final pending = ChatMessage.pending(
      id: tempId,
      conversationId: conversationId,
      senderId: me.id,
      senderName: me.name,
      content: content,
      file: file == null
          ? null
          : MessageFile(
        url: '',
        name: file.path.split(Platform.pathSeparator).last,
        ext: file.path.split('.').last.toLowerCase(),
        localPath: file.path,
      ),
      replyTo: replyTo,
    );
    messages.value = [...messages.value, pending];

    Future(() async {
      try {
        await _sendInternal(
          tempId: tempId,
          conversationId: conversationId,
          content: content,
          file: file,
          replyTo: replyTo,
        );
      } catch (_) {}
    });
  }

  Future<void> _sendInternal({
    required int tempId,
    required int conversationId,
    String? content,
    File? file,
    ReplyRef? replyTo,
  }) async {
    uploadProgress.value = file != null ? 0.0 : null;
    try {
      final res = await _api.sendMessage(
        conversationId: conversationId,
        content: content,
        filePath: file?.path,
        replyToId: replyTo?.id,
        onSendProgress: file == null
            ? null
            : (sent, total) {
          if (total > 0) uploadProgress.value = sent / total;
        },
      );
      uploadProgress.value = null;
      if (!res.success) throw Exception(res.message);

      final raw = res.data is Map ? (res.data['message'] ?? res.data) : null;
      if (raw == null) throw Exception('Invalid response');
      final msg = ChatMessage.fromJson(Map<String, dynamic>.from(raw));

      // Replace the pending bubble
      messages.value = messages.value
          .where((m) => m.id != tempId)
          .toList()
        ..add(msg);

      await loadConversations();
    } catch (e) {
      uploadProgress.value = null;
      // Mark as failed
      messages.value = messages.value.map((m) {
        if (m.id == tempId) {
          return m.copyWith(sendState: SendState.failed, sendError: '$e');
        }
        return m;
      }).toList();
      rethrow;
    }
  }

  void retry(int tempId) {
    final failed = messages.value.firstWhere((m) => m.id == tempId);
    final reply = failed.replyTo;
    final file = failed.file?.localPath != null ? File(failed.file!.localPath!) : null;

    messages.value = messages.value.where((m) => m.id != tempId).toList();

    Future(() async {
      try {
        await _sendInternal(
          tempId: tempId,
          conversationId: failed.conversationId,
          content: failed.content,
          file: file,
          replyTo: reply,
        );
      } catch (_) {}
    });
  }

  void discardPending(int tempId) {
    messages.value = messages.value.where((m) => m.id != tempId).toList();
  }

  Future<void> sendTyping(int conversationId) async {
    try {
      await _api.sendTyping(conversationId);
    } catch (_) {}
  }

  // ── Delete ────────────────────────────────────────────
  Future<List<int>> deleteMessages(
      List<int> ids, {
        required bool forEveryone,
      }) async {
    final res = await _api.deleteMessages(ids, scope: forEveryone ? 'everyone' : 'me');
    if (!res.success) throw Exception(res.message);
    final data = res.data is Map ? res.data as Map : {};
    final deleted = (data['deleted'] as List? ?? []).map((e) => e as int).toList();

    if (deleted.isNotEmpty) {
      if (forEveryone) {
        messages.value = messages.value.map((m) {
          if (deleted.contains(m.id)) {
            return m.copyWith(
              content: null,
              file: null,
              isDeleted: true,
              isPinned: false,
              isStarred: false,
              reactions: const [],
              myReaction: null,
              clearMyReaction: true,
            );
          }
          return m;
        }).toList();
      } else {
        messages.value = messages.value.where((m) => !deleted.contains(m.id)).toList();
      }
      pins.value = pins.value.where((m) => !deleted.contains(m.id)).toList();
    }
    await loadConversations();
    return deleted;
  }

  // ── Fetching for view ─────────────────────────────────
  Future<File> fetchForViewing(ChatMessage message) async {
    final url = message.file?.url;
    if (url == null || url.isEmpty) throw Exception('No file URL');
    final dir = await getTemporaryDirectory();
    final ext = message.file?.ext ?? 'bin';
    final local = File('${dir.path}/chat_${message.id}.$ext');
    if (await local.exists()) return local;

    final token = await StorageService.getToken();
    final dio = Dio();
    final absolute = url.startsWith('http')
        ? url
        : '${_api.baseUrl}$url';
    await dio.download(
      absolute,
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

  // ── Media / docs / links ──────────────────────────────
  Future<(List<ChatMessage>, bool)> fetchMedia(
      int conversationId,
      String tab, {
        int? beforeId,
      }) async {
    final res = await _api.fetchMedia(conversationId, tab, beforeId: beforeId);
    if (!res.success) throw Exception(res.message);
    final data = res.data is Map ? res.data as Map : {};
    final list = (data['messages'] as List? ?? [])
        .map((e) => ChatMessage.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    return (list, data['has_more'] == true);
  }

  // ── Starred ───────────────────────────────────────────
  Future<List<ChatMessage>> fetchStarred(int conversationId) async {
    final res = await _api.fetchStarred(conversationId);
    if (!res.success) throw Exception(res.message);
    final raw = res.data;
    final List list = raw is List ? raw : (raw is Map && raw['data'] is List ? raw['data'] : []);
    return list
        .map((e) => ChatMessage.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  // ── Reactions / pins / stars ─────────────────────────
  Future<void> react(int messageId, String? emoji) async {
    final res = await _api.react(messageId, emoji);
    if (!res.success) throw Exception(res.message);
    final raw = res.data is Map ? res.data : null;
    if (raw == null) return;
    final updated = ChatMessage.fromJson(Map<String, dynamic>.from(raw));
    messages.value = messages.value.map((m) => m.id == messageId ? updated : m).toList();
  }

  Future<bool> toggleStar(int messageId) async {
    final res = await _api.toggleStar(messageId);
    if (!res.success) throw Exception(res.message);
    final data = res.data is Map ? res.data as Map : {};
    final now = data['is_starred'] == true;
    messages.value = messages.value.map((m) {
      return m.id == messageId ? m.copyWith(isStarred: now) : m;
    }).toList();
    return now;
  }

  Future<bool> togglePin(int messageId) async {
    final res = await _api.togglePin(messageId);
    if (!res.success) throw Exception(res.message);
    final data = res.data is Map ? res.data as Map : {};
    final now = data['pinned'] == true;
    messages.value = messages.value.map((m) {
      return m.id == messageId ? m.copyWith(isPinned: now) : m;
    }).toList();
    pins.value = (data['pins'] as List? ?? [])
        .map((e) => ChatMessage.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    return now;
  }

  // ── Forward ──────────────────────────────────────────
  Future<void> forward({
    required List<int> messageIds,
    required List<int> conversationIds,
  }) async {
    final res = await _api.forward(messageIds: messageIds, conversationIds: conversationIds);
    if (!res.success) throw Exception(res.message);
  }

  Future<MessageInfo> fetchInfo(int messageId) async {
    final res = await _api.fetchMessageInfo(messageId);
    if (!res.success) throw Exception(res.message);
    return MessageInfo.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  // ── Updates ──────────────────────────────────────────
  Future<List<ChatUpdate>> fetchUpdates() async {
    final res = await _api.fetchChatUpdates();
    if (!res.success) throw Exception(res.message);
    final raw = res.data;
    final List list = raw is List ? raw : (raw is Map && raw['data'] is List ? raw['data'] : []);
    return list
        .map((e) => ChatUpdate.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> markStatusSeen(int technicianId) async {
    try {
      await _api.markStatusSeen(technicianId);
    } catch (_) {}
  }

  // ── Polling ──────────────────────────────────────────
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
    if (messages.value.isEmpty) {
      await _loadLatest(conversationId);
      return;
    }
    final lastId = messages.value.last.id;
    final res = await _api.getMessages(
      conversationId: conversationId,
      afterId: lastId > 0 ? lastId : null,
      since: _lastServerTime,
    );
    if (!res.success) return;
    final data = res.data is Map ? res.data as Map : {};

    _lastServerTime = data['server_time']?.toString();
    peerTyping.value = data['peer_typing'] == true;
    pins.value = (data['pins'] as List? ?? [])
        .map((e) => ChatMessage.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    final newer = (data['messages'] as List? ?? [])
        .map((e) => ChatMessage.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    final updates = (data['updates'] as List? ?? [])
        .map((e) => ChatMessage.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    if (newer.isNotEmpty) _appendMessages(newer);
    if (updates.isNotEmpty) _applyUpdates(updates);

    if (newer.isNotEmpty || updates.isNotEmpty) {
      await loadConversations();
    }
  }

  void _appendMessages(List<ChatMessage> incoming) {
    if (incoming.isEmpty) return;
    final existing = messages.value.map((m) => m.id).toSet();
    final unique = incoming.where((m) => !existing.contains(m.id)).toList();
    if (unique.isEmpty) return;
    messages.value = [...messages.value, ...unique];
  }

  void _applyUpdates(List<ChatMessage> updates) {
    final byId = {for (final u in updates) u.id: u};
    messages.value = messages.value.map((m) => byId[m.id] ?? m).toList();
  }

  void dispose() {
    _stopPolling();
  }
}