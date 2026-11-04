// lib/models/chat_message.dart
enum SendState { sending, sent, failed }

enum ChatFileKind { image, video, pdf, word, excel, powerpoint, other }

class ReactionSummary {
  final String emoji;
  final int count;
  final bool mine;
  const ReactionSummary({required this.emoji, required this.count, required this.mine});

  factory ReactionSummary.fromJson(Map<String, dynamic> json) => ReactionSummary(
    emoji: json['emoji'] ?? '',
    count: json['count'] ?? 0,
    mine: json['mine'] == true,
  );
}

class ReplyRef {
  final int id;
  final int senderId;
  final String senderName;
  final String content;
  final bool isDeleted;
  final bool isImage;

  const ReplyRef({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.content,
    this.isDeleted = false,
    this.isImage = false,
  });

  factory ReplyRef.fromMessage(ChatMessage m) => ReplyRef(
    id: m.id,
    senderId: m.senderId,
    senderName: m.senderName,
    content: m.content ?? '',
    isDeleted: m.isDeleted,
    isImage: m.isImage,
  );

  factory ReplyRef.fromJson(Map<String, dynamic> json) {
    final type = json['message_type'] ?? json['file_type'];
    return ReplyRef(
      id: json['id'] ?? 0,
      senderId: json['sender_id'] ?? 0,
      senderName: json['sender_name'] ?? '',
      content: json['content'] ?? '',
      isDeleted: json['is_deleted'] == true,
      isImage: type == 'image',
    );
  }

  String get snippet {
    if (isDeleted) return 'This message was deleted';
    if (isImage) return '📷 Photo';
    if (content.trim().isNotEmpty) return content.trim();
    return '📎 Attachment';
  }
}

class MessageFile {
  final String url;
  final String name;
  final String? ext;
  final int? size;
  final String? localPath;
  final ChatFileKind? _kind;

  const MessageFile({
    required this.url,
    required this.name,
    this.ext,
    this.size,
    this.localPath,
    ChatFileKind? kind,
  }) : _kind = kind;

  factory MessageFile.fromJson(Map<String, dynamic> json) {
    final ext = json['extension']?.toString().toLowerCase()
        ?? json['ext']?.toString().toLowerCase();
    final name = json['name']?.toString() ?? '';
    return MessageFile(
      url: json['url']?.toString() ?? '',
      name: name,
      ext: ext,
      size: json['size'] != null ? int.tryParse(json['size'].toString()) : null,
      kind: _determineKind(ext, name),
    );
  }

  static ChatFileKind _determineKind(String? ext, String name) {
    final e = (ext ?? name.split('.').last).toLowerCase();
    if (['jpg', 'jpeg', 'png', 'gif', 'webp', 'heic'].contains(e)) return ChatFileKind.image;
    if (['mp4', 'mov', 'avi', 'mkv', 'webm', '3gp'].contains(e)) return ChatFileKind.video;
    if (e == 'pdf') return ChatFileKind.pdf;
    if (['doc', 'docx'].contains(e)) return ChatFileKind.word;
    if (['xls', 'xlsx', 'csv'].contains(e)) return ChatFileKind.excel;
    if (['ppt', 'pptx'].contains(e)) return ChatFileKind.powerpoint;
    return ChatFileKind.other;
  }

  ChatFileKind get kind => _kind ?? _determineKind(ext, name);

  MessageFile withLocal(String path) => MessageFile(
    url: url, name: name, ext: ext, size: size, localPath: path, kind: kind,
  );

  String get formattedSize {
    if (size == null || size == 0) return '';
    if (size! < 1024) return '$size B';
    if (size! < 1024 * 1024) return '${(size! / 1024).toStringAsFixed(1)} KB';
    return '${(size! / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String get openMime {
    switch (kind) {
      case ChatFileKind.image: return 'image/*';
      case ChatFileKind.video: return 'video/*';
      case ChatFileKind.pdf: return 'application/pdf';
      case ChatFileKind.word: return 'application/msword';
      case ChatFileKind.excel: return 'application/vnd.ms-excel';
      case ChatFileKind.powerpoint: return 'application/vnd.ms-powerpoint';
      default: return 'application/octet-stream';
    }
  }
}

/// Helper: auth-protected URL for reply thumbnails.
class ChatFile {
  static String urlFor(int replyId) => '/v14/chat/messages/$replyId/file';
}

