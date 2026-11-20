// lib/models/service.dart

class ServiceCategory {
  final int id;
  final String name;
  final String swahiliName;
  final String slug;

  const ServiceCategory({
    required this.id,
    required this.name,
    this.swahiliName = '',
    this.slug = '',
  });

  factory ServiceCategory.fromJson(Map<String, dynamic> json) {
    return ServiceCategory(
      id: _toInt(json['id'] ?? json['service_categoryID']),
      name: (json['name'] ?? json['category_name'])?.toString() ?? '',
      swahiliName: json['swahili_name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'swahili_name': swahiliName,
    'slug': slug,
  };

  String localizedName(String locale) {
    if (locale == 'sw' && swahiliName.isNotEmpty) return swahiliName;
    return name;
  }

  static int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? 0;
  }
}

class Service {
  final int id;
  final String name;        // English
  final String swahiliName; // Swahili
  final List<ServiceCategory> categories;

  const Service({
    required this.id,
    required this.name,
    this.swahiliName = '',
    this.categories = const [],
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    final rawCategories = json['categories'];
    final categories = rawCategories is List
        ? rawCategories
        .whereType<Map>()
        .map((e) => ServiceCategory.fromJson(Map<String, dynamic>.from(e)))
        .toList(growable: false)
        : const <ServiceCategory>[];

    return Service(
      id: _toInt(json['id']),
      // Prefer name_en if API sends it, else name
      name: (json['name_en'] ?? json['name'])?.toString() ?? '',
      // Prefer name_sw if API sends it, else swahili_name
      swahiliName: (json['name_sw'] ?? json['swahili_name'])?.toString() ?? '',
      categories: categories,
    );
  }

  /// Serialize back to JSON. Writes both naming conventions so a round-trip
  /// through `toJson()` → `fromJson()` is lossless regardless of which one
  /// the server uses.
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'name_en': name,
    'swahili_name': swahiliName,
    'name_sw': swahiliName,
    'categories': categories.map((c) => c.toJson()).toList(),
  };

  /// Returns the name for the given locale ('en' or 'sw').
  /// Falls back to English if Swahili is empty.
  String localizedName(String locale) {
    if (locale == 'sw' && swahiliName.isNotEmpty) return swahiliName;
    return name;
  }

  static int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? 0;
  }
}