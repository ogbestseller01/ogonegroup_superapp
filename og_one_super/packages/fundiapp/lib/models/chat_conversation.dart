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
  });

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    final customer = json['customer'] != null ? ChatUser.fromJson(json['customer']) : null;
    final fundi = json['fundi'] != null ? ChatUser.fromJson(json['fundi']) : null;

    ChatUser otherParty;
    if (json['other_party'] != null) {
      otherParty = ChatUser.fromJson(json['other_party']);
    } else if (json['user_role'] == 'customer' && fundi != null) {
      otherParty = fundi;
    } else if (customer != null) {
      otherParty = customer;
    } else {
      otherParty = ChatUser(id: 0, name: 'Unknown', email: '');
    }

    ChatMessage? lastMessage;
    if (json['last_message_formatted'] != null) {
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
      unreadCount: json['unread_messages_count'] ?? 0,
      lastMessageAt: json['last_message_at'],
      isActive: json['is_active'] ?? true,
    );
  }
}