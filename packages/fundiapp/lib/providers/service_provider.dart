import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/service.dart';

class ServiceProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  List<Service> _services = [];
  bool _isLoading = false;
  String? _error;

  List<Service> get services => _services;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchServices({bool forceRefresh = false}) async {
    if (!forceRefresh && _services.isNotEmpty) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    final res = await _api.getServices();

    // ============================================================
    // 🔍 DEBUG LOGGING — remove once the root cause is confirmed
    // ============================================================
    debugPrint('┌─────────────────────────────────────────────');
    debugPrint('│ [ServiceProvider] fetchServices()');
    debugPrint('│ success: ${res.success}');
    debugPrint('│ message: ${res.message}');
    debugPrint('│ data == null: ${res.data == null}');
    debugPrint('│ data runtimeType: ${res.data.runtimeType}');
    if (res.data is List) {
      debugPrint('│ catalog service count: ${(res.data as List).length}');
    }
    debugPrint('└─────────────────────────────────────────────');
    // ============================================================

    if (res.success && res.data != null) {
      _services = (res.data as List)
          .map((e) => Service.fromJson(e as Map<String, dynamic>))
          .toList();

      debugPrint('✅ [ServiceProvider] Parsed ${_services.length} catalog services');
    } else {
      _error = res.message;
      debugPrint('❌ [ServiceProvider] fetchServices FAILED: ${res.message}');
    }

    _isLoading = false;
    notifyListeners();
  }
}