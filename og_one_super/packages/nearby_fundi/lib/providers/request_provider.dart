import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../models/request.dart';

class RequestProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<ServiceRequest> _requests = [];

  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _error;

  final Set<int> _pendingCancelIds = {};
  final Set<int> _pendingActionIds = {};

  // ── GETTERS ───────────────────────────────────────────────────────────
  List<ServiceRequest> get requests => List.unmodifiable(_requests);
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get error => _error;

  // ── COUNTS ────────────────────────────────────────────────────────────
  int get totalCount => _requests.length;
  int get pendingCount => _requests.where((r) => r.isPending).length;
  int get acceptedCount => _requests.where((r) => r.isAccepted).length;
  int get inProgressCount => _requests.where((r) => r.isInProgress).length;

  // ── RULES ─────────────────────────────────────────────────────────────
  /// A PENDING request to this fundi blocks sending another one.
  bool hasActiveRequest(int technicianId) =>
      _requests.any((r) => r.technicianId == technicianId && r.isActive);

  ServiceRequest? getRequestById(int id) {
    for (final r in _requests) {
      if (r.id == id) return r;
    }
    return null;
  }

  bool isCancelling(int requestId) => _pendingCancelIds.contains(requestId);
  bool isActing(int requestId) => _pendingActionIds.contains(requestId);

  // ── LOAD ──────────────────────────────────────────────────────────────
  Future<void> loadMyRequests() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _api.getMyRequests();

      if (res.success && res.data != null) {
        final raw = res.data;
        List<dynamic> list = [];

        if (raw is List) {
          list = raw;
        } else if (raw is Map) {
          final v = raw['data'] ?? raw['requests'] ?? raw['results'] ?? [];
          list = v is List ? v : [];
        }

        _requests = list
            .whereType<Map>()
            .map((e) => ServiceRequest.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      } else {
        _error = res.message;
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Error loading requests: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── CREATE ────────────────────────────────────────────────────────────
  // The server notifies the fundi by in-app/push + SMS + email.
  Future<bool> createRequest({
    required int technicianId,
    required int serviceId,
    required String description,
    int? categoryId,
    double? latitude,
    double? longitude,
  }) async {
    if (_isSubmitting) return false;

    if (hasActiveRequest(technicianId)) {
      _error = 'You already have a pending request with this fundi.';
      notifyListeners();
      return false;
    }

    _isSubmitting = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _api.createRequest(
        technicianId: technicianId,
        serviceId: serviceId,
        description: description,
        categoryId: categoryId,
        latitude: latitude,
        longitude: longitude,
      );

      if (res.success) {
        await loadMyRequests();
        return true;
      }

      _error = res.message;
      return false;
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Error creating request: $e');
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  // ── CANCEL (customer, pending only) ───────────────────────────────────
  Future<bool> cancelRequest(int id) async {
    final request = getRequestById(id);

    if (request == null) {
      _error = 'Request not found';
      notifyListeners();
      return false;
    }

    if (!request.canBeCancelled) {
      _error = request.isAccepted || request.isInProgress
          ? 'An accepted request can no longer be cancelled.'
          : 'This request is already ${request.statusLabel.toLowerCase()}.';
      notifyListeners();
      return false;
    }

    _pendingCancelIds.add(id);
    _error = null;
    notifyListeners();

    try {
      final res = await _api.cancelRequest(id);

      if (!res.success) {
        _error = res.message;
        return false;
      }

      await loadMyRequests();
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Error cancelling request: $e');
      return false;
    } finally {
      _pendingCancelIds.remove(id);
      notifyListeners();
    }
  }

  // ── FUNDI: ACCEPT / REJECT (pending only) ─────────────────────────────
  Future<bool> acceptRequest(int id) =>
      _answer(id, ServiceRequest.acceptedStatus);

  Future<bool> rejectRequest(int id) =>
      _answer(id, ServiceRequest.rejectedStatus);

  Future<bool> _answer(int id, String status) async {
    final request = getRequestById(id);

    if (request != null && !request.canBeAnswered) {
      _error = 'This request is already ${request.statusLabel.toLowerCase()} '
          'and can no longer be changed.';
      notifyListeners();
      return false;
    }

    _pendingActionIds.add(id);
    _error = null;
    notifyListeners();

    try {
      final res = await _api.updateRequestStatus(id, status);

      if (!res.success) {
        _error = res.message;
        return false;
      }

      await loadMyRequests();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _pendingActionIds.remove(id);
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
