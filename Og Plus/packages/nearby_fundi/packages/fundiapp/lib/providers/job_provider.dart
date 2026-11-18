// lib/providers/job_provider.dart

import 'package:flutter/material.dart';
import '../models/job.dart';
import '../services/api_service.dart';

class JobProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<WorkJob> _jobs = [];
  bool _isLoading = false;
  String? _error;

  List<WorkJob> get jobs => List.unmodifiable(_jobs);
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<WorkJob> get pendingJobs =>
      _jobs.where((j) => j.status == 'pending').toList();
  List<WorkJob> get activeJobs =>
      _jobs.where((j) => !j.isCompleted).toList();
  List<WorkJob> get completedJobs =>
      _jobs.where((j) => j.isCompleted).toList();

  int countByStatus(String status) =>
      _jobs.where((j) => j.status == status).length;

  /// The job that was created automatically for an accepted request.
  WorkJob? jobForRequest(int requestId) {
    for (final j in _jobs) {
      if (j.requestId == requestId) return j;
    }
    return null;
  }

  /// [silent] = refresh in the background, no spinner and no error banner.
  Future<void> loadJobs({bool silent = false}) async {
    debugPrint('🔄 [JobProvider.loadJobs] silent=$silent');

    if (!silent) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      final res = await _api.getMyJobs();
      debugPrint('🔄 [loadJobs] success=${res.success} message=${res.message}');

      if (res.success) {
        _jobs = extractList(res.data)
            .whereType<Map>()
            .map((e) => WorkJob.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        debugPrint('🔄 [loadJobs] loaded ${_jobs.length} jobs '
            '(pending=${countByStatus('pending')} '
            'on-progress=${countByStatus('on-progress')} '
            'completed=${countByStatus('completed')})');
      } else if (!silent) {
        _error = res.message;
        _jobs = [];
      }
    } catch (e, st) {
      debugPrint('❌ [loadJobs] error: $e\n$st');
      if (!silent) {
        _error = 'Failed to load jobs: $e';
        _jobs = [];
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Reloads a single job (used by the detail screen).
  Future<WorkJob?> fetchJob(int id) async {
    try {
      final res = await _api.getJobDetail(id);
      if (res.success && res.data is Map) {
        final data = res.data as Map;
        final map = data['data'] is Map ? data['data'] as Map : data;
        return WorkJob.fromJson(Map<String, dynamic>.from(map));
      }
    } catch (e) {
      debugPrint('❌ fetchJob error: $e');
    }
    return null;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}