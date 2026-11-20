import 'package:flutter/material.dart';

import '../models/service.dart';
import '../services/api_service.dart';

class ServiceProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<Service> _services = [];
  bool _isLoading = false;
  String? _error;
  String? _loadedLocale;

  List<Service> get services => List.unmodifiable(_services);
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchServices({
    bool forceRefresh = false,
    String locale = 'en',
  }) async {
    if (!forceRefresh && _services.isNotEmpty && _loadedLocale == locale) {
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _api.getServices(locale: locale);

      if (res.success && res.data != null) {
        _services = (res.data as List)
            .map((e) => Service.fromJson(e as Map<String, dynamic>))
            .toList();
        _loadedLocale = locale;
      } else {
        _error = res.message;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clear() {
    _services = [];
    _error = null;
    _loadedLocale = null;
    notifyListeners();
  }
}