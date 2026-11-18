// lib/services/chat_service.dart
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
import '../models/chat_update.dart';
import '../models/chat_user.dart';
import 'e2ee_service.dart';
import 'storage_service.dart';

const bool kE2ee = false;

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

  final ValueNotifier<List<ChatConversation>> conversations = ValueNotifier<List<ChatConversation>>([]);
  final ValueNotifier<List<ChatMessage>> messages = ValueNotifier<List<ChatMessage>>([]);
  final ValueNotifier<List<ChatMessage>> pins = ValueNotifier<List<ChatMessage>>([]);
  final ValueNotifier<int> totalUnread = ValueNotifier<int>(0);
  final ValueNotifier<bool> peerTyping = ValueNotifier<bool>(false);

  bool hasMoreOlder = false;
  String? listError;

  String? _token;
  ChatUser? _currentUser;
  int? _openId;
  String? _since;
  Timer? _listTimer;
  Timer? _messageTimer;

  List<ChatMessage> _server = [];
  final List<ChatMessage> _pending = [];
  int _tempId = 0;
  Future<void> _sendQueue = Future.value();
  final Map<int, int> _peerOf = {};
  final E2eeService _e2ee = E2eeService();

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
  ))..interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final token = _token ?? await StorageService.getToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    },
  ));

  ChatUser? get currentUser => _currentUser;
  Map<String, String> get authHeaders => {
    'Authorization': 'Bearer ${_token ?? ''}',
    'Accept': 'application/json',
  };

  void initialize({required String token, required ChatUser currentUser}) {
    if (_disposed) return;
    _token = token;
    _currentUser = currentUser;
    unawaited(clearViewCache());
    unawaited(loadConversations());
    if (kE2ee) unawaited(_e2ee.publishKey(_dio));

    _listTimer?.cancel();
    _listTimer = Timer.periodic(_listPollEvery, (_) => loadConversations());
  }

  void reset() {
    _listTimer?.cancel();
    _messageTimer?.cancel();
    _openId = null;
    _since = null;
    _token = null;
    _currentUser = null;
    _server = [];
    _pending.clear();
    _peerOf.clear();
    if (!_disposed) {
      conversations.value = [];
      messages.value = [];
      pins.value = [];
      totalUnread.value = 0;
      peerTyping.value = false;
    }
    unawaited(clearViewCache());
    unawaited(DefaultCacheManager().emptyCache());
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
    final server = _server.map((m) => m.isPinned == pinIds.contains(m.id) ? m : m.copyWith(isPinned: pinIds.contains(m.id))).toList();
    messages.value = [...server, ..._pending.where((m) => m.conversationId == open)];
  }

  Future<void> loadConversations() async {
    if (_disposed || _token == null || _loadingList) return;
    _loadingList = true;
    try {
      final data = await _request(() => _dio.get('/v14/chat/conversations'));
      if (_disposed) return;
      if (data is List) {
        final me = _currentUser?.id;
        final list = data.whereType<Map>().map((e) => ChatConversation.fromJson(Map<String, dynamic>.from(e))).where((c) => c.id > 0).toList();
        for (final c in list) {
          if (me == null) break;
          _peerOf[c.id] = (c.customerId == me) ? c.fundiId : c.customerId;
        }
        conversations.value = list;
        totalUnread.value = list.fold<int>(0, (sum, c) => sum + c.unreadCount);
        listError = null;
      }
    } catch (e) {
      listError = e.toString();
    } finally {
      _loadingList = false;
    }
  }

  Future<ChatConversation> createConversation({required int customerId, required int fundiId}) async {
    final data = await _request(() => _dio.post('/v14/chat/conversation', data: {'customer_id': customerId, 'fundi_id': fundiId}));
    if (data is! Map) throw const ChatException('Could not open the chat.');
    final conv = ChatConversation.fromJson(Map<String, dynamic>.from(data));
    unawaited(loadConversations());
    return conv;
  }

  Future<void> markConversationAsRead(int conversationId) async {
    try {
      await _request(() => _dio.post('/v14/chat/conversations/$conversationId/read'));
      final convs = List<ChatConversation>.from(conversations.value);
      final i = convs.indexWhere((c) => c.id == conversationId);
      if (i != -1) {
        convs[i] = convs[i].copyWith(unreadCount: 0);
        conversations.value = convs;
        totalUnread.value = convs.fold<int>(0, (s, c) => s + c.unreadCount);
      }
    } catch (_) {}
  }

  Future<bool> deleteConversation(int conversationId) async {
    try {
      await _request(() => _dio.delete('/v14/chat/conversations/$conversationId'));
      conversations.value = conversations.value.where((c) => c.id != conversationId).toList();
      totalUnread.value = conversations.value.fold<int>(0, (s, c) => s + c.unreadCount);
      if (_openId == conversationId) closeConversation();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> setConversationState(int id, {bool? pinned, bool? archived}) async {
    final before = conversations.value;
    conversations.value = [for (final c in before) if (c.id == id) c.copyWith(isPinned: pinned, isArchived: archived) else c];
    try {
      await _request(() => _dio.post('/v14/chat/conversations/$id/state', data: {
        if (pinned != null) 'pinned': pinned,
        if (archived != null) 'archived': archived
      }));
      unawaited(loadConversations());
    } catch (e) {
      conversations.value = before;
      rethrow;
    }
  }

  Future<void> markStatusSeen(int technicianId) async {
    conversations.value = [for (final c in conversations.value) if (c.technicianId == technicianId) c.copyWith(hasNewPost: false) else c];
    try { await _request(() => _dio.post('/v14/chat/status/$technicianId/seen')); } catch (_) {}
  }

  Future<List<ChatUpdate>> fetchUpdates() async {
    final data = await _request(() => _dio.get('/v14/chat/updates'));
    if (data is! List) return [];
    return data.whereType<Map>().map((e) => ChatUpdate.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<void> openConversation(int id) async {
    _openId = id;
    _server = [];
    _since = null;
    hasMoreOlder = false;
    peerTyping.value = false;
    pins.value = [];
    _publish();
    _messageTimer?.cancel();
    _messageTimer = Timer.periodic(_messagePollEvery, (_) => _pollNew());
    await _loadLatest();
  }

  void closeConversation() {
    _messageTimer?.cancel();
    _openId = null;
    _server = [];
    if (!_disposed) {
      peerTyping.value = false;
      pins.value = [];
      _publish();
    }
  }

  Future<void> _loadLatest() async {
    final id = _openId;
    if (id == null) return;
    final data = await _request(() => _dio.get('/v14/chat/conversations/$id/messages', queryParameters: {'limit': pageSize}));
    if (_openId != id || data is! Map || _disposed) return;
    hasMoreOlder = data['has_more'] == true;
    peerTyping.value = data['peer_typing'] == true;
    _since = data['server_time']?.toString();
    _applyPins(data['pins']);
    _server = await _parseMessages(data['messages'], id);
    _publish();
    unawaited(loadConversations());
  }

  Future<void> _pollNew() async {
    final id = _openId;
    if (id == null || _polling || _disposed) return;
    _polling = true;
    try {
      final lastId = _server.isEmpty ? 0 : _server.last.id;
      final data = await _request(() => _dio.get('/v14/chat/conversations/$id/messages', queryParameters: {'after_id': lastId, if (_since != null) 'since': _since}));
      if (_openId != id || data is! Map || _disposed) return;
      peerTyping.value = data['peer_typing'] == true;
      final fresh = await _parseMessages(data['messages'], id);
      var changed = _merge(fresh, _toInt(data['peer_read_upto']));
      final updates = await _parseMessages(data['updates'], id);
      if (updates.isNotEmpty && _applyUpdates(updates)) changed = true;
      if (_applyPins(data['pins'])) changed = true;
      _since = data['server_time']?.toString() ?? _since;
      if (changed) _publish();
      if (fresh.any((m) => m.senderId != _currentUser?.id)) unawaited(loadConversations());
    } catch (_) {} finally { _polling = false; }
  }

  Future<void> loadOlder() async {
    final id = _openId;
    if (id == null || !hasMoreOlder || _loadingOlder || _server.isEmpty) return;
    _loadingOlder = true;
    try {
      final firstId = _server.first.id;
      final data = await _request(() => _dio.get('/v14/chat/conversations/$id/messages', queryParameters: {'before_id': firstId, 'limit': pageSize}));
      if (_openId != id || data is! Map || _disposed) return;
      final older = await _parseMessages(data['messages'], id);
      hasMoreOlder = data['has_more'] == true;
      final known = _server.map((m) => m.id).toSet();
      _server = [...older.where((m) => !known.contains(m.id)), ..._server];
      _publish();
    } catch (_) {} finally { _loadingOlder = false; }
  }

  Future<bool> loadUntil(int id) async {
    final convId = _openId;
    if (convId == null) return false;
    if (_server.any((m) => m.id == id)) return true;
    if (_server.isEmpty || !hasMoreOlder) return false;
    final firstId = _server.first.id;
    if (id >= firstId) return false;
    try {
      final data = await _request(() => _dio.get('/v14/chat/conversations/$convId/messages', queryParameters: {'before_id': firstId, 'until_id': id}));
      if (_openId != convId || data is! Map || _disposed) return false;
      final older = await _parseMessages(data['messages'], convId);
      hasMoreOlder = data['has_more'] == true;
      final known = _server.map((m) => m.id).toSet();
      _server = [...older.where((m) => !known.contains(m.id)), ..._server];
      _publish();
      return _server.any((m) => m.id == id);
    } catch (_) { return false; }
  }

  Future<(List<ChatMessage>, bool)> fetchMedia(int conversationId, String tab, {int? beforeId}) async {
    final data = await _request(() => _dio.get('/v14/chat/conversations/$conversationId/media', queryParameters: {'tab': tab, if (beforeId != null) 'before_id': beforeId}));
    if (data is! Map) return (<ChatMessage>[], false);
    return (await _parseMessages(data['messages'], conversationId), data['has_more'] == true);
  }

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
      if (m.senderId == me && !m.isRead && peerReadUpTo > 0 && m.id <= peerReadUpTo) {
        list[i] = m.copyWith(isRead: true);
        changed = true;
      }
    }
    if (!changed) return false;
    list.sort((a, b) => a.id.compareTo(b.id));
    _server = list;
    return true;
  }

  String _sig(ChatMessage m) => m.reactions.map((e) => '${e.emoji}:${e.count}:${e.mine}').join('|');

  bool _applyUpdates(List<ChatMessage> ups) {
    var changed = false;
    final byId = <int, ChatMessage>{for (final m in _server) m.id: m};
    for (final u in ups) {
      final old = byId[u.id];
      if (old == null) continue;
      if (u.isDeleted && !old.isDeleted) {
        byId[u.id] = u;
        changed = true;
        continue;
      }
      if (_sig(old) != _sig(u) || old.myReaction != u.myReaction) {
        byId[u.id] = old.copyWith(reactions: u.reactions, myReaction: u.myReaction, clearMyReaction: u.myReaction == null);
        changed = true;
      }
    }
    if (changed) _server = byId.values.toList()..sort((a, b) => a.id.compareTo(b.id));
    return changed;
  }

  bool _applyPins(dynamic raw) {
    if (_disposed || raw is! List) return false;
    final next = raw.whereType<Map>().map((e) => ChatMessage.fromJson(Map<String, dynamic>.from(e))).where((m) => m.id > 0).toList();
    final same = listEquals(pins.value.map((m) => m.id).toList(), next.map((m) => m.id).toList());
    pins.value = next;
    return !same;
  }

  Future<void> sendTyping(int conversationId) async {
    try { await _dio.post('/v14/chat/typing', data: {'conversation_id': conversationId}); } catch (_) {}
  }

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
    for (final r in m.reactions) { counts[r.emoji] = r.count; order.add(r.emoji); }
    final old = m.myReaction;
    if (old != null && counts.containsKey(old)) {
      counts[old] = counts[old]! - 1;
      if (counts[old]! <= 0) { counts.remove(old); order.remove(old); }
    }
    if (emoji != null) { if (!counts.containsKey(emoji)) order.add(emoji); counts[emoji] = (counts[emoji] ?? 0) + 1; }
    return m.copyWith(reactions: [for (final e in order) ReactionSummary(emoji: e, count: counts[e]!, mine: e == emoji)], myReaction: emoji, clearMyReaction: emoji == null);
  }

  Future<void> react(int messageId, String? emoji) async {
    ChatMessage? before;
    _setServer(messageId, (m) { before = m; return _withMyReaction(m, emoji); });
    try { await _request(() => _dio.post('/v14/chat/messages/$messageId/react', data: {'reaction': emoji ?? ''})); } catch (e) {
      final old = before; if (old != null) _setServer(messageId, (_) => old); rethrow;
    }
  }

  Future<bool> toggleStar(int messageId) async {
    bool? was;
    _setServer(messageId, (m) { was = m.isStarred; return m.copyWith(isStarred: !m.isStarred); });
    try {
      final data = await _request(() => _dio.post('/v14/chat/messages/$messageId/star'));
      final starred = data is Map ? data['is_starred'] == true : !(was ?? false);
      _setServer(messageId, (m) => m.copyWith(isStarred: starred));
      return starred;
    } catch (e) {
      final w = was; if (w != null) _setServer(messageId, (m) => m.copyWith(isStarred: w)); rethrow;
    }
  }

  Future<bool> togglePin(int messageId) async {
    final data = await _request(() => _dio.post('/v14/chat/messages/$messageId/pin'));
    if (data is! Map) return false;
    _applyPins(data['pins']);
    _publish();
    return data['pinned'] == true;
  }

  Future<void> forward({required List<int> messageIds, required List<int> conversationIds}) async {
    await _request(() => _dio.post('/v14/chat/forward', data: {'message_ids': messageIds, 'conversation_ids': conversationIds}));
    unawaited(loadConversations());
    if (_openId != null && conversationIds.contains(_openId)) unawaited(_pollNew());
  }

  Future<MessageInfo> fetchInfo(int messageId) async {
    final data = await _request(() => _dio.get('/v14/chat/messages/$messageId/info'));
    if (data is! Map) throw const ChatException('Could not load message info.');
    return MessageInfo.fromJson(Map<String, dynamic>.from(data));
  }

  Future<List<ChatMessage>> fetchStarred(int conversationId) async {
    return await _parseMessages(await _request(() => _dio.get('/v14/chat/conversations/$conversationId/starred')), conversationId);
  }

  void send({required int conversationId, String? content, File? file, ReplyRef? replyTo}) {
    final me = _currentUser;
    final text = content?.trim() ?? '';
    if (me == null || (text.isEmpty && file == null)) return;

    MessageFile? messageFile;
    if (file != null) {
      final ext = p.extension(file.path).replaceFirst('.', '').toLowerCase();
      messageFile = MessageFile(
        url: '',
        name: p.basename(file.path),
        ext: ext,
        size: file.lengthSync(),
        localPath: file.path,
      );
    }

    final temp = ChatMessage.pending(
      id: --_tempId,
      conversationId: conversationId,
      senderId: me.id,
      senderName: me.name,
      content: text,
      file: messageFile,
      replyTo: replyTo,
    );
    _pending.add(temp);
    _publish();
    _sendQueue = _sendQueue.then((_) => _deliver(temp.id)).catchError((_) {});
  }

  void retry(int tempId) {
    final m = _findPending(tempId);
    if (m == null || m.sendState != SendState.failed) return;
    _updatePending(tempId, (x) => x.copyWith(sendState: SendState.sending, progress: 0, sendError: ''));
    _sendQueue = _sendQueue.then((_) => _deliver(tempId)).catchError((_) {});
  }

  void discardPending(int tempId) {
    _pending.removeWhere((m) => m.id == tempId);
    _publish();
  }

  ChatMessage? _findPending(int id) => _pending.cast<ChatMessage?>().firstWhere((m) => m?.id == id, orElse: () => null);

  void _updatePending(int id, ChatMessage Function(ChatMessage) change) {
    final i = _pending.indexWhere((m) => m.id == id);
    if (i == -1) return;
    _pending[i] = change(_pending[i]);
    _publish();
  }

  Future<void> _deliver(int tempId) async {
    final msg = _findPending(tempId);
    if (msg == null || _disposed) return;
    _updatePending(tempId, (m) => m.copyWith(sendState: SendState.sending, progress: 0, sendError: ''));

    try {
      final form = FormData();
      form.fields.add(MapEntry('conversation_id', '${msg.conversationId}'));
      var text = (msg.content ?? '').trim();
      var encrypted = false;
      final path = msg.file?.localPath;

      if (kE2ee && path == null && text.isNotEmpty) {
        final me = _currentUser;
        final peerId = _peerOf[msg.conversationId];
        if (me != null && peerId != null) {
          final enc = await _e2ee.encrypt(text, dio: _dio, myId: me.id, peerId: peerId);
          if (enc != null) { text = enc; encrypted = true; }
        }
      }

      if (text.isNotEmpty) form.fields.add(MapEntry('content', text));
      if (encrypted) form.fields.add(const MapEntry('is_encrypted', '1'));
      if (msg.replyTo != null) form.fields.add(MapEntry('reply_to_id', '${msg.replyTo!.id}'));
      if (path != null) form.files.add(MapEntry('file', await MultipartFile.fromFile(path, filename: p.basename(path))));

      var shown = 0.0;
      final data = await _request(() => _dio.post('/v14/chat/send', data: form, onSendProgress: (sent, total) {
        if (path == null || total <= 0) return;
        final v = sent / total;
        if (v - shown >= 0.03 || v >= 1) { shown = v; _updatePending(tempId, (m) => m.copyWith(progress: v)); }
      }));

      final raw = data is Map ? (data['message'] ?? data) : null;
      if (raw is! Map) throw const ChatException('Unexpected response from server.');
      var sent = ChatMessage.fromJson(Map<String, dynamic>.from(raw));

      if (encrypted && sent.content != null) {
        final me = _currentUser;
        if (me != null) {
          final plain = await _e2ee.decrypt(sent.content!, myId: me.id);
          if (plain != null) sent = sent.copyWith(content: plain);
        }
      }

      if (path != null && sent.file != null) sent = sent.copyWith(file: sent.file!.withLocal(path));

      _pending.removeWhere((m) => m.id == tempId);
      if (_openId == msg.conversationId) _merge([sent], 0);
      _publish();
      unawaited(loadConversations());
    } catch (e) {
      _updatePending(tempId, (m) => m.copyWith(sendState: SendState.failed, sendError: e.toString()));
    }
  }

  Future<List<int>> deleteMessages(List<int> ids, {required bool forEveryone}) async {
    final data = await _request(() => _dio.post('/v14/chat/messages/delete', data: {'message_ids': ids, 'scope': forEveryone ? 'everyone' : 'me'}));
    final done = (data is Map && data['deleted'] is List) ? (data['deleted'] as List).map(_toInt).toSet() : <int>{};

    if (forEveryone) {
      _server = _server.map((m) => done.contains(m.id) ? m.copyWith(isDeleted: true) : m).toList();
    } else {
      _server = _server.where((m) => !done.contains(m.id)).toList();
    }
    pins.value = pins.value.where((m) => !done.contains(m.id)).toList();
    _publish();
    unawaited(loadConversations());
    return done.toList();
  }

  Future<void> deleteMessage(int id) => deleteMessages([id], forEveryone: true);

  Future<File> fetchForViewing(ChatMessage message) async {
    final local = message.file?.localPath;
    if (local != null && await File(local).exists()) return File(local);
    final base = await getTemporaryDirectory();
    final folder = Directory(p.join(base.path, 'chat_view'));
    if (!await folder.exists()) await folder.create(recursive: true);
    var name = (message.file?.name ?? 'file_${message.id}').replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final ext = message.file?.ext ?? '';
    if (ext.isNotEmpty && !name.toLowerCase().endsWith('.$ext')) name = '$name.$ext';
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

  Future<List<ChatMessage>> _parseMessages(dynamic raw, int conversationId) async {
    if (raw is! List) return <ChatMessage>[];
    final me = _currentUser?.id;
    final peer = _peerOf[conversationId];
    final out = <ChatMessage>[];
    for (final e in raw.whereType<Map>()) {
      final m = ChatMessage.fromJson(Map<String, dynamic>.from(e));
      if (m.id <= 0) continue;

      if (kE2ee && me != null && peer != null && E2eeService.isEncrypted(m.content)) {
        final plain = await _e2ee.decrypt(m.content!, myId: me);
        out.add(m.copyWith(content: plain ?? '🔒 Message can’t be opened on this device'));
      } else {
        out.add(m);
      }
    }
    return out;
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
      if (body is Map && body['success'] == false) throw ChatException(body['message']?.toString() ?? 'Request failed.');
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
      case DioExceptionType.receiveTimeout: return 'The connection timed out. Please try again.';
      default: return 'Network error. Please check your connection.';
    }
  }
}