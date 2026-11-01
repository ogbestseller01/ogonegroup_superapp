// lib/models/technician.dart

class TechnicianService {
  final int id;
  final String name;
  const TechnicianService({required this.id, required this.name});

  factory TechnicianService.fromJson(Map<String, dynamic> json) =>
      TechnicianService(
        id: _asInt(json['id']),
        name: json['name']?.toString() ?? '',
      );

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}

class PortfolioImage {
  final int id;
  final String url;
  const PortfolioImage({required this.id, required this.url});

  factory PortfolioImage.fromJson(Map<String, dynamic> json) => PortfolioImage(
    id: _asInt(json['id']),
    url: (json['url'] ?? json['image'] ?? '').toString(),
  );

  Map<String, dynamic> toJson() => {'id': id, 'url': url};
  bool get isValid => url.isNotEmpty;
}

class PortfolioItem {
  final int id;
  final List<PortfolioImage> images;
  final String? createdAt;

  const PortfolioItem({
    required this.id,
    required this.images,
    this.createdAt,
  });

  factory PortfolioItem.fromJson(Map<String, dynamic> json) {
    List<PortfolioImage> imgs = [];

    final raw = json['images'];
    if (raw is List && raw.isNotEmpty) {
      imgs = raw
          .whereType<Map>()
          .map((e) => PortfolioImage.fromJson(Map<String, dynamic>.from(e)))
          .where((i) => i.isValid)
          .toList();
    }

    if (imgs.isEmpty) {
      final single = (json['image'] ?? json['url'] ?? '').toString();
      if (single.isNotEmpty) {
        imgs = [PortfolioImage(id: _asInt(json['id']), url: single)];
      }
    }

    return PortfolioItem(
      id: _asInt(json['id']),
      images: imgs,
      createdAt: json['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'images': images.map((i) => i.toJson()).toList(),
    'created_at': createdAt,
  };

  String? get firstImage => images.isNotEmpty ? images.first.url : null;
  bool get hasMultipleImages => images.length > 1;
}

class PriceRange {
  final double min;
  final double max;
  const PriceRange({required this.min, required this.max});

  factory PriceRange.fromJson(Map<String, dynamic> json) => PriceRange(
    min: _asDouble(json['min']),
    max: _asDouble(json['max']),
  );

  Map<String, dynamic> toJson() => {'min': min, 'max': max};
}

class ServicePrice {
  final int id;
  final String name;
  final double minPrice;
  final double maxPrice;

  const ServicePrice({
    required this.id,
    required this.name,
    required this.minPrice,
    required this.maxPrice,
  });

  factory ServicePrice.fromJson(Map<String, dynamic> json) => ServicePrice(
    id: _asInt(json['id']),
    name: json['name']?.toString() ?? '',
    minPrice: _asDouble(json['min_price']),
    maxPrice: _asDouble(json['max_price']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'min_price': minPrice,
    'max_price': maxPrice,
  };
}

class CompletedJob {
  final int id;
  final String jobNumber;
  final String? status;
  final String? startedAt;
  final String? completedAt;
  final String? notes;
  final String? serviceName;

  const CompletedJob({
    required this.id,
    required this.jobNumber,
    this.status,
    this.startedAt,
    this.completedAt,
    this.notes,
    this.serviceName,
  });

  factory CompletedJob.fromJson(Map<String, dynamic> json) {
    String? serviceName;
    final request = json['request'];
    if (request is Map && request['service'] is Map) {
      serviceName = (request['service'] as Map)['name']?.toString();
    }
    return CompletedJob(
      id: _asInt(json['id']),
      jobNumber: json['job_number']?.toString() ?? '',
      status: json['status']?.toString(),
      startedAt: json['started_at']?.toString(),
      completedAt: json['completed_at']?.toString(),
      notes: json['notes']?.toString(),
      serviceName: serviceName,
    );
  }
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
  final List<TechnicianService> serviceObjects;
  final List<PortfolioItem> portfolios;

  final int completedJobsCount;
  final PriceRange? priceRange;
  final List<ServicePrice> servicePrices;

  final int requestsCount;
  final int postLikes;
  final int postComments;
  final int reviewsCount;
  final double rankScore;
  final int rankPosition;

  const Technician({
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
    required this.isOnline,
    required this.verified,
    this.serviceObjects = const [],
    this.portfolios = const [],
    this.completedJobsCount = 0,
    this.priceRange,
    this.servicePrices = const [],
    this.requestsCount = 0,
    this.postLikes = 0,
    this.postComments = 0,
    this.reviewsCount = 0,
    this.rankScore = 0.0,
    this.rankPosition = 0,
  });

  List<String> get services =>
      serviceObjects.map((s) => s.name).toList(growable: false);

  /// Comparator to sort technicians by rank (Highest score first, then lowest position).
  /// Usage: `technicians.sort(Technician.byRank);`
  static int byRank(Technician a, Technician b) {
    final scoreCmp = b.rankScore.compareTo(a.rankScore); // Descending
    if (scoreCmp != 0) return scoreCmp;

    // If scores are equal, higher rank position (lower number) is better
    return a.rankPosition.compareTo(b.rankPosition);
  }

  Technician copyWith({
    int? id,
    int? userId,
    String? name,
    String? email,
    String? phone,
    String? profilePhoto,
    String? bio,
    int? experience,
    double? rating,
    double? hourlyRate,
    double? distanceKm,
    String? area,
    double? latitude,
    double? longitude,
    bool? isOnline,
    bool? verified,
    List<TechnicianService>? serviceObjects,
    List<PortfolioItem>? portfolios,
    int? completedJobsCount,
    PriceRange? priceRange,
    List<ServicePrice>? servicePrices,
    int? requestsCount,
    int? postLikes,
    int? postComments,
    int? reviewsCount,
    double? rankScore,
    int? rankPosition,
  }) =>
      Technician(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        name: name ?? this.name,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        profilePhoto: profilePhoto ?? this.profilePhoto,
        bio: bio ?? this.bio,
        experience: experience ?? this.experience,
        rating: rating ?? this.rating,
        hourlyRate: hourlyRate ?? this.hourlyRate,
        distanceKm: distanceKm ?? this.distanceKm,
        area: area ?? this.area,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        isOnline: isOnline ?? this.isOnline,
        verified: verified ?? this.verified,
        serviceObjects: serviceObjects ?? this.serviceObjects,
        portfolios: portfolios ?? this.portfolios,
        completedJobsCount: completedJobsCount ?? this.completedJobsCount,
        priceRange: priceRange ?? this.priceRange,
        servicePrices: servicePrices ?? this.servicePrices,
        requestsCount: requestsCount ?? this.requestsCount,
        postLikes: postLikes ?? this.postLikes,
        postComments: postComments ?? this.postComments,
        reviewsCount: reviewsCount ?? this.reviewsCount,
        rankScore: rankScore ?? this.rankScore,
        rankPosition: rankPosition ?? this.rankPosition,
      );

  factory Technician.fromJson(Map<String, dynamic> json, {bool isDetail = false}) {
    Map<String, dynamic> data = json;
    if (json['data'] is Map) {
      data = Map<String, dynamic>.from(json['data'] as Map);
    } else if (json['technician'] is Map) {
      data = Map<String, dynamic>.from(json['technician'] as Map);
    }

    final user = data['user'] is Map
        ? Map<String, dynamic>.from(data['user'] as Map)
        : null;
    final tech = data['technician'] is Map
        ? Map<String, dynamic>.from(data['technician'] as Map)
        : null;

    String name = data['name']?.toString() ?? '';
    if (name.isEmpty) name = user?['name']?.toString() ?? '';
    if (name.isEmpty) name = tech?['name']?.toString() ?? '';
    if (name.isEmpty) name = 'Unknown';

    // services
    List<TechnicianService> serviceObjs = [];
    final dynamic rawServices =
        data['services'] ?? tech?['services'] ?? user?['services'];
    if (rawServices is List) {
      if (rawServices.isNotEmpty && rawServices.first is Map) {
        serviceObjs = rawServices
            .whereType<Map>()
            .map((e) => TechnicianService.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      } else if (rawServices.isNotEmpty && rawServices.first is String) {
        serviceObjs = [
          for (var i = 0; i < rawServices.length; i++)
            TechnicianService(
              id: i + 1,
              name: rawServices[i].toString(),
            ),
        ];
      }
    }

    // portfolios
    List<PortfolioItem> portfolios = [];
    if (isDetail || data['portfolios'] is List) {
      final raw = data['portfolios'] ?? tech?['portfolios'];
      if (raw is List) {
        portfolios = raw
            .whereType<Map>()
            .map((e) => PortfolioItem.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    }

    // price range
    PriceRange? priceRange;
    if (data['price_range'] is Map) {
      final pr = Map<String, dynamic>.from(data['price_range'] as Map);
      final min = _asDouble(pr['min']);
      final max = _asDouble(pr['max']);
      if (min > 0 || max > 0) priceRange = PriceRange(min: min, max: max);
    }

    // service prices
    List<ServicePrice> servicePrices = [];
    if (data['service_prices'] is List) {
      servicePrices = data['service_prices']
          .whereType<Map>()
          .map((sp) => ServicePrice.fromJson(Map<String, dynamic>.from(sp)))
          .toList();
    }

    // Extract email and phone (checking root, user object, and tech object)
    final String? email = data['email']?.toString() ??
        user?['email']?.toString() ??
        tech?['email']?.toString();

    final String? phone = data['phone']?.toString() ??
        user?['phone']?.toString() ??
        tech?['phone']?.toString();

    return Technician(
      id: _asInt(data['id'] ?? tech?['id'] ?? json['id']),
      userId: _asInt(data['user_id'] ?? user?['id'] ?? tech?['user_id']),
      name: name,
      email: email,
      phone: phone,
      profilePhoto: data['profile_photo']?.toString() ??
          tech?['profile_photo']?.toString(),
      bio: data['bio']?.toString() ?? tech?['bio']?.toString(),
      experience: _asInt(data['experience'] ?? tech?['experience']),
      rating: _asDouble(data['rating'] ?? tech?['rating']),
      hourlyRate: _asNullableDouble(data['hourly_rate'] ?? tech?['hourly_rate']),
      distanceKm: _asDouble(data['distance'] ?? data['distance_km']),
      area: data['area']?.toString() ?? tech?['area']?.toString(),
      latitude: _asNullableDouble(data['latitude'] ?? tech?['latitude']),
      longitude: _asNullableDouble(data['longitude'] ?? tech?['longitude']),
      isOnline: _asBool(data['is_online'] ?? tech?['is_online']),
      verified: _asBool(data['verified'] ?? tech?['verified']),
      serviceObjects: serviceObjs,
      portfolios: portfolios,
      completedJobsCount:
      _asInt(data['completed_jobs_count'] ?? tech?['completed_jobs_count']),
      priceRange: priceRange,
      servicePrices: servicePrices,
      requestsCount: _asInt(data['requests_count']),
      postLikes: _asInt(data['post_likes']),
      postComments: _asInt(data['post_comments']),
      reviewsCount: _asInt(data['reviews_count']),
      rankScore: _asDouble(data['rank_score']),
      rankPosition: _asInt(data['rank_position']),
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
    'service_objects': serviceObjects.map((s) => s.toJson()).toList(),
    'portfolios': portfolios.map((p) => p.toJson()).toList(),
    'completed_jobs_count': completedJobsCount,
    'price_range': priceRange?.toJson(),
    'service_prices': servicePrices.map((sp) => sp.toJson()).toList(),
    'requests_count': requestsCount,
    'post_likes': postLikes,
    'post_comments': postComments,
    'reviews_count': reviewsCount,
    'rank_score': rankScore,
    'rank_position': rankPosition,
  };
}

// ── null-safe helpers ──────────────────────────────────────────────
int _asInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? 0;
}

double _asDouble(dynamic v) {
  if (v == null) return 0.0;
  if (v is double) return v;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0.0;
}

double? _asNullableDouble(dynamic v) {
  if (v == null) return null;
  if (v is double) return v;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}

bool _asBool(dynamic v) {
  if (v == null) return false;
  if (v is bool) return v;
  if (v is num) return v != 0;
  final s = v.toString().toLowerCase().trim();
  return s == 'true' || s == '1' || s == 'yes';
}