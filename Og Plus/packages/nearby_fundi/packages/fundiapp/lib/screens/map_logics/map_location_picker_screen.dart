// map_logics/map_location_picker_screen.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class MapLocationPickerScreen extends StatefulWidget {
  final LatLng? initialCenter;

  const MapLocationPickerScreen({super.key, this.initialCenter});

  @override
  State<MapLocationPickerScreen> createState() =>
      _MapLocationPickerScreenState();
}

class _MapLocationPickerScreenState extends State<MapLocationPickerScreen> {
  final MapController _mapController = MapController();

  LatLng? _selectedPoint;
  String? _placeName;
  bool _isReverseGeocoding = false;

  // Center of Tanzania (Dodoma area)
  static const _defaultCenter = LatLng(-6.369, 34.888);

  // Slightly padded TZ bounding box (SW corner → NE corner)
  static final LatLngBounds _tanzaniaBounds = LatLngBounds(
    const LatLng(-12.0, 29.0),
    const LatLng(-0.8, 40.9),
  );

  static const double _minZoom = 5.0;
  static const double _maxZoom = 18.0;

  @override
  void initState() {
    super.initState();
    _selectedPoint = widget.initialCenter ?? _defaultCenter;
    if (widget.initialCenter != null) {
      _reverseGeocode(widget.initialCenter!);
    }
  }

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
      final res = await http
          .get(url, headers: {'User-Agent': 'NearbyFundi-App/1.0'})
          .timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final addr = data['address'] as Map<String, dynamic>?;
        String? name;

        if (addr != null) {
          name = addr['suburb'] ??
              addr['neighbourhood'] ??
              addr['residential'] ??
              addr['quarter'] ??
              addr['city_district'] ??
              addr['village'] ??
              addr['town'] ??
              addr['city'] ??
              addr['county'];

          final city = addr['city'] ?? addr['town'] ?? addr['state'];
          if (name != null && city != null && city != name) {
            name = '$name, $city';
          }
        }
        name ??= data['display_name']?.toString();

        if (mounted && name != null && name.isNotEmpty) {
          setState(() => _placeName = name);
        }
      }
    } catch (_) {}

    if (mounted) setState(() => _isReverseGeocoding = false);
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    setState(() => _selectedPoint = point);
    _reverseGeocode(point);
  }

  void _zoomBy(double delta) {
    final cam = _mapController.camera;
    _mapController.move(cam.center, (cam.zoom + delta).clamp(_minZoom, _maxZoom));
  }

  void _confirm() {
    if (_selectedPoint == null) return;
    final name = (_placeName ?? '').trim().isNotEmpty
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
            child: const Text('OK',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedPoint ?? _defaultCenter,
              initialZoom: widget.initialCenter != null ? 14 : 6,
              minZoom: _minZoom,
              maxZoom: _maxZoom,
              // Remove this line if your flutter_map version complains.
              cameraConstraint: CameraConstraint.contain(bounds: _tanzaniaBounds),
              onTap: _onMapTap,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.ogonegroup.fundapp',
              ),
              if (_selectedPoint != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedPoint!,
                      width: 50,
                      height: 50,
                      child: const Icon(Icons.location_pin,
                          color: Colors.red, size: 50),
                    ),
                  ],
                ),
            ],
          ),

          Positioned(
            right: 16,
            bottom: 140,
            child: Column(
              children: [
                _ZoomButton(
                    icon: Icons.add,
                    tooltip: 'Zoom in',
                    onPressed: () => _zoomBy(1)),
                const SizedBox(height: 10),
                _ZoomButton(
                    icon: Icons.remove,
                    tooltip: 'Zoom out',
                    onPressed: () => _zoomBy(-1)),
              ],
            ),
          ),

          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
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
                                fontWeight: FontWeight.w600),
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
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Use this location',
                            style: TextStyle(fontWeight: FontWeight.bold)),
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