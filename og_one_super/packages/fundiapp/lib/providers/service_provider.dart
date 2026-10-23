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

  // In ServiceProvider – change fetchServices to accept locale

  Future<void> fetchServices({bool forceRefresh = false, String locale = 'en'}) async {
    if (!forceRefresh && _services.isNotEmpty) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    // Pass locale so API can use Accept-Language (or query)
    final res = await _api.getServices(locale: locale);

    if (res.success && res.data != null) {
      _services = (res.data as List)
          .map((e) => Service.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      _error = res.message;
    }

    _isLoading = false;
    notifyListeners();
  }
}