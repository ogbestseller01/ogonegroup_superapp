// lib/models/system_update.dart

class SystemUpdate {
  final int id;
  final String title;
  final String description;
  final DateTime? publishedAt;

  const SystemUpdate({
    required this.id,
    required this.title,
    required this.description,
    this.publishedAt,
  });

  factory SystemUpdate.fromJson(Map<String, dynamic> json) => SystemUpdate(
    id: int.tryParse('${json['id']}') ?? 0,
    title: (json['title'] ?? '').toString().trim(),
    description: (json['description'] ?? '').toString().trim(),
    publishedAt: DateTime.tryParse('${json['published_at'] ?? ''}'),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'published_at': publishedAt?.toIso8601String(),
  };

  @override
  bool operator ==(Object other) => other is SystemUpdate && other.id == id;

  @override
  int get hashCode => id.hashCode;
}