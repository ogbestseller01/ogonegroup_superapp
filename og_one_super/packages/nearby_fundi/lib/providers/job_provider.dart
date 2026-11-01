// lib/providers/job_provider.dart
import 'package:flutter/material.dart';

import '../models/job.dart';
import '../services/api_service.dart';

class JobProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<Job> _jobs = [];
  bool _isLoading = false;
  String? _error;

  List<Job> get jobs => List.unmodifiable(_jobs);
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<Job> get activeJobs => _jobs.where((j) => !j.isCompleted).toList();
  List<Job> get completedJobs => _jobs.where((j) => j.isCompleted).toList();
  List<Job> get jobsWithTicket => _jobs.where((j) => j.ticket != null).toList();

  Job? getJobById(int id) {
    for (final j in _jobs) {
      if (j.id == id) return j;
    }
    return null;
  }

  List<dynamic> _extractList(dynamic raw) {
    if (raw is List) return raw;
    if (raw is Map) {
      final v = raw['data'] ?? raw['jobs'] ?? raw['results'] ?? [];
      return v is List ? v : [];
    }
    return [];
  }

  Future<void> loadJobs() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _api.getMyJobs();
      if (res.success && res.data != null) {
        _jobs = _extractList(res.data)
            .whereType()
            .map((e) => Job.fromJson(Map<String, dynamic>.from(e)))
            .where((j) => Job.allStatuses.contains(j.status))
            .toList();
      } else {
        _error = res.message;
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Error loading jobs: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Job?> ensureJob(int id) async {
    final cached = getJobById(id);
    if (cached != null) return cached;
    await loadJobs();
    return getJobById(id);
  }

  Future<Job?> markAsJob(int requestId) async {
    _error = null;
    try {
      final res = await _api.markAsJob(requestId);
      if (res.success && res.data is Map) {
        final job = Job.fromJson(Map<String, dynamic>.from(res.data as Map));
        _jobs = [job, ..._jobs.where((j) => j.id != job.id)];
        notifyListeners();
        return job;
      }
      _error = res.message;
      notifyListeners();
      return null;
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ markAsJob failed: $e');
      notifyListeners();
      return null;
    }
  }

  Future<bool> requestCompletion(int jobId) async {
    _error = null;
    try {
      final res = await _api.requestCompletion(jobId);
      if (res.success) return true;
      _error = res.message;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyCompletion(int jobId, String code) async {
    _error = null;
    try {
      final res = await _api.verifyCompletion(jobId, code);
      if (res.success) {
        await loadJobs();
        return true;
      }
      _error = res.message;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}