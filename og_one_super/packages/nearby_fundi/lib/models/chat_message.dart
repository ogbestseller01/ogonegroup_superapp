// lib/models/chat_message.dart

class ChatMessage {
  final int id;
  final int conversationId;
  final int senderId;
  final String senderName;
  final String senderType;
  final int receiverId;
  final String messageType;
  final String? content;
  final bool isRead;
  final String? readAt;
  final bool isDelivered;
  final String? deliveredAt;
  final String? createdAt;
  final ChatFile? file;
  final int? voiceDuration;

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.senderType,
    required this.receiverId,
    required this.messageType,
    this.content,
    this.isRead = false,
    this.readAt,
    this.isDelivered = false,
    this.deliveredAt,
    this.createdAt,
    this.file,
    this.voiceDuration,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? 0,
      conversationId: json['conversation_id'] ?? 0,
      senderId: json['sender_id'] ?? 0,
      senderName: json['sender_name'] ?? 'Unknown',
      senderType: json['sender_type'] ?? 'customer',
      receiverId: json['receiver_id'] ?? 0,
      messageType: json['message_type'] ?? 'text',
      content: json['content'],
      isRead: json['is_read'] ?? false,
      readAt: json['read_at'],
      isDelivered: json['is_delivered'] ?? false,
      deliveredAt: json['delivered_at'],
      createdAt: json['created_at'],
      file: json['file'] != null ? ChatFile.fromJson(json['file']) : null,
      voiceDuration: json['voice_duration'],
    );
  }

  bool get isFromMe => senderType == 'customer';
  bool get isText => messageType == 'text';
  bool get isImage => messageType == 'image';
  bool get isFile => messageType == 'file';
  bool get isVoice => messageType == 'voice';
  bool get isVideo => messageType == 'video';

  String getDisplayMessage() {
    if (content != null && content!.isNotEmpty) {
      return content!;
    }
    switch (messageType) {
      case 'image':
        return '📷 Image';
      case 'video':
        return '🎬 Video';
      case 'voice':
        return '🎤 Voice message';
      case 'file':
        return '📎 ${file?.name ?? 'File'}';
      default:
        return 'Message';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'sender_id': senderId,
      'sender_name': senderName,
      'sender_type': senderType,
      'receiver_id': receiverId,
      'message_type': messageType,
      'content': content,
      'is_read': isRead,
      'read_at': readAt,
      'is_delivered': isDelivered,
      'delivered_at': deliveredAt,
      'created_at': createdAt,
      'file': file?.toJson(),
      'voice_duration': voiceDuration,
    };
  }

  ChatMessage copyWith({
    int? id,
    int? conversationId,
    int? senderId,
    String? senderName,
    String? senderType,
    int? receiverId,
    String? messageType,
    String? content,
    bool? isRead,
    String? readAt,
    bool? isDelivered,
    String? deliveredAt,
    String? createdAt,
    ChatFile? file,
    int? voiceDuration,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderType: senderType ?? this.senderType,
      receiverId: receiverId ?? this.receiverId,
      messageType: messageType ?? this.messageType,
      content: content ?? this.content,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      isDelivered: isDelivered ?? this.isDelivered,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      createdAt: createdAt ?? this.createdAt,
      file: file ?? this.file,
      voiceDuration: voiceDuration ?? this.voiceDuration,
    );
  }
}

class ChatFile {
  final String? url;
  final String? name;
  final int? size;
  final String? mimeType;
  final String? extension;
  final String? thumbnailUrl;

  ChatFile({
    this.url,
    this.name,
    this.size,
    this.mimeType,
    this.extension,
    this.thumbnailUrl,
  });

  factory ChatFile.fromJson(Map<String, dynamic> json) {
    return ChatFile(
      url: json['url'] ?? json['file_url'],
      name: json['name'] ?? json['file_name'],
      size: json['size'] ?? json['file_size'],
      mimeType: json['mime_type'] ?? json['file_mime_type'],
      extension: json['extension'] ?? json['file_extension'],
      thumbnailUrl: json['thumbnail_url'] ?? json['thumbnail_path'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'name': name,
      'size': size,
      'mime_type': mimeType,
      'extension': extension,
      'thumbnail_url': thumbnailUrl,
    };
  }

  bool get isImage {
    return mimeType?.startsWith('image/') ?? false;
  }

  bool get isVideo {
    return mimeType?.startsWith('video/') ?? false;
  }

  bool get isAudio {
    return mimeType?.startsWith('audio/') ?? false;
  }

  String get formattedSize {
    if (size == null) return '';
    if (size! < 1024) return '$size B';
    if (size! < 1024 * 1024) return '${(size! / 1024).toStringAsFixed(1)} KB';
    return '${(size! / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}