// lib/services/technician_heartbeat_service.dart
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:geolocator/geolocator.dart';
import 'api_service.dart';
import 'storage_service.dart';

class TechnicianHeartbeatService {
  static const int _intervalSeconds = 5;
  Timer? _timer;
  bool _isRunning = false;

  final ApiService _api = ApiService();

  void start() {
    if (_isRunning) return;
    _isRunning = true;
    _timer = Timer.periodic(
      const Duration(seconds: _intervalSeconds),
          (_) => _sendHeartbeat(),
    );
    // Send immediately on start
    _sendHeartbeat();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
  }

  bool get isRunning => _isRunning;

  Future<void> _sendHeartbeat() async {
    try {
      final token = await StorageService.getToken();
      if (token == null) {
        stop(); // Not logged in
        return;
      }

      final position = await _getCurrentLocation();
      if (position != null) {
        await _api.sendTechnicianHeartbeat(
          latitude: position.latitude,
          longitude: position.longitude,
        );
        debugPrint('📡 Heartbeat sent: ${position.latitude}, ${position.longitude}');
      }
    } catch (e) {
      debugPrint('❌ Heartbeat error: $e');
    }
  }

  Future<Position?> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      if (permission == LocationPermission.deniedForever) return null;

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 10, // 10 meters
        ),
      );
    } catch (_) {
      return null;
    }
  }
}