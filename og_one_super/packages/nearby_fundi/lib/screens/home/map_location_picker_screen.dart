// screens/home/map_location_picker_screen.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../../config/tanzania_map.dart';

class MapLocationPickerScreen extends StatefulWidget {
  final LatLng? initialCenter;

  const MapLocationPickerScreen({super.key, this.initialCenter});

  @override
  State<MapLocationPickerScreen> createState() =>
      _MapLocationPickerScreenState();
}

class _MapLocationPickerScreenState extends State<MapLocationPickerScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  LatLng? _selectedPoint;
  String? _placeName;
  bool _isReverseGeocoding = false;
  bool _isLocating = false;

  // Search state & Debouncer for low network usage
  List<dynamic> _searchResults = [];
  bool _isSearching = false;
  Timer? _debounceTimer;

  static const double _minZoom = TanzaniaMap.minZoom;
  static const double _maxZoom = TanzaniaMap.maxZoom;

  @override
  void initState() {
    super.initState();
    if (widget.initialCenter != null) {
      _selectedPoint = widget.initialCenter;
      _reverseGeocode(_selectedPoint!);
    } else {
      // By default, try to fetch the current location on startup
      _getCurrentLocation(moveToLocation: true);
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  /// Fetches the user's current GPS location and optionally moves the map
  Future<void> _getCurrentLocation({bool moveToLocation = false}) async {
    setState(() => _isLocating = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enable location services.')),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permissions are denied.')),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permissions are permanently denied.'),
            ),
          );
        }
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final point = LatLng(position.latitude, position.longitude);

      if (!TanzaniaMap.contains(point.latitude, point.longitude)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Current location is outside Tanzania.'),
            ),
          );
        }
        return;
      }

      if (mounted) {
        setState(() {
          _selectedPoint = point;
          _searchResults = [];
        });
        _reverseGeocode(point);

        if (moveToLocation) {
          _mapController.move(point, 15);
        }
      }
    } catch (e) {
      debugPrint('Error getting current location: $e');
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  /// Debouncing search to optimize network requests
  void _onSearchChanged(String query) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      _searchPlaces(query);
    });
  }

  /// Search places via OpenStreetMap Nominatim (restricted to Tanzania)
  Future<void> _searchPlaces(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) {
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
      }
      return;
    }

    setState(() => _isSearching = true);

    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
            '?q=${Uri.encodeComponent(cleanQuery)}'
            '&format=json&countrycodes=tz&limit=5&addressdetails=1',
      );

      final response = await http
          .get(url, headers: {'User-Agent': 'NearbyFundi/1.0'})
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200 && mounted) {
        final List<dynamic> decoded = jsonDecode(response.body);
        setState(() {
          _searchResults = decoded;
        });
      }
    } catch (e) {
      debugPrint('Search network error: $e');
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  /// Selects a location from search results and moves the map
  void _selectSearchResult(dynamic item) {
    final lat = double.tryParse(item['lat']?.toString() ?? '') ?? 0.0;
    final lon = double.tryParse(item['lon']?.toString() ?? '') ?? 0.0;
    final point = LatLng(lat, lon);

    if (!TanzaniaMap.contains(lat, lon)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selected location is outside Tanzania.')),
      );
      return;
    }

    final displayName = item['display_name'] ?? 'Selected location';
    final shortName = displayName.split(',').take(2).join(',').trim();

    setState(() {
      _selectedPoint = point;
      _placeName = shortName;
      _searchResults = [];
      _searchController.text = shortName;
    });

    _searchFocusNode.unfocus();
    _mapController.move(point, 15);
  }

  /// Reverse geocoding with fast fallback for offline/poor network conditions
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
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final address = data['address'] as Map<String, dynamic>?;

        String? cleanName;

        if (address != null) {
          cleanName = address['suburb'] ??
              address['neighbourhood'] ??
              address['residential'] ??
              address['quarter'] ??
              address['city_district'] ??
              address['village'] ??
              address['town'] ??
              address['city'] ??
              address['county'];

          if (cleanName != null) {
            final city = address['city'] ?? address['town'] ?? address['state'];
            if (city != null && city != cleanName) {
              cleanName = '$cleanName, $city';
            }
          }
        }

        if (cleanName == null || cleanName.trim().isEmpty) {
          final display = data['display_name'] as String?;
          if (display != null) {
            final parts = display.split(',');
            cleanName = parts.take(2).join(',').trim();
          }
        }

        if (mounted && cleanName != null && cleanName.isNotEmpty) {
          setState(() {
            _placeName = cleanName;
            _searchController.text = cleanName!;
          });
        }
      }
    } catch (e) {
      debugPrint('Reverse geocode error or timeout: $e');
    }

    if (mounted) {
      if (_placeName == null) {
        final fallbackStr =
            'Lat: ${point.latitude.toStringAsFixed(4)}, Lng: ${point.longitude.toStringAsFixed(4)}';
        setState(() {
          _placeName = fallbackStr;
          _searchController.text = fallbackStr;
        });
      }
      setState(() => _isReverseGeocoding = false);
    }
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    if (!TanzaniaMap.contains(point.latitude, point.longitude)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please pick a location inside Tanzania.')),
      );
      return;
    }

    _searchFocusNode.unfocus();
    setState(() {
      _selectedPoint = point;
      _searchResults = [];
    });

    _reverseGeocode(point);
  }

  void _zoomBy(double delta) {
    final camera = _mapController.camera;
    final newZoom = (camera.zoom + delta).clamp(_minZoom, _maxZoom);
    _mapController.move(camera.center, newZoom);
  }

  void _confirm() {
    if (_selectedPoint == null) return;

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
        title: const Text('Pick location'),
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
          // Flutter Map Layer
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedPoint ?? TanzaniaMap.center,
              initialZoom: _selectedPoint != null ? 15 : TanzaniaMap.defaultZoom,
              minZoom: _minZoom,
              maxZoom: _maxZoom,
              cameraConstraint: TanzaniaMap.constraint,
              onTap: _onMapTap,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.nearbyfundi',
                maxZoom: 19,
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

          // Search Bar Overlay & Suggestions List
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Column(
              children: [
                Material(
                  elevation: 6,
                  borderRadius: BorderRadius.circular(12),
                  color: theme.cardColor,
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Search place in Tanzania (e.g. Sinza, Arusha)...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchResults = []);
                        },
                      )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
                if (_isSearching)
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: LinearProgressIndicator(minHeight: 2),
                  ),
                if (_searchResults.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    constraints: const BoxConstraints(maxHeight: 220),
                    child: ListView.separated(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: _searchResults.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = _searchResults[index];
                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.location_on, size: 20),
                          title: Text(
                            item['display_name'] ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13),
                          ),
                          onTap: () => _selectSearchResult(item),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          // Zoom & Current Location Controls
          Positioned(
            right: 16,
            bottom: 140,
            child: Column(
              children: [
                _ZoomButton(
                  icon: _isLocating ? Icons.hourglass_empty : Icons.my_location,
                  tooltip: 'My current location',
                  onPressed: _isLocating
                      ? () {}
                      : () => _getCurrentLocation(moveToLocation: true),
                ),
                const SizedBox(height: 10),
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

          // Bottom Confirmation Card
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
                                'Tap map or search a location in Tanzania',
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