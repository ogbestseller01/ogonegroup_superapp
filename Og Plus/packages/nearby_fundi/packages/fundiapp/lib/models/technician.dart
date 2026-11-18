// lib/models/technician.dart

import 'service.dart';

class Technician {
  final int id;
  final int userId;
  final String? bio;
  final String? area;
  final double? latitude;
  final double? longitude;
  final String? nida;
  final String? idDocumentType;
  final String? idDocumentImage;
  final String? profilePhoto;
  final double? hourlyRate;
  final int experience;

  // Registration + verification state (from TechnicianController)
  final bool verified;
  final String? verificationStatus; // 'pending' | 'approved' | 'rejected'
  final int registrationStep;        // 0..6
  final bool registrationCompleted;
  final bool fingerprintEnrolled;
  final bool faceEnrolled;

  // Next of kin (visible on profile endpoint)
  final String? nextOfKinName;
  final String? nextOfKinPhone;
  final String? nextOfKinRelationship;

  // Location telemetry
  final DateTime? lastActivityAt;
  final DateTime? locationUpdatedAt;

  /// Services the technician offers. Populated from
  /// `GET /v19/technicians/profile` via `->with('services')`.
  final List<Service> services;

  const Technician({
    required this.id,
    required this.userId,
    this.bio,
    this.area,
    this.latitude,
    this.longitude,
    this.nida,
    this.idDocumentType,
    this.idDocumentImage,
    this.profilePhoto,
    this.hourlyRate,
    this.experience = 0,
    this.verified = false,
    this.verificationStatus,
    this.registrationStep = 0,
    this.registrationCompleted = false,
    this.fingerprintEnrolled = false,
    this.faceEnrolled = false,
    this.nextOfKinName,
    this.nextOfKinPhone,
    this.nextOfKinRelationship,
    this.lastActivityAt,
    this.locationUpdatedAt,
    this.services = const [],
  });

  bool get isPendingApproval =>
      registrationCompleted &&
          !verified &&
          (verificationStatus == null || verificationStatus == 'pending');

  bool get isApproved => verified && verificationStatus == 'approved';

  factory Technician.fromJson(
      Map<String, dynamic> json, {
        bool isDetail = false,
      }) {
    final rawServices = json['services'];
    final services = rawServices is List
        ? rawServices
        .whereType<Map>()
        .map((e) => Service.fromJson(Map<String, dynamic>.from(e)))
        .toList()
        : <Service>[];

    return Technician(
      id: _toInt(json['id']),
      userId: _toInt(json['user_id']),
      bio: json['bio']?.toString(),
      area: json['area']?.toString(),
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      nida: json['nida']?.toString(),
      idDocumentType: json['id_document_type']?.toString(),
      idDocumentImage: json['id_document_image']?.toString(),
      profilePhoto: json['profile_photo']?.toString(),
      hourlyRate: _toDouble(json['hourly_rate']),
      experience: _toInt(json['experience']),
      verified: _toBool(json['verified']),
      verificationStatus: json['verification_status']?.toString(),
      registrationStep: _toInt(json['registration_step']),
      registrationCompleted: _toBool(json['registration_completed']),
      fingerprintEnrolled: _toBool(json['fingerprint_enrolled']),
      faceEnrolled: _toBool(json['face_enrolled']),
      nextOfKinName: json['next_of_kin_name']?.toString(),
      nextOfKinPhone: json['next_of_kin_phone']?.toString(),
      nextOfKinRelationship: json['next_of_kin_relationship']?.toString(),
      lastActivityAt: _parseDate(json['last_activity_at']),
      locationUpdatedAt: _parseDate(json['location_updated_at']),
      services: services,
    );
  }

  static int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? 0;
  }

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  static bool _toBool(dynamic v) {
    if (v is bool) return v;
    if (v is num) return v == 1;
    if (v is String) return v == '1' || v.toLowerCase() == 'true';
    return false;
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }
}