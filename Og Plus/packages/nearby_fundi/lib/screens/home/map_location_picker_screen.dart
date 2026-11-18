// lib/screens/home/map_location_picker_screen.dart
//
// Location picker with persistent per-user search history.
//
// • MapOptions is built ONCE and cached. Every camera change goes through
//   _applyCamera() which clamps center+zoom to TanzaniaMap before touching
//   the controller.
// • Search history is persisted per user (namespaced by AuthProvider.user.id).
//   Max 10 entries, newest first, de-duped. Individual delete + "Clear all".
// • Single reused http.Client, LRU suggestion cache, debounced and
//   cancellable search + reverse geocoding.
//
// Returns {'lat': double, 'lng': double, 'name': String} via Navigator.pop.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/tanzania_map.dart';
import '../../providers/auth_provider.dart';

// ================================================================
// CONSTANTS
// ================================================================

class _PickerConst {
  static const double pickZoom = 15;
  static const Duration searchDebounce = Duration(milliseconds: 350);
  static const Duration geocodeDebounce = Duration(milliseconds: 350);
  static const Duration netTimeout = Duration(seconds: 6);
  static const Duration geocodeTimeout = Duration(seconds: 5);
  static const Duration locationTimeout = Duration(seconds: 15);
  static const int suggestionCacheSize = 30;
  static const int maxHistoryEntries = 10;

  // IMPORTANT: Replace with your REAL package name (not com.example.*)
  // This becomes the User-Agent that OSM sees.
  static const String userAgentPackageName = 'com.yourcompany.nearbyfundi';

  static const Map<String, String> nominatimHeaders = {
    'User-Agent': 'NearbyFundi/1.0 (contact@yourdomain.com)', // better identification
  };
}

// ================================================================
// SMALL VALUE TYPES
// ================================================================

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

  String get historyLabel => name.isNotEmpty ? name : full;
}

// ================================================================
// SCREEN
// ================================================================

/// Returns `{'lat': double, 'lng': double, 'name': String}` via Navigator.pop.
class MapLocationPickerScreen extends StatefulWidget {
  final LatLng? initialCenter;

  const MapLocationPickerScreen({super.key, this.initialCenter});

  @override
  State<MapLocationPickerScreen> createState() =>
      _MapLocationPickerScreenState();
}

class _MapLocationPickerScreenState extends State<MapLocationPickerScreen> {
  // ── Controllers ─────────────────────────────────────────────
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final http.Client _http = http.Client();

  // Built ONCE. Never rebuilt on setState.
  late final MapOptions _mapOptions = _buildMapOptions();

  // ── Map state ───────────────────────────────────────────────
  bool _mapReady = false;
  LatLng? _pendingCenter;
  double _pendingZoom = _PickerConst.pickZoom;

  // ── Selection state ─────────────────────────────────────────
  LatLng? _selectedPoint;
  String? _placeName;
  bool _isReverseGeocoding = false;
  bool _isLocating = false;

  // ── Suggestions state ───────────────────────────────────────
  List<_Place> _suggestions = const [];
  bool _isSearching = false;
  bool _showSuggestions = false;
  final Map<String, List<_Place>> _suggestionCache = {};

  Timer? _searchDebounce;
  int _searchRequestId = 0;

  // ── Reverse geocode state ───────────────────────────────────
  Timer? _geocodeDebounce;
  int _geocodeRequestId = 0;

  // ── History state (per-user) ────────────────────────────────
  SharedPreferences? _prefs;
  String? _historyKey;
  List<String> _history = const [];
  bool _historyLoaded = false;

  // ==============================================================
  // LIFECYCLE
  // ==============================================================

  @override
  void initState() {
    super.initState();

    final initial = widget.initialCenter;
    if (initial != null &&
        TanzaniaMap.contains(initial.latitude, initial.longitude)) {
      _selectedPoint = initial;
      _scheduleReverseGeocode(initial, delay: Duration.zero);
    }

    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _loadHistory();
    if (!mounted) return;
    // Auto-locate only when there was no valid seed.
    if (_selectedPoint == null) {
      await _getCurrentLocation(moveToLocation: true);
    }
  }

  @override
  void dispose() {
    _searchRequestId++;
    _geocodeRequestId++;
    _searchDebounce?.cancel();
    _geocodeDebounce?.cancel();
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
    final seed = _selectedPoint ?? TanzaniaMap.center;
    final safeCenter = TanzaniaMap.contains(seed.latitude, seed.longitude)
        ? seed
        : TanzaniaMap.center;

    return MapOptions(
      initialCenter: safeCenter,
      initialZoom: _selectedPoint != null
          ? _PickerConst.pickZoom
          : TanzaniaMap.defaultZoom,
      minZoom: TanzaniaMap.minZoom,
      maxZoom: TanzaniaMap.maxZoom,
      cameraConstraint: TanzaniaMap.constraint,
      onMapReady: _onMapReady,
      onTap: _onMapTap,
      interactionOptions: const InteractionOptions(
        flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
      ),
    );
  }

