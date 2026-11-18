class PrivacyPolicy {
  final int id;
  final String content;
  final DateTime? updatedAt;

  PrivacyPolicy({required this.id, required this.content, this.updatedAt});

  factory PrivacyPolicy.fromJson(Map<String, dynamic> json) => PrivacyPolicy(
    id: json['id'] ?? 0,
    content: json['content'] ?? '',
    updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
  );
}