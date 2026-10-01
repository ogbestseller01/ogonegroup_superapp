class About {
  final int id;
  final String content;
  final DateTime? updatedAt;

  About({required this.id, required this.content, this.updatedAt});

  factory About.fromJson(Map<String, dynamic> json) => About(
    id: json['id'] ?? 0,
    content: json['content'] ?? '',
    updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
  );
}