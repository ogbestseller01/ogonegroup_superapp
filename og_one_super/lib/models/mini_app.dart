class MiniApp {
  final int id;
  final String slug;
  final String name;
  final String subtitle;
  final String icon; // Kept for fallback
  final String color;
  final bool isComingSoon;
  final String? imageAsset; // New field for 3D icons

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
}