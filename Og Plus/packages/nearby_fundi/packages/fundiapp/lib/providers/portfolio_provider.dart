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
    try {
      final res = await _api.getMyPortfolios();
      if (res.success && res.data != null) {
        final List<dynamic> data = res.data is List ? res.data : res.data['data'] ?? [];
        _items = data.map((p) => PortfolioItem.fromJson(p)).toList();
        _error = null;
      } else {
        _error = res.message;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> addPortfolio(List<String> imagePaths) async {
    if (imagePaths.isEmpty) {
      _error = 'Please select at least one image.';
      notifyListeners();
      return false;
    }

    _setLoading(true);
    try {
      final res = await _api.createPortfolio(imagePaths);
      if (res.success) {
        await loadPortfolio();
        return true;
      }
      _error = res.message;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
    return false;
  }

  /// ✅ UPDATED: Update existing post (append new images, delete specific images)
  Future<bool> updatePortfolio(
      int id, {
        List<String>? newImagePaths,
        List<int>? deleteImageIds,
      }) async {
    _setLoading(true);
    try {
      final res = await _api.updatePortfolio(
        id,
        newImagePaths: newImagePaths,
        deleteImageIds: deleteImageIds,
      );

      if (res.success) {
        await loadPortfolio();
        return true;
      }
      _error = res.message;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
    return false;
  }

  Future<bool> deletePortfolio(int id) async {
    _setLoading(true);
    try {
      final res = await _api.deletePortfolio(id);
      if (res.success) {
        _items.removeWhere((item) => item.id == id);
        notifyListeners();
        await loadPortfolio();
        return true;
      }
      _error = res.message;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
    return false;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    if (value) _error = null;
    notifyListeners();
  }
}