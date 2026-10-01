// providers/service_provider.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/service.dart';

class ServiceProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  List<Service> _services = [];
  List<ServiceCategory> _allCategories = [];
  bool _isLoading = false;
  String? _error;
  String _currentLocale = 'en';

  List<Service> get services => _services;
  List<ServiceCategory> get allCategories => _allCategories;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get currentLocale => _currentLocale;

  List<Service> get localizedServices {
    return _services.map((service) {
      return Service(
        id: service.id,
        name: service.getDisplayName(_currentLocale),
        nameEn: service.nameEn,
        nameSw: service.nameSw,
        categories: service.categories?.map((category) {
          return ServiceCategory(
            id: category.id,
            name: category.getDisplayName(_currentLocale),
            nameEn: category.nameEn,
            nameSw: category.nameSw,
            slug: category.slug,
          );
        }).toList(),
      );
    }).toList();
  }

  List<Service> searchServices(String query) {
    if (query.isEmpty) return localizedServices;
    final lowerQuery = query.toLowerCase().trim();
    return localizedServices.where((service) =>
        service.matchesSearch(lowerQuery, _currentLocale)
    ).toList();
  }

  List<ServiceCategory> searchCategories(String query) {
    if (query.isEmpty) return _allCategories;
    final lowerQuery = query.toLowerCase().trim();
    return _allCategories.where((category) =>
        category.matchesSearch(lowerQuery, _currentLocale)
    ).toList();
  }

  Future<void> fetchServices({String locale = 'en'}) async {
    _currentLocale = locale;

    _isLoading = true;
    _error = null;
    notifyListeners();

    final res = await _api.getServicesWithCategories(locale: locale);
    if (res.success && res.data != null) {
      _services = (res.data as List).map((e) => Service.fromJson(e)).toList();

      final allCats = <ServiceCategory>{};
      for (var service in _services) {
        if (service.categories != null) {
          allCats.addAll(service.categories!);
        }
      }
      _allCategories = allCats.toList();
    } else {
      _error = res.message;
    }

    _isLoading = false;
    notifyListeners();
  }

  List<ServiceCategory> getCategoriesForService(int serviceId) {
    final service = _services.firstWhere(
          (s) => s.id == serviceId,
      orElse: () => Service(id: 0, name: ''),
    );
    return service.categories ?? [];
  }

  void setLocale(String locale) {
    if (_currentLocale != locale) {
      _currentLocale = locale;
      notifyListeners();
    }
  }
}