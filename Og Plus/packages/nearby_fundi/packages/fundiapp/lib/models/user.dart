// lib/models/user.dart

class User {
  final int id;
  final String name;
  final String? email;
  final String? phone;
  final String? nida;
  final String locale;

  /// 'pending' | 'active' | 'suspended' | 'inactive'
  final String status;

  /// Backend flag: true after admin approval.
  final bool isActive;

  /// Absolute URL of the profile photo (technician photo or Google avatar).
  final String? profilePhoto;

  /// Bearer token (only present after login). Never written to stored JSON.
  final String? token;

  const User({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.nida,
    this.locale = 'en',
    this.status = 'pending',
    this.isActive = false,
    this.profilePhoto,
    this.token,
  });

  bool get isValid => id != 0;

  /// True while waiting for admin approval (post step-6, pre-approve).
  bool get isPendingApproval => status == 'pending' && !isActive;

  factory User.fromJson(Map<String, dynamic> json, [String? token]) {
    final rawToken = token ?? json['token']?.toString();
    final rawActive = json['is_active'];
    final rawPhoto =
    (json['profile_photo'] ?? json['avatar'] ?? json['profile_image'])
        ?.toString();

    return User(
      id: (json['id'] is int)
          ? json['id'] as int
          : int.tryParse('${json['id']}') ?? 0,
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      nida: json['nida']?.toString(),
      locale: json['locale']?.toString() ?? 'en',
      status: json['status']?.toString() ?? 'pending',
      isActive: rawActive == true || rawActive == 1 || rawActive == '1',
      profilePhoto:
      (rawPhoto != null && rawPhoto.isNotEmpty) ? rawPhoto : null,
      token: (rawToken != null && rawToken.isNotEmpty) ? rawToken : null,
    );
  }

  /// Profile only: the token lives in secure storage, not here.
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'nida': nida,
    'locale': locale,
    'status': status,
    'is_active': isActive,
    'profile_photo': profilePhoto,
  };

  User copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    String? nida,
    String? locale,
    String? status,
    bool? isActive,
    String? profilePhoto,
    bool clearProfilePhoto = false,
    String? token,
  }) =>
      User(
        id: id ?? this.id,
        name: name ?? this.name,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        nida: nida ?? this.nida,
        locale: locale ?? this.locale,
        status: status ?? this.status,
        isActive: isActive ?? this.isActive,
        profilePhoto:
        clearProfilePhoto ? null : (profilePhoto ?? this.profilePhoto),
        token: token ?? this.token,
      );
}