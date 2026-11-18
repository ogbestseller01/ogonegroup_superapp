// lib/providers/technician_provider.dart

import 'dart:io';

import 'package:flutter/material.dart';

import '../models/technician.dart';
import '../services/api_service.dart';

class TechnicianProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  Technician? _technician;
  bool _isLoading = false;
  String? _error;

  Technician? get technician => _technician;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ── Write actions ─────────────────────────────────────────

  Future<bool> uploadProfilePhoto(File imageFile) async {
    _setLoading(true);
    final res = await _api.uploadProfilePhoto(imageFile);
    return _finish(res.success, res.message);
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    _setLoading(true);
    final res = await _api.updateTechnicianProfile(data);
    return _finish(res.success, res.message);
  }

  Future<bool> updateServices(List<int> serviceIds) async {
    _setLoading(true);
    final res = await _api.updateTechnicianServices(serviceIds);
    return _finish(res.success, res.message);
  }

  // NOTE: updateServicePrices() was removed — the backend has no
  // /v19/technicians/services/prices route. If the design needs
  // per-service pricing, it must be added to the backend first.

  // ── Read actions ──────────────────────────────────────────

  Future<void> fetchMyProfile() async {
    _setLoading(true);
    final res = await _api.getMyTechnicianProfile();

    if (res.success && res.data != null && res.data is Map) {
      _technician = Technician.fromJson(
        Map<String, dynamic>.from(res.data as Map),
        isDetail: true,
      );
    } else {
      _error = res.message;
    }
    _setLoading(false);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ── Helpers ───────────────────────────────────────────────

  Future<bool> _finish(bool success, String? message) async {
    if (success) {
      await fetchMyProfile();
      _setLoading(false);
      return true;
    }
    _error = message;
    _setLoading(false);
    return false;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    if (value) _error = null;
    notifyListeners();
  }
}