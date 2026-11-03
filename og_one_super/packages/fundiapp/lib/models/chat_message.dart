// lib/models/chat_message.dart
enum ChatFileKind { image, video, pdf, word, excel, powerpoint, other }

class ChatFile {
  final String? url;
  final String? name;
  final int? size;
  final String? mimeType;
  final String? extension;

  const ChatFile({
    this.url,
    this.name,
    this.size,
    this.mimeType,
    this.extension,
  });

  factory ChatFile.fromJson(Map<String, dynamic> json) {
    final rawSize = json['size'] ?? json['file_size'];
    return ChatFile(
      url: (json['url'] ?? json['file_url'])?.toString(),
      name: (json['name'] ?? json['file_name'])?.toString(),
      size: rawSize == null ? null : _toInt(rawSize),
      mimeType: (json['mime_type'] ?? json['file_mime_type'])?.toString(),
      extension: (json['extension'] ?? json['file_extension'])?.toString(),
    );
  }

  String get ext {
    final e = (extension ?? '').toLowerCase().replaceAll('.', '');
    if (e.isNotEmpty) return e;
    final n = name ?? '';
    final dot = n.lastIndexOf('.');
    return dot >= 0 ? n.substring(dot + 1).toLowerCase() : '';
  }

  ChatFileKind get kind {
    final mime = (mimeType ?? '').toLowerCase();
    final e = ext;
    if (mime.startsWith('image/') ||
        const ['jpg', 'jpeg', 'png', 'webp', 'gif', 'heic'].contains(e)) {
      return ChatFileKind.image;
    }
    if (mime.startsWith('video/') ||
        const ['mp4', 'mov', 'm4v', '3gp', 'webm', 'mkv'].contains(e)) {
      return ChatFileKind.video;
    }
    if (e == 'pdf' || mime == 'application/pdf') return ChatFileKind.pdf;
    if (const ['doc', 'docx', 'rtf', 'odt'].contains(e)) return ChatFileKind.word;
    if (const ['xls', 'xlsx', 'csv', 'ods'].contains(e)) return ChatFileKind.excel;
    if (const ['ppt', 'pptx'].contains(e)) return ChatFileKind.powerpoint;
    return ChatFileKind.other;
  }

  String get formattedSize {
    final s = size;
    if (s == null) return '';
    if (s < 1024) return '$s B';
    if (s < 1024 * 1024) return '${(s / 1024).toStringAsFixed(1)} KB';
    return '${(s / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  static int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }
}

class ChatMessage {
  final int id;
  final int conversationId;
  final int senderId;
  final String senderName;
  final String senderType; // 'customer' | 'fundi'
  final int receiverId;
  final String messageType; // text | image | video | file
  final String? content;
  final bool isRead;
  final String? createdAt;
  final ChatFile? file;

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
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: _toInt(json['id']),
      conversationId: _toInt(json['conversation_id']),
      senderId: _toInt(json['sender_id']),
      senderName: json['sender_name']?.toString() ?? 'Unknown',
      senderType: json['sender_type']?.toString() ?? 'customer',
      receiverId: _toInt(json['receiver_id']),
      messageType: json['message_type']?.toString() ?? 'text',
      content: json['content']?.toString(),
      isRead: json['is_read'] == true || json['is_read'] == 1,
      createdAt: json['created_at']?.toString(),
      file: json['file'] is Map
          ? ChatFile.fromJson(Map<String, dynamic>.from(json['file']))
          : null,
    );
  }

  bool isFromMe(int currentUserId) => senderId == currentUserId;

  bool get isText => messageType == 'text';
  bool get isImage => messageType == 'image';
  bool get isVideo => messageType == 'video';
  bool get isFile => messageType == 'file';

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

  String get timeLabel {
    final t = createdAt == null ? null : DateTime.tryParse(createdAt!)?.toLocal();
    if (t == null) return '';
    String two(int n) => n.toString().padLeft(2, '0');
    final hm = '${two(t.hour)}:${two(t.minute)}';
    final now = DateTime.now();
    final today = t.year == now.year && t.month == now.month && t.day == now.day;
    return today ? hm : '${t.day}/${t.month} $hm';
  }

  ChatMessage copyWith({bool? isRead}) {
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
      file: file,
    );
  }

  static int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }
}