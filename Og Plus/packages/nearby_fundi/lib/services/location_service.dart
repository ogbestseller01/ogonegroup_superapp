import 'package:geolocator/geolocator.dart';
import 'geocoding_service.dart';

class LocationService {
  static Future<Position> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw Exception('Location services are disabled.');

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions denied.');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions permanently denied.');
    }
    return await Geolocator.getCurrentPosition();
  }

  static Future<Position> getCoordinatesFromAddress(String address) async {
    return await GeocodingService.getCoordinatesFromAddress(address);
  }
}