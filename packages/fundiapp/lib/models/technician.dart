// lib/models/technician.dart


import 'portfolio.dart';

/// Handles the pivot price data from backend
class TechnicianServicePrice {
  final int id;
  final String name;
  final double minPrice;
  final double maxPrice;

  TechnicianServicePrice({
    required this.id,
    required this.name,
    required this.minPrice,
    required this.maxPrice,
  });

  factory TechnicianServicePrice.fromJson(Map<String, dynamic> json) {
    return TechnicianServicePrice(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      minPrice: double.tryParse(json['pivot']?['min_price']?.toString() ?? '0') ?? 0.0,
      maxPrice: double.tryParse(json['pivot']?['max_price']?.toString() ?? '0') ?? 0.0,
    );
  }
}

class Technician {
  final int id;
  final String name;
  final String? phone;
  final String? profilePhoto;
  final String? nida;
  final String? idDocumentType;
  final String? idDocumentImage;
  final bool verified;
  final String? verificationStatus;
  final int registrationStep;
  final bool registrationCompleted;
  final String? bio;
  final int experience;
  final double rating;
  final double? hourlyRate;
  final String? area;
  final double? latitude;   // ✅ ADDED
  final double? longitude;  // ✅ ADDED
  final bool isOnline;
  final List<String> services;
  final List<TechnicianServicePrice> servicePrices;
  final List<PortfolioItem> portfolios;

  Technician({
    required this.id,
    required this.name,
    this.phone,
    this.profilePhoto,
    this.nida,
    this.idDocumentType,
    this.idDocumentImage,
    this.verified = false,
    this.verificationStatus,
    this.registrationStep = 0,
    this.registrationCompleted = false,
    this.bio,
    this.experience = 0,
    this.rating = 0.0,
    this.hourlyRate,
    this.area,
    this.latitude,          // ✅ ADDED
    this.longitude,         // ✅ ADDED
    this.isOnline = false,
    this.services = const [],
    this.servicePrices = const [],
    this.portfolios = const [],
  });

  factory Technician.fromJson(Map<String, dynamic> json, {bool isDetail = false}) {
    String name = json['name'] ?? '';
    if (name.isEmpty && json['user'] != null && json['user']['name'] != null) {
      name = json['user']['name'];
    }

    String? phone = json['phone'];
    if (phone == null && json['user'] != null && json['user']['phone'] != null) {
      phone = json['user']['phone'];
    }

    String? profilePhoto = json['profile_photo'];
    if (profilePhoto == null &&
        json['user'] != null &&
        json['user']['profile_photo'] != null) {
      profilePhoto = json['user']['profile_photo'];
    }

    String? nida = json['nida'];

    int parseExperience(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    bool parseBool(dynamic value) {
      if (value == null) return false;
      if (value is bool) return value;
      if (value is int) return value == 1;
      if (value is String) {
        return value.toLowerCase() == 'true' || value == '1';
      }
      return false;
    }

    List<String> serviceNames = [];
    List<TechnicianServicePrice> servicePrices = [];

    if (json['service_prices'] != null && json['service_prices'] is List) {
      servicePrices = (json['service_prices'] as List)
          .map((e) => TechnicianServicePrice.fromJson(e as Map<String, dynamic>))
          .toList();
      serviceNames = servicePrices.map((s) => s.name).toList();
    } else if (json['services'] != null && json['services'] is List) {
      final raw = json['services'] as List;
      for (var item in raw) {
        if (item is String) {
          serviceNames.add(item);
        }
      }
    }

    return Technician(
      id: json['id'] ?? 0,
      name: name,
      phone: phone,
      profilePhoto: profilePhoto,
      nida: nida,
      idDocumentType: json['id_document_type'],
      idDocumentImage: json['id_document_image'],
      verified: parseBool(json['verified']),
      verificationStatus: json['verification_status'],
      registrationStep: parseExperience(json['registration_step']),
      registrationCompleted: parseBool(json['registration_completed']),
      bio: json['bio'],
      experience: parseExperience(json['experience']),
      rating: parseDouble(json['rating']),
      hourlyRate: json['hourly_rate'] != null
          ? parseDouble(json['hourly_rate'])
          : null,
      area: json['area'],
      // ✅ ADDED – parse latitude & longitude
      latitude: json['latitude'] != null ? parseDouble(json['latitude']) : null,
      longitude: json['longitude'] != null ? parseDouble(json['longitude']) : null,
      isOnline: parseBool(json['is_online']),
      services: serviceNames,
      servicePrices: servicePrices,
      portfolios: isDetail && json['portfolios'] != null
          ? (json['portfolios'] as List)
          .where((e) => e != null)
          .map((p) => PortfolioItem.fromJson(p))
          .toList()
          : [],
    );
  }
}