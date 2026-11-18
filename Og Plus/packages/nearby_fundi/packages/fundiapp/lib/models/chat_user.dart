// lib/models/chat_user.dart
class ChatUser {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? avatar;
  final bool isOnline;
  final String? lastSeen;

  const ChatUser({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.avatar,
    this.isOnline = false,
    this.lastSeen,
  });

  factory ChatUser.fromJson(Map<String, dynamic> json) {
    return ChatUser(
      id: _toInt(json['id']),
      name: json['name']?.toString() ?? 'Unknown',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString(),
      avatar: (json['profile_photo'] ?? json['avatar'])?.toString(),
      isOnline: json['is_online'] == true,
      lastSeen: (json['last_seen'] ?? json['last_login_at'])?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'profile_photo': avatar,
    'is_online': isOnline,
    'last_seen': lastSeen,
  };

  ChatUser copyWith({String? avatar, bool? isOnline, String? lastSeen}) => ChatUser(
    id: id,
    name: name,
    email: email,
    phone: phone,
    avatar: avatar ?? this.avatar,
    isOnline: isOnline ?? this.isOnline,
    lastSeen: lastSeen ?? this.lastSeen,
  );

  static int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }
}