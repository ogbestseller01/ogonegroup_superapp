// lib/models/request.dart

class ServiceRequest {
  final int id;
  final int technicianId;
  final int customerId;
  final String description;
  final String status;
  final DateTime createdAt;
  final String technicianName;
  final String serviceName;
  final String customerName;
  final String? customerPhone;          // ← NEW
  final String? technicianArea;
  final String? technicianPhone;
  final double? technicianRating;

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
    this.customerPhone,                 // ← NEW
    this.technicianArea,
    this.technicianPhone,
    this.technicianRating,
  });

  // Status helpers
  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isOnTheWay => status == 'on_the_way';
  bool get isArrived => status == 'arrived';
  bool get isInProgress => status == 'in_progress';
  bool get isCompleted => status == 'completed';
  bool get isRejected => status == 'rejected';
  bool get isCancelled => status == 'cancelled';

  bool get isActive =>
      isPending || isAccepted || isOnTheWay || isArrived || isInProgress;

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
      }
      techArea = tech['area']?.toString();
      if (tech['rating'] != null) {
        techRating = double.tryParse(tech['rating'].toString());
      }
    }

    if (techName == 'Unknown' && json['technician_name'] != null) {
      techName = json['technician_name'].toString();
    }

    // Customer data
    String customerName = 'Customer';
    String? customerPhone;
    int customerId = json['customer_id'] ?? 0;

    if (json['customer'] != null && json['customer'] is Map) {
      final customer = json['customer'] as Map;
      customerName = customer['name']?.toString() ?? customerName;
      customerPhone = customer['phone']?.toString();
      customerId = customer['id'] ?? customerId;
    }

    // Fallbacks for flat responses
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
      serviceName:
      json['service']?['name'] ?? json['service_name'] ?? 'Service',
      customerName: customerName,
      customerPhone: customerPhone,       // ← NEW
      technicianArea: techArea,
      technicianPhone: techPhone,
      technicianRating: techRating,
    );
  }
}