  // ==============================================================
  // SAFE CAMERA
  // ==============================================================

  LatLng _clampCenter(LatLng c) {
    final b = TanzaniaMap.bounds;
    return LatLng(
      c.latitude.clamp(b.south, b.north),
      c.longitude.clamp(b.west, b.east),
    );
  }

  double _clampZoom(double z) =>
      z.clamp(TanzaniaMap.minZoom, TanzaniaMap.maxZoom);

  void _applyCamera(LatLng center, double zoom) {
    if (!mounted) return;
    final safeCenter = _clampCenter(center);
    final safeZoom = _clampZoom(zoom);
    if (!_mapReady) {
      _pendingCenter = safeCenter;
      _pendingZoom = safeZoom;
      return;
    }
    _mapController.move(safeCenter, safeZoom);
  }

  void _zoomBy(double delta) {
    if (!_mapReady) return;
    final cam = _mapController.camera;
    _applyCamera(cam.center, cam.zoom + delta);
  }

  void _onMapReady() {
    _mapReady = true;
    final pending = _pendingCenter;
    if (pending != null) {
      _pendingCenter = null;
      _applyCamera(pending, _pendingZoom);
    }
  }

  // ==============================================================
  // HISTORY (per-user)
  // ==============================================================

  Future<SharedPreferences> _getPrefs() async =>
      _prefs ??= await SharedPreferences.getInstance();

  String _resolveHistoryKey() {
    String? uid;
    try {
      uid = context.read<AuthProvider>().user?.id?.toString();
    } catch (_) {
      uid = null;
    }
    return (uid == null || uid.isEmpty)
        ? 'picker_history__anon'
        : 'picker_history__$uid';
  }

  Future<void> _loadHistory() async {
    final prefs = await _getPrefs();
    final key = _resolveHistoryKey();
    if (!mounted) return;
    setState(() {
      _historyKey = key;
      _history = prefs.getStringList(key) ?? const <String>[];
      _historyLoaded = true;
    });
  }

  Future<void> _pushHistory(String value) async {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;

    final prefs = await _getPrefs();
    final key = _historyKey ?? _resolveHistoryKey();

    final list = List<String>.from(
      prefs.getStringList(key) ?? const <String>[],
    );
    list.remove(trimmed);
    list.insert(0, trimmed);
    if (list.length > _PickerConst.maxHistoryEntries) {
      list.removeRange(_PickerConst.maxHistoryEntries, list.length);
    }
    await prefs.setStringList(key, list);

    if (!mounted) return;
    setState(() {
      _historyKey = key;
      _history = list;
    });
  }

  Future<void> _removeHistory(String value) async {
    final prefs = await _getPrefs();
    final key = _historyKey ?? _resolveHistoryKey();
    final list = List<String>.from(
      prefs.getStringList(key) ?? const <String>[],
    )..remove(value);
    await prefs.setStringList(key, list);
    if (!mounted) return;
    setState(() => _history = list);
  }

  Future<void> _clearHistory() async {
    final prefs = await _getPrefs();
    final key = _historyKey ?? _resolveHistoryKey();
    await prefs.remove(key);
    if (!mounted) return;
    setState(() => _history = const []);
  }

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
          _showSnack('Location permission denied.');
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        _showSnack(
          'Location permission permanently denied.',
          actionLabel: 'Settings',
          onAction: () => Geolocator.openAppSettings(),
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: _PickerConst.locationTimeout,
      );

      if (!mounted) return;

      final point = LatLng(position.latitude, position.longitude);
      if (!TanzaniaMap.contains(point.latitude, point.longitude)) {
        _showSnack('Your location is outside Tanzania.');
        return;
      }

