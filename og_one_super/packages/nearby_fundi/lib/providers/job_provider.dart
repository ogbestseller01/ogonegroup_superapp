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

  /// Completed jobs the customer has not reviewed yet.
  List<Job> get jobsAwaitingReview => _jobs.where((j) => j.canReview).toList();

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

  /// [silent] = refresh in the background, no spinner and no error banner.
  Future<void> loadJobs({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      final res = await _api.getMyJobs();
      if (res.success && res.data != null) {
        _jobs = _extractList(res.data)
            .whereType<Map>()
            .map((e) => Job.fromJson(Map<String, dynamic>.from(e)))
            .where((j) => Job.allStatuses.contains(j.status))
            .toList();
      } else if (!silent) {
        _error = res.message;
      }
    } catch (e) {
      if (!silent) _error = e.toString();
      debugPrint('❌ Error loading jobs: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Re-fetch ONE job from the server and replace it in the list.
  Future<void> refreshJob(int id) async {
    try {
      final res = await _api.getJob(id);
      if (res.success && res.data is Map) {
        final fresh = Job.fromJson(Map<String, dynamic>.from(res.data as Map));
        final i = _jobs.indexWhere((j) => j.id == id);
        final next = [..._jobs];
        if (i == -1) {
          next.insert(0, fresh);
        } else {
          next[i] = fresh;
        }
        _jobs = next;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ refreshJob failed: $e');
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
        await refreshJob(jobId);

        // If the refresh failed, still show "completed" locally.
        final j = getJobById(jobId);
        if (j != null && !j.isCompleted) {
          _jobs = _jobs
              .map((e) => e.id == jobId
              ? e.copyWith(
            status: Job.completedStatus,
            completedAt: DateTime.now(),
          )
              : e)
              .toList();
          notifyListeners();
        }
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

  /// Customer submits rating (1-5) + remark for a completed job.
  /// The review shows on the job immediately; screens then call refreshJob().
  Future<bool> submitReview(
      int jobId, {
        required int rating,
        String? comment,
      }) async {
    _error = null;
    try {
      final res =
      await _api.submitJobReview(jobId, rating: rating, comment: comment);

      if (res.success) {
        JobReview? review;
        if (res.data is Map) {
          review =
              JobReview.fromJson(Map<String, dynamic>.from(res.data as Map));
        }
        review ??= JobReview(
          id: 0,
          rating: rating.toDouble(),
          comment: (comment == null || comment.trim().isEmpty)
              ? null
              : comment.trim(),
          createdAt: DateTime.now(),
        );

        _jobs = _jobs
            .map((j) => j.id == jobId ? j.copyWith(review: review) : j)
            .toList();
        notifyListeners();
        return true;
      }

      _error = res.message;

      // Already reviewed on the server → pull that review into the UI.
      if (res.message.toLowerCase().contains('already been reviewed')) {
        await refreshJob(jobId);
      }

      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ submitReview failed: $e');
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}