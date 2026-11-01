// lib/models/job.dart

/// Pulls a list out of any of the response shapes the API returns:
///  - [ ... ]
///  - { data: [ ... ] }
///  - { data: { data: [ ... ] } }   (paginated)
List<dynamic> extractList(dynamic data) {
  if (data is List) return data;
  if (data is Map) {
    final inner = data['data'];
    if (inner is List) return inner;
    if (inner is Map && inner['data'] is List) return inner['data'] as List;
  }
  return [];
}

DateTime? _parseDate(dynamic v) {
  if (v == null) return null;
  return DateTime.tryParse(v.toString());
}

String? _str(dynamic v) {
  if (v == null) return null;
  final s = v.toString();
  return s.isEmpty ? null : s;
}

// ================================================================
// TICKET
// ================================================================
class WorkTicket {
  final int id;
  final String ticketNumber;
  final String status; // on-progress | completed
  final String title;
  final String? description;
  final DateTime? createdAt;
  final DateTime? completedAt;

  // Related info (from the parent job)
  final int? jobId;
  final String? jobNumber;
  final String? jobStatus;
  final String? customerName;
  final String? serviceName;

  WorkTicket({
    required this.id,
    required this.ticketNumber,
    required this.status,
    required this.title,
    this.description,
    this.createdAt,
    this.completedAt,
    this.jobId,
    this.jobNumber,
    this.jobStatus,
    this.customerName,
    this.serviceName,
  });

  bool get isCompleted => status == 'completed';

  /// [jobNumber], [customerName], [serviceName] are fallbacks used when the
  /// ticket is nested inside a job payload (which has no `job` key).
  factory WorkTicket.fromJson(
      Map<String, dynamic> json, {
        int? jobId,
        String? jobNumber,
        String? jobStatus,
        String? customerName,
        String? serviceName,
      }) {
    final job = json['job'] is Map ? json['job'] as Map : null;
    final customer = json['customer'] is Map ? json['customer'] as Map : null;
    final service = json['service'] is Map ? json['service'] as Map : null;

    return WorkTicket(
      id: (json['id'] as num?)?.toInt() ?? 0,
      ticketNumber: _str(json['ticket_number']) ?? '-',
      status: _str(json['status']) ?? 'on-progress',
      title: _str(json['title']) ?? '-',
      description: _str(json['description']),
      createdAt: _parseDate(json['created_at']),
      completedAt: _parseDate(json['completed_at']),
      jobId: (job?['id'] as num?)?.toInt() ??
          (json['job_id'] as num?)?.toInt() ??
          jobId,
      jobNumber: _str(job?['job_number']) ?? jobNumber,
      jobStatus: _str(job?['status']) ?? jobStatus,
      customerName: _str(customer?['name']) ?? customerName,
      serviceName: _str(service?['name']) ?? serviceName,
    );
  }
}

// ================================================================
// JOB
// ================================================================
class WorkJob {
  final int id;
  final String jobNumber;
  final String status; // pending | on-progress | completed
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? createdAt;
  final String? notes;

  final int? requestId;
  final String? description;
  final String? serviceName;
  final String? categoryName;
  final String? customerName;

  final List<WorkTicket> tickets;

  WorkJob({
    required this.id,
    required this.jobNumber,
    required this.status,
    this.startedAt,
    this.completedAt,
    this.createdAt,
    this.notes,
    this.requestId,
    this.description,
    this.serviceName,
    this.categoryName,
    this.customerName,
    this.tickets = const [],
  });

  bool get isCompleted => status == 'completed';

  factory WorkJob.fromJson(Map<String, dynamic> json) {
    final req = json['request'] is Map ? json['request'] as Map : null;
    final service = req?['service'] is Map ? req!['service'] as Map : null;
    final category = req?['category'] is Map ? req!['category'] as Map : null;
    final customer = json['customer'] is Map ? json['customer'] as Map : null;

    final id = (json['id'] as num?)?.toInt() ?? 0;
    final jobNumber = _str(json['job_number']) ?? '-';
    final status = _str(json['status']) ?? 'pending';
    final customerName = _str(customer?['name']);
    final serviceName = _str(service?['name']);

    // Prefer the full `tickets` list, fall back to the single `ticket`.
    final tickets = <WorkTicket>[];
    if (json['tickets'] is List) {
      for (final t in json['tickets'] as List) {
        if (t is Map) {
          tickets.add(WorkTicket.fromJson(
            Map<String, dynamic>.from(t),
            jobId: id,
            jobNumber: jobNumber,
            jobStatus: status,
            customerName: customerName,
            serviceName: serviceName,
          ));
        }
      }
    } else if (json['ticket'] is Map) {
      tickets.add(WorkTicket.fromJson(
        Map<String, dynamic>.from(json['ticket'] as Map),
        jobId: id,
        jobNumber: jobNumber,
        jobStatus: status,
        customerName: customerName,
        serviceName: serviceName,
      ));
    }

    return WorkJob(
      id: id,
      jobNumber: jobNumber,
      status: status,
      startedAt: _parseDate(json['started_at']),
      completedAt: _parseDate(json['completed_at']),
      createdAt: _parseDate(json['created_at']),
      notes: _str(json['notes']),
      requestId: (req?['id'] as num?)?.toInt(),
      description: _str(req?['description']),
      serviceName: serviceName,
      categoryName: _str(category?['name']),
      customerName: customerName,
      tickets: tickets,
    );
  }
}