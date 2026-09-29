import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class GeocodingService {
  static const String _nominatimUrl = 'https://nominatim.openstreetmap.org/search';

  static Future<Position> getCoordinatesFromAddress(String address) async {
    final url = Uri.parse(
      '$_nominatimUrl?q=${Uri.encodeComponent(address)}&format=json&limit=1',
    );
    final response = await http.get(url, headers: {
      'User-Agent': 'FundiApp/1.0',
    });
    if (response.statusCode != 200) {
      throw Exception('Geocoding service error: ${response.statusCode}');
    }
    final List<dynamic> data = jsonDecode(response.body);
    if (data.isEmpty) throw Exception('Address not found');
    final lat = double.parse(data[0]['lat']);
    final lon = double.parse(data[0]['lon']);
    return Position(
      latitude: lat,
      longitude: lon,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      heading: 0,
      speed: 0,
      speedAccuracy: 0,
      altitudeAccuracy: 0,
      headingAccuracy: 0,
    );
  }
}