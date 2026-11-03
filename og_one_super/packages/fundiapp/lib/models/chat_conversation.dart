// lib/models/chat_conversation.dart
import 'chat_message.dart';
import 'chat_user.dart';

class ChatConversation {
  final int id;
  final int customerId;
  final int fundiId;
  final ChatUser otherParty;
  final ChatMessage? lastMessage;
  final int unreadCount;
  final String? lastMessageAt;
  final bool isActive;
  final String? userRole; // 'customer' | 'fundi'

  const ChatConversation({
    required this.id,
    required this.customerId,
    required this.fundiId,
    required this.otherParty,
    this.lastMessage,
    this.unreadCount = 0,
    this.lastMessageAt,
    this.isActive = true,
    this.userRole,
  });

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    ChatUser otherParty;
    if (json['other_party'] != null) {
      otherParty = ChatUser.fromJson(
        Map<String, dynamic>.from(json['other_party']),
      );
    } else {
      otherParty = const ChatUser(id: 0, name: 'Unknown', email: '');
    }

    ChatMessage? lastMessage;
    if (json['last_message'] != null) {
      lastMessage = ChatMessage.fromJson(
        Map<String, dynamic>.from(json['last_message']),
      );
    }

    return ChatConversation(
      id: _toInt(json['id']),
      customerId: _toInt(json['customer_id']),
      fundiId: _toInt(json['fundi_id']),
      otherParty: otherParty,
      lastMessage: lastMessage,
      unreadCount: _toInt(json['unread_count'] ?? json['unread_messages_count']),
      lastMessageAt: json['last_message_at']?.toString(),
      isActive: json['is_active'] != false,
      userRole: json['user_role']?.toString(),
    );
  }

  String getLastMessageDisplay() {
    return lastMessage?.getDisplayMessage() ?? 'No messages yet';
  }

  String getFormattedLastMessageTime() {
    if (lastMessageAt == null) return '';
    try {
      final dateTime = DateTime.parse(lastMessageAt!).toLocal();
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays > 7) {
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      } else if (difference.inDays > 0) {
        return '${difference.inDays}d';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m';
      }
      return 'Just now';
    } catch (_) {
      return '';
    }
  }

  /// This is the method that was missing
  ChatConversation copyWith({
    int? id,
    int? customerId,
    int? fundiId,
    ChatUser? otherParty,
    ChatMessage? lastMessage,
    int? unreadCount,
    String? lastMessageAt,
    bool? isActive,
    String? userRole,
  }) {
    return ChatConversation(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      fundiId: fundiId ?? this.fundiId,
      otherParty: otherParty ?? this.otherParty,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      isActive: isActive ?? this.isActive,
      userRole: userRole ?? this.userRole,
    );
  }

  static int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }
}