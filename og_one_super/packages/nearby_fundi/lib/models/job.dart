// lib/models/job.dart
import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import 'ticket.dart';

/// The customer's review of a completed job (rating 1-5 + remark).
class JobReview {
  final int id;
  final double rating;
  final String? comment;
  final DateTime? createdAt;

  JobReview({
    required this.id,
    required this.rating,
    this.comment,
    this.createdAt,
  });

  factory JobReview.fromJson(Map<String, dynamic> json) {
    final comment = json['comment']?.toString().trim();
    return JobReview(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      rating: double.tryParse(json['rating']?.toString() ?? '') ?? 0,
      comment: (comment == null || comment.isEmpty) ? null : comment,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.tryParse(json['created_at'].toString()),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'rating': rating,
    'comment': comment,
    'created_at': createdAt?.toIso8601String(),
  };
}

class Job {
  static const String pendingStatus = 'pending';
  static const String onProgressStatus = 'on-progress';
  static const String completedStatus = 'completed';

  static const List<String> allStatuses = [
    pendingStatus,
    onProgressStatus,
    completedStatus,
  ];

  final int id;
  final String serviceName;
  final String description;
  final String jobNumber;

  final String technicianName;
  final String? technicianArea;
  final int technicianUserId;

  final String status;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? createdAt;

  final Ticket? ticket;
  final JobReview? review;

  Job({
    required this.id,
    required this.serviceName,
    required this.description,
    required this.jobNumber,
    required this.technicianName,
    this.technicianArea,
    required this.technicianUserId,
    required this.status,
    this.startedAt,
    this.completedAt,
    this.createdAt,
    this.ticket,
    this.review,
  });

  bool get isPending => status == pendingStatus;
  bool get isOnProgress => status == onProgressStatus;
  bool get isCompleted => status == completedStatus;

  /// Customer can leave a review only once the job is completed (one per job).
  bool get canReview => isCompleted && review == null;
  bool get hasReview => review != null;

  String get statusLabel => statusLabelFor(status);
  Color get statusColor => statusColorFor(status);

  IconData get statusIcon {
    switch (status) {
      case pendingStatus:
        return Icons.hourglass_empty_rounded;
      case onProgressStatus:
        return Icons.engineering_rounded;
      case completedStatus:
        return Icons.task_alt_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  static String statusLabelFor(String status) {
    switch (status.toLowerCase()) {
      case pendingStatus:
        return 'Pending';
      case onProgressStatus:
      case 'in_progress':
      case 'in-progress':
        return 'In progress';
      case completedStatus:
        return 'Completed';
      default:
        return status.replaceAll('-', ' ').replaceAll('_', ' ').toUpperCase();
    }
  }

  static Color statusColorFor(String status) {
    switch (status.toLowerCase()) {
      case pendingStatus:
        return AppTheme.warning;
      case onProgressStatus:
      case 'in_progress':
      case 'in-progress':
        return AppTheme.accent;
      case completedStatus:
        return AppTheme.success;
      default:
        return AppTheme.warning;
    }
  }

  static int _int(dynamic value, [int fallback = 0]) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static String _string(dynamic value, [String fallback = '']) {
    final result = value?.toString().trim();
    return result == null || result.isEmpty ? fallback : result;
  }

  static DateTime? _date(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  static Map<String, dynamic>? _map(dynamic v) =>
      v is Map ? Map<String, dynamic>.from(v) : null;

  factory Job.fromJson(Map<String, dynamic> json) {
    final req = _map(json['request']);
    final service = _map(req?['service']);
    final tech = _map(json['technician']);
    final techUser = _map(tech?['user']);

    final dynamic rawTicket = json['ticket'] ?? json['tickets'];
    Map<String, dynamic>? ticketMap;
    if (rawTicket is Map) {
      ticketMap = Map<String, dynamic>.from(rawTicket);
    } else if (rawTicket is List && rawTicket.isNotEmpty && rawTicket.first is Map) {
      ticketMap = Map<String, dynamic>.from(rawTicket.first as Map);
    }

    final technicianName = _string(
      tech?['name'] ?? techUser?['name'] ?? json['technician_name'],
      'Fundi',
    );
    final jobNumber = _string(json['job_number']);

    Ticket? parsedTicket;
    if (ticketMap != null) {
      parsedTicket = Ticket.fromJson(ticketMap).copyWith(
        technicianName: technicianName,
        jobNumber: jobNumber,
      );
    }

    final reviewMap = _map(json['review']);

    return Job(
      id: _int(json['id']),
      serviceName: _string(service?['name'] ?? json['service_name'], 'Service'),
      description: _string(req?['description'] ?? json['description']),
      jobNumber: jobNumber,
      technicianName: technicianName,
      technicianArea: (tech?['area'] ?? json['technician_area'])?.toString(),
      technicianUserId: _int(tech?['user_id'] ?? json['technician_user_id']),
      status: _string(json['status'], pendingStatus),
      startedAt: _date(json['started_at']),
      completedAt: _date(json['completed_at']),
      createdAt: _date(json['created_at']),
      ticket: parsedTicket,
      review: reviewMap != null ? JobReview.fromJson(reviewMap) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'service_name': serviceName,
    'description': description,
    'job_number': jobNumber,
    'technician_name': technicianName,
    'technician_area': technicianArea,
    'technician_user_id': technicianUserId,
    'status': status,
    'started_at': startedAt?.toIso8601String(),
    'completed_at': completedAt?.toIso8601String(),
    'created_at': createdAt?.toIso8601String(),
    'ticket': ticket?.toJson(),
    'review': review?.toJson(),
  };

  Job copyWith({
    String? status,
    DateTime? completedAt,
    Ticket? ticket,
    JobReview? review,
  }) {
    return Job(
      id: id,
      serviceName: serviceName,
      description: description,
      jobNumber: jobNumber,
      technicianName: technicianName,
      technicianArea: technicianArea,
      technicianUserId: technicianUserId,
      status: status ?? this.status,
      startedAt: startedAt,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt,
      ticket: ticket ?? this.ticket,
      review: review ?? this.review,
    );
  }
}