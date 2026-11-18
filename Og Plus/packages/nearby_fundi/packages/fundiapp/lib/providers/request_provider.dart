// lib/providers/request_provider.dart
import 'package:flutter/material.dart';
import '../models/request.dart';
import '../services/api_service.dart';

class RequestProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  static const _validStatuses = ['pending', 'accepted', 'cancelled', 'rejected'];

  List<ServiceRequest> _requests = [];
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _error;
  double _submissionProgress = 0.0;

  /// Requests with an accept / reject / cancel call in flight.
  /// Tracked per request so the whole screen never swaps to a spinner.
  final Set<int> _pendingActionIds = {};

  // ─── Getters ────────────────────────────────────────────────
  List<ServiceRequest> get requests => List.unmodifiable(_requests);
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get error => _error;
  double get submissionProgress => _submissionProgress;

  List<ServiceRequest> get pendingRequests =>
      _requests.where((r) => r.isPending).toList();
  List<ServiceRequest> get acceptedRequests =>
      _requests.where((r) => r.isAccepted).toList();

  int get pendingCount => pendingRequests.length;
  int get acceptedCount => acceptedRequests.length;
  int get totalCount => _requests.length;

  bool isActing(int requestId) => _pendingActionIds.contains(requestId);

  ServiceRequest? getRequestById(int id) {
    for (final r in _requests) {
      if (r.id == id) return r;
    }
    return null;
  }

  bool hasActiveRequest(int technicianId) {
    return _requests.any((r) => r.technicianId == technicianId && r.isActive);
  }

  // ─── Load My Requests ───────────────────────────────────────
  /// [silent] = refresh in the background: no spinner, and the current list
  /// is kept if the call fails.
  Future<void> loadMyRequests({bool silent = false}) async {
    debugPrint('🔄 [RequestProvider.loadMyRequests] silent=$silent');

    if (!silent) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      final res = await _api.getMyRequests();
      debugPrint('🔄 [loadMyRequests] success=${res.success} message=${res.message}');

      if (res.success && res.data != null) {
        final data = res.data;
        List<dynamic> requestsData = [];

        if (data is List) {
          requestsData = data;
        } else if (data is Map && data.containsKey('data')) {
          if (data['data'] is List) {
            requestsData = data['data'];
          } else if (data['data'] is Map && data['data'].containsKey('data')) {
            requestsData = data['data']['data'] as List? ?? [];
          }
        }

        _requests = requestsData
            .whereType<Map>()
            .map((e) => ServiceRequest.fromJson(Map<String, dynamic>.from(e)))
            .toList();

        debugPrint('🔄 [loadMyRequests] loaded ${_requests.length} requests '
            '(pending=$pendingCount accepted=$acceptedCount)');
      } else if (!silent) {
        _error = res.message ?? 'Failed to load requests';
        _requests = [];
      }
    } catch (e, st) {
      debugPrint('❌ [loadMyRequests] error: $e\n$st');
      if (!silent) {
        _error = 'Failed to load requests: $e';
        _requests = [];
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  // ─── Create Request ─────────────────────────────────────────
  Future<bool> createRequest({
    required int technicianId,
    required int serviceId,
    required String description,
    int? categoryId,
    double? latitude,
    double? longitude,
  }) async {
    if (_isSubmitting) return false;

    _submissionProgress = 0.0;
    _isSubmitting = true;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _submissionProgress = 0.2;
      notifyListeners();

      final res = await _api.createRequest({
        'technician_id': technicianId,
        'service_id': serviceId,
        'description': description,
        if (categoryId != null) 'category_id': categoryId,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      });

      _submissionProgress = 0.7;
      notifyListeners();

      if (res.success) {
        _submissionProgress = 1.0;
        notifyListeners();
        await Future.delayed(const Duration(milliseconds: 300));
        await loadMyRequests();
        return true;
      } else {
        _error = res.message ?? 'Failed to create request';
        return false;
      }
    } catch (e) {
      _error = 'Failed to create request: $e';
      debugPrint('❌ createRequest error: $e');
      return false;
    } finally {
      _isSubmitting = false;
      _isLoading = false;
      _submissionProgress = 0.0;
      notifyListeners();
    }
  }

  // ─── Update Status (pending → accepted | rejected | cancelled) ──────────
  // Accepting also makes the backend create the Job + Ticket (pending).
  Future<bool> updateStatus(int id, String status) async {
    debugPrint('🔵 [RequestProvider.updateStatus] request=$id → $status');

    if (!_validStatuses.contains(status)) {
      debugPrint('❌ [updateStatus] invalid status "$status"');
      _error = 'Invalid status';
      notifyListeners();
      return false;
    }

    if (_pendingActionIds.contains(id)) {
      debugPrint('⚠️ [updateStatus] request=$id already in flight, ignored');
      return false;
    }

    _pendingActionIds.add(id);
    _error = null;
    notifyListeners();

    try {
      final res = await _api.updateRequestStatus(id, status);
      debugPrint('🔵 [updateStatus] response success=${res.success} '
          'message=${res.message} data=${res.data}');

      if (res.success) {
        await loadMyRequests(silent: true); // no spinner, list stays on screen
        return true;
      }

      _error = res.message ?? 'Failed to update status';
      debugPrint('❌ [updateStatus] server refused: $_error');
      return false;
    } catch (e, st) {
      _error = 'Failed to update status: $e';
      debugPrint('❌ [updateStatus] exception: $e\n$st');
      return false;
    } finally {
      _pendingActionIds.remove(id);
      notifyListeners();
    }
  }

  // ─── Cancel Request (customer only, pending → cancelled) ────────────────
  Future<bool> cancelRequest(int id) async {
    debugPrint('🔵 [RequestProvider.cancelRequest] request=$id');

    if (_pendingActionIds.contains(id)) return false;

    _pendingActionIds.add(id);
    _error = null;
    notifyListeners();

    try {
      final res = await _api.cancelRequest(id);
      debugPrint('🔵 [cancelRequest] success=${res.success} message=${res.message}');

      if (res.success) {
        await loadMyRequests(silent: true);
        return true;
      }
      _error = res.message ?? 'Failed to cancel request';
      return false;
    } catch (e, st) {
      _error = 'Failed to cancel request: $e';
      debugPrint('❌ [cancelRequest] exception: $e\n$st');
      return false;
    } finally {
      _pendingActionIds.remove(id);
      notifyListeners();
    }
  }

  // ─── Convenience Methods ────────────────────────────────────
  Future<bool> acceptRequest(int id) => updateStatus(id, 'accepted');
  Future<bool> rejectRequest(int id) => updateStatus(id, 'rejected');

  // ─── Helpers ────────────────────────────────────────────────
  void clearError() {
    _error = null;
    notifyListeners();
  }

  void resetProgress() {
    _submissionProgress = 0.0;
    notifyListeners();
  }

  Future<void> refresh() => loadMyRequests(silent: true);
}