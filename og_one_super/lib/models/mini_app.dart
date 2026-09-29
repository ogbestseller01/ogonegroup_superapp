// lib/models/mini_app.dart

class MiniApp {
  final int id;
  final String slug;
  final String name;
  final String? subtitle;
  final String icon;
  final String color;
  final bool isComingSoon;

  const MiniApp({
    required this.id,
    required this.slug,
    required this.name,
    this.subtitle,
    required this.icon,
    required this.color,
    this.isComingSoon = false,
  });
}