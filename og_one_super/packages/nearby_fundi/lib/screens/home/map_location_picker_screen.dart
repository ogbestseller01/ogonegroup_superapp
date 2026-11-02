// screens/home/map_location_picker_screen.dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../../config/tanzania_map.dart';

/// Returns `{'lat': double, 'lng': double, 'name': String}` via Navigator.pop.
class MapLocationPickerScreen extends StatefulWidget {
  final LatLng? initialCenter;

  const MapLocationPickerScreen({super.key, this.initialCenter});

  @override
  State<MapLocationPickerScreen> createState() =>
      _MapLocationPickerScreenState();
}

class _MapLocationPickerScreenState extends State<MapLocationPickerScreen> {
  static const double _minZoom = TanzaniaMap.minZoom;
  static const double _maxZoom = TanzaniaMap.maxZoom;
  static const double _pickZoom = 15;

  static const Map<String, String> _nominatimHeaders = {
    'User-Agent': 'NearbyFundi/1.0',
  };

  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final http.Client _http = http.Client();

  // Built exactly once. Rebuilding MapOptions on every setState makes
  // flutter_map re-assert cameraConstraint, which throws if the live camera
  // has drifted outside the bounding box.
  late final MapOptions _mapOptions = _buildMapOptions();

  bool _mapReady = false;
  LatLng? _pendingCenter;
  double _pendingZoom = _pickZoom;

  LatLng? _selectedPoint;
  String? _placeName;
  bool _isReverseGeocoding = false;
  bool _isLocating = false;

  List<dynamic> _searchResults = [];
  bool _isSearching = false;
  Timer? _debounceTimer;
  int _searchRequestId = 0;

