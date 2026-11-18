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
      name: json['name'] ?? 'Unknown User',
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

  ChatUser copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    String? avatar,
    bool? isOnline,
    String? lastSeen,
    String? fcmToken,
  }) {
    return ChatUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatar: avatar ?? this.avatar,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is ChatUser &&
              runtimeType == other.runtimeType &&
              id == other.id;

  @override
  int get hashCode => id.hashCode;
}