class Term {
  final int id;
  final String content;
  final DateTime? updatedAt;

  Term({required this.id, required this.content, this.updatedAt});

  factory Term.fromJson(Map<String, dynamic> json) => Term(
    id: json['id'] ?? 0,
    content: json['content'] ?? '',
    updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
  );
}