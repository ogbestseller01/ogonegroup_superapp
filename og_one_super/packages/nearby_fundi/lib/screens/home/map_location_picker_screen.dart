// screens/home/map_location_picker_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class MapLocationPickerScreen extends StatefulWidget {
  final LatLng? initialCenter;

  const MapLocationPickerScreen({super.key, this.initialCenter});

  @override
  State<MapLocationPickerScreen> createState() => _MapLocationPickerScreenState();
}

class _MapLocationPickerScreenState extends State<MapLocationPickerScreen> {
  final MapController _mapController = MapController();
  LatLng? _selectedPoint;
  String? _placeName;
  bool _isReverseGeocoding = false;

  static const _defaultCenter = LatLng(-6.7924, 39.2083); // Dar es Salaam
  static const double _minZoom = 4.0;
  static const double _maxZoom = 18.0;

  @override
  void initState() {
    super.initState();
    _selectedPoint = widget.initialCenter ?? _defaultCenter;
    // Immediately reverse-geocode the initial point
    if (_selectedPoint != null) {
      _reverseGeocode(_selectedPoint!);
    }
  }

  /// Better reverse geocoding – tries to get a clean area name
  Future<void> _reverseGeocode(LatLng point) async {
    setState(() {
      _isReverseGeocoding = true;
      _placeName = null;
    });

    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
            '?lat=${point.latitude}&lon=${point.longitude}'
            '&format=json&addressdetails=1&zoom=16',
      );

      final response = await http
          .get(url, headers: {'User-Agent': 'NearbyFundi/1.0'})
          .timeout(const Duration(seconds: 7));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final address = data['address'] as Map<String, dynamic>?;

        String? cleanName;

        if (address != null) {
          // Priority order for a nice name customers understand
          cleanName = address['suburb'] ??
              address['neighbourhood'] ??
              address['residential'] ??
              address['quarter'] ??
              address['city_district'] ??
              address['village'] ??
              address['town'] ??
              address['city'] ??
              address['county'];

          // If we got a suburb, try to add the city for clarity
          if (cleanName != null) {
            final city = address['city'] ?? address['town'] ?? address['state'];
            if (city != null && city != cleanName) {
              cleanName = '$cleanName, $city';
            }
          }
        }

        // Fallback to display_name (shortened)
        if (cleanName == null || cleanName.trim().isEmpty) {
          final display = data['display_name'] as String?;
          if (display != null) {
            final parts = display.split(',');
            cleanName = parts.take(2).join(',').trim();
          }
        }

        if (mounted && cleanName != null && cleanName.isNotEmpty) {
          setState(() => _placeName = cleanName);
        }
      }
    } catch (e) {
      debugPrint('Reverse geocode error: $e');
    }

    if (mounted) {
      setState(() => _isReverseGeocoding = false);
    }
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    setState(() => _selectedPoint = point);
    _reverseGeocode(point);
  }

  void _zoomBy(double delta) {
    final camera = _mapController.camera;
    final newZoom = (camera.zoom + delta).clamp(_minZoom, _maxZoom);
    _mapController.move(camera.center, newZoom);
  }

  void _confirm() {
    if (_selectedPoint == null) return;

    // Prefer human-readable name. Only use coordinates as last resort.
    final name = (_placeName != null && _placeName!.trim().isNotEmpty)
        ? _placeName!
        : 'Selected location';

    Navigator.pop(context, {
      'lat': _selectedPoint!.latitude,
      'lng': _selectedPoint!.longitude,
      'name': name,
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick location on map'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _selectedPoint != null ? _confirm : null,
            child: const Text(
              'OK',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedPoint ?? _defaultCenter,
              initialZoom: 14,
              minZoom: _minZoom,
              maxZoom: _maxZoom,
              onTap: _onMapTap,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.nearbyfundi',
              ),
              if (_selectedPoint != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedPoint!,
                      width: 50,
                      height: 50,
                      child: const Icon(
                        Icons.location_pin,
                        color: Colors.red,
                        size: 50,
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // Zoom controls
          Positioned(
            right: 16,
            bottom: 140,
            child: Column(
              children: [
                _ZoomButton(
                  icon: Icons.add,
                  tooltip: 'Zoom in',
                  onPressed: () => _zoomBy(1),
                ),
                const SizedBox(height: 10),
                _ZoomButton(
                  icon: Icons.remove,
                  tooltip: 'Zoom out',
                  onPressed: () => _zoomBy(-1),
                ),
              ],
            ),
          ),

          // Bottom info card
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.place, color: theme.primaryColor),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _isReverseGeocoding
                              ? const Text('Getting address…')
                              : Text(
                            _placeName ??
                                'Tap on the map to select a location',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _selectedPoint != null ? _confirm : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Use this location',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ZoomButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _ZoomButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      shape: const CircleBorder(),
      elevation: 4,
      child: IconButton(
        icon: Icon(icon, color: theme.primaryColor, size: 22),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }
}