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

  /// Correct ownership check – use current user id
  bool isFromMe(int currentUserId) => senderId == currentUserId;

  bool get isText => messageType == 'text';
  bool get isImage => messageType == 'image';
  bool get isFile => messageType == 'file';
  bool get isVoice => messageType == 'voice';
  bool get isVideo => messageType == 'video';
}

class ChatFile {
  final String? url;
  final String? name;
  final int? size;
  final String? mimeType;
  final String? extension;

  ChatFile({this.url, this.name, this.size, this.mimeType, this.extension});

  factory ChatFile.fromJson(Map<String, dynamic> json) {
    return ChatFile(
      url: json['url'] ?? json['file_url'],
      name: json['name'] ?? json['file_name'],
      size: json['size'] ?? json['file_size'],
      mimeType: json['mime_type'] ?? json['file_mime_type'],
      extension: json['extension'] ?? json['file_extension'],
    );
  }
}