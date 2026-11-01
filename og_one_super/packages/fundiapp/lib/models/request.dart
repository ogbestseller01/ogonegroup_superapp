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
  final bool canMarkAsJob;
  final bool hasJob;

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
    this.canMarkAsJob = false,
    this.hasJob = false,
  });

  // ─── Status helpers (only the 4 allowed statuses) ───────────────────────
  bool get isPending   => status == 'pending';
  bool get isAccepted  => status == 'accepted';
  bool get isCancelled => status == 'cancelled';
  bool get isRejected  => status == 'rejected';

  bool get isActive => isPending || isAccepted;

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
    int customerId = json['customer_id'] ?? 0;

    if (json['customer'] != null && json['customer'] is Map) {
      final customer = json['customer'] as Map;
      customerName = customer['name']?.toString() ?? customerName;
      customerPhone = customer['phone']?.toString();
      customerId = customer['id'] ?? customerId;
    }

    if (json['customer_name'] != null) {
      customerName = json['customer_name'].toString();
    }
    if (json['customer_phone'] != null) {
      customerPhone = json['customer_phone'].toString();
    }

    return ServiceRequest(
      id: json['id'] ?? 0,
      technicianId: json['technician_id'] ?? 0,
      customerId: customerId,
      description: json['description'] ?? '',
      status: json['status'] ?? 'pending',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      technicianName: techName,
      serviceName: json['service']?['name'] ?? json['service_name'] ?? 'Service',
      customerName: customerName,
      customerPhone: customerPhone,
      technicianArea: techArea,
      technicianPhone: techPhone,
      technicianRating: techRating,
      canCancel: json['can_cancel'] == true,
      canMarkAsJob: json['can_mark_as_job'] == true,
      hasJob: json['has_job'] == true,
    );
  }
}