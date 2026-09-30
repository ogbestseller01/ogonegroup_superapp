// lib/models/user.dart

class User {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? locale;
  final String? profilePhoto;
  final String token;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.locale,
    this.profilePhoto,
    required this.token,
  });

  factory User.fromJson(Map<String, dynamic> json, String token) {
    return User(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      locale: json['locale'] ?? 'en',
      profilePhoto: json['profile_photo'] ?? json['avatar'] ?? json['profile_image'],
      token: token,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'locale': locale,
    'profile_photo': profilePhoto,
  };

  User copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    String? locale,
    String? profilePhoto,
    String? token,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      locale: locale ?? this.locale,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      token: token ?? this.token,
    );
  }
}