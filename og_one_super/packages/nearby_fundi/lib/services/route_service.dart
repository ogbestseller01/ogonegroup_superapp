// lib/services/route_service.dart
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// One driving route from the picked point to a technician.
class TechnicianRouteData {
  final List<LatLng> points;
  final double distanceKm;
  final double durationMin;

  /// true  = real road route
  /// false = straight-line fallback (road servers unreachable)
  final bool isRoad;

  const TechnicianRouteData({
    required this.points,
    required this.distanceKm,
    required this.durationMin,
    this.isRoad = true,
  });
}

class RouteTarget {
  final int id;
  final LatLng point;
  final double fallbackKm;

  const RouteTarget({
    required this.id,
    required this.point,
    this.fallbackKm = 0,
  });
}

class RouteService {
  RouteService._();
  static final RouteService instance = RouteService._();

  /// Tried in order. The second one is used when the first fails.
  static const List<String> _servers = [
    'https://router.project-osrm.org/route/v1/driving',
    'https://routing.openstreetmap.de/routed-car/route/v1/driving',
  ];

  static const Map<String, String> _headers = {
    'User-Agent': 'NearbyFundi/1.0',
    'Accept': 'application/json',
  };

  static const Duration _timeout = Duration(seconds: 7);
  static const int _maxCache = 120;
  static const double _assumedSpeedKmh = 30;

  final Map<String, TechnicianRouteData> _cache = {};

  String _key(LatLng a, LatLng b) =>
      '${a.latitude.toStringAsFixed(5)},${a.longitude.toStringAsFixed(5)}|'
          '${b.latitude.toStringAsFixed(5)},${b.longitude.toStringAsFixed(5)}';

  /// Fetches routes in small batches and reports each one as soon as it
  /// arrives, so lines appear on the map one by one.
  Future<void> fetchMany({
    required LatLng origin,
    required List<RouteTarget> targets,
    required void Function(int id, TechnicianRouteData route) onRoute,
    bool Function()? isCancelled,
    int batchSize = 4,
  }) async {
    for (var i = 0; i < targets.length; i += batchSize) {
      if (isCancelled?.call() ?? false) return;

      final batch = targets.skip(i).take(batchSize);

      await Future.wait(batch.map((target) async {
        final route = await fetch(
          origin,
          target.point,
          fallbackKm: target.fallbackKm,
        );
        if (isCancelled?.call() ?? false) return;
        onRoute(target.id, route);
      }));
    }
  }

  /// One route. Never throws. Falls back to a straight line.
  Future<TechnicianRouteData> fetch(
      LatLng origin,
      LatLng destination, {
        double fallbackKm = 0,
      }) async {
    final key = _key(origin, destination);
    final cached = _cache[key];
    if (cached != null) return cached;

    for (final server in _servers) {
      final route = await _fromServer(server, origin, destination);
      if (route != null) {
        if (_cache.length >= _maxCache) {
          _cache.remove(_cache.keys.first);
        }
        _cache[key] = route;
        return route;
      }
    }

    // Failures are not cached, so the next search tries the servers again.
    return _straight(origin, destination, fallbackKm);
  }

  Future<TechnicianRouteData?> _fromServer(
      String server,
      LatLng origin,
      LatLng destination,
      ) async {
    try {
      final url = Uri.parse(
        '$server/'
            '${origin.longitude},${origin.latitude};'
            '${destination.longitude},${destination.latitude}'
            '?overview=full&geometries=geojson',
      );

      final response =
      await http.get(url, headers: _headers).timeout(_timeout);

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['code'] != 'Ok') return null;

      final routes = data['routes'];
      if (routes is! List || routes.isEmpty) return null;

      final route = routes.first as Map<String, dynamic>;
      final coordinates =
      (route['geometry'] as Map<String, dynamic>)['coordinates']
      as List<dynamic>;

      final points = coordinates.map<LatLng>((c) {
        final v = c as List<dynamic>;
        return LatLng((v[1] as num).toDouble(), (v[0] as num).toDouble());
      }).toList();

      if (points.length < 2) return null;

      // Roads are snapped to the nearest street, so join the line to the
      // exact picked point and to the technician pin.
      const meter = Distance();
      if (meter.as(LengthUnit.Meter, origin, points.first) > 10) {
        points.insert(0, origin);
      }
      if (meter.as(LengthUnit.Meter, destination, points.last) > 10) {
        points.add(destination);
      }

      return TechnicianRouteData(
        points: points,
        distanceKm: (route['distance'] as num).toDouble() / 1000,
        durationMin: (route['duration'] as num).toDouble() / 60,
        isRoad: true,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('Route server failed ($server): $e');
      return null;
    }
  }

  TechnicianRouteData _straight(
      LatLng origin,
      LatLng destination,
      double fallbackKm,
      ) {
    final km = fallbackKm > 0
        ? fallbackKm
        : const Distance().as(LengthUnit.Kilometer, origin, destination);

    return TechnicianRouteData(
      points: [origin, destination],
      distanceKm: km,
      durationMin: (km / _assumedSpeedKmh) * 60,
      isRoad: false,
    );
  }
}