class PortfolioItem {
  final int id;
  final String image;
  final String? description;
  final DateTime? createdAt;

  PortfolioItem({
    required this.id,
    required this.image,
    this.description,
    this.createdAt,
  });

  factory PortfolioItem.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    return PortfolioItem(
      id: data['id'] ?? 0,
      image: data['image'] ?? '',
      description: data['description'],
      createdAt: data['created_at'] != null
          ? DateTime.parse(data['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'image': image,
    'description': description,
    'created_at': createdAt?.toIso8601String(),
  };
}