  Timer? _geocodeTimer;
  int _geocodeRequestId = 0;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialCenter;
    if (initial != null &&
        TanzaniaMap.contains(initial.latitude, initial.longitude)) {
      _selectedPoint = initial;
      _scheduleReverseGeocode(initial, delay: Duration.zero);
    } else {
      _getCurrentLocation(moveToLocation: true);
    }
  }

  @override
  void dispose() {
    _searchRequestId++;
    _geocodeRequestId++;
    _debounceTimer?.cancel();
    _geocodeTimer?.cancel();
    _mapReady = false;
    _http.close();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _mapController.dispose();
    super.dispose();
  }

  // ==============================================================
  // MAP OPTIONS (built once)
  // ==============================================================

  MapOptions _buildMapOptions() {
    final raw = _selectedPoint ?? TanzaniaMap.center;
    final safeCenter = TanzaniaMap.contains(raw.latitude, raw.longitude)
        ? raw
        : TanzaniaMap.center;

    return MapOptions(
      initialCenter: safeCenter,
      initialZoom: _selectedPoint != null ? _pickZoom : TanzaniaMap.defaultZoom,
      minZoom: _minZoom,
      maxZoom: _maxZoom,
      cameraConstraint: TanzaniaMap.constraint,
      onMapReady: _onMapReady,
      onTap: _onMapTap,
      interactionOptions: const InteractionOptions(
        flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
      ),
    );
  }

  // ==============================================================
  // HELPERS
  // ==============================================================

  void _showSnack(String message, {String? actionLabel, VoidCallback? onAction}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          action: (actionLabel != null && onAction != null)
              ? SnackBarAction(label: actionLabel, onPressed: onAction)
              : null,
        ),
      );
  }

  void _moveMap(LatLng point, double zoom) {
    if (!mounted) return;
    if (!_mapReady) {
      _pendingCenter = point;
      _pendingZoom = zoom;
      return;
    }
    _mapController.move(point, zoom);
  }

  void _onMapReady() {
    _mapReady = true;
    final pending = _pendingCenter;
    if (pending != null) {
      _pendingCenter = null;
      _mapController.move(pending, _pendingZoom);
    }
  }

  String _coordinateLabel(LatLng point) =>
      'Lat: ${point.latitude.toStringAsFixed(4)}, '
          'Lng: ${point.longitude.toStringAsFixed(4)}';

  // ==============================================================
  // CURRENT LOCATION
  // ==============================================================

  Future<void> _getCurrentLocation({bool moveToLocation = false}) async {
    if (_isLocating) return;
    setState(() => _isLocating = true);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnack(
          'Please enable location services.',
          actionLabel: 'Settings',
          onAction: () => Geolocator.openLocationSettings(),
        );
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnack('Location permissions are denied.');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showSnack(
          'Location permissions are permanently denied.',
          actionLabel: 'Settings',
          onAction: () => Geolocator.openAppSettings(),
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      if (!mounted) return;

      final point = LatLng(position.latitude, position.longitude);

      if (!TanzaniaMap.contains(point.latitude, point.longitude)) {
        _showSnack('Current location is outside Tanzania.');
        return;
      }

      setState(() {
        _selectedPoint = point;
        _searchResults = [];
      });
      _scheduleReverseGeocode(point, delay: Duration.zero);

      if (moveToLocation) _moveMap(point, _pickZoom);
    } catch (e) {
      debugPrint('Error getting current location: $e');
      _showSnack('Could not get your location. Please try again.');
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  // ==============================================================
  // PLACE SEARCH
  // ==============================================================

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    final q = query.trim();

    if (q.length < 2) {
      _searchRequestId++;
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {});
    _debounceTimer = Timer(
      const Duration(milliseconds: 350),
          () => _searchPlaces(q),
    );
  }

  Future<void> _searchPlaces(String query) async {
    if (!mounted) return;

    final requestId = ++_searchRequestId;
    setState(() => _isSearching = true);

    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
            '?q=${Uri.encodeComponent(query)}'
            '&format=json&countrycodes=tz&limit=5&addressdetails=1',
      );

      final response = await _http
          .get(url, headers: _nominatimHeaders)
          .timeout(const Duration(seconds: 5));

      if (!mounted || requestId != _searchRequestId) return;

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        setState(() {
          _searchResults = decoded is List ? decoded : <dynamic>[];
        });
      }
    } catch (e) {
      debugPrint('Search network error: $e');
    } finally {
      if (mounted && requestId == _searchRequestId) {
        setState(() => _isSearching = false);
      }
    }
  }

  void _selectSearchResult(dynamic item) {
    final lat = double.tryParse(item['lat']?.toString() ?? '');
    final lon = double.tryParse(item['lon']?.toString() ?? '');

    if (lat == null || lon == null) {
      _showSnack('This place has no valid location.');
      return;
    }

    if (!TanzaniaMap.contains(lat, lon)) {
      _showSnack('Selected location is outside Tanzania.');
      return;
    }

    final displayName = item['display_name']?.toString() ?? 'Selected location';
    final shortName = displayName.split(',').take(2).join(',').trim();
    final point = LatLng(lat, lon);

    _debounceTimer?.cancel();
    _geocodeTimer?.cancel();
    _searchRequestId++;
    _geocodeRequestId++;

    setState(() {
      _selectedPoint = point;
      _placeName = shortName;
      _searchResults = [];
      _isSearching = false;
      _isReverseGeocoding = false;
      _searchController.text = shortName;
    });

    _searchFocusNode.unfocus();
    _moveMap(point, _pickZoom);
  }

  // ==============================================================
  // REVERSE GEOCODING
  // ==============================================================

  void _scheduleReverseGeocode(
      LatLng point, {
        Duration delay = const Duration(milliseconds: 350),
      }) {
    _geocodeTimer?.cancel();
    final requestId = ++_geocodeRequestId;

    setState(() {
      _isReverseGeocoding = true;
      _placeName = null;
    });

    _geocodeTimer = Timer(delay, () => _reverseGeocode(point, requestId));
  }

  Future<void> _reverseGeocode(LatLng point, int requestId) async {
    String? name;

    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
            '?lat=${point.latitude}&lon=${point.longitude}'
            '&format=json&addressdetails=1&zoom=16',
      );

      final response = await _http
          .get(url, headers: _nominatimHeaders)
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          name = _nameFromReverseResult(data);
        }
      }
    } catch (e) {
      debugPrint('Reverse geocode error or timeout: $e');
    }

    if (!mounted || requestId != _geocodeRequestId) return;

    final resolved =
    (name != null && name.trim().isNotEmpty) ? name : _coordinateLabel(point);

    setState(() {
      _placeName = resolved;
      _isReverseGeocoding = false;
      if (!_searchFocusNode.hasFocus) _searchController.text = resolved;
    });
  }

  String? _nameFromReverseResult(Map<String, dynamic> data) {
    final address = data['address'];
    String? cleanName;

    if (address is Map) {
      final raw = address['suburb'] ??
          address['neighbourhood'] ??
          address['residential'] ??
          address['quarter'] ??
          address['city_district'] ??
          address['village'] ??
          address['town'] ??
          address['city'] ??
          address['county'];
      cleanName = raw?.toString();

      if (cleanName != null) {
        final city = address['city'] ?? address['town'] ?? address['state'];
        if (city != null && city.toString() != cleanName) {
          cleanName = '$cleanName, $city';
        }
      }
    }

    if (cleanName == null || cleanName.trim().isEmpty) {
      final display = data['display_name']?.toString();
      if (display != null && display.isNotEmpty) {
        cleanName = display.split(',').take(2).join(',').trim();
      }
    }

    return cleanName;
  }

  // ==============================================================
  // MAP INTERACTION
  // ==============================================================

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    if (!TanzaniaMap.contains(point.latitude, point.longitude)) {
      _showSnack('Please pick a location inside Tanzania.');
      return;
    }

    _searchFocusNode.unfocus();
    setState(() {
      _selectedPoint = point;
      _searchResults = [];
    });

    _scheduleReverseGeocode(point);
  }

  void _zoomBy(double delta) {
    if (!_mapReady) return;
    final camera = _mapController.camera;
    final newZoom = (camera.zoom + delta).clamp(_minZoom, _maxZoom).toDouble();
    _mapController.move(camera.center, newZoom);
  }

  void _confirm() {
    final point = _selectedPoint;
    if (point == null) return;

    final name = (_placeName != null && _placeName!.trim().isNotEmpty)
        ? _placeName!
        : _coordinateLabel(point);

    Navigator.pop(context, {
      'lat': point.latitude,
      'lng': point.longitude,
      'name': name,
    });
  }

  // ==============================================================
  // BUILD
  // ==============================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      resizeToAvoidBottomInset: false,
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
          // MAP — uses the cached MapOptions (built once)
          FlutterMap(
            mapController: _mapController,
            options: _mapOptions,
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
                      alignment: Alignment.topCenter,
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

          // SEARCH BAR + SUGGESTIONS
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
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText:
                      'Search place in Tanzania (e.g. Sinza, Arusha)...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _debounceTimer?.cancel();
                          _searchRequestId++;
                          _searchController.clear();
                          setState(() {
                            _searchResults = [];
                            _isSearching = false;
                          });
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
                  Padding(
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
                          itemCount: _searchResults.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final item = _searchResults[index];
                            return ListTile(
                              dense: true,
                              leading: const Icon(Icons.location_on, size: 20),
                              title: Text(
                                item['display_name']?.toString() ?? '',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13),
                              ),
                              onTap: () => _selectSearchResult(item),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ZOOM + CURRENT LOCATION
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

          // CONFIRMATION CARD
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