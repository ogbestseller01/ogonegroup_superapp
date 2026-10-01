// lib/models/privacy_policy.dart

class PrivacyPolicy {
  final int id;
  final String content;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PrivacyPolicy({
    required this.id,
    required this.content,
    this.createdAt,
    this.updatedAt,
  });

  factory PrivacyPolicy.fromJson(Map<String, dynamic> json) {
    return PrivacyPolicy(
      id: json['id'] ?? 0,
      content: json['content'] ?? '',
      // ✅ Safe parsing: check for null before using DateTime.parse
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}