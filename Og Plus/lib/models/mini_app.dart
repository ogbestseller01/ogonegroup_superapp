
class MiniApp {
  final int id;
  final String slug;
  final String name;
  final String subtitle;
  final String icon;
  final String color;
  final bool isComingSoon;
  final bool isDemo;
  final String? imageAsset;

  const MiniApp({
    required this.id,
    required this.slug,
    required this.name,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.isComingSoon = false,
    this.isDemo = false,
    this.imageAsset,
  });

  /// Creates a copy while preserving unchanged properties.
  MiniApp copyWith({
    int? id,
    String? slug,
    String? name,
    String? subtitle,
    String? icon,
    String? color,
    bool? isComingSoon,
    bool? isDemo,
    String? imageAsset,
  }) {
    return MiniApp(
      id: id ?? this.id,
      slug: slug ?? this.slug,
      name: name ?? this.name,
      subtitle: subtitle ?? this.subtitle,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isComingSoon: isComingSoon ?? this.isComingSoon,
      isDemo: isDemo ?? this.isDemo,
      imageAsset: imageAsset ?? this.imageAsset,
    );
  }
}
