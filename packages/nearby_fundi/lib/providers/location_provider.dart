import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';

class LocationProvider extends ChangeNotifier {
  Position? _position;
  bool _isLoading = false;
  String? _error;

  Position? get position => _position;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Clear previous error when starting new operation
  void _startLoading() {
    _isLoading = true;
    _error = null;
    notifyListeners();
  }

  void _stopLoading() {
    _isLoading = false;
    notifyListeners();
  }

  Future<void> getCurrentLocation() async {
    _startLoading();
    try {
      _position = await LocationService.getCurrentLocation();
      _error = null;
    } catch (e) {
      _error = 'Failed to get current location: ${e.toString()}';
      _position = null;
    }
    _stopLoading();
  }

  Future<void> getLocationFromAddress(String address) async {
    if (address.trim().isEmpty) {
      _error = 'Please enter a place name';
      notifyListeners();
      return;
    }

    _startLoading();
    try {
      _position = await LocationService.getCoordinatesFromAddress(address.trim());
      _error = null;
    } catch (e) {
      _error = 'Location search failed. Please check internet or try current location.';
      _position = null;
    }
    _stopLoading();
  }

  // Optional: Clear error manually
  void clearError() {
    _error = null;
    notifyListeners();
  }
}