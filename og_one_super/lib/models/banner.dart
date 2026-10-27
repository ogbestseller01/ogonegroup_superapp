class BannerItem {
  final String image;
  final String? link;

  const BannerItem({
    required this.image,
    this.link,
  });

  factory BannerItem.fromJson(Map<String, dynamic> json) {
    return BannerItem(
      image: (json['image'] ?? '').toString(),
      link: json['link']?.toString(),
    );
  }

  bool get hasLink => link != null && link!.trim().isNotEmpty;
}