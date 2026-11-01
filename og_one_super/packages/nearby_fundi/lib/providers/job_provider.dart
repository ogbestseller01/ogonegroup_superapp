import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../models/job.dart';

/// Jobs + tickets. Tickets arrive nested inside each job, so there is one
/// source of truth and one API call.
///
/// Requires these ApiService methods:
///   getMyJobs(), markRequestAsJob(requestId),
///   requestJobCompletion(jobId), verifyJobCompletion(jobId, otp)
class JobProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<Job> _jobs = [];
  bool _isLoading = false;
  String? _error;

  final Set<int> _busyJobIds = {};

  List<Job> get jobs => List.unmodifiable(_jobs);
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<Job> get activeJobs => _jobs.where((j) => !j.isCompleted).toList();
  List<Job> get completedJobs => _jobs.where((j) => j.isCompleted).toList();

  /// Jobs that carry a ticket (every job created by Mark as Job does).
  List<Job> get jobsWithTicket => _jobs.where((j) => j.ticket != null).toList();

  bool isBusy(int jobId) => _busyJobIds.contains(jobId);

  // ── LOAD ──────────────────────────────────────────────────────────────
  Future<void> loadJobs() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _api.getMyJobs();
      if (res.success && res.data != null) {
        final raw = res.data;
        final list = raw is List ? raw : (raw is Map ? (raw['data'] ?? []) : []);
        _jobs = (list as List)
            .whereType<Map>()
            .map((e) => Job.fromJson(Map<String, dynamic>.from(e)))
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

  // ── MARK AS JOB (request accepted → in_progress + Job + Ticket) ───────
  Future<Job?> markAsJob(int requestId) async {
    _error = null;
    try {
      final res = await _api.markRequestAsJob(requestId);
      if (res.success && res.data is Map) {
        final job = Job.fromJson(Map<String, dynamic>.from(res.data as Map));
        _jobs = [job, ..._jobs.where((j) => j.id != job.id)];
        notifyListeners();
        return job;
      }
      _error = res.message;
    } catch (e) {
      _error = e.toString();
    }
    notifyListeners();
    return null;
  }

  // ── MARK COMPLETE (server generates the OTP) ──────────────────────────
  Future<bool> requestCompletion(int jobId) async {
    _busyJobIds.add(jobId);
    _error = null;
    notifyListeners();

    try {
      final res = await _api.requestJobCompletion(jobId);
      if (res.success) return true;
      _error = res.message;
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _busyJobIds.remove(jobId);
      notifyListeners();
    }
  }

  // ── ENTER OTP → job + ticket completed ────────────────────────────────
  Future<bool> verifyCompletion(int jobId, String otp) async {
    _busyJobIds.add(jobId);
    _error = null;
    notifyListeners();

    try {
      final res = await _api.verifyJobCompletion(jobId, otp);
      if (res.success && res.data is Map) {
        final updated = Job.fromJson(Map<String, dynamic>.from(res.data as Map));
        _jobs = _jobs.map((j) => j.id == updated.id ? updated : j).toList();
        return true;
      }
      _error = res.message;
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _busyJobIds.remove(jobId);
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}