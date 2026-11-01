import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// One place that defines "the map is all of Tanzania".
class TanzaniaMap {
  static const LatLng center = LatLng(-6.3690, 34.8888);
  static const double defaultZoom = 5.4;
  static const double minZoom = 5.0;
  static const double maxZoom = 18.0;

  static const double minLat = -11.9, maxLat = -0.9;
  static const double minLng = 29.2, maxLng = 40.6;

  static final LatLngBounds bounds =
  LatLngBounds(const LatLng(minLat, minLng), const LatLng(maxLat, maxLng));

  /// Keeps panning inside Tanzania.
  static CameraConstraint get constraint =>
      CameraConstraint.contain(bounds: bounds);

  static bool contains(double lat, double lng) =>
      lat >= minLat && lat <= maxLat && lng >= minLng && lng <= maxLng;
}