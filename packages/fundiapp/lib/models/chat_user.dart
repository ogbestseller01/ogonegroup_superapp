// lib/models/chat_user.dart

class ChatUser {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? avatar;
  final bool isOnline;
  final String? lastSeen;
  final String? fcmToken;

  ChatUser({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.avatar,
    this.isOnline = false,
    this.lastSeen,
    this.fcmToken,
  });

  factory ChatUser.fromJson(Map<String, dynamic> json) {
    return ChatUser(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      avatar: json['profile_photo'] ?? json['avatar'],
      isOnline: json['is_online'] ?? false,
      lastSeen: json['last_seen'] ?? json['last_login_at'],
      fcmToken: json['fcm_device_token'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'profile_photo': avatar,
      'is_online': isOnline,
      'last_login_at': lastSeen,
      'fcm_device_token': fcmToken,
    };
  }
}