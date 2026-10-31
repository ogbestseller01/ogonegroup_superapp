// lib/services/geocoding_service.dart
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class GeocodingResult {
  final LatLng latLng;
  final String displayName;

  const GeocodingResult({required this.latLng, required this.displayName});
}

class GeocodingService {
  static const _base = 'https://nominatim.openstreetmap.org';
  static const _headers = {
    'User-Agent': 'NearbyFundi-App/1.0',
    'Accept': 'application/json',
  };

  /// Free-text search: "Sinza", "Mbeya", "Kariakoo, Dar es Salaam" ...
  /// Returns null on failure / not found — never throws.
  static Future<GeocodingResult?> search(String query) async {
    final q = query.trim();
    if (q.isEmpty) return null;

    try {
      final url = Uri.parse(
        '$_base/search'
            '?q=${Uri.encodeComponent(q)}'
            '&format=json&limit=1&addressdetails=1&countrycodes=tz,ke,ug,rw,bi,cd,zm,mw,mz',
      );
      final res = await http
          .get(url, headers: _headers)
          .timeout(const Duration(seconds: 10));

      if (res.statusCode != 200) return null;

      final data = jsonDecode(res.body);
      if (data is! List || data.isEmpty) return null;

      final item = data.first as Map<String, dynamic>;
      final lat = double.tryParse(item['lat']?.toString() ?? '');
      final lon = double.tryParse(item['lon']?.toString() ?? '');
      if (lat == null || lon == null) return null;

      return GeocodingResult(
        latLng: LatLng(lat, lon),
        displayName: item['display_name']?.toString() ?? q,
      );
    } catch (_) {
      return null;
    }
  }

  /// Reverse geocode: coords → short human-friendly area name.
  static Future<String?> reverse(LatLng point) async {
    try {
      final url = Uri.parse(
        '$_base/reverse'
            '?lat=${point.latitude}&lon=${point.longitude}'
            '&format=json&addressdetails=1&zoom=16',
      );
      final res = await http
          .get(url, headers: _headers)
          .timeout(const Duration(seconds: 10));

      if (res.statusCode != 200) return null;

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final addr = data['address'] as Map<String, dynamic>?;

      if (addr != null) {
        final candidates = <String?>[
          addr['suburb']?.toString(),
          addr['neighbourhood']?.toString(),
          addr['residential']?.toString(),
          addr['quarter']?.toString(),
          addr['city_district']?.toString(),
          addr['village']?.toString(),
          addr['town']?.toString(),
          addr['city']?.toString(),
          addr['county']?.toString(),
          addr['state']?.toString(),
        ];

        final parts = candidates
            .whereType<String>()
            .where((s) => s.isNotEmpty)
            .toList();

        if (parts.isNotEmpty) {
          return parts.take(2).join(', ');
        }
      }

      return data['display_name']?.toString();
    } catch (_) {
      return null;
    }
  }
}