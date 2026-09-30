// models/technician.dart
class TechnicianService {
  final int id;
  final String name;

  TechnicianService({required this.id, required this.name});

  factory TechnicianService.fromJson(Map<String, dynamic> json) => TechnicianService(
    id: json['id'] ?? 0,
    name: json['name'] ?? '',
  );

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}

class PortfolioItem {
  final int id;
  final String image;
  final String? description;
  final String? createdAt;
  final String? instagram;
  final String? facebook;
  final String? tiktok;
  final String? twitter;
  final String? telegram;

  PortfolioItem({
    required this.id,
    required this.image,
    this.description,
    this.createdAt,
    this.instagram,
    this.facebook,
    this.tiktok,
    this.twitter,
    this.telegram,
  });

  factory PortfolioItem.fromJson(Map<String, dynamic> json) {
    final socialLinks = json['social_links'] as Map<String, dynamic>?;

    return PortfolioItem(
      id: json['id'] ?? 0,
      image: json['image'] ?? '',
      description: json['description'],
      createdAt: json['created_at'],
      instagram: socialLinks?['instagram'] ?? json['instagram'],
      facebook: socialLinks?['facebook'] ?? json['facebook'],
      tiktok: socialLinks?['tiktok'] ?? json['tiktok'],
      twitter: socialLinks?['twitter'] ?? json['twitter'],
      telegram: socialLinks?['telegram'] ?? json['telegram'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'image': image,
    'description': description,
    'created_at': createdAt,
    'instagram': instagram,
    'facebook': facebook,
    'tiktok': tiktok,
    'twitter': twitter,
    'telegram': telegram,
  };

  bool get hasSocialLinks {
    return instagram != null ||
        facebook != null ||
        tiktok != null ||
        twitter != null ||
        telegram != null;
  }
}

// NEW: PriceRange
class PriceRange {
  final double min;
  final double max;
  PriceRange({required this.min, required this.max});

  factory PriceRange.fromJson(Map<String, dynamic> json) => PriceRange(
    min: (json['min'] as num?)?.toDouble() ?? 0,
    max: (json['max'] as num?)?.toDouble() ?? 0,
  );

  Map<String, dynamic> toJson() => {'min': min, 'max': max};
}

// NEW: ServicePrice
class ServicePrice {
  final int id;
  final String name;
  final double minPrice;
  final double maxPrice;

  ServicePrice({required this.id, required this.name, required this.minPrice, required this.maxPrice});

  factory ServicePrice.fromJson(Map<String, dynamic> json) => ServicePrice(
    id: json['id'] ?? 0,
    name: json['name'] ?? '',
    minPrice: (json['min_price'] as num?)?.toDouble() ?? 0,
    maxPrice: (json['max_price'] as num?)?.toDouble() ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'min_price': minPrice,
    'max_price': maxPrice,
  };
}

class Technician {
  final int id;
  final int userId;
  final String name;
  final String? email;
  final String? phone;
  final String? profilePhoto;
  final String? bio;
  final int experience;
  final double rating;
  final double? hourlyRate;
  final double distanceKm;
  final String? area;
  final double? latitude;
  final double? longitude;
  final bool isOnline;
  final bool verified;
  final List<String> services;
  final List<TechnicianService> serviceObjects;
  final List<PortfolioItem> portfolios;

  // NEW FIELDS
  final int completedJobsCount;
  final PriceRange? priceRange;
  final List<ServicePrice> servicePrices;

  Technician({
    required this.id,
    this.userId = 0,
    required this.name,
    this.email,
    this.phone,
    this.profilePhoto,
    this.bio,
    this.experience = 0,
    this.rating = 0.0,
    this.hourlyRate,
    this.distanceKm = 0.0,
    this.area,
    this.latitude,
    this.longitude,
    this.isOnline = false,
    this.verified = false,
    this.services = const [],
    this.serviceObjects = const [],
    this.portfolios = const [],
    this.completedJobsCount = 0,
    this.priceRange,
    this.servicePrices = const [],
  });

  factory Technician.fromJson(Map<String, dynamic> json, {bool isDetail = false}) {
    Map<String, dynamic> safeCast(Map<dynamic, dynamic> map) {
      return Map<String, dynamic>.from(map);
    }

    List<Map<String, dynamic>> safeCastList(List<dynamic> list) {
      return list.map((item) {
        if (item is Map<dynamic, dynamic>) {
          return Map<String, dynamic>.from(item);
        } else if (item is Map<String, dynamic>) {
          return item;
        } else {
          return <String, dynamic>{};
        }
      }).where((item) => item.isNotEmpty).toList();
    }

    Map<String, dynamic> data = json;

    if (json['technician'] != null && json['technician'] is Map) {
      data = json['technician'] is Map<dynamic, dynamic>
          ? Map<String, dynamic>.from(json['technician'] as Map<dynamic, dynamic>)
          : json['technician'] as Map<String, dynamic>;
    } else if (json['data'] != null && json['data'] is Map) {
      data = json['data'] is Map<dynamic, dynamic>
          ? Map<String, dynamic>.from(json['data'] as Map<dynamic, dynamic>)
          : json['data'] as Map<String, dynamic>;
    }

    Map<String, dynamic>? user;
    if (data['user'] != null && data['user'] is Map) {
      user = data['user'] is Map<dynamic, dynamic>
          ? Map<String, dynamic>.from(data['user'] as Map<dynamic, dynamic>)
          : data['user'] as Map<String, dynamic>;
    }

    Map<String, dynamic>? tech;
    if (data['technician'] != null && data['technician'] is Map) {
      tech = data['technician'] is Map<dynamic, dynamic>
          ? Map<String, dynamic>.from(data['technician'] as Map<dynamic, dynamic>)
          : data['technician'] as Map<String, dynamic>;
    }

    String name = data['name'] ?? '';
    if (name.isEmpty && user != null) name = user['name'] ?? '';
    if (name.isEmpty && tech != null) name = tech['name'] ?? '';
    if (name.isEmpty) name = 'Unknown';

    String? email = data['email'] ?? user?['email'] ?? tech?['email'];
    String? phone = data['phone'] ?? user?['phone'] ?? tech?['phone'];

    int userId = data['user_id'] ?? 0;
    if (userId == 0 && user != null) userId = user['id'] ?? 0;
    if (userId == 0 && tech != null) userId = tech['user_id'] ?? 0;

    // Parse services
    List<String> serviceNames = [];
    List<TechnicianService> serviceObjs = [];

    dynamic servicesData = data['services'] ?? tech?['services'] ?? user?['services'] ?? data['service_objects'];

    if (servicesData is List) {
      if (servicesData.isNotEmpty) {
        if (servicesData.first is Map) {
          final safeList = safeCastList(servicesData);
          serviceObjs = safeList.map((e) => TechnicianService.fromJson(e)).toList();
          serviceNames = serviceObjs.map((s) => s.name).toList();
        } else if (servicesData.first is String) {
          serviceNames = servicesData.whereType<String>().toList();
          serviceObjs = serviceNames.asMap().entries.map((entry) {
            return TechnicianService(id: entry.key + 1, name: entry.value);
          }).toList();
        }
      }
    } else if (servicesData is Map) {
      try {
        final serviceMap = servicesData is Map<dynamic, dynamic>
            ? Map<String, dynamic>.from(servicesData)
            : servicesData as Map<String, dynamic>;
        final serviceObj = TechnicianService.fromJson(serviceMap);
        serviceObjs = [serviceObj];
        serviceNames = [serviceObj.name];
      } catch (_) {}
    }

    if (serviceObjs.isEmpty && json['services'] != null) {
      final origServices = json['services'];
      if (origServices is List && origServices.isNotEmpty && origServices.first is Map) {
        final safeList = safeCastList(origServices);
        serviceObjs = safeList.map((e) => TechnicianService.fromJson(e)).toList();
        serviceNames = serviceObjs.map((s) => s.name).toList();
      }
    }

    // Parse portfolios
    List<PortfolioItem> portfolios = [];
    if (isDetail) {
      dynamic portfoliosData = data['portfolios'] ?? tech?['portfolios'];
      if (portfoliosData != null && portfoliosData is List) {
        final safeList = safeCastList(portfoliosData);
        portfolios = safeList.map((e) => PortfolioItem.fromJson(e)).toList();
      }
    }

    // ─── NEW: Parse price_range and service_prices ──────────────────
    PriceRange? priceRange;
    if (data['price_range'] != null && data['price_range'] is Map) {
      final pr = data['price_range'] as Map<dynamic, dynamic>;
      final min = (pr['min'] as num?)?.toDouble() ?? 0;
      final max = (pr['max'] as num?)?.toDouble() ?? 0;
      if (min > 0 || max > 0) {
        priceRange = PriceRange(min: min, max: max);
      }
    }

    List<ServicePrice> servicePrices = [];
    if (data['service_prices'] != null && data['service_prices'] is List) {
      final spList = data['service_prices'] as List;
      servicePrices = spList.map((sp) => ServicePrice.fromJson(sp)).toList();
    }

    // ─── Parse completed_jobs_count ──────────────────────────────────
    int completedJobs = 0;
    if (data['completed_jobs_count'] != null) {
      completedJobs = (data['completed_jobs_count'] as num).toInt();
    }
    // ────────────────────────────────────────────────────────────────

    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0.0;
    }

    double? parseNullableDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString());
    }

    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toInt();
      return int.tryParse(value.toString()) ?? 0;
    }

    String? profilePhoto = data['profile_photo'] ?? tech?['profile_photo'];
    String? bio = data['bio'] ?? tech?['bio'];
    String? area = data['area'] ?? tech?['area'];
    double? latitude = parseNullableDouble(data['latitude'] ?? tech?['latitude']);
    double? longitude = parseNullableDouble(data['longitude'] ?? tech?['longitude']);
    double? hourlyRate = parseNullableDouble(data['hourly_rate'] ?? tech?['hourly_rate']);
    int experience = parseInt(data['experience'] ?? tech?['experience']);
    double rating = parseDouble(data['rating'] ?? tech?['rating']);
    bool isOnline = data['is_online'] ?? tech?['is_online'] ?? false;
    bool verified = data['verified'] ?? tech?['verified'] ?? false;

    return Technician(
      id: data['id'] ?? tech?['id'] ?? json['id'] ?? 0,
      userId: userId,
      name: name,
      email: email,
      phone: phone,
      profilePhoto: profilePhoto,
      bio: bio,
      experience: experience,
      rating: rating,
      hourlyRate: hourlyRate,
      distanceKm: parseDouble(data['distance'] ?? data['distance_km'] ?? 0.0),
      area: area,
      latitude: latitude,
      longitude: longitude,
      isOnline: isOnline,
      verified: verified,
      services: serviceNames,
      serviceObjects: serviceObjs,
      portfolios: portfolios,
      completedJobsCount: completedJobs,
      priceRange: priceRange,
      servicePrices: servicePrices,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'name': name,
    'email': email,
    'phone': phone,
    'profile_photo': profilePhoto,
    'bio': bio,
    'experience': experience,
    'rating': rating,
    'hourly_rate': hourlyRate,
    'distance_km': distanceKm,
    'area': area,
    'latitude': latitude,
    'longitude': longitude,
    'is_online': isOnline,
    'verified': verified,
    'services': services,
    'service_objects': serviceObjects.map((s) => s.toJson()).toList(),
    'portfolios': portfolios.map((p) => p.toJson()).toList(),
    'completed_jobs_count': completedJobsCount,
    'price_range': priceRange?.toJson(),
    'service_prices': servicePrices.map((sp) => sp.toJson()).toList(),
  };
}