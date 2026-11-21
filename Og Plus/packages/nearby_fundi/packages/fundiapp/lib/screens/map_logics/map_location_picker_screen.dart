// map_logics/map_location_picker_screen.dart
import 'dart:async';
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

  // ── SEARCH ADDITIONS (new state only) ───────────────────────
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final http.Client _searchHttp = http.Client();

  List<_Place> _suggestions = const [];
  bool _isSearching = false;
  bool _showSuggestions = false;
  Timer? _searchDebounce;
  int _searchRequestId = 0;
  // ────────────────────────────────────────────────────────────

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

  // ── SEARCH CONSTANTS (new) ──────────────────────────────────
  static const Duration _searchDebounceDur = Duration(milliseconds: 350);
  static const Duration _searchTimeout = Duration(seconds: 6);
  static const Map<String, String> _nominatimHeaders = {
    'User-Agent': 'NearbyFundi/1.0 (contact@yourdomain.com)',
  };
  // ────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _selectedPoint = widget.initialCenter ?? _defaultCenter;
    if (widget.initialCenter != null) {
      _reverseGeocode(widget.initialCenter!);
    }
  }

  @override
  void dispose() {
    // ── SEARCH CLEANUP (new) ──
    _searchRequestId++;
    _searchDebounce?.cancel();
    _searchHttp.close();
    _searchController.dispose();
    _searchFocusNode.dispose();
    // ──────────────────────────
    _mapController.dispose();
    super.dispose();
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
    // ── SEARCH ADDITIONS ──
    _searchFocusNode.unfocus();
    setState(() {
      _suggestions = const [];
      _showSuggestions = false;
    });
    // ──────────────────────
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

  // ── SEARCH HANDLERS (new) ───────────────────────────────────
  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    final q = query.trim();

    if (q.length < 2) {
      _searchRequestId++;
      setState(() {
        _suggestions = const [];
        _isSearching = false;
        _showSuggestions = false;
      });
      return;
    }

    setState(() => _showSuggestions = true);
    _searchDebounce = Timer(_searchDebounceDur, () => _searchPlaces(q));
  }

  Future<void> _searchPlaces(String query) async {
    if (!mounted) return;

    final requestId = ++_searchRequestId;
    setState(() => _isSearching = true);

    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
            '?q=${Uri.encodeComponent(query)}'
            '&format=json'
            '&countrycodes=tz'
            '&limit=6'
            '&addressdetails=1',
      );

      final response = await _searchHttp
          .get(url, headers: _nominatimHeaders)
          .timeout(_searchTimeout);

      if (!mounted || requestId != _searchRequestId) return;

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final places = <_Place>[];

        if (decoded is List) {
          for (final item in decoded) {
            if (item is! Map) continue;
            final lat = double.tryParse(item['lat']?.toString() ?? '');
            final lon = double.tryParse(item['lon']?.toString() ?? '');
            if (lat == null || lon == null) continue;

            final display = item['display_name']?.toString() ?? '';
            places.add(_Place(
              name: display.split(',').take(2).join(',').trim(),
              full: display,
              lat: lat,
              lng: lon,
            ));
          }
        }

        setState(() {
          _suggestions = places;
          _showSuggestions = true;
        });
      }
    } catch (e) {
      debugPrint('searchPlaces error: $e');
    } finally {
      if (mounted && requestId == _searchRequestId) {
        setState(() => _isSearching = false);
      }
    }
  }

  void _selectSuggestion(_Place place) {
    _searchDebounce?.cancel();
    _searchRequestId++;

    _searchController.text = place.name;
    _searchFocusNode.unfocus();

    setState(() {
      _selectedPoint = LatLng(place.lat, place.lng);
      _placeName = place.name;
      _suggestions = const [];
      _showSuggestions = false;
      _isSearching = false;
      _isReverseGeocoding = false;
    });

    _mapController.move(
      LatLng(place.lat, place.lng),
      14,
    );
  }
  // ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      resizeToAvoidBottomInset: false,
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

          // ── SEARCH OVERLAY (new) ─────────────────────────────
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: _buildSearchOverlay(theme),
          ),
          // ────────────────────────────────────────────────────

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

  // ── SEARCH UI BUILDERS (new) ────────────────────────────────
  Widget _buildSearchOverlay(ThemeData theme) {
    return Column(
      children: [
        Material(
          elevation: 6,
          borderRadius: BorderRadius.circular(12),
          color: theme.cardColor,
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            onChanged: _onSearchChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search a place in Tanzania…',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                tooltip: 'Clear',
                icon: const Icon(Icons.close_rounded),
                onPressed: () {
                  _searchDebounce?.cancel();
                  _searchRequestId++;
                  _searchController.clear();
                  setState(() {
                    _suggestions = const [];
                    _isSearching = false;
                    _showSuggestions = false;
                  });
                },
              )
                  : null,
              border: InputBorder.none,
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
        if (_isSearching)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: LinearProgressIndicator(minHeight: 2),
          ),
        if (_showSuggestions && _suggestions.isNotEmpty)
          _buildSuggestionList(theme),
      ],
    );
  }

  Widget _buildSuggestionList(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Material(
        color: theme.cardColor,
        elevation: 6,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 220),
          child: ListView.separated(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            itemCount: _suggestions.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, index) {
              final p = _suggestions[index];
              return ListTile(
                dense: true,
                leading: const Icon(Icons.location_on_rounded, size: 20),
                title: Text(
                  p.full,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13),
                ),
                onTap: () => _selectSuggestion(p),
              );
            },
          ),
        ),
      ),
    );
  }
// ────────────────────────────────────────────────────────────
}

// ── SEARCH VALUE TYPE (new) ─────────────────────────────────
class _Place {
  final String name;
  final String full;
  final double lat;
  final double lng;

  const _Place({
    required this.name,
    required this.full,
    required this.lat,
    required this.lng,
  });
}
// ────────────────────────────────────────────────────────────

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