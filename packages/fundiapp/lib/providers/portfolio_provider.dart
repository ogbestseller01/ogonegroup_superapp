import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/portfolio.dart';

class PortfolioProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  List<PortfolioItem> _items = [];
  bool _isLoading = false;
  String? _error;

  List<PortfolioItem> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadPortfolio() async {
    _setLoading(true);
    final res = await _api.getMyPortfolios();
    if (res.success && res.data != null) {
      final List<dynamic> data = res.data is List ? res.data : res.data['data'] ?? [];
      _items = data.map((p) => PortfolioItem.fromJson(p)).toList();
      _error = null;
    } else {
      _error = res.message;
    }
    _setLoading(false);
  }

  Future<bool> addPortfolio(Map<String, dynamic> data) async {
    _setLoading(true);
    final res = await _api.createPortfolio(data);
    if (res.success) {
      await loadPortfolio();
      _setLoading(false);
      return true;
    }
    _error = res.message;
    _setLoading(false);
    return false;
  }

  Future<bool> updatePortfolio(int id, Map<String, dynamic> data) async {
    _setLoading(true);
    final res = await _api.updatePortfolio(id, data);
    if (res.success) {
      await loadPortfolio();
      _setLoading(false);
      return true;
    }
    _error = res.message;
    _setLoading(false);
    return false;
  }

  Future<bool> deletePortfolio(int id) async {
    _setLoading(true);
    final res = await _api.deletePortfolio(id);
    if (res.success) {
      await loadPortfolio();
      _setLoading(false);
      return true;
    }
    _error = res.message;
    _setLoading(false);
    return false;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    if (value) _error = null;
    notifyListeners();
  }
}