class PortfolioImage {
  final int id;
  final String url;

  PortfolioImage({
    required this.id,
    required this.url,
  });

  factory PortfolioImage.fromJson(Map<String, dynamic> json) {
    return PortfolioImage(
      id: json['id'] ?? 0,
      url: json['url'] ?? '',
    );
  }
}

class PortfolioItem {
  final int id;
  final List<PortfolioImage> images;
  final DateTime? createdAt;

  PortfolioItem({
    required this.id,
    required this.images,
    this.createdAt,
  });

  factory PortfolioItem.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;

    final rawImages = data['images'] as List? ?? [];
    final parsedImages = rawImages
        .map((img) => PortfolioImage.fromJson(img))
        .toList();

    return PortfolioItem(
      id: data['id'] ?? 0,
      images: parsedImages,
      createdAt: data['created_at'] != null
          ? DateTime.parse(data['created_at'])
          : null,
    );
  }
}