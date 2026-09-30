import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../config/app_theme.dart';

class ServiceRequest {
  final int id;
  final int technicianId;
  final String description;
  final String status;
  final DateTime createdAt;

  final String technicianName;
  final String serviceName;

  final int customerId;
  final String? customerName;

  final String? technicianEmail;
  final String? technicianPhone;
  final String? technicianProfilePhoto;
  final String? technicianArea;

  final double? technicianRating;
  final bool? technicianIsOnline;

  final int? categoryId;
  final String? categoryName;

  final double? latitude;
  final double? longitude;

  final bool hasReview;

  ServiceRequest({
    required this.id,
    required this.technicianId,
    required this.description,
    required this.status,
    required this.createdAt,
    required this.technicianName,
    required this.serviceName,
    this.customerId = 0,
    this.customerName,
    this.technicianEmail,
    this.technicianPhone,
    this.technicianProfilePhoto,
    this.technicianArea,
    this.technicianRating,
    this.technicianIsOnline,
    this.categoryId,
    this.categoryName,
    this.latitude,
    this.longitude,
    this.hasReview = false,
  });

  // ─────────────────────────────────────────────────────────────────────────
  // STATUS GETTERS
  // ─────────────────────────────────────────────────────────────────────────

  bool get isPending =>
      status == 'pending';

  bool get isAccepted =>
      status == 'accepted';

  bool get isOnTheWay =>
      status == 'on_the_way';

  bool get isArrived =>
      status == 'arrived';

  bool get isInProgress =>
      status == 'in_progress';

  bool get isCompleted =>
      status == 'completed';

  bool get isCancelled =>
      status == 'cancelled';

  bool get isRejected =>
      status == 'rejected';

  // ─────────────────────────────────────────────────────────────────────────
  // ACTIVE REQUEST
  //
  // These statuses mean the request is currently ongoing.
  // They block creating another request to the same technician.
  // ─────────────────────────────────────────────────────────────────────────

  bool get isActive =>
      isPending ||
          isAccepted ||
          isOnTheWay ||
          isArrived ||
          isInProgress;

  // ─────────────────────────────────────────────────────────────────────────
  // TERMINAL REQUEST
  //
  // These statuses are finished.
  // User can request the same technician again.
  // ─────────────────────────────────────────────────────────────────────────

  bool get isTerminal =>
      isCompleted ||
          isCancelled ||
          isRejected;

  // ─────────────────────────────────────────────────────────────────────────
  // CANCEL
  // ─────────────────────────────────────────────────────────────────────────

  bool get canBeCancelled =>
      isPending ||
          isAccepted;

  // ─────────────────────────────────────────────────────────────────────────
  // NEW REQUEST
  //
  // IMPORTANT:
  //
  // No active request = user can request again.
  //
  // This means:
  // completed  -> YES
  // cancelled  -> YES
  // rejected   -> YES
  // pending    -> NO
  // accepted   -> NO
  // on_the_way -> NO
  // arrived    -> NO
  // in_progress -> NO
  // ─────────────────────────────────────────────────────────────────────────

  bool get allowsNewRequest =>
      !isActive;

  // ─────────────────────────────────────────────────────────────────────────
  // STATUS LABEL
  // ─────────────────────────────────────────────────────────────────────────

  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'Pending';

      case 'accepted':
        return 'Accepted';

      case 'on_the_way':
        return 'On The Way';

      case 'arrived':
        return 'Arrived';

      case 'in_progress':
        return 'In Progress';

      case 'completed':
        return 'Completed';

      case 'cancelled':
        return 'Cancelled';

      case 'rejected':
        return 'Rejected';

      default:
        return status.toUpperCase();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STATUS COLOR
  // ─────────────────────────────────────────────────────────────────────────

