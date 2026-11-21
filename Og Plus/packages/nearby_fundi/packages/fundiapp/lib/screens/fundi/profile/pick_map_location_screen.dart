// lib/screens/fundi/profile/pick_map_location_screen.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class PickMapLocationScreen extends StatefulWidget {
  final LatLng? initialCenter;
  final String? initialPlaceName;

  const PickMapLocationScreen({
    super.key,
    this.initialCenter,
    this.initialPlaceName,
  });

  @override
  State<PickMapLocationScreen> createState() => _PickMapLocationScreenState();
}

class _PickMapLocationScreenState extends State<PickMapLocationScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  LatLng? _selectedPoint;
  String? _placeName;
  bool _isReverseGeocoding = false;

  // Search & suggestion state (history-free)
  Timer? _debounceTimer;
  bool _isSearching = false;
  List<_PlaceSuggestion> _suggestions = [];

  static const _defaultCenter = LatLng(-6.7924, 39.2083); // Dar es Salaam
  static const double _minZoom = 4.0;
  static const double _maxZoom = 18.0;

  @override
  void initState() {
    super.initState();
    _selectedPoint = widget.initialCenter ?? _defaultCenter;
    _placeName = widget.initialPlaceName;
    if (_selectedPoint != null && (_placeName == null || _placeName!.isEmpty)) {
      _reverseGeocode(_selectedPoint!);
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();

    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _suggestions = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    _debounceTimer = Timer(const Duration(milliseconds: 450), () {
      _searchPlaces(trimmed);
    });
  }

  Future<void> _searchPlaces(String query) async {
    try {
      final center = _mapController.camera.center;
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
            '?q=${Uri.encodeQueryComponent(query)}'
            '&format=json&addressdetails=1&limit=6'
            '&viewbox=${center.longitude - 0.35},${center.latitude + 0.35},${center.longitude + 0.35},${center.latitude - 0.35}',
      );

      final response = await http
          .get(url, headers: {'User-Agent': 'ogonegroup-fundi-app/1.0'})
          .timeout(const Duration(seconds: 8));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final parsed = <_PlaceSuggestion>[];

        for (final item in data) {
          final lat = double.tryParse(item['lat']?.toString() ?? '');
          final lon = double.tryParse(item['lon']?.toString() ?? '');
          if (lat == null || lon == null) continue;

          final address = item['address'] as Map<String, dynamic>?;
          final title = _buildSuggestionTitle(
            address,
            item['display_name']?.toString() ?? query,
          );
          final subtitle = item['display_name']?.toString() ?? '';

          parsed.add(
            _PlaceSuggestion(
              title: title,
              subtitle: subtitle,
              point: LatLng(lat, lon),
            ),
          );
        }

        setState(() {
          _suggestions = parsed;
          _isSearching = false;
        });
      } else {
        setState(() => _isSearching = false);
      }
    } catch (e) {
      debugPrint('Place search error: $e');
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  String _buildSuggestionTitle(
      Map<String, dynamic>? address,
      String fallbackDisplay,
      ) {
    if (address != null) {
      final primary = address['amenity'] ??
          address['building'] ??
          address['road'] ??
          address['suburb'] ??
          address['neighbourhood'] ??
          address['residential'] ??
          address['quarter'] ??
          address['city_district'] ??
          address['village'] ??
          address['town'] ??
          address['city'];

      if (primary != null && primary.toString().trim().isNotEmpty) {
        final city = address['city'] ?? address['town'] ?? address['state'];
        if (city != null &&
            city.toString().trim().isNotEmpty &&
            city.toString() != primary.toString()) {
          return '${primary.toString().trim()}, ${city.toString().trim()}';
        }
        return primary.toString().trim();
      }
    }

    final parts = fallbackDisplay.split(',');
    return parts.take(2).join(',').trim();
  }

  void _selectSuggestion(_PlaceSuggestion suggestion) {
    _debounceTimer?.cancel();
    _searchFocusNode.unfocus();

    setState(() {
      _selectedPoint = suggestion.point;
      _placeName = suggestion.title;
      _suggestions = [];
      _isSearching = false;
      _searchController.text = suggestion.title;
    });

    final currentZoom = _mapController.camera.zoom.clamp(14.0, _maxZoom);
    _mapController.move(suggestion.point, currentZoom);
  }

  void _clearSearch() {
    _debounceTimer?.cancel();
    _searchController.clear();
    setState(() {
      _suggestions = [];
      _isSearching = false;
    });
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

      final response = await http
          .get(url, headers: {'User-Agent': 'ogonegroup-fundi-app/1.0'})
          .timeout(const Duration(seconds: 8));

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
    if (_searchFocusNode.hasFocus) {
      _searchFocusNode.unfocus();
    }
    if (_suggestions.isNotEmpty) {
      setState(() => _suggestions = []);
    }
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
                userAgentPackageName: 'com.ogonegroup.fundapp',
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

          // Search bar + suggestion list overlay
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Material(
                  elevation: 6,
                  borderRadius: BorderRadius.circular(14),
                  color: theme.colorScheme.surface,
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    textInputAction: TextInputAction.search,
                    onChanged: _onSearchChanged,
                    onSubmitted: (value) {
                      final trimmed = value.trim();
                      if (trimmed.isNotEmpty) {
                        _debounceTimer?.cancel();
                        _searchPlaces(trimmed);
                      }
                    },
                    decoration: InputDecoration(
                      hintText: 'Search area, street, or landmark…',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _isSearching
                          ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        ),
                      )
                          : _searchController.text.isNotEmpty
                          ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _clearSearch,
                      )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                if (_suggestions.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(14),
                    color: theme.colorScheme.surface,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 240),
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        itemCount: _suggestions.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = _suggestions[index];
                          return ListTile(
                            dense: true,
                            leading: Icon(
                              Icons.location_on_outlined,
                              color: theme.colorScheme.primary,
                            ),
                            title: Text(
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              item.subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () => _selectSuggestion(item),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ],
            ),
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
                        Icon(Icons.place, color: theme.colorScheme.primary),
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
                          backgroundColor: theme.colorScheme.primary,
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

class _PlaceSuggestion {
  final String title;
  final String subtitle;
  final LatLng point;

  const _PlaceSuggestion({
    required this.title,
    required this.subtitle,
    required this.point,
  });
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
        icon: Icon(icon, color: theme.colorScheme.primary, size: 22),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }
}