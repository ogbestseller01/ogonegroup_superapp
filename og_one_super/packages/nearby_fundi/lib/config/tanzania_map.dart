// lib/config/tanzania_map.dart
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Hard limits so every map stays inside Tanzania only.
class TanzaniaMap {
  TanzaniaMap._();

  // Geographic centre (near Dodoma)
  static const LatLng center = LatLng(-6.3690, 34.8888);

  // Safe national bounding box (slightly padded)
  static const double minLat = -11.80;
  static const double maxLat = -0.90;
  static const double minLng = 29.20;
  static const double maxLng = 40.55;

  /// Non-const because LatLngBounds is a factory constructor
  static final LatLngBounds bounds = LatLngBounds(
    const LatLng(minLat, minLng),
    const LatLng(maxLat, maxLng),
  );

  /// Camera cannot pan outside Tanzania
  static final CameraConstraint constraint = CameraConstraint.contain(
    bounds: bounds,
  );

  static const double minZoom = 5.0;
  static const double maxZoom = 18.0;
  static const double defaultZoom = 6.2;

  static bool contains(double lat, double lng) {
    return lat >= minLat &&
        lat <= maxLat &&
        lng >= minLng &&
        lng <= maxLng;
  }

  static bool containsLatLng(LatLng point) =>
      contains(point.latitude, point.longitude);

  static LatLng clamp(LatLng point) {
    return LatLng(
      point.latitude.clamp(minLat, maxLat),
      point.longitude.clamp(minLng, maxLng),
    );
  }
}