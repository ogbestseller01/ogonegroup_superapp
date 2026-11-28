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

  // NOTE: Instant service updates are no longer allowed here.
  // Service changes must go through ManageServicesScreen, which uses
  // ApiService.getServiceChangeOptions() / submitServiceChange() and
  // is subject to admin approval.
  //
  // updateServicePrices() also has no backend route and must not be
  // re-added until the backend supports it.

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