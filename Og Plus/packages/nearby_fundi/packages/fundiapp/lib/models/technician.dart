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

  // Registration + verification state
  final bool verified;
  final String? verificationStatus; // 'pending' | 'approved' | 'rejected'
  final int registrationStep;       // 0..6
  final bool registrationCompleted;
  final bool fingerprintEnrolled;
  final bool faceEnrolled;

  // Next of kin
  final String? nextOfKinName;
  final String? nextOfKinPhone;
  final String? nextOfKinRelationship;

  // Location telemetry
  final DateTime? lastActivityAt;
  final DateTime? locationUpdatedAt;

  /// Services this technician offers.
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

  // ── Derived state ────────────────────────────────────────

  bool get isPendingApproval =>
      registrationCompleted &&
          !verified &&
          (verificationStatus == null || verificationStatus == 'pending');

  bool get isApproved => verified && verificationStatus == 'approved';

  bool get isRejected => verificationStatus == 'rejected';

  bool get hasBiometrics => fingerprintEnrolled && faceEnrolled;

  bool get hasLocation => latitude != null && longitude != null;

  bool get hasServices => services.isNotEmpty;

  /// 0.0 → 1.0 — useful for progress bars during registration.
  double get registrationProgress =>
      (registrationStep.clamp(0, 6)) / 6.0;

  // ── Copy-with ────────────────────────────────────────────

  Technician copyWith({
    int? id,
    int? userId,
    String? bio,
    String? area,
    double? latitude,
    double? longitude,
    String? nida,
    String? idDocumentType,
    String? idDocumentImage,
    String? profilePhoto,
    double? hourlyRate,
    int? experience,
    bool? verified,
    String? verificationStatus,
    int? registrationStep,
    bool? registrationCompleted,
    bool? fingerprintEnrolled,
    bool? faceEnrolled,
    String? nextOfKinName,
    String? nextOfKinPhone,
    String? nextOfKinRelationship,
    DateTime? lastActivityAt,
    DateTime? locationUpdatedAt,
    List<Service>? services,
  }) {
    return Technician(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      bio: bio ?? this.bio,
      area: area ?? this.area,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      nida: nida ?? this.nida,
      idDocumentType: idDocumentType ?? this.idDocumentType,
      idDocumentImage: idDocumentImage ?? this.idDocumentImage,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      experience: experience ?? this.experience,
      verified: verified ?? this.verified,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      registrationStep: registrationStep ?? this.registrationStep,
      registrationCompleted: registrationCompleted ?? this.registrationCompleted,
      fingerprintEnrolled: fingerprintEnrolled ?? this.fingerprintEnrolled,
      faceEnrolled: faceEnrolled ?? this.faceEnrolled,
      nextOfKinName: nextOfKinName ?? this.nextOfKinName,
      nextOfKinPhone: nextOfKinPhone ?? this.nextOfKinPhone,
      nextOfKinRelationship: nextOfKinRelationship ?? this.nextOfKinRelationship,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
      locationUpdatedAt: locationUpdatedAt ?? this.locationUpdatedAt,
      services: services ?? this.services,
    );
  }

  // ── JSON ─────────────────────────────────────────────────

  factory Technician.fromJson(
      Map<String, dynamic> json, {
        bool isDetail = false,
      }) {
    final rawServices = json['services'];
    final services = rawServices is List
        ? rawServices
        .whereType<Map>()
        .map((e) => Service.fromJson(Map<String, dynamic>.from(e)))
        .toList(growable: false)
        : const <Service>[];

    return Technician(
      id: _toInt(json['id']),
      userId: _toInt(json['user_id']),
      bio: _asString(json['bio']),
      area: _asString(json['area']),
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      nida: _asString(json['nida']),
      idDocumentType: _asString(json['id_document_type']),
      idDocumentImage: _asString(json['id_document_image']),
      profilePhoto: _asString(json['profile_photo']),
      hourlyRate: _toDouble(json['hourly_rate']),
      experience: _toInt(json['experience']),
      verified: _toBool(json['verified']),
      verificationStatus: _asString(json['verification_status']),
      registrationStep: _toInt(json['registration_step']),
      registrationCompleted: _toBool(json['registration_completed']),
      fingerprintEnrolled: _toBool(json['fingerprint_enrolled']),
      faceEnrolled: _toBool(json['face_enrolled']),
      nextOfKinName: _asString(json['next_of_kin_name']),
      nextOfKinPhone: _asString(json['next_of_kin_phone']),
      nextOfKinRelationship: _asString(json['next_of_kin_relationship']),
      lastActivityAt: _parseDate(json['last_activity_at']),
      locationUpdatedAt: _parseDate(json['location_updated_at']),
      services: services,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'bio': bio,
    'area': area,
    'latitude': latitude,
    'longitude': longitude,
    'nida': nida,
    'id_document_type': idDocumentType,
    'id_document_image': idDocumentImage,
    'profile_photo': profilePhoto,
    'hourly_rate': hourlyRate,
    'experience': experience,
    'verified': verified,
    'verification_status': verificationStatus,
    'registration_step': registrationStep,
    'registration_completed': registrationCompleted,
    'fingerprint_enrolled': fingerprintEnrolled,
    'face_enrolled': faceEnrolled,
    'next_of_kin_name': nextOfKinName,
    'next_of_kin_phone': nextOfKinPhone,
    'next_of_kin_relationship': nextOfKinRelationship,
    'last_activity_at': lastActivityAt?.toIso8601String(),
    'location_updated_at': locationUpdatedAt?.toIso8601String(),
    'services': services.map((s) => s.toJson()).toList(),
  };

  // ── Coercion helpers ─────────────────────────────────────

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

  static String? _asString(dynamic v) {
    if (v == null) return null;
    final s = v.toString();
    return s.isEmpty ? null : s;
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }
}