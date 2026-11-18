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
  final String? userRole;
  final bool isPinned;
  final bool isArchived;
  final bool hasNewPost;
  final int? technicianId;

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
    this.isPinned = false,
    this.isArchived = false,
    this.hasNewPost = false,
    this.technicianId,
  });

  // ── FIXED: Restored the missing fromJson factory ──
  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    final other = json['other_party'] is Map
        ? ChatUser.fromJson(Map<String, dynamic>.from(json['other_party'] as Map))
        : const ChatUser(id: 0, name: 'Unknown', email: '');

    final rawLast = json['last_message'] ?? json['last_message_formatted'];

    return ChatConversation(
      id: _toInt(json['id']),
      customerId: _toInt(json['customer_id']),
      fundiId: _toInt(json['fundi_id']),
      otherParty: other,
      lastMessage: rawLast is Map
          ? ChatMessage.fromJson(Map<String, dynamic>.from(rawLast))
          : null,
      unreadCount: _toInt(json['unread_count'] ?? json['unread_messages_count']),
      lastMessageAt: json['last_message_at']?.toString(),
      isActive: json['is_active'] != false,
      userRole: json['user_role']?.toString(),
      isPinned: json['is_pinned'] == true,
      isArchived: json['is_archived'] == true,
      hasNewPost: json['has_new_post'] == true,
      technicianId: json['technician_id'] == null
          ? (other.id != 0 ? other.id : null)
          : int.tryParse(json['technician_id'].toString()),
    );
  }

  bool get isRead => unreadCount == 0 && lastMessage?.isRead == true;

  String getLastMessageDisplay() =>
      lastMessage?.getDisplayMessage() ?? 'No messages yet';

  String getFormattedLastMessageTime() {
    if (lastMessageAt == null) return '';
    final d = DateTime.tryParse(lastMessageAt!)?.toLocal();
    if (d == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = today.difference(DateTime(d.year, d.month, d.day)).inDays;
    String two(int n) => n.toString().padLeft(2, '0');
    if (days == 0) return '${two(d.hour)}:${two(d.minute)}';
    if (days == 1) return 'Yesterday';
    if (days < 7) return const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][d.weekday - 1];
    return '${two(d.day)}/${two(d.month)}/${d.year % 100}';
  }

  ChatConversation copyWith({
    int? unreadCount,
    bool? isPinned,
    bool? isArchived,
    bool? hasNewPost,
    ChatMessage? lastMessage,
    String? lastMessageAt,
  }) => ChatConversation(
    id: id,
    customerId: customerId,
    fundiId: fundiId,
    otherParty: otherParty,
    lastMessage: lastMessage ?? this.lastMessage,
    unreadCount: unreadCount ?? this.unreadCount,
    lastMessageAt: lastMessageAt ?? this.lastMessageAt,
    isActive: isActive,
    userRole: userRole,
    isPinned: isPinned ?? this.isPinned,
    isArchived: isArchived ?? this.isArchived,
    hasNewPost: hasNewPost ?? this.hasNewPost,
    technicianId: technicianId,
  );

  static int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }
}