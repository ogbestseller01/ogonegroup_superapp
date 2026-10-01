// lib/models/user.dart
class User {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? nida;
  final String locale;
  final String token;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.nida,
    this.locale = 'en',
    required this.token,
  });

  factory User.fromJson(Map<String, dynamic> json, String token) {
    return User(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      nida: json['nida'],
      locale: json['locale'] ?? 'en',
      token: token,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'nida': nida,
      'locale': locale,
      'token': token,
    };
  }
}