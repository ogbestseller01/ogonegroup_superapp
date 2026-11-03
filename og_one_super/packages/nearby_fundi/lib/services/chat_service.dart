// lib/services/chat_service.dart
// Polling chat with optimistic sending, replies, reactions, stars, pins,
// forward, jump-to-quoted-message and private file access.

import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../config/app_config.dart';
import '../models/chat_conversation.dart';
import '../models/chat_message.dart';
import '../models/chat_user.dart';
import 'storage_service.dart';

class ChatException implements Exception {
  final String message;
  const ChatException(this.message);

  @override
  String toString() => message;
}

class ChatService {
  static const Duration _listPollEvery = Duration(seconds: 15);
  static const Duration _messagePollEvery = Duration(seconds: 3);
  static const int pageSize = 30;

  // ── State exposed to the provider ──────────────────────
  final ValueNotifier<List<ChatConversation>> conversations =
  ValueNotifier<List<ChatConversation>>([]);

  /// Messages of the open conversation, oldest -> newest (pending ones last).
  final ValueNotifier<List<ChatMessage>> messages =
  ValueNotifier<List<ChatMessage>>([]);

  /// Pinned messages of the open conversation (newest pin first).
  final ValueNotifier<List<ChatMessage>> pins =
  ValueNotifier<List<ChatMessage>>([]);

  final ValueNotifier<int> totalUnread = ValueNotifier<int>(0);
  final ValueNotifier<bool> peerTyping = ValueNotifier<bool>(false);

  bool hasMoreOlder = false;
  String? listError;

  // ── Private ────────────────────────────────────────────
  String? _token;
  ChatUser? _currentUser;
  int? _openId;
  String? _since; // server_time of the last poll (for reaction updates)
  Timer? _listTimer;
  Timer? _messageTimer;

  List<ChatMessage> _server = [];
  final List<ChatMessage> _pending = [];
  int _tempId = 0;
  Future<void> _sendQueue = Future.value();

  bool _loadingList = false;
  bool _polling = false;
  bool _loadingOlder = false;
  bool _disposed = false;

