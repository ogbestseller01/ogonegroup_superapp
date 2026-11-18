class Comment {
  final int id;
  final String comment;
  final String userName;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.comment,
    required this.userName,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] ?? 0,
      comment: json['comment'] ?? '',
      userName: json['user']?['name'] ?? 'Anonymous',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}