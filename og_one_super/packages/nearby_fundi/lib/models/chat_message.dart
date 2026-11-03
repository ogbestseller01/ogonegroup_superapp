// lib/models/chat_message.dart
import 'dart:io';

import 'package:path/path.dart' as p;

import '../config/app_config.dart';

enum ChatFileKind { image, video, pdf, word, excel, powerpoint, other }

enum SendState { sent, sending, failed }

int _toInt(dynamic v, [int fallback = 0]) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v?.toString() ?? '') ?? fallback;
}

DateTime? _toDate(dynamic v) =>
    v == null ? null : DateTime.tryParse(v.toString())?.toLocal();

const _imageExts = {'jpg', 'jpeg', 'png', 'webp', 'gif', 'heic', 'heif'};
const _videoExts = {'mp4', 'mov', 'm4v', '3gp', 'webm', 'mkv'};

ChatFileKind kindForExtension(String ext, [String? mime]) {
  final e = ext.toLowerCase();
  final m = (mime ?? '').toLowerCase();
  if (m.startsWith('image/') || _imageExts.contains(e)) return ChatFileKind.image;
  if (m.startsWith('video/') || _videoExts.contains(e)) return ChatFileKind.video;
  if (e == 'pdf' || m == 'application/pdf') return ChatFileKind.pdf;
  if (const ['doc', 'docx', 'rtf', 'odt'].contains(e)) return ChatFileKind.word;
  if (const ['xls', 'xlsx', 'csv', 'ods'].contains(e)) return ChatFileKind.excel;
  if (const ['ppt', 'pptx'].contains(e)) return ChatFileKind.powerpoint;
  return ChatFileKind.other;
}

/// "Today", "Yesterday" or "3 Nov 2026".
String chatDayLabel(DateTime d) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(d.year, d.month, d.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  return '${d.day} ${months[d.month - 1]} ${d.year}';
}

/// "Today, 14:05"
String chatDateTimeLabel(DateTime d) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${chatDayLabel(d)}, ${two(d.hour)}:${two(d.minute)}';
}

class ChatFile {
  final String? url;
  final String? name;
  final int? size;
  final String? mimeType;
  final String? extension;

  /// Set for files this device sent (instant preview, no re-download).
  final String? localPath;

  const ChatFile({
    this.url,
    this.name,
    this.size,
    this.mimeType,
    this.extension,
    this.localPath,
  });

  /// The private, authenticated file endpoint of a message.
  static String urlFor(int messageId) =>
      '${AppConfig.baseUrl}/v14/chat/messages/$messageId/file';

  factory ChatFile.fromJson(Map<String, dynamic> json, {required int messageId}) {
    final rawSize = json['size'] ?? json['file_size'];
    return ChatFile(
      url: messageId > 0 ? urlFor(messageId) : null,
      name: (json['name'] ?? json['file_name'])?.toString(),
      size: rawSize == null ? null : _toInt(rawSize),
      mimeType: (json['mime_type'] ?? json['file_mime_type'])?.toString(),
      extension: (json['extension'] ?? json['file_extension'])?.toString(),
    );
  }

  ChatFile withLocal(String path) => ChatFile(
    url: url,
    name: name,
    size: size,
    mimeType: mimeType,
    extension: extension,
    localPath: path,
  );

  /// Lower-case extension without the dot.
  String get ext {
    final e = (extension ?? '').toLowerCase().replaceAll('.', '');
    if (e.isNotEmpty) return e;
    final n = name ?? '';
    final dot = n.lastIndexOf('.');
    return dot >= 0 ? n.substring(dot + 1).toLowerCase() : '';
  }

  ChatFileKind get kind => kindForExtension(ext, mimeType);

