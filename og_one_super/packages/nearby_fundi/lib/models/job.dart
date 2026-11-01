import 'package:flutter/material.dart';
import '../config/app_theme.dart';

/// Ticket attached to a job (status: on-progress | completed).
class JobTicket {
  final int id;
  final String status;
  final String title;
  final String? description;
  final DateTime? completedAt;

  const JobTicket({
    required this.id,
    required this.status,
    required this.title,
    this.description,
    this.completedAt,
  });

  bool get isCompleted => status == 'completed';

  factory JobTicket.fromJson(Map<String, dynamic> j) => JobTicket(
        id: int.tryParse('${j['id']}') ?? 0,
        status: j['status']?.toString() ?? 'on-progress',
        title: j['title']?.toString() ?? 'Ticket',
        description: j['description']?.toString(),
        completedAt: DateTime.tryParse(j['completed_at']?.toString() ?? ''),
      );
}

/// Job statuses: pending | on-progress | completed
class Job {
  static const String pendingStatus = 'pending';
  static const String onProgressStatus = 'on-progress';
  static const String completedStatus = 'completed';

  final int id;
  final String jobNumber;
  final String status;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime createdAt;

  final int requestId;
  final String serviceName;
  final String? categoryName;
  final String description;

  final int technicianId;

  /// users.id of the fundi — the ONLY thing the chat needs.
  final int technicianUserId;
  final String technicianName;
  final String? technicianPhoto;
  final String? technicianArea;

  final JobTicket? ticket;

  const Job({
    required this.id,
    required this.jobNumber,
    required this.status,
    required this.createdAt,
    required this.requestId,
    required this.serviceName,
    required this.description,
    required this.technicianId,
    required this.technicianUserId,
    required this.technicianName,
    this.startedAt,
    this.completedAt,
    this.categoryName,
    this.technicianPhoto,
    this.technicianArea,
    this.ticket,
  });

  bool get isPending => status == pendingStatus;
  bool get isOnProgress => status == onProgressStatus;
  bool get isCompleted => status == completedStatus;

  /// "Mark Complete" is available only while the job is running.
  bool get canMarkComplete => isOnProgress;

  String get statusLabel => statusLabelFor(status);

  Color get statusColor => statusColorFor(status);

  static String statusLabelFor(String s) {
    switch (s) {
      case pendingStatus:
        return 'Pending';
      case onProgressStatus:
        return 'On Progress';
      case completedStatus:
        return 'Completed';
      default:
        return s;
    }
  }

  static Color statusColorFor(String s) {
    switch (s) {
      case onProgressStatus:
        return AppTheme.accent;
      case completedStatus:
        return AppTheme.success;
      default:
        return AppTheme.warning;
    }
  }

  static Map<String, dynamic>? _map(dynamic v) =>
      v is Map ? Map<String, dynamic>.from(v) : null;

  factory Job.fromJson(Map<String, dynamic> j) {
    final req = _map(j['request']);
    final service = _map(req?['service']);
    final category = _map(req?['category']);
    final tech = _map(j['technician']);
    final ticket = _map(j['ticket']);

    return Job(
      id: int.tryParse('${j['id']}') ?? 0,
      jobNumber: j['job_number']?.toString() ?? '',
      status: j['status']?.toString() ?? pendingStatus,
      startedAt: DateTime.tryParse(j['started_at']?.toString() ?? ''),
      completedAt: DateTime.tryParse(j['completed_at']?.toString() ?? ''),
      createdAt:
          DateTime.tryParse(j['created_at']?.toString() ?? '') ?? DateTime.now(),
      requestId: int.tryParse('${req?['id']}') ?? 0,
      serviceName: service?['name']?.toString() ?? 'Service',
      categoryName: category?['name']?.toString(),
      description: req?['description']?.toString() ?? '',
      technicianId: int.tryParse('${tech?['id']}') ?? 0,
      technicianUserId: int.tryParse('${tech?['user_id']}') ?? 0,
      technicianName: tech?['name']?.toString() ?? 'Fundi',
      technicianPhoto: tech?['profile_photo']?.toString(),
      technicianArea: tech?['area']?.toString(),
      ticket: ticket == null ? null : JobTicket.fromJson(ticket),
    );
  }
}
