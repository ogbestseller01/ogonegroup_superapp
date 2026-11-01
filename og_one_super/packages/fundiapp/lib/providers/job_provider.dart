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

  int countByStatus(String status) =>
      _jobs.where((j) => j.status == status).length;

  Future<void> loadJobs() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _api.getMyJobs();
      if (res.success) {
        _jobs = extractList(res.data)
            .whereType<Map>()
            .map((e) => WorkJob.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      } else {
        _error = res.message;
        _jobs = [];
      }
    } catch (e) {
      _error = 'Failed to load jobs: $e';
      _jobs = [];
      debugPrint('❌ loadJobs error: $e');
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