      setState(() {
        _selectedPoint = point;
        _suggestions = const [];
      });
      _scheduleReverseGeocode(point, delay: Duration.zero);
      if (moveToLocation) _applyCamera(point, _PickerConst.pickZoom);
    } catch (e) {
      debugPrint('getCurrentLocation error: $e');
      _showSnack('Could not get your location. Please try again.');
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  // ==============================================================
  // PLACE SEARCH
  // ==============================================================

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    final q = query.trim();

    if (q.length < 2) {
      _searchRequestId++;
      setState(() {
        _suggestions = const [];
        _isSearching = false;
        _showSuggestions = q.isEmpty && _history.isNotEmpty;
      });
      return;
    }

    setState(() => _showSuggestions = true);
    _searchDebounce = Timer(
      _PickerConst.searchDebounce,
          () => _searchPlaces(q),
    );
  }

  void _cacheSuggestions(String key, List<_Place> value) {
    if (_suggestionCache.length >= _PickerConst.suggestionCacheSize) {
      _suggestionCache.remove(_suggestionCache.keys.first);
    }
    _suggestionCache[key] = value;
  }

  Future<void> _searchPlaces(String query) async {
    if (!mounted) return;

    final key = query.toLowerCase();
    final requestId = ++_searchRequestId;

    final cached = _suggestionCache[key];
    if (cached != null) {
      setState(() {
        _suggestions = cached;
        _isSearching = false;
        _showSuggestions = true;
      });
      return;
    }

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

      final response = await _http
          .get(url, headers: _PickerConst.nominatimHeaders)
          .timeout(_PickerConst.netTimeout);

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
            if (!TanzaniaMap.contains(lat, lon)) continue;

            final display = item['display_name']?.toString() ?? '';
            places.add(_Place(
              name: display.split(',').take(2).join(',').trim(),
              full: display,
              lat: lat,
              lng: lon,
            ));
          }
        }

        _cacheSuggestions(key, places);
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
    _geocodeDebounce?.cancel();
    _searchRequestId++;
    _geocodeRequestId++;

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

    _applyCamera(LatLng(place.lat, place.lng), _PickerConst.pickZoom);
    unawaited(_pushHistory(place.historyLabel));
  }

  // ==============================================================
  // REVERSE GEOCODING
  // ==============================================================

  void _scheduleReverseGeocode(
      LatLng point, {
        Duration delay = _PickerConst.geocodeDebounce,
      }) {
    _geocodeDebounce?.cancel();
    final requestId = ++_geocodeRequestId;

    setState(() {
      _isReverseGeocoding = true;
      _placeName = null;
    });

    if (delay == Duration.zero) {
      unawaited(_reverseGeocode(point, requestId));
    } else {
      _geocodeDebounce = Timer(delay, () => _reverseGeocode(point, requestId));
    }
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
          .get(url, headers: _PickerConst.nominatimHeaders)
          .timeout(_PickerConst.geocodeTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          name = _nameFromReverse(data);
        }
      }
    } catch (e) {
      debugPrint('reverseGeocode error: $e');
    }

    if (!mounted || requestId != _geocodeRequestId) return;

    final resolved = (name != null && name.trim().isNotEmpty)
        ? name
        : _coordinateLabel(point);

    setState(() {
      _placeName = resolved;
      _isReverseGeocoding = false;
      if (!_searchFocusNode.hasFocus) _searchController.text = resolved;
    });
  }

  String? _nameFromReverse(Map<String, dynamic> data) {
    final address = data['address'];
    if (address is! Map) {
      final display = data['display_name']?.toString();
      return (display != null && display.isNotEmpty)
          ? display.split(',').take(3).join(',').trim()
          : null;
    }

    String? pick(List<String> keys) {
      for (final k in keys) {
        final v = address[k];
        if (v != null && v.toString().trim().isNotEmpty) {
          return v.toString().trim();
        }
      }
      return null;
    }

    final village = pick([
      'village',
      'hamlet',
      'suburb',
      'neighbourhood',
      'residential',
      'quarter',
    ]);
    final district = pick(['county', 'state_district', 'district']);
    final city = pick(['city', 'town', 'municipality']);
    final region = pick(['state', 'region']);

    final parts = <String>[];
    for (final c in [village, district, city, region]) {
      if (c != null && !parts.contains(c)) parts.add(c);
    }
    if (parts.isNotEmpty) return parts.take(3).join(', ');

    final display = data['display_name']?.toString();
    return (display != null && display.isNotEmpty)
        ? display.split(',').take(3).join(',').trim()
        : null;
  }

  String _coordinateLabel(LatLng point) =>
      'Lat: ${point.latitude.toStringAsFixed(4)}, '
          'Lng: ${point.longitude.toStringAsFixed(4)}';

  // ==============================================================
  // MAP INTERACTION
  // ==============================================================

  void _onMapTap(TapPosition _, LatLng point) {
    if (!TanzaniaMap.contains(point.latitude, point.longitude)) {
      _showSnack('Please pick a location inside Tanzania.');
      return;
    }
    _searchFocusNode.unfocus();
    setState(() {
      _selectedPoint = point;
      _suggestions = const [];
      _showSuggestions = false;
    });
    _scheduleReverseGeocode(point);
  }

  void _confirm() {
    final point = _selectedPoint;
    if (point == null) return;

    final name = (_placeName != null && _placeName!.trim().isNotEmpty)
        ? _placeName!
        : _coordinateLabel(point);

    unawaited(_pushHistory(name));

    Navigator.pop(context, {
      'lat': point.latitude,
      'lng': point.longitude,
      'name': name,
    });
  }

  void _showSnack(
      String message, {
        String? actionLabel,
        VoidCallback? onAction,
      }) {
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
          // MAP
          RepaintBoundary(
            child: FlutterMap(
              mapController: _mapController,
              options: _mapOptions,
              children: [
                TileLayer(
                  urlTemplate:
                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: _PickerConst.userAgentPackageName,
                  maxZoom: 19,
                  // Optional: improves behaviour on flaky networks
                  // tileProvider: NetworkTileProvider(),
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
                // Required by OSM Tile Usage Policy
                const RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution(
                      '© OpenStreetMap contributors',
                    ),
                  ],
                ),
              ],
            ),
          ),

          // SEARCH + SUGGESTIONS + HISTORY
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: _buildSearchOverlay(theme),
          ),

          // MAP CONTROLS
          Positioned(
            right: 16,
            bottom: 140,
            child: Column(
              children: [
                _CircleButton(
                  icon: _isLocating
                      ? Icons.hourglass_empty_rounded
                      : Icons.my_location_rounded,
                  tooltip: 'My current location',
                  onPressed: _isLocating
                      ? null
                      : () => _getCurrentLocation(moveToLocation: true),
                ),
                const SizedBox(height: 10),
                _CircleButton(
                  icon: Icons.add,
                  tooltip: 'Zoom in',
                  onPressed: () => _zoomBy(1),
                ),
                const SizedBox(height: 10),
                _CircleButton(
                  icon: Icons.remove,
                  tooltip: 'Zoom out',
                  onPressed: () => _zoomBy(-1),
                ),
              ],
            ),
          ),

          // BOTTOM CONFIRM CARD
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: _buildConfirmCard(theme),
          ),
        ],
      ),
    );
  }

  // ==============================================================
  // SEARCH OVERLAY + HISTORY PANEL
  // ==============================================================

  Widget _buildSearchOverlay(ThemeData theme) {
    final showHistory = _showSuggestions &&
        _suggestions.isEmpty &&
        !_isSearching &&
        _history.isNotEmpty;

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
            onTap: () {
              setState(() {
                _showSuggestions = _searchController.text.isEmpty
                    ? _history.isNotEmpty
                    : (_suggestions.isNotEmpty || _isSearching);
              });
            },
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search a place in Tanzania…',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () {
                  _searchDebounce?.cancel();
                  _searchRequestId++;
                  _searchController.clear();
                  setState(() {
                    _suggestions = const [];
                    _isSearching = false;
                    _showSuggestions = _history.isNotEmpty;
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
        if (_suggestions.isNotEmpty) _buildSuggestionList(theme),
        if (showHistory) _buildHistoryPanel(theme),
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

  Widget _buildHistoryPanel(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Material(
        color: theme.cardColor,
        elevation: 6,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 8, 4),
              child: Row(
                children: [
                  Icon(Icons.history_rounded,
                      size: 18, color: theme.hintColor),
                  const SizedBox(width: 8),
                  Text(
                    'Recent',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: theme.hintColor,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _historyLoaded ? _clearHistory : null,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(0, 28),
                    ),
                    child: const Text(
                      'Clear all',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: ListView.separated(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: _history.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, index) {
                  final value = _history[index];
                  return ListTile(
                    dense: true,
                    leading: Icon(Icons.history_rounded,
                        size: 18, color: theme.hintColor),
                    title: Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13.5),
                    ),
                    trailing: IconButton(
                      tooltip: 'Remove',
                      iconSize: 18,
                      onPressed: () => _removeHistory(value),
                      icon: const Icon(Icons.close_rounded),
                    ),
                    onTap: () {
                      _searchDebounce?.cancel();
                      _searchRequestId++;
                      _searchController.text = value;
                      _searchFocusNode.unfocus();
                      setState(() => _showSuggestions = false);

                      unawaited(_searchPlaces(value).then((_) {
                        if (!mounted) return;
                        if (_suggestions.isNotEmpty) {
                          _selectSuggestion(_suggestions.first);
                        }
                      }));
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==============================================================
  // CONFIRM CARD
  // ==============================================================

  Widget _buildConfirmCard(ThemeData theme) {
    final hasPoint = _selectedPoint != null;
    final label = _isReverseGeocoding
        ? 'Getting address…'
        : (_placeName ?? 'Tap the map or search for a place');

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.place_rounded, color: theme.primaryColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.w600),
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
                onPressed: hasPoint ? _confirm : null,
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
    );
  }
}

// ================================================================
// SMALL WIDGETS
// ================================================================

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  const _CircleButton({
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