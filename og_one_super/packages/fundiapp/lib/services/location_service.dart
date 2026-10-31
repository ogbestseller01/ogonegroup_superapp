// lib/services/location_service.dart
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'geocoding_service.dart';

class LocationService {
  /// Current GPS position. Returns null if services/permissions are off.
  /// Never throws — the caller just sees `null` and shows a hint.
  static Future<LatLng?> getCurrentLocation({
    Duration timeout = const Duration(seconds: 15),
  }) async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: timeout,
      );
      return LatLng(pos.latitude, pos.longitude);
    } catch (_) {
      // Fall back to the last known point on timeout / hardware error.
      try {
        final last = await Geolocator.getLastKnownPosition();
        if (last != null) return LatLng(last.latitude, last.longitude);
      } catch (_) {}
      return null;
    }
  }

  static Future<GeocodingResult?> geocode(String place) =>
      GeocodingService.search(place);

  static Future<String?> reverseGeocode(LatLng point) =>
      GeocodingService.reverse(point);
}