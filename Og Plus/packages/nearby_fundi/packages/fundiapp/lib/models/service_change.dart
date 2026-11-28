// lib/models/service_change.dart

class CatalogCategory {
  final int id;
  final String nameEn;
  final String nameSw;

  CatalogCategory({
    required this.id,
    required this.nameEn,
    required this.nameSw,
  });

  factory CatalogCategory.fromJson(Map<String, dynamic> json) {
    return CatalogCategory(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      nameEn: json['name_en']?.toString() ?? json['name']?.toString() ?? '',
      nameSw: json['name_sw']?.toString() ?? json['name']?.toString() ?? '',
    );
  }

  String name(String lang) => lang == 'sw' ? nameSw : nameEn;
}

class CatalogService {
  final int id;
  final String nameEn;
  final String nameSw;
  final List<CatalogCategory> categories;

  CatalogService({
    required this.id,
    required this.nameEn,
    required this.nameSw,
    required this.categories,
  });

  factory CatalogService.fromJson(Map<String, dynamic> json) {
    final cats = <CatalogCategory>[];
    if (json['categories'] is List) {
      for (final c in json['categories']) {
        if (c is Map) {
          cats.add(CatalogCategory.fromJson(Map<String, dynamic>.from(c)));
        }
      }
    }
    return CatalogService(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      nameEn: json['name_en']?.toString() ?? json['name']?.toString() ?? '',
      nameSw: json['name_sw']?.toString() ?? json['name']?.toString() ?? '',
      categories: cats,
    );
  }

  String name(String lang) => lang == 'sw' ? nameSw : nameEn;
}

class ServiceChangeRequest {
  final int id;
  final String status; // pending | approved | rejected
  final String reason;
  final String? rejectionReason;
  final List<int> addedIds;
  final List<int> removedIds;
  final DateTime? createdAt;

  ServiceChangeRequest({
    required this.id,
    required this.status,
    required this.reason,
    this.rejectionReason,
    required this.addedIds,
    required this.removedIds,
    this.createdAt,
  });

  bool get isPending => status == 'pending';
  bool get isRejected => status == 'rejected';
  bool get isApproved => status == 'approved';

  factory ServiceChangeRequest.fromJson(Map<String, dynamic> json) {
    List<int> parseIds(dynamic raw) {
      if (raw is! List) return [];
      return raw
          .map((e) => e is int ? e : int.tryParse('$e'))
          .whereType<int>()
          .toList();
    }

    return ServiceChangeRequest(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      status: json['status']?.toString() ?? 'pending',
      reason: json['reason']?.toString() ?? '',
      rejectionReason: json['rejection_reason']?.toString(),
      addedIds: parseIds(json['added_service_ids'] ?? json['added_ids']),
      removedIds: parseIds(json['removed_service_ids'] ?? json['removed_ids']),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }
}

class ServiceChangeOptions {
  final List<CatalogService> services;
  final Set<int> currentIds;
  final Set<int> blockedIds;
  final ServiceChangeRequest? latest;

  ServiceChangeOptions({
    required this.services,
    required this.currentIds,
    required this.blockedIds,
    this.latest,
  });

  factory ServiceChangeOptions.fromJson(Map<String, dynamic> json) {
    final services = <CatalogService>[];
    if (json['services'] is List) {
      for (final s in json['services']) {
        if (s is Map) {
          services.add(CatalogService.fromJson(Map<String, dynamic>.from(s)));
        }
      }
    }

    Set<int> parseIdSet(dynamic raw) {
      if (raw is! List) return {};
      return raw
          .map((e) => e is int ? e : int.tryParse('$e'))
          .whereType<int>()
          .toSet();
    }

    ServiceChangeRequest? latest;
    if (json['latest_request'] is Map) {
      latest = ServiceChangeRequest.fromJson(
        Map<String, dynamic>.from(json['latest_request'] as Map),
      );
    } else if (json['pending_request'] is Map) {
      latest = ServiceChangeRequest.fromJson(
        Map<String, dynamic>.from(json['pending_request'] as Map),
      );
    }

    return ServiceChangeOptions(
      services: services,
      currentIds: parseIdSet(json['current_service_ids'] ?? json['current_ids']),
      blockedIds: parseIdSet(json['blocked_service_ids'] ?? json['blocked_ids']),
      latest: latest,
    );
  }
}