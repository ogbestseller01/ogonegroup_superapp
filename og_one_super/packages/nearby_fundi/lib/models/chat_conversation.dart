// lib/models/chat_conversation.dart

import 'chat_message.dart';
import 'chat_user.dart';

class ChatConversation {
  final int id;
  final int customerId;
  final int fundiId;
  final ChatUser? customer;
  final ChatUser? fundi;
  final ChatUser otherParty;
  final ChatMessage? lastMessage;
  final int unreadCount;
  final String? lastMessageAt;
  final bool isActive;
  final String? userRole;

  ChatConversation({
    required this.id,
    required this.customerId,
    required this.fundiId,
    this.customer,
    this.fundi,
    required this.otherParty,
    this.lastMessage,
    this.unreadCount = 0,
    this.lastMessageAt,
    this.isActive = true,
    this.userRole,
  });

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    final customer = json['customer'] != null
        ? ChatUser.fromJson(json['customer'])
        : null;
    final fundi = json['fundi'] != null
        ? ChatUser.fromJson(json['fundi'])
        : null;

    ChatUser otherParty;
    if (json['other_party'] != null) {
      otherParty = ChatUser.fromJson(json['other_party']);
    } else if (json['user_role'] == 'customer' && fundi != null) {
      otherParty = fundi;
    } else if (customer != null) {
      otherParty = customer;
    } else {
      otherParty = ChatUser(
        id: 0,
        name: 'Unknown User',
        email: '',
      );
    }

    ChatMessage? lastMessage;
    if (json['last_message'] != null) {
      lastMessage = ChatMessage.fromJson(json['last_message']);
    } else if (json['last_message_formatted'] != null) {
      lastMessage = ChatMessage.fromJson(json['last_message_formatted']);
    }

    return ChatConversation(
      id: json['id'] ?? 0,
      customerId: json['customer_id'] ?? 0,
      fundiId: json['fundi_id'] ?? 0,
      customer: customer,
      fundi: fundi,
      otherParty: otherParty,
      lastMessage: lastMessage,
      unreadCount: json['unread_messages_count'] ?? json['unread_count'] ?? 0,
      lastMessageAt: json['last_message_at'] ?? json['updated_at'],
      isActive: json['is_active'] ?? true,
      userRole: json['user_role'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'fundi_id': fundiId,
      'customer': customer?.toJson(),
      'fundi': fundi?.toJson(),
      'other_party': otherParty.toJson(),
      'last_message': lastMessage?.toJson(),
      'unread_count': unreadCount,
      'last_message_at': lastMessageAt,
      'is_active': isActive,
      'user_role': userRole,
    };
  }

  String getLastMessageDisplay() {
    if (lastMessage != null) {
      return lastMessage!.getDisplayMessage();
    }
    return 'No messages yet';
  }

  String getFormattedLastMessageTime() {
    if (lastMessageAt == null) return '';
    try {
      final dateTime = DateTime.parse(lastMessageAt!);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays > 7) {
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      } else if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (_) {
      return '';
    }
  }

  ChatConversation copyWith({
    int? id,
    int? customerId,
    int? fundiId,
    ChatUser? customer,
    ChatUser? fundi,
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
      customer: customer ?? this.customer,
      fundi: fundi ?? this.fundi,
      otherParty: otherParty ?? this.otherParty,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      isActive: isActive ?? this.isActive,
      userRole: userRole ?? this.userRole,
    );
  }
}