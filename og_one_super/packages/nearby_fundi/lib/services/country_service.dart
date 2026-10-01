import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/country.dart';

class CountryService {
  static const String _apiUrl = 'https://restcountries.com/v3.1/all';

  static Future<List<Country>> fetchCountries() async {
    final response = await http.get(Uri.parse(_apiUrl));
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((json) {
        return Country(
          name: json['name']['common'] ?? 'Unknown',
          dialCode: _extractDialCode(json),
          flag: json['flag'] ?? '🏳️',
        );
      }).toList()
        ..sort((a, b) => a.name.compareTo(b.name));
    } else {
      throw Exception('Failed to load countries');
    }
  }

  static String _extractDialCode(Map<String, dynamic> json) {
    try {
      final idd = json['idd'];
      if (idd == null) return '+0';
      final root = idd['root'] ?? '';
      final suffixes = idd['suffixes'] as List?;
      if (suffixes != null && suffixes.isNotEmpty) {
        return '$root${suffixes[0]}';
      }
      return root;
    } catch (_) {
      return '+0';
    }
  }
}