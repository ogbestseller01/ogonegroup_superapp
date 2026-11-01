import 'package:flutter/material.dart';
import '../config/app_theme.dart';

/// Matches the DB enum:  pending | accepted | in_progress | cancelled | rejected
///
///  • pending     → accepted / rejected (fundi) or cancelled (customer)
///  • accepted    → in_progress (customer taps "Mark as Job")
///  • everything except pending is LOCKED for accept / reject / cancel
///
/// No contact info (phone / email) is kept here on purpose.
class ServiceRequest {
  static const String pendingStatus = 'pending';
  static const String acceptedStatus = 'accepted';
  static const String inProgressStatus = 'in_progress';
  static const String cancelledStatus = 'cancelled';
  static const String rejectedStatus = 'rejected';

  final int id;
  final int technicianId;
  final String description;
  final String status;
  final DateTime createdAt;

  final String technicianName;
  final String serviceName;

  final int customerId;
  final String? customerName;

  final String? technicianProfilePhoto;
  final String? technicianArea;
  final double? technicianRating;

  final int? categoryId;
  final String? categoryName;

  final double? latitude;
  final double? longitude;

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
    this.technicianProfilePhoto,
    this.technicianArea,
    this.technicianRating,
    this.categoryId,
    this.categoryName,
    this.latitude,
    this.longitude,
  });

  // ── STATUS GETTERS ────────────────────────────────────────────────────
  bool get isPending => status == pendingStatus;
  bool get isAccepted => status == acceptedStatus;
  bool get isInProgress => status == inProgressStatus;
  bool get isCancelled => status == cancelledStatus;
  bool get isRejected => status == rejectedStatus;

  /// Only a PENDING request blocks sending another one to the same fundi.
  bool get isActive => isPending;

  /// Customer can cancel ONLY while pending.
  bool get canBeCancelled => isPending;

  /// Fundi can accept / reject ONLY while pending.
  bool get canBeAnswered => isPending;

  /// Customer sees the "Mark as Job" button ONLY once accepted.
  bool get canMarkAsJob => isAccepted;

  // ── STATUS UI ─────────────────────────────────────────────────────────
  String get statusLabel {
    switch (status) {
      case pendingStatus:
        return 'Pending';
      case acceptedStatus:
        return 'Accepted';
      case inProgressStatus:
        return 'In Progress';
      case cancelledStatus:
        return 'Cancelled';
      case rejectedStatus:
        return 'Rejected';
      default:
        return status.toUpperCase();
    }
  }

  Color get statusColor {
    switch (status) {
      case pendingStatus:
        return AppTheme.warning;
      case acceptedStatus:
        return AppTheme.success;
      case inProgressStatus:
        return AppTheme.accent;
      case cancelledStatus:
        return Colors.grey.shade600;
      case rejectedStatus:
        return AppTheme.error;
      default:
        return AppTheme.warning;
    }
  }

  IconData get statusIcon {
    switch (status) {
      case pendingStatus:
        return Icons.hourglass_empty_rounded;
      case acceptedStatus:
        return Icons.check_circle_outline_rounded;
      case inProgressStatus:
        return Icons.engineering_rounded;
      case cancelledStatus:
        return Icons.do_not_disturb_on_outlined;
      case rejectedStatus:
        return Icons.cancel_outlined;
      default:
        return Icons.help_outline_rounded;
    }
  }

  // ── JSON ──────────────────────────────────────────────────────────────
  static int _int(dynamic v, [int d = 0]) =>
      int.tryParse(v?.toString() ?? '') ?? d;

  static double? _dbl(dynamic v) =>
      v == null ? null : double.tryParse(v.toString());

  static Map<String, dynamic>? _map(dynamic v) =>
      v is Map ? Map<String, dynamic>.from(v) : null;

  static String _pick(List<dynamic> options, String fallback) {
    for (final o in options) {
      final s = o?.toString();
      if (s != null && s.isNotEmpty) return s;
    }
    return fallback;
  }

  factory ServiceRequest.fromJson(Map<String, dynamic> json) {
    final tech = _map(json['technician']);
    final techUser = _map(tech?['user']);
    final service = _map(json['service']);
    final category = _map(json['category']);
    final customer = _map(json['customer']);

    return ServiceRequest(
      id: _int(json['id']),
      technicianId: _int(json['technician_id'] ?? tech?['id']),
      description: json['description']?.toString() ?? '',
      status: json['status']?.toString() ?? pendingStatus,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      technicianName: _pick(
          [techUser?['name'], tech?['name'], json['technician_name']], 'Unknown'),
      serviceName: _pick([service?['name'], json['service_name']], 'Service'),
      customerId: _int(customer?['id'] ?? json['customer_id']),
      customerName:
      customer?['name']?.toString() ?? json['customer_name']?.toString(),
      technicianProfilePhoto: tech?['profile_photo']?.toString(),
      technicianArea: tech?['area']?.toString(),
      technicianRating: _dbl(tech?['rating']),
      categoryId: category == null
          ? null
          : int.tryParse('${category['id'] ?? category['service_categoryID']}'),
      categoryName:
      (category?['name'] ?? category?['category_name'])?.toString(),
      latitude: _dbl(json['latitude']),
      longitude: _dbl(json['longitude']),
    );
  }

  Map<String, dynamic> toJson() => {
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
    if (latitude != null) 'latitude': latitude,
    if (longitude != null) 'longitude': longitude,
  };
}
