// lib/models/ticket.dart
import 'package:flutter/material.dart';

import '../config/app_theme.dart';

class Ticket {
  final int id;
  final String ticketNumber;
  final String title;
  final String? description;
  final String status;
  final String? technicianName;
  final String? jobNumber;
  final DateTime? completedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Ticket({
    required this.id,
    required this.title,
    required this.status,
    this.ticketNumber = '',
    this.description,
    this.technicianName,
    this.jobNumber,
    this.completedAt,
    this.createdAt,
    this.updatedAt,
  });

  static const String openStatus = 'open';
  static const String pendingStatus = 'pending';
  static const String inProgressStatus = 'in-progress';
  static const String onProgressStatus = 'on-progress';
  static const String completedStatus = 'completed';
  static const String closedStatus = 'closed';

  bool get isCompleted =>
      status.toLowerCase() == completedStatus ||
          status.toLowerCase() == closedStatus;

  String get statusLabel {
    switch (status.toLowerCase()) {
      case openStatus:
        return 'Open';
      case pendingStatus:
        return 'Pending';
      case inProgressStatus:
      case onProgressStatus:
      case 'in_progress':
        return 'In progress';
      case completedStatus:
        return 'Completed';
      case closedStatus:
        return 'Closed';
      default:
        return status
            .replaceAll('-', ' ')
            .replaceAll('_', ' ')
            .split(' ')
            .map((w) =>
        w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
            .join(' ');
    }
  }

  Color get statusColor => JobTicketStatus.colorFor(status);

  factory Ticket.fromJson(Map<String, dynamic> json) {
    final tech = json['technician'] is Map
        ? Map<String, dynamic>.from(json['technician'] as Map)
        : null;

    return Ticket(
      id: _parseInt(json['id']),
      ticketNumber: _parseString(json['ticket_number'], ''),
      title: _parseString(json['title'] ?? json['subject'], 'Service ticket'),
      description: json['description']?.toString(),
      status: _parseString(json['status'], openStatus),
      technicianName: tech?['name']?.toString() ??
          json['technician_name']?.toString(),
      jobNumber: json['job_number']?.toString(),
      completedAt: _parseDate(json['completed_at'] ?? json['closed_at']),
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'ticket_number': ticketNumber,
    'title': title,
    'description': description,
    'status': status,
    'technician_name': technicianName,
    'job_number': jobNumber,
    'completed_at': completedAt?.toIso8601String(),
    'created_at': createdAt?.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
  };

  Ticket copyWith({String? technicianName, String? jobNumber}) => Ticket(
    id: id,
    ticketNumber: ticketNumber,
    title: title,
    description: description,
    status: status,
    technicianName: technicianName ?? this.technicianName,
    jobNumber: jobNumber ?? this.jobNumber,
    completedAt: completedAt,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _parseString(dynamic value, String fallback) {
    final result = value?.toString().trim();
    return result == null || result.isEmpty ? fallback : result;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}

class JobTicketStatus {
  static Color colorFor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'closed':
        return AppTheme.success;
      case 'in-progress':
      case 'in_progress':
      case 'on-progress':
        return AppTheme.accent;
      default:
        return AppTheme.warning;
    }
  }
}