  Color get statusColor {
    switch (status) {
      case 'pending':
        return AppTheme.warning;

      case 'accepted':
        return AppTheme.primary;

      case 'on_the_way':
        return Colors.orange;

      case 'arrived':
        return Colors.teal;

      case 'in_progress':
        return Colors.purple;

      case 'completed':
        return AppTheme.success;

      case 'cancelled':
        return AppTheme.error;

      case 'rejected':
        return AppTheme.error;

      default:
        return AppTheme.warning;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STATUS ICON
  // ─────────────────────────────────────────────────────────────────────────

  IconData get statusIcon {
    switch (status) {
      case 'pending':
        return Icons.hourglass_empty_rounded;

      case 'accepted':
        return Icons.check_circle_outline_rounded;

      case 'on_the_way':
        return Icons.directions_car_rounded;

      case 'arrived':
        return Icons.location_on_rounded;

      case 'in_progress':
        return Icons.construction_rounded;

      case 'completed':
        return Icons.verified_outlined;

      case 'cancelled':
        return Icons.cancel_outlined;

      case 'rejected':
        return Icons.block_rounded;

      default:
        return Icons.help_outline_rounded;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // FROM JSON
  // ─────────────────────────────────────────────────────────────────────────

  factory ServiceRequest.fromJson(
      Map<String, dynamic> json,
      ) {
    Map<String, dynamic>? technicianData;

    String techName = 'Unknown';
    String? techEmail;
    String? techPhone;
    String? techPhoto;
    String? techArea;

    double? techRating;
    bool? techIsOnline;

    // ──────────────────────────────────────────────
    // TECHNICIAN
    // ──────────────────────────────────────────────

    if (json['technician'] != null &&
        json['technician'] is Map) {
      technicianData =
      Map<String, dynamic>.from(
        json['technician'] as Map,
      );
    }

    int techId = 0;

    if (json['technician_id'] != null) {
      techId = int.tryParse(
        json['technician_id'].toString(),
      ) ??
          0;
    } else if (technicianData != null &&
        technicianData['id'] != null) {
      techId = int.tryParse(
        technicianData['id'].toString(),
      ) ??
          0;
    }

    if (technicianData != null) {
      if (technicianData['user'] != null &&
          technicianData['user'] is Map) {
        final userData =
        Map<String, dynamic>.from(
          technicianData['user'] as Map,
        );

        techName =
            userData['name']?.toString() ??
                techName;

        techEmail =
            userData['email']?.toString();

        techPhone =
            userData['phone']?.toString();

        final onlineValue =
        userData['is_online'];

        if (onlineValue != null) {
          techIsOnline =
          onlineValue is bool
              ? onlineValue
              : onlineValue
              .toString()
              .toLowerCase() ==
              '1';
        }
      }

      if (techName == 'Unknown' &&
          technicianData['name'] != null) {
        techName =
            technicianData['name'].toString();
      }

      techPhoto =
          technicianData['profile_photo']
              ?.toString();

      techArea =
          technicianData['area']?.toString();

      if (technicianData['rating'] != null) {
        techRating = double.tryParse(
          technicianData['rating'].toString(),
        );
      }

      if (technicianData['is_online'] != null) {
        final value =
        technicianData['is_online'];

        techIsOnline = value is bool
            ? value
            : value
            .toString()
            .toLowerCase() ==
            '1';
      }
    }

    if (techName == 'Unknown' &&
        json['technician_name'] != null) {
      techName =
          json['technician_name'].toString();
    }

    // ──────────────────────────────────────────────
    // SERVICE
    // ──────────────────────────────────────────────

    String serviceName = 'Service';

    if (json['service'] != null &&
        json['service'] is Map) {
      final serviceData =
      Map<String, dynamic>.from(
        json['service'] as Map,
      );

      serviceName =
          serviceData['name']?.toString() ??
              'Service';
    }

    if (serviceName == 'Service' &&
        json['service_name'] != null) {
      serviceName =
          json['service_name'].toString();
    }

    // ──────────────────────────────────────────────
    // CATEGORY
    // ──────────────────────────────────────────────

    int? categoryId;
    String? categoryName;

    if (json['category'] != null &&
        json['category'] is Map) {
      final categoryData =
      Map<String, dynamic>.from(
        json['category'] as Map,
      );

      categoryId = int.tryParse(
        (categoryData['id'] ??
            categoryData['service_categoryID'])
            .toString(),
      );

      categoryName =
          (categoryData['name'] ??
              categoryData['category_name'])
              ?.toString();
    }

    // ──────────────────────────────────────────────
    // CUSTOMER
    // ──────────────────────────────────────────────

    int customerId = 0;
    String? customerName;

    if (json['customer'] != null &&
        json['customer'] is Map) {
      final customerData =
      Map<String, dynamic>.from(
        json['customer'] as Map,
      );

      customerId = int.tryParse(
        customerData['id']
            ?.toString() ??
            '0',
      ) ??
          0;

      customerName =
          customerData['name']?.toString();
    }

    // ──────────────────────────────────────────────
    // LOCATION
    // ──────────────────────────────────────────────

    double? lat;
    double? lng;

    if (json['latitude'] != null) {
      lat = double.tryParse(
        json['latitude'].toString(),
      );
    }

    if (json['longitude'] != null) {
      lng = double.tryParse(
        json['longitude'].toString(),
      );
    }

    // ──────────────────────────────────────────────
    // REVIEW
    // ──────────────────────────────────────────────

    bool hasReview = false;

    if (json['has_review'] != null) {
      final value = json['has_review'];

      hasReview = value is bool
          ? value
          : value
          .toString()
          .toLowerCase() ==
          'true' ||
          value.toString() == '1';
    }

    // ──────────────────────────────────────────────
    // CREATE OBJECT
    // ──────────────────────────────────────────────

    return ServiceRequest(
      id: int.tryParse(
        json['id']?.toString() ?? '0',
      ) ??
          0,

      technicianId: techId,

      description:
      json['description']?.toString() ?? '',

      status:
      json['status']?.toString() ??
          'pending',

      createdAt: DateTime.tryParse(
        json['created_at']?.toString() ?? '',
      ) ??
          DateTime.now(),

      technicianName: techName,

      serviceName: serviceName,

      customerId: customerId,

      customerName: customerName,

      technicianEmail: techEmail,

      technicianPhone: techPhone,

      technicianProfilePhoto:
      techPhoto,

      technicianArea: techArea,

      technicianRating: techRating,

      technicianIsOnline:
      techIsOnline,

      categoryId: categoryId,

      categoryName: categoryName,

      latitude: lat,

      longitude: lng,

      hasReview: hasReview,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TO JSON
  // ─────────────────────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'technician_id': technicianId,
      'description': description,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'technician_name': technicianName,
      'service_name': serviceName,
      'customer_id': customerId,
      'customer_name': customerName,
      'category_id': categoryId,
      'category_name': categoryName,
      if (latitude != null)
        'latitude': latitude,
      if (longitude != null)
        'longitude': longitude,
      'has_review': hasReview,
    };
  }
}