  /// MIME hint for the system viewer (helps Android pick the right app).
  String? get openMime {
    switch (ext) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'ppt':
        return 'application/vnd.ms-powerpoint';
      case 'pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case 'csv':
        return 'text/csv';
      case 'txt':
        return 'text/plain';
    }
    return mimeType;
  }

  String get formattedSize {
    final s = size;
    if (s == null) return '';
    if (s < 1024) return '$s B';
    if (s < 1024 * 1024) return '${(s / 1024).toStringAsFixed(1)} KB';
    return '${(s / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// The quoted message shown above a reply.
class ReplyRef {
  final int id;
  final int senderId;
  final String? senderName;
  final String messageType; // text | image | video | file
  final String? content;
  final String? fileName;

  const ReplyRef({
    required this.id,
    required this.senderId,
    this.senderName,
    required this.messageType,
    this.content,
    this.fileName,
  });

  factory ReplyRef.fromJson(Map<String, dynamic> json) => ReplyRef(
    id: _toInt(json['id']),
    senderId: _toInt(json['sender_id']),
    senderName: json['sender_name']?.toString(),
    messageType: json['message_type']?.toString() ?? 'text',
    content: json['content']?.toString(),
    fileName: json['file_name']?.toString(),
  );

  factory ReplyRef.fromMessage(ChatMessage m) {
    var text = (m.content ?? '').trim();
    if (text.length > 120) text = '${text.substring(0, 120)}…';
    return ReplyRef(
      id: m.id,
      senderId: m.senderId,
      senderName: m.senderName,
      messageType: m.messageType,
      content: m.isText ? text : null,
      fileName: m.file?.name,
    );
  }

  bool get isImage => messageType == 'image';

  String get snippet {
    switch (messageType) {
      case 'image':
        return '📷 Photo';
      case 'video':
        return '🎬 Video';
      case 'file':
        return '📎 ${fileName ?? 'File'}';
      default:
        final c = (content ?? '').trim();
        return c.isEmpty ? 'Message' : c;
    }
  }
}

/// One emoji bubble under a message: "👍 2".
class ReactionSummary {
  final String emoji;
  final int count;
  final bool mine;

  const ReactionSummary({required this.emoji, required this.count, this.mine = false});

  factory ReactionSummary.fromJson(Map<String, dynamic> j) => ReactionSummary(
    emoji: j['emoji']?.toString() ?? '',
    count: _toInt(j['count'], 1),
    mine: j['mine'] == true,
  );
}

/// Who reacted (shown in the Info sheet).
class ReactorInfo {
  final int userId;
  final String name;
  final String emoji;

  const ReactorInfo({required this.userId, required this.name, required this.emoji});

  factory ReactorInfo.fromJson(Map<String, dynamic> j) => ReactorInfo(
    userId: _toInt(j['user_id']),
    name: j['user_name']?.toString() ?? 'Unknown',
    emoji: j['emoji']?.toString() ?? '',
  );
}

class MessageInfo {
  final bool isMine;
  final DateTime? sentAt;
  final DateTime? deliveredAt;
  final DateTime? readAt;
  final List<ReactorInfo> reactions;

  const MessageInfo({
    required this.isMine,
    this.sentAt,
    this.deliveredAt,
    this.readAt,
    this.reactions = const [],
  });

  factory MessageInfo.fromJson(Map<String, dynamic> j) => MessageInfo(
    isMine: j['is_mine'] == true,
    sentAt: _toDate(j['sent_at']),
    deliveredAt: _toDate(j['delivered_at']),
    readAt: _toDate(j['read_at']),
    reactions: (j['reactions'] is List)
        ? (j['reactions'] as List)
        .whereType<Map>()
        .map((e) => ReactorInfo.fromJson(Map<String, dynamic>.from(e)))
        .toList()
        : const [],
  );
}

class ChatMessage {
  final int id; // negative = not delivered yet (local only)
  final int conversationId;
  final int senderId;
  final String senderName;
  final String senderType;
  final int receiverId;

  /// text | image | video | file
  final String messageType;
  final String? content;
  final bool isRead;
  final String? createdAt;
  final ChatFile? file;
  final ReplyRef? replyTo;

  // WhatsApp-style extras
  final bool isForwarded;
  final bool isStarred; // private to me
  final bool isPinned; // shared
  final List<ReactionSummary> reactions;
  final String? myReaction;

  // Local sending state
  final SendState sendState;
  final double progress;
  final String? sendError;

  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.senderType,
    required this.receiverId,
    required this.messageType,
    this.content,
    this.isRead = false,
    this.createdAt,
    this.file,
    this.replyTo,
    this.isForwarded = false,
    this.isStarred = false,
    this.isPinned = false,
    this.reactions = const [],
    this.myReaction,
    this.sendState = SendState.sent,
    this.progress = 0,
    this.sendError,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final id = _toInt(json['id']);
    final type = json['message_type']?.toString() ?? 'text';

    ChatFile? file;
    if (json['file'] is Map) {
      file = ChatFile.fromJson(Map<String, dynamic>.from(json['file'] as Map),
          messageId: id);
    } else if (type != 'text') {
      file = ChatFile.fromJson(json, messageId: id); // flat keys fallback
    }

    final rawReactions = json['reactions'];

    return ChatMessage(
      id: id,
      conversationId: _toInt(json['conversation_id']),
      senderId: _toInt(json['sender_id']),
      senderName: json['sender_name']?.toString() ?? 'Unknown',
      senderType: json['sender_type']?.toString() ?? 'customer',
      receiverId: _toInt(json['receiver_id']),
      messageType: type,
      content: json['content']?.toString(),
      isRead: json['is_read'] == true || json['is_read'] == 1,
      createdAt: json['created_at']?.toString(),
      file: file,
      replyTo: json['reply_to'] is Map
          ? ReplyRef.fromJson(Map<String, dynamic>.from(json['reply_to'] as Map))
          : null,
      isForwarded: json['is_forwarded'] == true || json['is_forwarded'] == 1,
      isStarred: json['is_starred'] == true,
      isPinned: json['is_pinned'] == true,
      reactions: rawReactions is List
          ? rawReactions
          .whereType<Map>()
          .map((e) => ReactionSummary.fromJson(Map<String, dynamic>.from(e)))
          .toList()
          : const [],
      myReaction: json['my_reaction']?.toString(),
    );
  }

  /// A message that is still being uploaded / sent.
  factory ChatMessage.pending({
    required int id,
    required int conversationId,
    required int senderId,
    required String senderName,
    String? content,
    File? file,
    ReplyRef? replyTo,
  }) {
    ChatFile? cf;
    var type = 'text';
    if (file != null) {
      final ext = p.extension(file.path).replaceFirst('.', '').toLowerCase();
      final kind = kindForExtension(ext);
      type = kind == ChatFileKind.image
          ? 'image'
          : kind == ChatFileKind.video
          ? 'video'
          : 'file';
      cf = ChatFile(
        name: p.basename(file.path),
        size: file.lengthSync(),
        extension: ext,
        localPath: file.path,
      );
    }
    return ChatMessage(
      id: id,
      conversationId: conversationId,
      senderId: senderId,
      senderName: senderName,
      senderType: '',
      receiverId: 0,
      messageType: type,
      content: content,
      createdAt: DateTime.now().toIso8601String(),
      file: cf,
      replyTo: replyTo,
      sendState: SendState.sending,
    );
  }

  bool get isText => messageType == 'text';
  bool get isImage => messageType == 'image';
  bool get isVideo => messageType == 'video';
  bool get isFile => messageType == 'file';
  bool get isPending => id < 0;
  int get reactionTotal => reactions.fold<int>(0, (s, r) => s + r.count);

  String getDisplayMessage() {
    switch (messageType) {
      case 'image':
        return '📷 Photo';
      case 'video':
        return '🎬 Video';
      case 'file':
        return '📎 ${file?.name ?? 'File'}';
      default:
        final c = content?.trim() ?? '';
        return c.isEmpty ? 'Message' : c;
    }
  }

  DateTime? get time =>
      createdAt == null ? null : DateTime.tryParse(createdAt!)?.toLocal();

  /// HH:mm
  String get timeLabel {
    final t = time;
    if (t == null) return '';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(t.hour)}:${two(t.minute)}';
  }

  ChatMessage copyWith({
    bool? isRead,
    SendState? sendState,
    double? progress,
    String? sendError,
    ChatFile? file,
    bool? isStarred,
    bool? isPinned,
    List<ReactionSummary>? reactions,
    String? myReaction,
    bool clearMyReaction = false,
  }) {
    return ChatMessage(
      id: id,
      conversationId: conversationId,
      senderId: senderId,
      senderName: senderName,
      senderType: senderType,
      receiverId: receiverId,
      messageType: messageType,
      content: content,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      file: file ?? this.file,
      replyTo: replyTo,
      isForwarded: isForwarded,
      isStarred: isStarred ?? this.isStarred,
      isPinned: isPinned ?? this.isPinned,
      reactions: reactions ?? this.reactions,
      myReaction: clearMyReaction ? null : (myReaction ?? this.myReaction),
      sendState: sendState ?? this.sendState,
      progress: progress ?? this.progress,
      sendError: sendError ?? this.sendError,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'conversation_id': conversationId,
    'sender_id': senderId,
    'sender_name': senderName,
    'sender_type': senderType,
    'receiver_id': receiverId,
    'message_type': messageType,
    'content': content,
    'is_read': isRead,
    'created_at': createdAt,
  };
}
