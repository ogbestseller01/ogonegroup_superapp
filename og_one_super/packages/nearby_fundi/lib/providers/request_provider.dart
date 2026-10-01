import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../models/request.dart';

class RequestProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<ServiceRequest> _requests = [];

  bool _isLoading = false;
  bool _isSubmitting = false;

  String? _error;

  double _submissionProgress = 0.0;

  // Track pending operations
  final Set<int> _pendingCancelIds = {};
  final Set<int> _pendingCreateIds = {};

  // ─────────────────────────────────────────────────────────────────────────
  // GETTERS
  // ─────────────────────────────────────────────────────────────────────────

  List<ServiceRequest> get requests =>
      List.unmodifiable(_requests);

  bool get isLoading => _isLoading;

  bool get isSubmitting => _isSubmitting;

  String? get error => _error;

  double get submissionProgress =>
      _submissionProgress;

  // ─────────────────────────────────────────────────────────────────────────
  // STATUS COUNTS
  // ─────────────────────────────────────────────────────────────────────────

  int get pendingCount =>
      _requests.where((r) => r.isPending).length;

  int get acceptedCount =>
      _requests.where((r) => r.isAccepted).length;

  int get onTheWayCount =>
      _requests.where((r) => r.isOnTheWay).length;

  int get arrivedCount =>
      _requests.where((r) => r.isArrived).length;

  int get inProgressCount =>
      _requests.where((r) => r.isInProgress).length;

  int get completedCount =>
      _requests.where((r) => r.isCompleted).length;

  int get cancelledCount =>
      _requests.where((r) => r.isCancelled).length;

  int get rejectedCount =>
      _requests.where((r) => r.isRejected).length;

  int get activeCount =>
      _requests.where((r) => r.isActive).length;

  int get terminalCount =>
      _requests.where((r) => r.isTerminal).length;

  // ─────────────────────────────────────────────────────────────────────────
  // ACTIVE REQUEST CHECK
  //
  // THIS IS THE IMPORTANT METHOD.
  //
  // Only active requests block a new request.
  // Completed/cancelled/rejected do NOT block.
  // ─────────────────────────────────────────────────────────────────────────

  bool hasActiveRequest(int technicianId) {
    return _requests.any(
          (request) =>
      request.technicianId == technicianId &&
          request.isActive,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CHECK SPECIFIC STATUS
  // ─────────────────────────────────────────────────────────────────────────

  bool hasRequestWithStatus(
      int technicianId,
      String status,
      ) {
    return _requests.any(
          (request) =>
      request.technicianId == technicianId &&
          request.status == status,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CAN MAKE NEW REQUEST
  //
  // IMPORTANT:
  //
  // No active request = YES
  //
  // Therefore:
  //
  // completed = YES
  // cancelled = YES
  // rejected  = YES
  //
  // pending = NO
  // accepted = NO
  // on_the_way = NO
  // arrived = NO
  // in_progress = NO
  // ─────────────────────────────────────────────────────────────────────────

  bool canMakeNewRequest(int technicianId) {
    return !hasActiveRequest(technicianId);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // GET ACTIVE REQUEST
  // ─────────────────────────────────────────────────────────────────────────

  ServiceRequest? getActiveRequest(
      int technicianId,
      ) {
    for (final request in _requests) {
      if (request.technicianId == technicianId &&
          request.isActive) {
        return request;
      }
    }

    return null;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // GET LATEST REQUEST
  // ─────────────────────────────────────────────────────────────────────────

  ServiceRequest? getLatestRequest(
      int technicianId,
      ) {
    final technicianRequests = _requests
        .where(
          (request) =>
      request.technicianId == technicianId,
    )
        .toList();

    if (technicianRequests.isEmpty) {
      return null;
    }

    technicianRequests.sort(
          (a, b) =>
          b.createdAt.compareTo(a.createdAt),
    );

    return technicianRequests.first;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STATUS MESSAGE
  // ─────────────────────────────────────────────────────────────────────────

  String getStatusMessage(int technicianId) {
    final active =
    getActiveRequest(technicianId);

    if (active != null) {
      return 'Request is ${active.statusLabel}';
    }

    final latest =
    getLatestRequest(technicianId);

    if (latest == null) {
      return 'You can make a new request';
    }

    if (latest.isCancelled) {
      return 'Previous request was cancelled. You can make a new request.';
    }

    if (latest.isRejected) {
      return 'Previous request was rejected. You can make a new request.';
    }

    if (latest.isCompleted) {
      return 'Previous request was completed. You can make a new request.';
    }

    return 'You can make a new request';
  }

  // ─────────────────────────────────────────────────────────────────────────
  // LOAD MY REQUESTS
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> loadMyRequests() async {
    _isLoading = true;
    _error = null;

    notifyListeners();

    try {
      final res =
      await _api.getMyRequests();

      if (res.success && res.data != null) {
        final rawData = res.data;

        List<dynamic> dataList;

        if (rawData is List) {
          dataList = rawData;
        } else if (rawData is Map) {
          final value =
              rawData['data'] ??
                  rawData['requests'] ??
                  rawData['results'] ??
                  [];

          dataList =
          value is List ? value : [];
        } else {
          dataList = [];
        }

        _requests = dataList
            .whereType<Map>()
            .map(
              (item) =>
              ServiceRequest.fromJson(
                Map<String, dynamic>.from(
                  item,
                ),
              ),
        )
            .toList();

        debugPrint(
          '🔄 Loaded ${_requests.length} requests',
        );

        for (final request in _requests) {
          debugPrint(
            '📝 Request #${request.id} '
                '- Tech: ${request.technicianId} '
                '- Status: ${request.status} '
                '- Active: ${request.isActive}',
          );
        }
      } else {
        _error =
            res.message ??
                'Failed to load requests';
      }
    } catch (e) {
      _error = e.toString();

      debugPrint(
        '❌ Error loading requests: $e',
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CREATE REQUEST
  //
  // Prevents duplicate ACTIVE requests only.
  //
  // A completed/cancelled/rejected request does NOT prevent creation.
  // ─────────────────────────────────────────────────────────────────────────

  Future<bool> createRequest({
    required int technicianId,
    required int serviceId,
    required String description,
    int? categoryId,
    double? latitude,
    double? longitude,
  }) async {
    if (_isSubmitting) {
      return false;
    }

    // ──────────────────────────────────────────────
    // PREVENT DUPLICATE ACTIVE REQUEST
    // ──────────────────────────────────────────────

    if (hasActiveRequest(technicianId)) {
      _error =
      'You already have an active request with this technician.';

      notifyListeners();

      return false;
    }

    // ──────────────────────────────────────────────
    // START SUBMISSION
    // ──────────────────────────────────────────────

    _submissionProgress = 0.0;

    _isSubmitting = true;
    _isLoading = true;

    _error = null;

    notifyListeners();

    void updateProgress(double value) {
      _submissionProgress = value;
      notifyListeners();
    }

    try {
      updateProgress(0.1);

      final res =
      await _api.createRequest(
        technicianId: technicianId,
        serviceId: serviceId,
        description: description,
        categoryId: categoryId,
        latitude: latitude,
        longitude: longitude,
      );

      updateProgress(0.6);

      if (res.success) {
        _submissionProgress = 1.0;

        notifyListeners();

        await Future.delayed(
          const Duration(
            milliseconds: 300,
          ),
        );

        // Reload requests so the newly created
        // active request immediately blocks
        // another request.
        await loadMyRequests();

        return true;
      }

      _error =
          res.message ??
              'Failed to create request';

      _submissionProgress = 0.0;

      notifyListeners();

      debugPrint(
        '❌ Create request error: ${res.message}',
      );

      return false;
    } catch (e) {
      _error = e.toString();

      _submissionProgress = 0.0;

      debugPrint(
        '❌ Error creating request: $e',
      );

      notifyListeners();

      return false;
    } finally {
      _isLoading = false;
      _isSubmitting = false;

      notifyListeners();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CANCEL REQUEST
  //
  // Only pending and accepted can be cancelled.
  // ─────────────────────────────────────────────────────────────────────────

  Future<bool> cancelRequest(int id) async {
    ServiceRequest? request;

    try {
      request = _requests.firstWhere(
            (r) => r.id == id,
      );
    } catch (_) {
      _error = 'Request not found';

      notifyListeners();

      return false;
    }

    if (!request.canBeCancelled) {
      _error =
      'Only pending or accepted requests can be cancelled. '
          'Current status: ${request.statusLabel}';

      notifyListeners();

      return false;
    }

    _isLoading = true;
    _error = null;

    _pendingCancelIds.add(id);

    notifyListeners();

    try {
      final res =
      await _api.cancelRequest(id);

      if (!res.success) {
        _error =
            res.message ??
                'Failed to cancel request';

        return false;
      }

      // Reload the complete request list.
      //
      // IMPORTANT:
      // We do NOT remove the old request.
      // It remains in request history as "cancelled".
      await loadMyRequests();

      final updatedRequest =
      getRequestById(id);

      if (updatedRequest != null &&
          updatedRequest.isCancelled) {
        debugPrint(
          '✅ Request #$id cancelled successfully',
        );

        return true;
      }

      // One more refresh in case backend
      // response was delayed.
      await loadMyRequests();

      final reloadedRequest =
      getRequestById(id);

      return reloadedRequest?.isCancelled ??
          false;
    } catch (e) {
      _error = e.toString();

      debugPrint(
        '❌ Error cancelling request: $e',
      );

      return false;
    } finally {
      _isLoading = false;

      _pendingCancelIds.remove(id);

      notifyListeners();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // GET REQUEST BY ID
  // ─────────────────────────────────────────────────────────────────────────

  ServiceRequest? getRequestById(int id) {
    for (final request in _requests) {
      if (request.id == id) {
        return request;
      }
    }

    return null;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // UPDATE REQUEST STATUS
  // ─────────────────────────────────────────────────────────────────────────

  Future<bool> updateRequestStatus(
      int id,
      String status,
      ) async {
    _isLoading = true;
    _error = null;

    notifyListeners();

    try {
      final res =
      await _api.updateRequestStatus(
        id,
        status,
      );

      if (res.success) {
        await loadMyRequests();

        return true;
      }

      _error = res.message;

      return false;
    } catch (e) {
      _error = e.toString();

      return false;
    } finally {
      _isLoading = false;

      notifyListeners();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // RESET PROGRESS
  // ─────────────────────────────────────────────────────────────────────────

  void resetProgress() {
    _submissionProgress = 0.0;

    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CLEAR ERROR
  // ─────────────────────────────────────────────────────────────────────────

  void clearError() {
    _error = null;

    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CHECK IF REQUEST IS CURRENTLY BEING CANCELLED
  // ─────────────────────────────────────────────────────────────────────────

  bool isCancelling(int requestId) {
    return _pendingCancelIds.contains(
      requestId,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CHECK IF REQUEST IS CURRENTLY BEING CREATED
  // ─────────────────────────────────────────────────────────────────────────

  bool isCreating(int technicianId) {
    return _pendingCreateIds.contains(
      technicianId,
    );
  }
}