  late final Dio _dio = Dio(BaseOptions(
    baseUrl: AppConfig.baseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 60),
    sendTimeout: const Duration(minutes: 3),
    headers: {'Accept': 'application/json'},
  ))
    ..interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = _token ?? await StorageService.getToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ));

  ChatUser? get currentUser => _currentUser;

  /// Headers needed to view private chat files (images / video).
  Map<String, String> get authHeaders => {
    'Authorization': 'Bearer ${_token ?? ''}',
    'Accept': 'application/json',
  };

  // ============================================================
  // LIFECYCLE
  // ============================================================

  void initialize({required String token, required ChatUser currentUser}) {
    if (_disposed) return;
    _token = token;
    _currentUser = currentUser;

    unawaited(clearViewCache());
    unawaited(loadConversations());

    _listTimer?.cancel();
    _listTimer = Timer.periodic(_listPollEvery, (_) => loadConversations());
  }

  /// Called on logout.
  void reset() {
    _listTimer?.cancel();
    _messageTimer?.cancel();
    _listTimer = null;
    _messageTimer = null;
    _openId = null;
    _since = null;
    _token = null;
    _currentUser = null;
    _server = [];
    _pending.clear();
    hasMoreOlder = false;
    listError = null;

    if (!_disposed) {
      conversations.value = const <ChatConversation>[];
      messages.value = const <ChatMessage>[];
      pins.value = const <ChatMessage>[];
      totalUnread.value = 0;
      peerTyping.value = false;
    }
    unawaited(clearViewCache());
    unawaited(DefaultCacheManager().emptyCache()); // private images
  }

  void dispose() {
    if (_disposed) return;
    _listTimer?.cancel();
    _messageTimer?.cancel();
    _disposed = true;
    conversations.dispose();
    messages.dispose();
    pins.dispose();
    totalUnread.dispose();
    peerTyping.dispose();
  }

  void _publish() {
    if (_disposed) return;
    final open = _openId;
    final pinIds = pins.value.map((m) => m.id).toSet();

    final server = _server
        .map((m) => m.isPinned == pinIds.contains(m.id)
        ? m
        : m.copyWith(isPinned: pinIds.contains(m.id)))
        .toList();

    messages.value = [
      ...server,
      ..._pending.where((m) => m.conversationId == open),
    ];
  }

  // ============================================================
  // CONVERSATIONS
  // ============================================================

  Future<void> loadConversations() async {
    if (_disposed || _token == null || _loadingList) return;
    _loadingList = true;
    try {
      final data = await _request(() => _dio.get('/v14/chat/conversations'));
      if (_disposed) return;
      if (data is List) {
        final list = data
            .whereType<Map>()
            .map((e) => ChatConversation.fromJson(Map<String, dynamic>.from(e)))
            .where((c) => c.id > 0)
            .toList();
        conversations.value = list;
        totalUnread.value = list.fold<int>(0, (sum, c) => sum + c.unreadCount);
        listError = null;
      }
    } catch (e) {
      listError = e.toString();
      debugPrint('Chat list error: $e');
    } finally {
      _loadingList = false;
    }
  }

  Future<ChatConversation> createConversation({
    required int customerId,
    required int fundiId,
  }) async {
    final data = await _request(() => _dio.post('/v14/chat/conversation', data: {
      'customer_id': customerId,
      'fundi_id': fundiId,
    }));
    if (data is! Map) throw const ChatException('Could not open the chat.');
    final conv = ChatConversation.fromJson(Map<String, dynamic>.from(data));
    unawaited(loadConversations());
    return conv;
  }

  Future<void> markConversationAsRead(int conversationId) async {
    try {
      await _request(
              () => _dio.post('/v14/chat/conversations/$conversationId/read'));
      final convs = List<ChatConversation>.from(conversations.value);
      final i = convs.indexWhere((c) => c.id == conversationId);
      if (i != -1) {
        convs[i] = convs[i].copyWith(unreadCount: 0);
        conversations.value = convs;
        totalUnread.value = convs.fold<int>(0, (s, c) => s + c.unreadCount);
      }
    } catch (e) {
      debugPrint('Mark read error: $e');
    }
  }

  Future<bool> deleteConversation(int conversationId) async {
    try {
      await _request(
              () => _dio.delete('/v14/chat/conversations/$conversationId'));
      conversations.value =
          conversations.value.where((c) => c.id != conversationId).toList();
      totalUnread.value =
          conversations.value.fold<int>(0, (s, c) => s + c.unreadCount);
      if (_openId == conversationId) closeConversation();
      return true;
    } catch (e) {
      debugPrint('Delete conversation error: $e');
      return false;
    }
  }

  // ============================================================
  // OPEN CHAT (messages + polling)
  // ============================================================

  Future<void> openConversation(int id) async {
    _openId = id;
    _server = [];
    _since = null;
    hasMoreOlder = false;
    peerTyping.value = false;
    pins.value = const <ChatMessage>[];
    _publish();

    _messageTimer?.cancel();
    _messageTimer = Timer.periodic(_messagePollEvery, (_) => _pollNew());

    await _loadLatest();
  }

  void closeConversation() {
    _messageTimer?.cancel();
    _messageTimer = null;
    _openId = null;
    _since = null;
    _server = [];
    hasMoreOlder = false;
    if (!_disposed) {
      peerTyping.value = false;
      pins.value = const <ChatMessage>[];
      _publish();
    }
  }

  Future<void> _loadLatest() async {
    final id = _openId;
    if (id == null) return;

    final data = await _request(() => _dio.get(
      '/v14/chat/conversations/$id/messages',
      queryParameters: {'limit': pageSize},
    ));
    if (_openId != id || data is! Map || _disposed) return;

    hasMoreOlder = data['has_more'] == true;
    peerTyping.value = data['peer_typing'] == true;
    _since = data['server_time']?.toString();
    _applyPins(data['pins']);
    _server = _parseMessages(data['messages']);
    _publish();
    unawaited(loadConversations());
  }

  Future<void> _pollNew() async {
    final id = _openId;
    if (id == null || _polling || _disposed) return;
    _polling = true;
    try {
      final lastId = _server.isEmpty ? 0 : _server.last.id;
      final data = await _request(() => _dio.get(
        '/v14/chat/conversations/$id/messages',
        queryParameters: {
          'after_id': lastId,
          if (_since != null) 'since': _since,
        },
      ));
      if (_openId != id || data is! Map || _disposed) return;

      peerTyping.value = data['peer_typing'] == true;

      final fresh = _parseMessages(data['messages']);
      var changed = _merge(fresh, _toInt(data['peer_read_upto']));

      final updates = _parseMessages(data['updates']);
      if (updates.isNotEmpty && _applyUpdates(updates)) changed = true;
      if (_applyPins(data['pins'])) changed = true;

      _since = data['server_time']?.toString() ?? _since;
      if (changed) _publish();

      final me = _currentUser?.id;
      if (fresh.any((m) => m.senderId != me)) {
        unawaited(loadConversations());
      }
    } catch (e) {
      debugPrint('Chat poll error: $e');
    } finally {
      _polling = false;
    }
  }

  Future<void> loadOlder() async {
    final id = _openId;
    if (id == null || !hasMoreOlder || _loadingOlder || _server.isEmpty) {
      return;
    }
    _loadingOlder = true;
    try {
      final firstId = _server.first.id;
      final data = await _request(() => _dio.get(
        '/v14/chat/conversations/$id/messages',
        queryParameters: {'before_id': firstId, 'limit': pageSize},
      ));
      if (_openId != id || data is! Map || _disposed) return;

      final older = _parseMessages(data['messages']);
      hasMoreOlder = data['has_more'] == true;

      final known = _server.map((m) => m.id).toSet();
      _server = [...older.where((m) => !known.contains(m.id)), ..._server];
      _publish();
    } catch (e) {
      debugPrint('Load older error: $e');
    } finally {
      _loadingOlder = false;
    }
  }

  /// Loads everything between [id] and the oldest loaded message in ONE request,
  /// so "tap the quoted message" can jump to it however far up it is.
  Future<bool> loadUntil(int id) async {
    final convId = _openId;
    if (convId == null) return false;
    if (_server.any((m) => m.id == id)) return true;
    if (_server.isEmpty || !hasMoreOlder) return false;

    final firstId = _server.first.id;
    if (id >= firstId) return false; // deleted

    try {
      final data = await _request(() => _dio.get(
        '/v14/chat/conversations/$convId/messages',
        queryParameters: {'before_id': firstId, 'until_id': id},
      ));
      if (_openId != convId || data is! Map || _disposed) return false;

      final older = _parseMessages(data['messages']);
      hasMoreOlder = data['has_more'] == true;

      final known = _server.map((m) => m.id).toSet();
      _server = [...older.where((m) => !known.contains(m.id)), ..._server];
      _publish();
      return _server.any((m) => m.id == id);
    } catch (e) {
      debugPrint('Load until error: $e');
      return false;
    }
  }

  /// Adds new messages and updates ✓✓ for my messages. Returns true on change.
  bool _merge(List<ChatMessage> fresh, int peerReadUpTo) {
    var changed = false;
    final byId = <int, ChatMessage>{for (final m in _server) m.id: m};

    for (final m in fresh) {
      if (!byId.containsKey(m.id)) changed = true;
      byId[m.id] = m;
    }

    final me = _currentUser?.id;
    final list = byId.values.toList();
    for (var i = 0; i < list.length; i++) {
      final m = list[i];
      if (m.senderId == me &&
          !m.isRead &&
          peerReadUpTo > 0 &&
          m.id <= peerReadUpTo) {
        list[i] = m.copyWith(isRead: true);
        changed = true;
      }
    }

    if (!changed) return false;
    list.sort((a, b) => a.id.compareTo(b.id));
    _server = list;
    return true;
  }

  String _sig(ChatMessage m) =>
      m.reactions.map((e) => '${e.emoji}:${e.count}:${e.mine}').join('|');

  /// Reaction changes made by the other person on older messages.
  bool _applyUpdates(List<ChatMessage> ups) {
    var changed = false;
    final byId = <int, ChatMessage>{for (final m in _server) m.id: m};

    for (final u in ups) {
      final old = byId[u.id];
      if (old == null) continue;
      if (_sig(old) != _sig(u) || old.myReaction != u.myReaction) {
        byId[u.id] = old.copyWith(
          reactions: u.reactions,
          myReaction: u.myReaction,
          clearMyReaction: u.myReaction == null,
        );
        changed = true;
      }
    }

    if (changed) {
      _server = byId.values.toList()..sort((a, b) => a.id.compareTo(b.id));
    }
    return changed;
  }

  /// Updates the pinned list. Returns true if the set of pinned ids changed.
  bool _applyPins(dynamic raw) {
    if (_disposed || raw is! List) return false;
    final next = _parseMessages(raw);
    final oldIds = pins.value.map((m) => m.id).toList();
    final newIds = next.map((m) => m.id).toList();
    final same = listEquals(oldIds, newIds);
    pins.value = next;
    return !same;
  }

  /// "typing…" signal for the other person (call at most every ~3 s).
  Future<void> sendTyping(int conversationId) async {
    try {
      await _dio.post('/v14/chat/typing',
          data: {'conversation_id': conversationId});
    } catch (_) {}
  }

  // ============================================================
  // REACTIONS / STARS / PINS / FORWARD / INFO
  // ============================================================

  void _setServer(int id, ChatMessage Function(ChatMessage) change) {
    final i = _server.indexWhere((m) => m.id == id);
    if (i == -1) return;
    final list = List<ChatMessage>.from(_server);
    list[i] = change(list[i]);
    _server = list;
    _publish();
  }

  ChatMessage _withMyReaction(ChatMessage m, String? emoji) {
    final counts = <String, int>{};
    final order = <String>[];
    for (final r in m.reactions) {
      counts[r.emoji] = r.count;
      order.add(r.emoji);
    }
    final old = m.myReaction;
    if (old != null && counts.containsKey(old)) {
      counts[old] = counts[old]! - 1;
      if (counts[old]! <= 0) {
        counts.remove(old);
        order.remove(old);
      }
    }
    if (emoji != null) {
      if (!counts.containsKey(emoji)) order.add(emoji);
      counts[emoji] = (counts[emoji] ?? 0) + 1;
    }
    return m.copyWith(
      reactions: [
        for (final e in order)
          ReactionSummary(emoji: e, count: counts[e]!, mine: e == emoji),
      ],
      myReaction: emoji,
      clearMyReaction: emoji == null,
    );
  }

  /// [emoji] == null removes my reaction. Optimistic, rolls back on failure.
  Future<void> react(int messageId, String? emoji) async {
    ChatMessage? before;
    _setServer(messageId, (m) {
      before = m;
      return _withMyReaction(m, emoji);
    });
    try {
      await _request(() => _dio.post('/v14/chat/messages/$messageId/react',
          data: {'reaction': emoji ?? ''}));
    } catch (e) {
      final old = before;
      if (old != null) _setServer(messageId, (_) => old);
      rethrow;
    }
  }

  /// Returns the new starred state. Stars are private to me.
  Future<bool> toggleStar(int messageId) async {
    bool? was;
    _setServer(messageId, (m) {
      was = m.isStarred;
      return m.copyWith(isStarred: !m.isStarred);
    });
    try {
      final data = await _request(
              () => _dio.post('/v14/chat/messages/$messageId/star'));
      final starred = data is Map ? data['is_starred'] == true : !(was ?? false);
      _setServer(messageId, (m) => m.copyWith(isStarred: starred));
      return starred;
    } catch (e) {
      final w = was;
      if (w != null) _setServer(messageId, (m) => m.copyWith(isStarred: w));
      rethrow;
    }
  }

  /// Returns true if the message is now pinned. Throws (e.g. "max 3 pins").
  Future<bool> togglePin(int messageId) async {
    final data = await _request(
            () => _dio.post('/v14/chat/messages/$messageId/pin'));
    if (data is! Map) return false;
    _applyPins(data['pins']);
    _publish();
    return data['pinned'] == true;
  }

  Future<void> forward({
    required List<int> messageIds,
    required List<int> conversationIds,
  }) async {
    await _request(() => _dio.post('/v14/chat/forward', data: {
      'message_ids': messageIds,
      'conversation_ids': conversationIds,
    }));
    unawaited(loadConversations());
    if (_openId != null && conversationIds.contains(_openId)) {
      unawaited(_pollNew());
    }
  }

  Future<MessageInfo> fetchInfo(int messageId) async {
    final data =
    await _request(() => _dio.get('/v14/chat/messages/$messageId/info'));
    if (data is! Map) throw const ChatException('Could not load message info.');
    return MessageInfo.fromJson(Map<String, dynamic>.from(data));
  }

  Future<List<ChatMessage>> fetchStarred(int conversationId) async {
    final data = await _request(
            () => _dio.get('/v14/chat/conversations/$conversationId/starred'));
    return _parseMessages(data);
  }

  // ============================================================
  // SEND (optimistic) / RETRY / DELETE
  // ============================================================

  /// Shows the message immediately, then uploads in the background (in order).
  void send({
    required int conversationId,
    String? content,
    File? file,
    ReplyRef? replyTo,
  }) {
    final me = _currentUser;
    final text = content?.trim() ?? '';
    if (me == null || (text.isEmpty && file == null)) return;

    final temp = ChatMessage.pending(
      id: --_tempId,
      conversationId: conversationId,
      senderId: me.id,
      senderName: me.name,
      content: text,
      file: file,
      replyTo: replyTo,
    );
    _pending.add(temp);
    _publish();
    _enqueue(temp.id);
  }

  void retry(int tempId) {
    final m = _findPending(tempId);
    if (m == null || m.sendState != SendState.failed) return;
    _updatePending(tempId,
            (x) => x.copyWith(sendState: SendState.sending, progress: 0, sendError: ''));
    _enqueue(tempId);
  }

  void discardPending(int tempId) {
    _pending.removeWhere((m) => m.id == tempId);
    _publish();
  }

  void _enqueue(int tempId) {
    _sendQueue =
        _sendQueue.then((_) => _deliver(tempId)).catchError((_) {});
  }

  ChatMessage? _findPending(int id) {
    for (final m in _pending) {
      if (m.id == id) return m;
    }
    return null;
  }

  void _updatePending(int id, ChatMessage Function(ChatMessage) change) {
    final i = _pending.indexWhere((m) => m.id == id);
    if (i == -1) return;
    _pending[i] = change(_pending[i]);
    _publish();
  }

  Future<void> _deliver(int tempId) async {
    final msg = _findPending(tempId);
    if (msg == null || _disposed) return; // discarded meanwhile
    _updatePending(tempId,
            (m) => m.copyWith(sendState: SendState.sending, progress: 0, sendError: ''));

    try {
      final form = FormData();
      form.fields.add(MapEntry('conversation_id', '${msg.conversationId}'));
      final text = (msg.content ?? '').trim();
      if (text.isNotEmpty) form.fields.add(MapEntry('content', text));
      if (msg.replyTo != null) {
        form.fields.add(MapEntry('reply_to_id', '${msg.replyTo!.id}'));
      }
      final path = msg.file?.localPath;
      if (path != null) {
        form.files.add(MapEntry(
          'file',
          await MultipartFile.fromFile(path, filename: p.basename(path)),
        ));
      }

      var shown = 0.0;
      final data = await _request(() => _dio.post(
        '/v14/chat/send',
        data: form,
        onSendProgress: (sent, total) {
          if (path == null || total <= 0) return;
          final v = sent / total;
          if (v - shown >= 0.03 || v >= 1) {
            shown = v;
            _updatePending(tempId, (m) => m.copyWith(progress: v));
          }
        },
      ));

      final raw = data is Map ? (data['message'] ?? data) : null;
      if (raw is! Map) throw const ChatException('Unexpected response from server.');

      var sent = ChatMessage.fromJson(Map<String, dynamic>.from(raw));
      // keep the local copy so our own photo doesn't flash/re-download
      if (path != null && sent.file != null) {
        sent = sent.copyWith(file: sent.file!.withLocal(path));
      }

      _pending.removeWhere((m) => m.id == tempId);
      if (_openId == msg.conversationId) _merge([sent], 0);
      _publish();
      unawaited(loadConversations());
    } catch (e) {
      _updatePending(
          tempId,
              (m) => m.copyWith(
              sendState: SendState.failed, sendError: e.toString()));
    }
  }

  Future<void> deleteMessage(int messageId) async {
    await _request(() => _dio.delete('/v14/chat/messages/$messageId'));
    _server = _server.where((m) => m.id != messageId).toList();
    pins.value = pins.value.where((m) => m.id != messageId).toList();
    _publish();
    unawaited(loadConversations());
  }

  // ============================================================
  // VIEWING FILES (temporary private copy)
  // ============================================================

  Future<File> fetchForViewing(ChatMessage message) async {
    final local = message.file?.localPath;
    if (local != null && await File(local).exists()) return File(local);

    final base = await getTemporaryDirectory();
    final folder = Directory(p.join(base.path, 'chat_view'));
    if (!await folder.exists()) await folder.create(recursive: true);

    var name = (message.file?.name ?? 'file_${message.id}')
        .replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final ext = message.file?.ext ?? '';
    if (ext.isNotEmpty && !name.toLowerCase().endsWith('.$ext')) {
      name = '$name.$ext';
    }

    final target = File(p.join(folder.path, '${message.id}_$name'));
    if (await target.exists() && await target.length() > 0) return target;

    final part = File('${target.path}.part');
    try {
      await _dio.download('/v14/chat/messages/${message.id}/file', part.path);
      await part.rename(target.path);
    } on DioException catch (e) {
      if (await part.exists()) await part.delete();
      throw ChatException(_dioMessage(e));
    }
    return target;
  }

  Future<void> clearViewCache() async {
    try {
      final base = await getTemporaryDirectory();
      final folder = Directory(p.join(base.path, 'chat_view'));
      if (await folder.exists()) await folder.delete(recursive: true);
    } catch (_) {}
  }

  // ============================================================
  // HELPERS
  // ============================================================

  List<ChatMessage> _parseMessages(dynamic raw) {
    if (raw is! List) return <ChatMessage>[];
    return raw
        .whereType<Map>()
        .map((e) => ChatMessage.fromJson(Map<String, dynamic>.from(e)))
        .where((m) => m.id > 0)
        .toList();
  }

  int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  Future<dynamic> _request(Future<Response<dynamic>> Function() call) async {
    try {
      final res = await call();
      final body = res.data;
      if (body is Map && body['success'] == false) {
        throw ChatException(body['message']?.toString() ?? 'Request failed.');
      }
      return body is Map ? body['data'] : null;
    } on DioException catch (e) {
      throw ChatException(_dioMessage(e));
    }
  }

  String _dioMessage(DioException e) {
    final status = e.response?.statusCode;
    final body = e.response?.data;

    if (body is Map) {
      final errs = body['errors'];
      if (errs is Map && errs.isNotEmpty) {
        final first = errs.values.first;
        if (first is List && first.isNotEmpty) return first.first.toString();
      }
      final msg = body['message']?.toString();
      if (msg != null && msg.isNotEmpty) return msg;
    }

    if (status == 401) return 'Session expired. Please log in again.';
    if (status == 413) return 'The file is too large for the server.';

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'The connection timed out. Please try again.';
      default:
        return 'Network error. Please check your connection.';
    }
  }
}
