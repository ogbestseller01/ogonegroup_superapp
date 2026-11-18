// lib/models/request.dart

class ServiceRequest {
  final int id;
  final int technicianId;
  final int customerId;
  final String description;
  final String status; // pending | accepted | cancelled | rejected
  final DateTime createdAt;
  final String technicianName;
  final String serviceName;
  final String customerName;
  final String? customerPhone;
  final String? technicianArea;
  final String? technicianPhone;
  final double? technicianRating;
  final bool canCancel;

  // The job is created automatically by the backend when the request is accepted.
  final bool hasJob;
  final int? jobId;
  final String? jobNumber;
  final String? jobStatus; // pending | on-progress | completed

  ServiceRequest({
    required this.id,
    required this.technicianId,
    required this.customerId,
    required this.description,
    required this.status,
    required this.createdAt,
    required this.technicianName,
    required this.serviceName,
    required this.customerName,
    this.customerPhone,
    this.technicianArea,
    this.technicianPhone,
    this.technicianRating,
    this.canCancel = false,
    this.hasJob = false,
    this.jobId,
    this.jobNumber,
    this.jobStatus,
  });

  // ─── Status helpers (only the 4 allowed statuses) ───────────────────────
  bool get isPending   => status == 'pending';
  bool get isAccepted  => status == 'accepted';
  bool get isCancelled => status == 'cancelled';
  bool get isRejected  => status == 'rejected';

  bool get isActive => isPending || isAccepted;

  static int _int(dynamic v, [int fallback = 0]) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('${v ?? ''}') ?? fallback;
  }

  factory ServiceRequest.fromJson(Map<String, dynamic> json) {
    String techName = 'Unknown';
    String? techArea;
    String? techPhone;
    double? techRating;

    if (json['technician'] != null && json['technician'] is Map) {
      final tech = json['technician'] as Map;
      if (tech['user'] != null && tech['user'] is Map) {
        final user = tech['user'] as Map;
        techName = user['name']?.toString() ?? techName;
        techPhone = user['phone']?.toString();
      } else {
        techName = tech['name']?.toString() ?? techName;
        techPhone = tech['phone']?.toString();
      }
      techArea = tech['area']?.toString();
      if (tech['rating'] != null) {
        techRating = double.tryParse(tech['rating'].toString());
      }
    }

    if (techName == 'Unknown' && json['technician_name'] != null) {
      techName = json['technician_name'].toString();
    }

    String customerName = 'Customer';
    String? customerPhone;
    int customerId = _int(json['customer_id']);

    if (json['customer'] != null && json['customer'] is Map) {
      final customer = json['customer'] as Map;
      customerName = customer['name']?.toString() ?? customerName;
      customerPhone = customer['phone']?.toString();
      customerId = _int(customer['id'], customerId);
    }

    if (json['customer_name'] != null) {
      customerName = json['customer_name'].toString();
    }
    if (json['customer_phone'] != null) {
      customerPhone = json['customer_phone'].toString();
    }

    // Job (auto-created on accept)
    final jobMap = json['job'] is Map ? json['job'] as Map : null;
    final jobId = jobMap != null ? _int(jobMap['id']) : null;

    return ServiceRequest(
      id: _int(json['id']),
      technicianId: _int(json['technician_id']),
      customerId: customerId,
      description: json['description']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      createdAt: DateTime.tryParse('${json['created_at'] ?? ''}') ?? DateTime.now(),
      technicianName: techName,
      serviceName:
      json['service']?['name']?.toString() ?? json['service_name']?.toString() ?? 'Service',
      customerName: customerName,
      customerPhone: customerPhone,
      technicianArea: techArea,
      technicianPhone: techPhone,
      technicianRating: techRating,
      canCancel: json['can_cancel'] == true,
      hasJob: json['has_job'] == true || jobMap != null,
      jobId: (jobId != null && jobId != 0) ? jobId : null,
      jobNumber: jobMap?['job_number']?.toString(),
      jobStatus: jobMap?['status']?.toString(),
    );
  }
}