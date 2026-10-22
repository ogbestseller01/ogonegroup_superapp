class MiniApp {
  final int id;
  final String slug;
  final String name;
  final String subtitle;
  final String icon; // fallback icon name
  final String color;
  final bool isComingSoon;
  final String? imageAsset; // 3D icon

  const MiniApp({
    required this.id,
    required this.slug,
    required this.name,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.isComingSoon = false,
    this.imageAsset,
  });

  /// Server can change labels and the "coming soon" flag.
  /// Icon, colour and image stay local because they are compiled in.
  MiniApp copyWith({
    String? name,
    String? subtitle,
    bool? isComingSoon,
  }) {
    return MiniApp(
      id: id,
      slug: slug,
      name: name ?? this.name,
      subtitle: subtitle ?? this.subtitle,
      icon: icon,
      color: color,
      isComingSoon: isComingSoon ?? this.isComingSoon,
      imageAsset: imageAsset,
    );
  }
}