// lib/models/request.dart
import 'package:flutter/material.dart';
import '../config/app_theme.dart';

/// Server enum (requests.status): pending | accepted | cancelled | rejected
///  pending → accepted | rejected (fundi), pending → cancelled (customer)
/// Work progress lives on the Job / Ticket, not on the request.
class ServiceRequest {
  static const String pendingStatus   = 'pending';
  static const String acceptedStatus  = 'accepted';
  static const String cancelledStatus = 'cancelled';
  static const String rejectedStatus  = 'rejected';

  static const List<String> allStatuses = [
    pendingStatus,
    acceptedStatus,
    cancelledStatus,
    rejectedStatus,
  ];

  final int id;
  final int technicianId;
  final String description;
  final String status;
  final DateTime createdAt;

  final String technicianName;
  final String serviceName;

  /// users.id of the fundi — needed to open the chat.
  final int technicianUserId;

  final String? technicianProfilePhoto;
  final String? technicianArea;
  final double? technicianRating;

  final int? categoryId;
  final String? categoryName;

  final int? jobId;

  ServiceRequest({
    required this.id,
    required this.technicianId,
    required this.description,
    required this.status,
    required this.createdAt,
    required this.technicianName,
    required this.serviceName,
    this.technicianUserId = 0,
    this.technicianProfilePhoto,
    this.technicianArea,
    this.technicianRating,
    this.categoryId,
    this.categoryName,
    this.jobId,
  });

  // ── STATUS ──
  bool get isPending   => status == pendingStatus;
  bool get isAccepted  => status == acceptedStatus;
  bool get isCancelled => status == cancelledStatus;
  bool get isRejected  => status == rejectedStatus;

  /// Open = still alive (pending or accepted). Closed = cancelled/rejected.
  bool get isClosed => isCancelled || isRejected;

  bool get canBeCancelled => isPending;
  bool get canBeAnswered  => isPending;

  bool get hasJob => jobId != null && jobId! > 0;

  /// Customer can turn an accepted request into a job once.
  bool get canBeMarkedAsJob => isAccepted && !hasJob;

  String get statusLabel {
    switch (status) {
      case pendingStatus:   return 'Pending';
      case acceptedStatus:  return 'Accepted';
      case cancelledStatus: return 'Cancelled';
      case rejectedStatus:  return 'Rejected';
      default:              return status.toUpperCase();
    }
  }

  Color get statusColor {
    switch (status) {
      case pendingStatus:   return AppTheme.warning;
      case acceptedStatus:  return AppTheme.success;
      case cancelledStatus: return Colors.grey;
      case rejectedStatus:  return AppTheme.error;
      default:              return AppTheme.warning;
    }
  }

  IconData get statusIcon {
    switch (status) {
      case pendingStatus:   return Icons.hourglass_empty_rounded;
      case acceptedStatus:  return Icons.check_circle_outline_rounded;
      case cancelledStatus: return Icons.cancel_outlined;
      case rejectedStatus:  return Icons.block_rounded;
      default:              return Icons.help_outline_rounded;
    }
  }

  // ── JSON ──
  static int _int(dynamic v, [int d = 0]) =>
      int.tryParse(v?.toString() ?? '') ?? d;

  static double? _dbl(dynamic v) =>
      v == null ? null : double.tryParse(v.toString());

  static Map<String, dynamic>? _map(dynamic v) =>
      v is Map ? Map<String, dynamic>.from(v) : null;

  static String _pick(List<dynamic> options, String fallback) {
    for (final o in options) {
      final s = o?.toString().trim();
      if (s != null && s.isNotEmpty) return s;
    }
    return fallback;
  }

  factory ServiceRequest.fromJson(Map<String, dynamic> json) {
    final tech     = _map(json['technician']);
    final techUser = _map(tech?['user']);
    final service  = _map(json['service']);
    final category = _map(json['category']);
    final job      = _map(json['job']);

    final rawJobId = job != null ? job['id'] : json['job_id'];
    final parsedJobId = rawJobId == null ? null : _int(rawJobId);

    return ServiceRequest(
      id: _int(json['id']),
      technicianId: _int(json['technician_id'] ?? tech?['id']),
      description: json['description']?.toString() ?? '',
      status: json['status']?.toString() ?? pendingStatus,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      technicianName: _pick(
        [tech?['name'], techUser?['name'], json['technician_name']],
        'Unknown',
      ),
      serviceName: _pick([service?['name'], json['service_name']], 'Service'),
      technicianUserId: _int(tech?['user_id'] ?? techUser?['id']),
      technicianProfilePhoto: tech?['profile_photo']?.toString(),
      technicianArea: tech?['area']?.toString(),
      technicianRating: _dbl(tech?['rating']),
      categoryId: category == null
          ? null
          : int.tryParse('${category['id'] ?? category['service_categoryID']}'),
      categoryName:
      (category?['name'] ?? category?['category_name'])?.toString(),
      jobId: (parsedJobId == null || parsedJobId == 0) ? null : parsedJobId,
    );
  }
}