class ChatMessage {
  final int id;
  final int conversationId;
  final int senderId;
  final String senderName;
  final String? content;
  final MessageFile? file;
  final ReplyRef? replyTo;
  final String createdAt;
  final bool isRead;
  final bool isStarred;
  final bool isPinned;
  final bool isDeleted;
  final bool isForwarded;
  final List<ReactionSummary> reactions;
  final String? myReaction;
  final SendState sendState;
  final double progress;
  final String sendError;

  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    this.content,
    this.file,
    this.replyTo,
    required this.createdAt,
    this.isRead = false,
    this.isStarred = false,
    this.isPinned = false,
    this.isDeleted = false,
    this.isForwarded = false,
    this.reactions = const [],
    this.myReaction,
    this.sendState = SendState.sent,
    this.progress = 1.0,
    this.sendError = '',
  });

  factory ChatMessage.pending({
    required int id,
    required int conversationId,
    required int senderId,
    required String senderName,
    String? content,
    MessageFile? file,
    ReplyRef? replyTo,
  }) => ChatMessage(
    id: id,
    conversationId: conversationId,
    senderId: senderId,
    senderName: senderName,
    content: content,
    file: file,
    replyTo: replyTo,
    createdAt: DateTime.now().toIso8601String(),
    sendState: SendState.sending,
    progress: 0,
  );

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? 0,
      conversationId: json['conversation_id'] ?? 0,
      senderId: json['sender_id'] ?? 0,
      senderName: json['sender_name'] ?? '',
      content: json['content'],
      file: json['file'] is Map
          ? MessageFile.fromJson(Map<String, dynamic>.from(json['file']))
          : null,
      replyTo: json['reply_to'] is Map
          ? ReplyRef.fromJson(Map<String, dynamic>.from(json['reply_to']))
          : null,
      createdAt: json['created_at'] ?? '',
      isRead: json['is_read'] == true,
      isStarred: json['is_starred'] == true,
      isPinned: json['is_pinned'] == true,
      isDeleted: json['is_deleted'] == true,
      isForwarded: json['is_forwarded'] == true,
      reactions: (json['reactions'] as List?)
          ?.whereType<Map>()
          .map((e) => ReactionSummary.fromJson(Map<String, dynamic>.from(e)))
          .toList() ?? const [],
      myReaction: json['my_reaction'],
    );
  }

  ChatMessage copyWith({
    String? content,
    MessageFile? file,
    bool? isRead,
    bool? isStarred,
    bool? isPinned,
    bool? isDeleted,
    List<ReactionSummary>? reactions,
    String? myReaction,
    bool clearMyReaction = false,
    SendState? sendState,
    double? progress,
    String? sendError,
  }) => ChatMessage(
    id: id, conversationId: conversationId, senderId: senderId,
    senderName: senderName,
    content: content ?? this.content,
    file: file ?? this.file, replyTo: replyTo,
    createdAt: createdAt,
    isRead: isRead ?? this.isRead,
    isStarred: isStarred ?? this.isStarred,
    isPinned: isPinned ?? this.isPinned,
    isDeleted: isDeleted ?? this.isDeleted,
    isForwarded: isForwarded,
    reactions: reactions ?? this.reactions,
    myReaction: clearMyReaction ? null : (myReaction ?? this.myReaction),
    sendState: sendState ?? this.sendState,
    progress: progress ?? this.progress,
    sendError: sendError ?? this.sendError,
  );

  bool get isPending => id < 0 || sendState != SendState.sent;
  bool get isImage => file?.kind == ChatFileKind.image;
  bool get isVideo => file?.kind == ChatFileKind.video;

  String get messageType {
    if (isImage) return 'image';
    if (isVideo) return 'video';
    if (file != null) return 'file';
    return 'text';
  }

  int get reactionTotal => reactions.fold(0, (s, r) => s + r.count);
  DateTime? get time => DateTime.tryParse(createdAt);

  bool get canDeleteForEveryone {
    if (isPending || isDeleted) return false;
    final t = time;
    if (t == null) return true;
    return DateTime.now().difference(t).inHours < 48;
  }

  String get timeLabel {
    final dt = DateTime.tryParse(createdAt)?.toLocal();
    if (dt == null) return '';
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String getDisplayMessage() {
    if (isDeleted) return 'This message was deleted';
    if (content != null && content!.trim().isNotEmpty) return content!.trim();
    if (file != null) {
      if (isImage) return '📷 Photo';
      if (isVideo) return '🎥 Video';
      return '📎 ${file!.name}';
    }
    return '';
  }
}

class MessageInfoReaction {
  final int userId;
  final String name;
  final String emoji;
  const MessageInfoReaction({required this.userId, required this.name, required this.emoji});

  factory MessageInfoReaction.fromJson(Map<String, dynamic> json) => MessageInfoReaction(
    userId: json['user_id'] ?? 0,
    name: json['user_name'] ?? json['name'] ?? '',
    emoji: json['emoji'] ?? '',
  );
}

class MessageInfo {
  final bool isMine;
  final DateTime? sentAt;
  final DateTime? deliveredAt;
  final DateTime? readAt;
  final List<MessageInfoReaction> reactions;

  const MessageInfo({
    required this.isMine,
    this.sentAt,
    this.deliveredAt,
    this.readAt,
    this.reactions = const [],
  });

  factory MessageInfo.fromJson(Map<String, dynamic> json) => MessageInfo(
    isMine: json['is_mine'] == true,
    sentAt: json['sent_at'] != null ? DateTime.tryParse(json['sent_at'].toString()) : null,
    deliveredAt: json['delivered_at'] != null ? DateTime.tryParse(json['delivered_at'].toString()) : null,
    readAt: json['read_at'] != null ? DateTime.tryParse(json['read_at'].toString()) : null,
    reactions: (json['reactions'] as List?)
        ?.whereType<Map>()
        .map((e) => MessageInfoReaction.fromJson(Map<String, dynamic>.from(e)))
        .toList() ?? const [],
  );
}