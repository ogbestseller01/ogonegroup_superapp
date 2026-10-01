// models/service.dart
class Service {
  final int id;
  final String name;
  final String? nameEn;
  final String? nameSw;
  final List<ServiceCategory>? categories;

  Service({
    required this.id,
    required this.name,
    this.nameEn,
    this.nameSw,
    this.categories,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    List<ServiceCategory>? categories;
    if (json['categories'] != null && json['categories'] is List) {
      categories = (json['categories'] as List)
          .map((e) => ServiceCategory.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return Service(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      nameEn: json['name_en'] ?? json['name'],
      nameSw: json['name_sw'],
      categories: categories,
    );
  }

  /// Get service name in the current locale
  String getDisplayName(String locale) {
    if (locale == 'sw' && nameSw != null && nameSw!.isNotEmpty) {
      return nameSw!;
    }
    return nameEn ?? name;
  }

  /// Check if service name matches search query (in both languages)
  bool matchesSearch(String query, String locale) {
    final lowerQuery = query.toLowerCase().trim();
    if (lowerQuery.isEmpty) return true;

    final nameLower = name.toLowerCase();
    final nameEnLower = nameEn?.toLowerCase() ?? '';
    final nameSwLower = nameSw?.toLowerCase() ?? '';

    return nameLower.contains(lowerQuery) ||
        nameEnLower.contains(lowerQuery) ||
        nameSwLower.contains(lowerQuery);
  }
}

class ServiceCategory {
  final int id;
  final String name;
  final String? nameEn;
  final String? nameSw;
  final String? slug;

  ServiceCategory({
    required this.id,
    required this.name,
    this.nameEn,
    this.nameSw,
    this.slug,
  });

  factory ServiceCategory.fromJson(Map<String, dynamic> json) {
    return ServiceCategory(
      id: json['id'] ?? json['service_categoryID'] ?? 0,
      name: json['name'] ?? json['category_name'] ?? '',
      nameEn: json['name_en'] ?? json['category_name'],
      nameSw: json['name_sw'],
      slug: json['slug'],
    );
  }

  /// Get category name in the current locale
  String getDisplayName(String locale) {
    if (locale == 'sw' && nameSw != null && nameSw!.isNotEmpty) {
      return nameSw!;
    }
    return nameEn ?? name;
  }

  /// Check if category name matches search query (in both languages)
  bool matchesSearch(String query, String locale) {
    final lowerQuery = query.toLowerCase().trim();
    if (lowerQuery.isEmpty) return true;

    final nameLower = name.toLowerCase();
    final nameEnLower = nameEn?.toLowerCase() ?? '';
    final nameSwLower = nameSw?.toLowerCase() ?? '';

    return nameLower.contains(lowerQuery) ||
        nameEnLower.contains(lowerQuery) ||
        nameSwLower.contains(lowerQuery);
  }
}