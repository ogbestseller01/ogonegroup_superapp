import 'package:flutter/material.dart';
import 'dart:io';
import '../services/api_service.dart';
import '../models/technician.dart';

class TechnicianProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  Technician? _technician;
  bool _isLoading = false;
  String? _error;

  Technician? get technician => _technician;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<bool> uploadProfilePhoto(File imageFile) async {
    _setLoading(true);
    final res = await _api.uploadProfilePhoto(imageFile);
    if (res.success) {
      await fetchMyProfile();
      _setLoading(false);
      return true;
    }
    _error = res.message;
    _setLoading(false);
    return false;
  }

  Future<void> fetchMyProfile() async {
    _setLoading(true);
    final res = await _api.getMyTechnicianProfile();

    // ============================================================
    // 🔍 DEBUG LOGGING — remove once the root cause is confirmed
    // ============================================================
    debugPrint('┌─────────────────────────────────────────────');
    debugPrint('│ [TechnicianProvider] fetchMyProfile()');
    debugPrint('│ success: ${res.success}');
    debugPrint('│ message: ${res.message}');
    debugPrint('│ data == null: ${res.data == null}');
    debugPrint('│ data runtimeType: ${res.data.runtimeType}');
    if (res.data is Map) {
      final map = res.data as Map;
      debugPrint('│ top-level keys: ${map.keys.toList()}');
      debugPrint('│ has "service_prices" key: ${map.containsKey('service_prices')}');
      debugPrint('│ service_prices value: ${map['service_prices']}');
      debugPrint('│ service_prices runtimeType: ${map['service_prices'].runtimeType}');
      debugPrint('│ nida value: ${map['nida']}');
      debugPrint('│ registration_completed: ${map['registration_completed']}');
      debugPrint('│ id: ${map['id']}');
    }
    debugPrint('└─────────────────────────────────────────────');
    // ============================================================

    if (res.success && res.data != null) {
      _technician = Technician.fromJson(res.data, isDetail: true);

      // 🔍 Confirm what actually landed in the parsed model
      debugPrint('┌─────────────────────────────────────────────');
      debugPrint('│ [TechnicianProvider] Parsed Technician');
      debugPrint('│ id: ${_technician?.id}');
      debugPrint('│ name: ${_technician?.name}');
      debugPrint('│ nida: ${_technician?.nida}');
      debugPrint('│ servicePrices.length: ${_technician?.servicePrices.length}');
      for (final sp in _technician?.servicePrices ?? []) {
        debugPrint('│   - ${sp.name} (id=${sp.id}) TZS ${sp.minPrice}-${sp.maxPrice}');
      }
      debugPrint('└─────────────────────────────────────────────');
    } else {
      _error = res.message;
      debugPrint('❌ [TechnicianProvider] fetchMyProfile FAILED: ${res.message}');
    }
    _setLoading(false);
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    _setLoading(true);
    final res = await _api.updateTechnicianProfile(data);
    if (res.success) {
      await fetchMyProfile();
      _setLoading(false);
      return true;
    }
    _error = res.message;
    _setLoading(false);
    return false;
  }

  Future<bool> updateServices(List<int> serviceIds) async {
    _setLoading(true);
    final res = await _api.updateTechnicianServices(serviceIds);
    if (res.success) {
      await fetchMyProfile();
      _setLoading(false);
      return true;
    }
    _error = res.message;
    _setLoading(false);
    return false;
  }

  Future<bool> updateServicePrices(List<Map<String, dynamic>> prices) async {
    _setLoading(true);
    final res = await _api.updateServicePrices(prices);
    if (res.success) {
      await fetchMyProfile();
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