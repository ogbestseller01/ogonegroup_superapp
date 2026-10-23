// lib/models/service.dart

class ServiceCategory {
  final int id;
  final String name;
  final String swahiliName;
  final String slug;

  ServiceCategory({
    required this.id,
    required this.name,
    this.swahiliName = '',
    this.slug = '',
  });

  factory ServiceCategory.fromJson(Map<String, dynamic> json) {
    return ServiceCategory(
      id: json['id'] ?? json['service_categoryID'] ?? 0,
      name: json['name'] ?? json['category_name'] ?? '',
      swahiliName: json['swahili_name'] ?? '',
      slug: json['slug'] ?? '',
    );
  }

  String localizedName(String locale) {
    if (locale == 'sw' && swahiliName.isNotEmpty) return swahiliName;
    return name;
  }
}

class Service {
  final int id;
  final String name;        // English
  final String swahiliName; // Swahili
  final List<ServiceCategory> categories;

  Service({
    required this.id,
    required this.name,
    this.swahiliName = '',
    this.categories = const [],
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    List<ServiceCategory> categories = [];
    if (json['categories'] != null && json['categories'] is List) {
      categories = (json['categories'] as List)
          .map((e) => ServiceCategory.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return Service(
      id: json['id'] ?? 0,
      // Prefer name_en if API sends it, else name
      name: json['name_en'] ?? json['name'] ?? '',
      swahiliName: json['name_sw'] ?? json['swahili_name'] ?? '',
      categories: categories,
    );
  }

  /// Returns the name for the given locale ('en' or 'sw').
  /// Falls back to English if Swahili is empty.
  String localizedName(String locale) {
    if (locale == 'sw' && swahiliName.isNotEmpty) return swahiliName;
    return name;
  }
}