// FILE: lib/screens/home/nearby_screen.dart
// Nearby Fundi - clean, borderless UI (login-guarded actions + road routes)
// Search is strictly "nearby": 15 km first, widening up to 100 km max.
// Results are ranked by the server (rating, jobs, requests, reviews,
// post likes/comments, proximity).
//
// Performance notes:
// - One shared search pipeline (map picker, typed place, suggestion, retry)
// - Suggestion coordinates are reused (no second server-side geocode)
// - Reused HTTP client + small LRU cache for place suggestions
// - Ranked list, markers and polylines are cached and rebuilt only when
//   their inputs change (typing in the search box no longer rebuilds them)
// - Route results are applied in throttled batches (not one setState each)
// - Map is fitted as soon as results arrive (before routes finish)
// - Pulse animation only runs while a search origin is on the map
// - Avatars are decoded at display size (cacheWidth) and a failed image URL
//   (404) is requested only once (SafeNetworkImage)
// - RepaintBoundary isolation (map, markers, carousel, search panel)

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/service.dart';
import '../../models/technician.dart';
import '../../providers/technician_provider.dart';
import '../../providers/service_provider.dart';
import '../../providers/settings_provider.dart';
import '../../config/app_routes.dart';
import '../../config/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/image_utils.dart';
import '../../utils/auth_guard.dart';
import '../../services/route_service.dart';
import '../../widgets/route_polylines.dart';
import '../../widgets/safe_network_image.dart';
import 'nearby_map_screen.dart';
import 'map_location_picker_screen.dart';

// ================================================================
// RESPONSIVE CONSTANTS
// ================================================================

class ResponsiveConstants {
  static const double mobileBreakpoint = 480;
  static const double desktopBreakpoint = 1024;

  static double _width(BuildContext context) =>
      MediaQuery.sizeOf(context).width;

  static double getPadding(BuildContext context) {
    final width = _width(context);
    if (width < mobileBreakpoint) return 12.0;
    if (width < desktopBreakpoint) return 14.0;
    return 16.0;
  }

  static double getAvatarSize(BuildContext context) {
    final width = _width(context);
    if (width < mobileBreakpoint) return 40.0;
    if (width < desktopBreakpoint) return 46.0;
    return 52.0;
  }

  static int getGridColumns(BuildContext context) {
    final width = _width(context);
    if (width < mobileBreakpoint) return 1;
    if (width < desktopBreakpoint) return 2;
    return 3;
  }

  static bool isTablet(BuildContext context) {
    final width = _width(context);
    return width >= mobileBreakpoint && width < desktopBreakpoint;
  }

  static bool isDesktop(BuildContext context) =>
      _width(context) >= desktopBreakpoint;

  static double getMarkerWidth(BuildContext context) {
    final width = _width(context);
    if (width < mobileBreakpoint) return 80.0;
    if (width < desktopBreakpoint) return 90.0;
    return 100.0;
  }

  static double getMarkerHeight(BuildContext context) {
    final width = _width(context);
    if (width < mobileBreakpoint) return 84.0;
    if (width < desktopBreakpoint) return 96.0;
    return 108.0;
  }
}

// ================================================================
// CONSTANTS
// ================================================================

class NearbyConstants {
  // Geographic centre of Tanzania (near Dodoma)
  static const LatLng defaultMapCenter = LatLng(-6.3690, 34.8888);

  static const int maxHistoryEntries = 10;
  static const int recommendedCount = 2;
  static const int maxRouteTargets = 10;
  static const int routeFetchBatchSize = 4;

  // Matches the backend: never more than 100 km
  static const int defaultRadiusKm = 15;
  static const int maxRadiusKm = 100;
  static const List<int> expandSteps = [15, 25, 50, 75, 100];

  static const Duration suggestionDebounce = Duration(milliseconds: 450);
  static const Duration placeSearchTimeout = Duration(seconds: 6);
  static const Duration routeFlushInterval = Duration(milliseconds: 90);
  static const int suggestionCacheSize = 40;

  static const String historyPrefsKey = 'location_search_history';
}

class NearbyStrings {
  static const filterByService = 'Filter by service...';
  static const chooseOnMap = 'Choose location on map';
  static const recommendedReason =
      'Top ranked near you: rating, jobs and requests';
  static const recentSearches = 'Recent searches';
  static const clear = 'Clear';
  static const findingRoutes = 'Finding best routes...';
  static const searchForTechnicians = 'Search for technicians';
  static const noTechniciansNearby = 'No technicians found nearby';
  static const expandSearchRadius = 'Search wider';
  static const you = 'You';
  static const zoomIn = 'Zoom in';
  static const zoomOut = 'Zoom out';
  static const fitTechnicians = 'Fit technicians';
  static const showList = 'Show technician list';
  static const showFullMap = 'Show full-screen map';
  static const clearFilters = 'Clear filters';
  static const viewProfile = 'View Profile';
  static const directions = 'Get directions';
  static const couldNotOpenMaps = 'Could not open maps app.';
  static const topPick = 'Top pick';
  static const searchFailed =
      'Search failed. Please check your connection and try again.';
}

// Messages shown in the "create account" modal
const String _kSearchLoginMessage =
    'Sign in or create an account to search for fundis near you.';
const String _kFilterLoginMessage =
    'Sign in or create an account to filter fundis by service.';

// ================================================================
// UI HELPERS (visual only)
// ================================================================

const Color _gold = Color(0xFFF2B93B);
const Color _goldInk = Color(0xFF8A6200);
const Color _verifiedBlue = Color(0xFF3B9BE8);
const Color _darkAccentTone = Color(0xFF6DB6F2);

bool _isDark(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark;

Color _ink(BuildContext context) =>
    _isDark(context) ? Colors.white : AppTheme.primary;

Color _softFill(BuildContext context) => _isDark(context)
    ? Colors.white.withValues(alpha: 0.08)
    : const Color(0xFFF1F5F9);

/// Gold text colour that stays readable in both themes.
Color _goldText(BuildContext context) => _isDark(context) ? _gold : _goldInk;

/// Lightens dark brand colours when the app is in dark mode.
Color _tone(BuildContext context, Color color) {
  if (!_isDark(context)) return color;
  if (color == AppTheme.primary) return Colors.white;
  if (color == AppTheme.accent) return _darkAccentTone;
  return color;
}

// ================================================================
// SMALL VALUE TYPES
// ================================================================

/// A place with known coordinates (from suggestions or the map picker).
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

// ================================================================
// SCREEN
// ================================================================

class NearbyScreen extends StatefulWidget {
  const NearbyScreen({super.key});

  @override
  State<NearbyScreen> createState() => _NearbyScreenState();
}

class _NearbyScreenState extends State<NearbyScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _serviceSearchController = TextEditingController();
  final FocusNode _locationFocus = FocusNode();
  final ScrollController _serviceChipScrollController = ScrollController();
  final ScrollController _categoryChipScrollController = ScrollController();
  final ScrollController _carouselController = ScrollController();
  final MapController _mapController = MapController();

  // One client for all place-suggestion requests (keep-alive connection)
  final http.Client _http = http.Client();

  late final AnimationController _pulseController;

  bool _mapReady = false;
  bool _isHeaderVisible = true;
  bool _isSearching = false;
  bool _isFetchingRoutes = false;

  int? _selectedServiceId;
  int? _selectedCategoryId;
  int? _selectedTechnicianId;

  String _serviceSearchQuery = '';
  String _currentLocale = 'en';
  String _searchedArea = '';

  int _searchRadiusKm = NearbyConstants.defaultRadiusKm;

  // Routes
  final Map<int, TechnicianRouteData> _routesData = {};
  int _routeRequestId = 0;
  int _routesVersion = 0;
  Timer? _routeFlushTimer;

  // Search
  int _searchRequestId = 0;
  _Place? _pickedPlace; // coordinates for the text currently in the field

  // History + suggestions
  SharedPreferences? _prefs;
  List<String> _searchHistory = [];
  List<_Place> _placeSuggestions = [];
  final Map<String, List<_Place>> _suggestionCache = {};

  bool _showSuggestions = false;
  bool _isLoadingSuggestions = false;

  Timer? _suggestionDebounce;
  int _suggestionRequestId = 0;

  // Derived data cache (rebuilt only when technicians change)
  List<Technician> _rankedTechs = const [];
  Set<int> _recommendedIds = const {};
  Object? _techListRef;
  int _techHash = 0;
  int _techVersion = 0;

  // Map layer caches
  List<Marker> _markerCache = const [];
  Object? _markerKey;
  List<Polyline> _polylineCache = const [];
  Object? _polylineKey;

  // Carousel scrolling
  double _carouselCardWidth = 264;
  static const double _carouselGap = 10;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _loadSearchHistory();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final settings = context.read<SettingsProvider>();
      _currentLocale = settings.locale;
      context.read<ServiceProvider>().fetchServices(locale: _currentLocale);
    });
  }

  @override
  void dispose() {
    _routeRequestId++;
    _searchRequestId++;
    _mapReady = false;
    _pulseController.dispose();
    _suggestionDebounce?.cancel();
    _routeFlushTimer?.cancel();
    _http.close();

    _locationController.dispose();
    _serviceSearchController.dispose();
    _locationFocus.dispose();
    _serviceChipScrollController.dispose();
    _categoryChipScrollController.dispose();
    _carouselController.dispose();
    _mapController.dispose();

    super.dispose();
  }

  // ==============================================================
  // SAFE MAP CONTROL
  // ==============================================================

  void _moveMap(LatLng center, double zoom) {
    if (!_mapReady || !mounted) return;
    _mapController.move(center, zoom);
  }

  void _zoomBy(double amount) {
    if (!_mapReady || !mounted) return;
    final camera = _mapController.camera;
    final zoom = (camera.zoom + amount).clamp(4.0, 18.0);
    _mapController.move(camera.center, zoom);
  }

  // ==============================================================
  // PULSE (only runs while something pulses on the map)
  // ==============================================================

  void _syncPulse(bool needed) {
    if (needed == _pulseController.isAnimating) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (needed) {
        if (!_pulseController.isAnimating) _pulseController.repeat();
      } else {
        _pulseController.stop();
      }
    });
  }

  // ==============================================================
  // SEARCH HISTORY
  // ==============================================================

  Future<SharedPreferences> _getPrefs() async =>
      _prefs ??= await SharedPreferences.getInstance();

  Future<void> _loadSearchHistory() async {
    final prefs = await _getPrefs();
    if (!mounted) return;
    setState(() {
      _searchHistory =
          prefs.getStringList(NearbyConstants.historyPrefsKey) ?? [];
    });
  }

  Future<void> _saveToHistory(String place) async {
    if (place.trim().isEmpty) return;

    final prefs = await _getPrefs();
    final history = List<String>.from(
      prefs.getStringList(NearbyConstants.historyPrefsKey) ?? const [],
    );

    history.remove(place);
    history.insert(0, place);

    if (history.length > NearbyConstants.maxHistoryEntries) {
      history.removeLast();
    }

    await prefs.setStringList(NearbyConstants.historyPrefsKey, history);

    if (!mounted) return;
    setState(() => _searchHistory = history);
  }

  Future<void> _clearHistory() async {
    final prefs = await _getPrefs();
    await prefs.remove(NearbyConstants.historyPrefsKey);
    if (!mounted) return;
    setState(() => _searchHistory = []);
  }

  // ==============================================================
  // PLACE SUGGESTIONS
  // ==============================================================

  void _onLocationQueryChanged(String value) {
    final query = value.trim();

    // Typing over a picked place invalidates its saved coordinates
    if (_pickedPlace != null && _pickedPlace!.name != query) {
      _pickedPlace = null;
    }

    _suggestionDebounce?.cancel();

    if (query.length < 2) {
      _suggestionRequestId++; // drop any in-flight response
      setState(() {
        _placeSuggestions = [];
        _showSuggestions = _searchHistory.isNotEmpty;
        _isLoadingSuggestions = false;
      });
      return;
    }

    // Refreshes the clear (x) button
    setState(() {});

    _suggestionDebounce = Timer(
      NearbyConstants.suggestionDebounce,
          () => _fetchPlaceSuggestions(query),
    );
  }

  void _cacheSuggestions(String key, List<_Place> value) {
    if (_suggestionCache.length >= NearbyConstants.suggestionCacheSize) {
      _suggestionCache.remove(_suggestionCache.keys.first);
    }
    _suggestionCache[key] = value;
  }

  Future<void> _fetchPlaceSuggestions(String query) async {
    if (!mounted) return;

    final key = query.toLowerCase();
    final requestId = ++_suggestionRequestId;

    final cached = _suggestionCache[key];
    if (cached != null) {
      setState(() {
        _placeSuggestions = cached;
        _isLoadingSuggestions = false;
        _showSuggestions = true;
      });
      return;
    }

    setState(() {
      _isLoadingSuggestions = true;
      _showSuggestions = true;
    });

    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
            '?q=${Uri.encodeComponent(query)}'
            '&format=json'
            '&addressdetails=1'
            '&limit=8'
            '&countrycodes=tz',
      );

      final response = await _http
          .get(url, headers: {'User-Agent': 'NearbyFundi/1.0'})
          .timeout(NearbyConstants.placeSearchTimeout);

      if (requestId != _suggestionRequestId || !mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        final places = <_Place>[];

        for (final item in data) {
          final value = item as Map<String, dynamic>;
          final lat = double.tryParse(value['lat']?.toString() ?? '');
          final lng = double.tryParse(value['lon']?.toString() ?? '');
          if (lat == null || lng == null) continue;

          final display = value['display_name']?.toString() ?? '';
          places.add(_Place(
            name: display.split(',').take(3).join(',').trim(),
            full: display,
            lat: lat,
            lng: lng,
          ));
        }

        _cacheSuggestions(key, places);
        setState(() => _placeSuggestions = places);
      }
    } catch (e) {
      debugPrint('Place suggestion error: $e');
    }

    if (requestId != _suggestionRequestId || !mounted) return;
    setState(() => _isLoadingSuggestions = false);
  }

  // ==============================================================
  // MAP LOCATION PICKER
  // ==============================================================

  Future<void> _openMapPicker() async {
    if (!AuthGuard.ensure(context, message: _kSearchLoginMessage)) return;

    final techProvider = context.read<TechnicianProvider>();

    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => MapLocationPickerScreen(
          initialCenter: techProvider.hasSearchOrigin
              ? LatLng(techProvider.searchLat!, techProvider.searchLng!)
              : null,
        ),
      ),
    );

    if (result == null || !mounted) return;

    final name = result['name']?.toString() ?? '';
    final lat = (result['lat'] as num?)?.toDouble();
    final lng = (result['lng'] as num?)?.toDouble();

    if (lat == null || lng == null) {
      _showErrorSnackBar('Invalid location selected. Please try again.');
      return;
    }

    _locationController.text = name;
    _pickedPlace = _Place(name: name, full: name, lat: lat, lng: lng);

    await _runSearch(place: name, lat: lat, lng: lng);
  }

  // ==============================================================
  // SEARCH
  // ==============================================================

  /// Search from whatever is in the location field. Uses saved
  /// coordinates (suggestion / map picker) when they match the text,
  /// otherwise lets the server geocode the place name.
  Future<void> _performSearch() async {
    if (!AuthGuard.ensure(context, message: _kSearchLoginMessage)) return;

    final place = _locationController.text.trim();

    if (place.isEmpty) {
      final l10n = AppLocalizations.of(context)!;
      _showErrorSnackBar(l10n.pleaseEnterLocation);
      return;
    }

    final picked = (_pickedPlace != null && _pickedPlace!.name == place)
        ? _pickedPlace
        : null;

    await _runSearch(place: place, lat: picked?.lat, lng: picked?.lng);
  }

  /// Single search pipeline shared by every entry point.
  Future<void> _runSearch({
    required String place,
    double? lat,
    double? lng,
  }) async {
    if (_isSearching) return; // one search at a time

    final requestId = ++_searchRequestId;
    _suggestionDebounce?.cancel();
    _suggestionRequestId++;

    setState(() {
      _showSuggestions = false;
      _isSearching = true;
      _searchedArea = place;
      _selectedTechnicianId = null;
      _resetRoutes();
    });

    unawaited(_saveToHistory(place)); // not needed to start the search

    final techProvider = context.read<TechnicianProvider>();
    techProvider.clearTechnicians();

    final succeeded = await _fetchTechnicians(
      techProvider,
      place: place,
      lat: lat,
      lng: lng,
    );

    if (!mounted || requestId != _searchRequestId) return;

    setState(() => _isSearching = false);
    _locationFocus.unfocus();

    if (!succeeded) {
      _showErrorSnackBar(NearbyStrings.searchFailed);
      return;
    }

    // Show results immediately; routes fill in afterwards.
    _collapsePanelIfResults();
    _updateMapBounds();
    await _fetchRoutesForTechnicians();
  }

  Future<bool> _fetchTechnicians(
      TechnicianProvider techProvider, {
        required String place,
        double? lat,
        double? lng,
      }) async {
    final search =
    _serviceSearchQuery.isNotEmpty ? _serviceSearchQuery : null;

    Future<void> byPlace() => techProvider.searchByPlace(
      place: place,
      serviceId: _selectedServiceId,
      categoryId: _selectedCategoryId,
      radius: _searchRadiusKm,
      search: search,
      locale: _currentLocale,
    );

    try {
      if (lat != null && lng != null) {
        try {
          await techProvider.searchByCoordinates(
            lat: lat,
            lng: lng,
            serviceId: _selectedServiceId,
            categoryId: _selectedCategoryId,
            radius: _searchRadiusKm,
            search: search,
            locale: _currentLocale,
            placeName: place,
          );
        } catch (e) {
          debugPrint('Coordinate search failed: $e');
          await byPlace(); // fallback
        }
      } else {
        await byPlace();
      }
      return true;
    } catch (e) {
      debugPrint('Search error: $e');
      return false;
    }
  }

  void _collapsePanelIfResults() {
    if (!mounted) return;
    if (context.read<TechnicianProvider>().technicians.isNotEmpty) {
      setState(() => _isHeaderVisible = false);
    }
  }

  int get _activeRadiusKm =>
      context.read<TechnicianProvider>().searchRadiusKm ?? _searchRadiusKm;

  int? get _nextExpandStep {
    final current = _activeRadiusKm;
    for (final step in NearbyConstants.expandSteps) {
      if (step > current) return step;
    }
    return null;
  }

  Future<void> _retryWithLargerRadius() async {
    final next = _nextExpandStep;
    if (next == null) return;

    setState(() => _searchRadiusKm = next);

    if (_locationController.text.trim().isNotEmpty) {
      await _performSearch();
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  // ==============================================================
  // ROAD ROUTES
  // ==============================================================

  void _resetRoutes() {
    _routeRequestId++;
    _routeFlushTimer?.cancel();
    _routeFlushTimer = null;
    _routesData.clear();
    _routesVersion++;
    _isFetchingRoutes = false;
  }

  /// Stores a route and schedules ONE rebuild for a burst of routes.
  void _onRouteLoaded(int id, TechnicianRouteData route) {
    _routesData[id] = route;
    _routesVersion++;
    _routeFlushTimer ??= Timer(NearbyConstants.routeFlushInterval, () {
      _routeFlushTimer = null;
      if (mounted) setState(() {});
    });
  }

  Future<void> _fetchRoutesForTechnicians() async {
    if (!mounted) return;

    final techProvider = context.read<TechnicianProvider>();
    if (!techProvider.hasSearchOrigin) return;

    final origin = LatLng(techProvider.searchLat!, techProvider.searchLng!);

    final targets = _rankedValid(techProvider.technicians)
        .take(NearbyConstants.maxRouteTargets)
        .where((t) => !_routesData.containsKey(t.id)) // skip cached routes
        .map((t) => RouteTarget(
      id: t.id,
      point: LatLng(t.latitude!, t.longitude!),
      fallbackKm: t.distanceKm,
    ))
        .toList();

    if (targets.isEmpty) return;

    final requestId = ++_routeRequestId;
    setState(() => _isFetchingRoutes = true);

    bool cancelled() => !mounted || requestId != _routeRequestId;

    await RouteService.instance.fetchMany(
      origin: origin,
      targets: targets,
      batchSize: NearbyConstants.routeFetchBatchSize,
      isCancelled: cancelled,
      onRoute: (id, route) {
        if (cancelled()) return;
        _onRouteLoaded(id, route);
      },
    );

    if (cancelled()) return;

    _routeFlushTimer?.cancel();
    _routeFlushTimer = null;
    setState(() => _isFetchingRoutes = false);
  }

  // ==============================================================
  // CLEAR
  // ==============================================================

  void _clearAllFilters() {
    _locationController.clear();
    _serviceSearchController.clear();
    _suggestionDebounce?.cancel();
    _suggestionRequestId++;
    _searchRequestId++; // ignore any search still in flight
    _pickedPlace = null;

    setState(() {
      _selectedServiceId = null;
      _selectedCategoryId = null;
      _selectedTechnicianId = null;
      _serviceSearchQuery = '';
      _resetRoutes();
      _searchedArea = '';
      _showSuggestions = false;
      _placeSuggestions = [];
      _isSearching = false;
      _searchRadiusKm = NearbyConstants.defaultRadiusKm;
    });

    context.read<TechnicianProvider>().clearTechnicians();
    _locationFocus.unfocus();
    _moveMap(NearbyConstants.defaultMapCenter, 5.5);
  }

  // ==============================================================
  // MAP BOUNDS
  // ==============================================================

  void _updateMapBounds() {
    if (!_mapReady || !mounted) return;

    final techProvider = context.read<TechnicianProvider>();
    if (!techProvider.hasSearchOrigin) return;

    final origin = LatLng(techProvider.searchLat!, techProvider.searchLng!);

    final techPoints = techProvider.technicians
        .where((t) => t.latitude != null && t.longitude != null)
        .map((t) => LatLng(t.latitude!, t.longitude!))
        .toList();

    if (techPoints.isEmpty) {
      _mapController.move(origin, 13);
      return;
    }

    final bounds = LatLngBounds.fromPoints([origin, ...techPoints]);

    // Keep the markers clear of the search panel (top) and the carousel
    // (bottom) without eating too much of a small screen.
    final height = MediaQuery.sizeOf(context).height;
    final topPadding =
    _isHeaderVisible ? (height * 0.34).clamp(120.0, 260.0) : 110.0;
    final bottomPadding = (height * 0.24).clamp(140.0, 200.0);

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: EdgeInsets.fromLTRB(60, topPadding, 60, bottomPadding),
        maxZoom: 16,
        minZoom: 4,
      ),
    );
  }

  void _scrollCarouselTo(int techId) {
    if (!_carouselController.hasClients) return;

    final index = _rankedTechs.indexWhere((t) => t.id == techId);
    if (index < 0) return;

    final target = index * (_carouselCardWidth + _carouselGap);
    final max = _carouselController.position.maxScrollExtent;

    _carouselController.animateTo(
      target.clamp(0.0, max).toDouble(),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  // ==============================================================
  // FILTER SERVICES
  // ==============================================================

  List<Service> _getFilteredServices(List<Service> services) {
    if (_serviceSearchQuery.trim().isEmpty) return services;
    final query = _serviceSearchQuery.toLowerCase().trim();
    return services
        .where((service) => service.matchesSearch(query, _currentLocale))
        .toList();
  }

  List<ServiceCategory> _getCategoriesForSelectedService(
      ServiceProvider provider,
      ) {
    if (_selectedServiceId == null) return [];
    return provider.getCategoriesForService(_selectedServiceId!);
  }

  // ==============================================================
  // RANKING (cached)
  // ==============================================================

  List<Technician> _rankedValid(List<Technician> technicians) {
    return technicians
        .where((t) => t.latitude != null && t.longitude != null)
        .toList()
      ..sort(Technician.byRank);
  }

  /// Re-sorts only when the technician list really changed.
  void _syncDerived(List<Technician> technicians) {
    final hash = Object.hashAll(technicians.map((t) => Object.hash(
      t.id,
      t.latitude,
      t.longitude,
      t.rating,
      t.distanceKm,
      t.completedJobsCount,
      t.requestsCount,
      t.reviewsCount,
      t.verified,
    )));

    if (identical(technicians, _techListRef) && hash == _techHash) return;

    _techListRef = technicians;
    _techHash = hash;
    _techVersion++;

    _rankedTechs = _rankedValid(technicians);
    _recommendedIds = _rankedTechs
        .take(NearbyConstants.recommendedCount)
        .map((t) => t.id)
        .toSet();
  }

  // ==============================================================
  // AVATAR
  // ==============================================================

  Widget _buildAvatar(
      Technician tech, {
        double? size,
        double? iconSize,
      }) {
    final contextSize = size ?? ResponsiveConstants.getAvatarSize(context);
    final contextIconSize = iconSize ?? contextSize * 0.5;
    final dpr = MediaQuery.devicePixelRatioOf(context);

    final fallback = Center(
      child: Icon(
        Icons.build_rounded,
        size: contextIconSize,
        color: AppTheme.greyText,
      ),
    );

    return Container(
      width: contextSize,
      height: contextSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        // A missing file (404) is requested once, then the icon is shown
        child: SafeNetworkImage(
          url: tech.profilePhoto == null
              ? null
              : ImageUtils.getFullImageUrl(tech.profilePhoto!),
          size: contextSize,
          cacheWidth: (contextSize * dpr).round(),
          fallback: fallback,
        ),
      ),
    );
  }

  /// Avatar with a gold ring when recommended (ring avatar is [size],
  /// plain avatar is slightly larger so both occupy the same space).
  Widget _buildTileAvatar(Technician tech, bool recommended, double size) {
    if (!recommended) {
      return _buildAvatar(tech, size: size + 4, iconSize: size * 0.5);
    }
    return Container(
      padding: const EdgeInsets.all(2.5),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: _gold,
      ),
      child: _buildAvatar(tech, size: size, iconSize: size * 0.5),
    );
  }

  Widget _verifiedBadge(double size, double leftPad) {
    return Padding(
      padding: EdgeInsets.only(left: leftPad),
      child: Icon(Icons.verified_rounded, color: _verifiedBlue, size: size),
    );
  }

  // ==============================================================
  // RECOMMENDED PULSE
  // ==============================================================

  Widget _buildRecommendationPulse(Technician tech, double size) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final value = _pulseController.value;
        final scale = 0.8 + (value * 0.45);
        final opacity = 0.50 * (1 - value);

        return Stack(
          alignment: Alignment.center,
          children: [
            Transform.scale(
              scale: scale,
              child: Container(
                width: size + 18,
                height: size + 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _gold.withValues(alpha: opacity.clamp(0.0, 1.0)),
                    width: 3,
                  ),
                ),
              ),
            ),
            child!,
          ],
        );
      },
      // Static part is built once, not on every animation tick
      child: Container(
        padding: const EdgeInsets.all(2.5),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: _gold,
        ),
        child: _buildAvatar(tech, size: size, iconSize: size * 0.48),
      ),
    );
  }

  // ==============================================================
  // SMALL INFO CHIP
  // ==============================================================

  Widget _infoChip(IconData icon, String text, Color color) {
    final tone = _tone(context, color);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: tone),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: tone,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _proofChips(Technician t) => [
    if (t.completedJobsCount > 0)
      _infoChip(Icons.task_alt_rounded, '${t.completedJobsCount} jobs',
          AppTheme.accent),
    if (t.requestsCount > 0)
      _infoChip(Icons.assignment_turned_in_rounded,
          '${t.requestsCount} requests', AppTheme.primary),
  ];

  // ==============================================================
  // TECHNICIAN LIST (bottom sheet)
  // ==============================================================

  void _showTechniciansList(
      BuildContext context,
      List<Technician> technicians,
      Set<int> recommendedIds,
      ) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isTablet = ResponsiveConstants.isTablet(context);
    final isDesktop = ResponsiveConstants.isDesktop(context);
    final ink = _ink(context);

    final sorted = [...technicians]..sort(Technician.byRank);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      constraints: const BoxConstraints(maxWidth: 900),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: isDesktop ? 0.6 : (isTablet ? 0.7 : 0.78),
          minChildSize: isDesktop ? 0.3 : (isTablet ? 0.4 : 0.45),
          maxChildSize: isDesktop ? 0.85 : (isTablet ? 0.9 : 0.95),
          expand: false,
          builder: (context, controller) {
            final columns = ResponsiveConstants.getGridColumns(context);
            final pad = ResponsiveConstants.getPadding(context);

            return Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(pad + 6, 16, pad - 2, 10),
                  child: Row(
                    children: [
                      Container(
                        width: 5,
                        height: 26,
                        decoration: BoxDecoration(
                          color: _gold,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${sorted.length} ${l10n.fundisFound}',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: ink,
                          ),
                        ),
                      ),
                      _SoftIconButton(
                        icon: Icons.close_rounded,
                        onTap: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: columns > 1
                      ? GridView.builder(
                    controller: controller,
                    padding: EdgeInsets.all(pad),
                    cacheExtent: 400,
                    addAutomaticKeepAlives: false,
                    gridDelegate:
                    SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: pad,
                      mainAxisSpacing: pad,
                      childAspectRatio: isDesktop ? 3.0 : 2.6,
                    ),
                    itemCount: sorted.length,
                    itemBuilder: (_, index) {
                      final tech = sorted[index];
                      return _buildListTile(
                        context,
                        tech,
                        recommendedIds.contains(tech.id),
                      );
                    },
                  )
                      : ListView.separated(
                    controller: controller,
                    padding: EdgeInsets.all(pad),
                    cacheExtent: 400,
                    addAutomaticKeepAlives: false,
                    itemCount: sorted.length,
                    separatorBuilder: (_, __) =>
                    const SizedBox(height: 12),
                    itemBuilder: (_, index) {
                      final tech = sorted[index];
                      return _buildListTile(
                        context,
                        tech,
                        recommendedIds.contains(tech.id),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ==============================================================
  // LIST TILE
  // ==============================================================

  Widget _buildListTile(
      BuildContext context,
      Technician tech,
      bool recommended,
      ) {
    final theme = Theme.of(context);
    final ink = _ink(context);

    final route = _routesData[tech.id];
    final distance = route?.distanceKm ?? tech.distanceKm;
    final duration = route?.durationMin;
    final selected = _selectedTechnicianId == tech.id;

    return Material(
      color: selected
          ? Color.alphaBlend(
        _gold.withValues(alpha: 0.14),
        theme.colorScheme.surface,
      )
          : theme.colorScheme.surface,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () {
          // Take the navigator first: the sheet's context is gone after pop
          final navigator = Navigator.of(context);
          setState(() => _selectedTechnicianId = tech.id);
          navigator.pop();
          navigator.pushNamed(
            AppRoutes.technicianDetail,
            arguments: tech.id,
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _buildTileAvatar(tech, recommended, 50),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            tech.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: ink,
                            ),
                          ),
                        ),
                        if (tech.verified) _verifiedBadge(16, 5),
                      ],
                    ),
                    if (tech.area != null && tech.area!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        tech.area!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: theme.hintColor,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _infoChip(
                          Icons.directions_car_rounded,
                          '${distance.toStringAsFixed(1)} km',
                          AppTheme.primary,
                        ),
                        if (duration != null)
                          _infoChip(
                            Icons.access_time_rounded,
                            '~${duration.toStringAsFixed(0)} min',
                            AppTheme.accent,
                          ),
                        if (tech.rating > 0)
                          _infoChip(
                            Icons.star_rounded,
                            tech.rating.toStringAsFixed(1),
                            AppTheme.secondary,
                          ),
                        ..._proofChips(tech),
                        if (recommended)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _gold.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              NearbyStrings.topPick,
                              style: TextStyle(
                                color: _goldInk,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _softFill(context),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.chevron_right_rounded, color: ink, size: 22),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==============================================================
  // BOTTOM CAROUSEL CARD
  // ==============================================================

  Widget _buildTechCard(
      Technician tech,
      bool recommended,
      LatLng origin,
      double cardWidth,
      ) {
    final theme = Theme.of(context);
    final ink = _ink(context);

    final route = _routesData[tech.id];
    final distance = route?.distanceKm ?? tech.distanceKm;
    final duration = route?.durationMin;
    final selected = _selectedTechnicianId == tech.id;

    final compact = cardWidth < 290;
    final avatarSize = compact ? 46.0 : 52.0;

    final String subtitle;
    if (recommended) {
      subtitle = NearbyStrings.topPick;
    } else if (tech.completedJobsCount > 0) {
      subtitle = '${tech.completedJobsCount} jobs done';
    } else {
      subtitle = (tech.area != null && tech.area!.isNotEmpty) ? tech.area! : '';
    }

    return RepaintBoundary(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTechnicianId = selected ? null : tech.id;
          });

          if (tech.latitude != null && tech.longitude != null) {
            _moveMap(LatLng(tech.latitude!, tech.longitude!), 15);
          }

          _showTechnicianModal(context, tech, origin, recommended);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: cardWidth,
          margin: const EdgeInsets.only(right: _carouselGap),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: selected
                ? Color.alphaBlend(
              _gold.withValues(alpha: 0.16),
              theme.colorScheme.surface,
            )
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: selected ? 0.22 : 0.14),
                blurRadius: selected ? 20 : 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildTileAvatar(tech, recommended, avatarSize),
              const SizedBox(width: 10),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, box) {
                    return FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        width: box.maxWidth,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    tech.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: ink,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14.5,
                                      height: 1.2,
                                    ),
                                  ),
                                ),
                                if (tech.verified) _verifiedBadge(15, 4),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                if (tech.rating > 0) ...[
                                  const Icon(Icons.star_rounded,
                                      color: AppTheme.secondary, size: 15),
                                  const SizedBox(width: 2),
                                  Text(
                                    tech.rating.toStringAsFixed(1),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12.5,
                                      height: 1.2,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                ],
                                Expanded(
                                  child: Text(
                                    subtitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: recommended
                                          ? _goldText(context)
                                          : theme.hintColor,
                                      fontSize: 12,
                                      height: 1.2,
                                      fontWeight: recommended
                                          ? FontWeight.w800
                                          : FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                _infoChip(
                                  Icons.directions_car_rounded,
                                  '${distance.toStringAsFixed(1)} km',
                                  AppTheme.primary,
                                ),
                                if (duration != null)
                                  _infoChip(
                                    Icons.access_time_rounded,
                                    '~${duration.toStringAsFixed(0)} min',
                                    AppTheme.accent,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==============================================================
  // BUILD
  // ==============================================================

  @override
  Widget build(BuildContext context) {
    final techProvider = context.watch<TechnicianProvider>();
    final serviceProvider = context.watch<ServiceProvider>();
    final settings = context.watch<SettingsProvider>();
    final theme = Theme.of(context);

    if (_currentLocale != settings.locale) {
      _currentLocale = settings.locale;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<ServiceProvider>().fetchServices(locale: _currentLocale);
      });
    }

    final services = _getFilteredServices(serviceProvider.localizedServices);
    final categories = _getCategoriesForSelectedService(serviceProvider);

    // Sorted list / recommended ids are recomputed only on real changes
    _syncDerived(techProvider.technicians);
    final sortedByRank = _rankedTechs;
    final recommendedIds = _recommendedIds;

    _syncPulse(techProvider.hasSearchOrigin);

    final mq = MediaQuery.of(context);
    final clampedScaler = mq.textScaler.clamp(
      minScaleFactor: 0.9,
      maxScaleFactor: 1.2,
    );

    final hasFilters =
        _locationController.text.isNotEmpty || _selectedServiceId != null;
    final hasTechnicians = techProvider.technicians.isNotEmpty;

    final showCarousel =
        techProvider.hasSearchOrigin && sortedByRank.isNotEmpty;
    final carouselOrigin = showCarousel
        ? LatLng(techProvider.searchLat!, techProvider.searchLng!)
        : NearbyConstants.defaultMapCenter;

    final fontScale = clampedScaler.scale(1.0);
    final carouselHeight = (116.0 * fontScale).clamp(116.0, 142.0);
    final cardWidth = (mq.size.width * 0.8).clamp(264.0, 340.0);
    _carouselCardWidth = cardWidth;

    final controlsBottom = showCarousel ? carouselHeight + 20 : 20.0;

    return MediaQuery(
      data: mq.copyWith(textScaler: clampedScaler),
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Stack(
          children: [
            // MAP
            Positioned.fill(
              child: RepaintBoundary(
                child: _buildMapView(theme, techProvider, recommendedIds),
              ),
            ),

            // FLOATING SEARCH CARD
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: AnimatedSize(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      alignment: Alignment.topCenter,
                      child: _isHeaderVisible
                          ? RepaintBoundary(
                        child: _buildSearchPanel(
                          context,
                          theme,
                          services,
                          categories,
                          techProvider,
                          hasFilters,
                        ),
                      )
                          : _buildShowSearchButton(theme),
                    ),
                  ),
                ),
              ),
            ),

            // ZOOM CONTROLS
            Positioned(
              right: 12,
              bottom: controlsBottom,
              child: Column(
                children: [
                  _MapControlButton(
                    icon: Icons.add,
                    tooltip: NearbyStrings.zoomIn,
                    onPressed: () => _zoomBy(1),
                  ),
                  const SizedBox(height: 8),
                  _MapControlButton(
                    icon: Icons.remove,
                    tooltip: NearbyStrings.zoomOut,
                    onPressed: () => _zoomBy(-1),
                  ),
                  const SizedBox(height: 8),
                  _MapControlButton(
                    icon: Icons.my_location_rounded,
                    tooltip: NearbyStrings.fitTechnicians,
                    onPressed: _updateMapBounds,
                    highlighted: true,
                  ),
                ],
              ),
            ),

            // LIST + FULL MAP BUTTONS
            if (hasTechnicians)
              Positioned(
                left: 12,
                bottom: controlsBottom,
                child: Row(
                  children: [
                    _PillButton(
                      icon: Icons.list_rounded,
                      label: '${techProvider.technicians.length}',
                      tooltip: NearbyStrings.showList,
                      filled: true,
                      onPressed: () => _showTechniciansList(
                        context,
                        techProvider.technicians,
                        recommendedIds,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _PillButton(
                      icon: Icons.fullscreen_rounded,
                      tooltip: NearbyStrings.showFullMap,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const NearbyMapScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

            // FUNDI CAROUSEL
            if (showCarousel)
              Positioned(
                left: 0,
                right: 0,
                bottom: 8,
                height: carouselHeight,
                child: ListView.builder(
                  controller: _carouselController,
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  cacheExtent: 600,
                  addAutomaticKeepAlives: false,
                  padding: const EdgeInsets.fromLTRB(12, 4, 2, 8),
                  itemCount: sortedByRank.length,
                  itemBuilder: (_, index) {
                    final tech = sortedByRank[index];
                    return _buildTechCard(
                      tech,
                      recommendedIds.contains(tech.id),
                      carouselOrigin,
                      cardWidth,
                    );
                  },
                ),
              ),

            // ROUTE LOADING
            if (_isFetchingRoutes)
              Positioned(
                bottom: showCarousel ? carouselHeight + 78 : 80,
                left: 0,
                right: 0,
                child: Center(
                  child: RepaintBoundary(child: _routeLoadingBadge()),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ==============================================================
  // SEARCH PANEL
  // ==============================================================

  Widget _buildShowSearchButton(ThemeData theme) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
        child: _PillButton(
          key: const ValueKey('hidden-search'),
          icon: Icons.search_rounded,
          label: 'Search',
          tooltip: 'Show search',
          filled: true,
          onPressed: () => setState(() => _isHeaderVisible = true),
        ),
      ),
    );
  }

  Widget _buildSearchPanel(
      BuildContext context,
      ThemeData theme,
      List<Service> services,
      List<ServiceCategory> categories,
      TechnicianProvider techProvider,
      bool hasFilters,
      ) {
    final l10n = AppLocalizations.of(context)!;
    final ink = _ink(context);
    final media = MediaQuery.of(context);
    final loggedIn = AuthGuard.isLoggedIn(context);
    final availableHeight = media.size.height - media.viewInsets.bottom;
    final usedRadius = techProvider.searchRadiusKm ?? _searchRadiusKm;

    return Container(
      key: const ValueKey('visible-search'),
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: availableHeight * 0.58),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADING + HIDE
              Row(
                children: [
                  Container(
                    width: 5,
                    height: 22,
                    decoration: BoxDecoration(
                      color: _gold,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Find a fundi near you',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: ink,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  _SoftIconButton(
                    icon: Icons.keyboard_arrow_up_rounded,
                    tooltip: 'Hide search',
                    size: 34,
                    iconSize: 22,
                    onTap: () => setState(() => _isHeaderVisible = false),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // LOCATION SEARCH
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _locationController,
                      focusNode: _locationFocus,
                      readOnly: !loggedIn,
                      textInputAction: TextInputAction.search,
                      style: const TextStyle(fontSize: 14.5),
                      decoration: InputDecoration(
                        hintText: l10n.searchLocation,
                        hintStyle:
                        TextStyle(color: theme.hintColor, fontSize: 14),
                        prefixIcon:
                        Icon(Icons.search_rounded, color: ink, size: 22),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_locationController.text.isNotEmpty)
                              IconButton(
                                tooltip: NearbyStrings.clear,
                                icon: const Icon(Icons.close_rounded, size: 18),
                                onPressed: () {
                                  _locationController.clear();
                                  _suggestionDebounce?.cancel();
                                  _suggestionRequestId++;
                                  _pickedPlace = null;
                                  setState(() {
                                    _placeSuggestions = [];
                                    _isLoadingSuggestions = false;
                                    _showSuggestions =
                                        _searchHistory.isNotEmpty;
                                  });
                                },
                              ),
                            IconButton(
                              tooltip: NearbyStrings.chooseOnMap,
                              icon: Icon(Icons.map_outlined,
                                  color: ink, size: 22),
                              onPressed: _openMapPicker,
                            ),
                          ],
                        ),
                        filled: true,
                        fillColor: _softFill(context),
                        isDense: true,
                        contentPadding:
                        const EdgeInsets.symmetric(vertical: 14),
                        border: _borderless(16),
                        enabledBorder: _borderless(16),
                        focusedBorder: _borderless(16),
                      ),
                      onChanged: _onLocationQueryChanged,
                      onTap: () {
                        if (!loggedIn) {
                          _locationFocus.unfocus();
                          AuthGuard.showLoginRequired(
                            context,
                            message: _kSearchLoginMessage,
                          );
                          return;
                        }
                        setState(() => _showSuggestions = true);
                      },
                      onSubmitted: (_) => _performSearch(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 50,
                    width: 50,
                    child: ElevatedButton(
                      onPressed: _isSearching ? null : _performSearch,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _gold,
                        foregroundColor: AppTheme.primary,
                        disabledBackgroundColor: _gold.withValues(alpha: 0.55),
                        elevation: 0,
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(50, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isSearching
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: AppTheme.primary,
                        ),
                      )
                          : const Icon(Icons.search_rounded, size: 24),
                    ),
                  ),
                ],
              ),

              // SUGGESTIONS
              if (_showSuggestions)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: _buildSuggestions(context, theme),
                ),

              // RESULT SUMMARY
              if (_searchedArea.isNotEmpty &&
                  techProvider.technicians.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: AppTheme.error.withValues(alpha: 0.10),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.location_on_rounded,
                            color: AppTheme.error, size: 16),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _searchedArea,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: ink,
                            fontWeight: FontWeight.w800,
                            fontSize: 13.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _gold.withValues(alpha: 0.20),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${techProvider.technicians.length} found • $usedRadius km',
                          style: TextStyle(
                            color: _goldText(context),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              if (techProvider.searchExpanded &&
                  techProvider.technicians.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded,
                          size: 15, color: theme.hintColor),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'No fundis very close, so we searched up to $usedRadius km.',
                          style: TextStyle(
                            color: theme.hintColor,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 10),

              // SERVICE FILTER
              SizedBox(
                height: 42,
                child: TextField(
                  controller: _serviceSearchController,
                  readOnly: !loggedIn,
                  onTap: () {
                    if (!loggedIn) {
                      FocusScope.of(context).unfocus();
                      AuthGuard.showLoginRequired(
                        context,
                        message: _kFilterLoginMessage,
                      );
                    }
                  },
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: NearbyStrings.filterByService,
                    hintStyle:
                    TextStyle(color: theme.hintColor, fontSize: 13.5),
                    prefixIcon:
                    Icon(Icons.build_outlined, color: ink, size: 18),
                    suffixIcon: _serviceSearchQuery.isNotEmpty
                        ? IconButton(
                      tooltip: NearbyStrings.clear,
                      icon: const Icon(Icons.close_rounded, size: 16),
                      onPressed: () {
                        _serviceSearchController.clear();
                        setState(() => _serviceSearchQuery = '');
                      },
                    )
                        : null,
                    filled: true,
                    fillColor: _softFill(context),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                    border: _borderless(14),
                    enabledBorder: _borderless(14),
                    focusedBorder: _borderless(14),
                  ),
                  onChanged: (value) {
                    setState(() => _serviceSearchQuery = value);
                  },
                ),
              ),

              // SERVICE CHIPS
              if (services.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: SizedBox(
                    height: 38,
                    child: ListView(
                      controller: _serviceChipScrollController,
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildChip(
                          label: 'All',
                          isSelected: _selectedServiceId == null,
                          onTap: () {
                            setState(() {
                              _selectedServiceId = null;
                              _selectedCategoryId = null;
                            });
                          },
                        ),
                        ...services.map((service) {
                          final selected = _selectedServiceId == service.id;
                          return _buildChip(
                            label: service.name,
                            isSelected: selected,
                            onTap: () {
                              setState(() {
                                _selectedServiceId =
                                selected ? null : service.id;
                                _selectedCategoryId = null;
                              });
                            },
                          );
                        }),
                      ],
                    ),
                  ),
                ),

              // CATEGORY CHIPS
              if (categories.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: SizedBox(
                    height: 34,
                    child: ListView(
                      controller: _categoryChipScrollController,
                      scrollDirection: Axis.horizontal,
                      children: categories.map((category) {
                        final selected = _selectedCategoryId == category.id;
                        return _buildChip(
                          label: category.name,
                          isSelected: selected,
                          outlined: true,
                          onTap: () {
                            setState(() {
                              _selectedCategoryId =
                              selected ? null : category.id;
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ),

              // CLEAR FILTERS
              if (hasFilters)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: TextButton.icon(
                    onPressed: _clearAllFilters,
                    icon: const Icon(Icons.clear_all_rounded, size: 18),
                    label: const Text(NearbyStrings.clearFilters),
                    style: TextButton.styleFrom(
                      foregroundColor: ink,
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      textStyle: const TextStyle(
                          fontSize: 12.5, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  InputBorder _borderless(double radius) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(radius),
    borderSide: BorderSide.none,
  );

  // ==============================================================
  // SUGGESTIONS
  // ==============================================================

  Widget _buildSuggestions(BuildContext context, ThemeData theme) {
    final ink = _ink(context);
    final showHistoryHeader = _searchHistory.isNotEmpty &&
        _placeSuggestions.isEmpty &&
        !_isLoadingSuggestions;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: _softFill(context),
        borderRadius: BorderRadius.circular(18),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListView(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        children: [
          if (showHistoryHeader)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 6, 6, 0),
              child: Row(
                children: [
                  Text(
                    NearbyStrings.recentSearches,
                    style: TextStyle(
                      color: theme.hintColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _clearHistory,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      minimumSize: const Size(0, 28),
                    ),
                    child: Text(
                      NearbyStrings.clear,
                      style: TextStyle(color: ink, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          if (showHistoryHeader)
            ..._searchHistory.map(
                  (place) => ListTile(
                dense: true,
                leading: Icon(Icons.history_rounded,
                    color: theme.hintColor, size: 18),
                title: Text(
                  place,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14),
                ),
                onTap: () {
                  _locationController.text = place;
                  _pickedPlace = null;
                  setState(() => _showSuggestions = false);
                  _performSearch();
                },
              ),
            ),
          if (_isLoadingSuggestions)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          ..._placeSuggestions.map((suggestion) {
            return ListTile(
              dense: true,
              leading: const Icon(Icons.location_on_outlined,
                  color: AppTheme.error, size: 18),
              title: Text(
                suggestion.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14),
              ),
              subtitle: Text(
                suggestion.full,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11.5),
              ),
              onTap: () {
                // Keep coordinates so the search skips server geocoding
                _locationController.text = suggestion.name;
                _pickedPlace = suggestion;
                setState(() => _showSuggestions = false);
                _performSearch();
              },
            );
          }),
        ],
      ),
    );
  }

  // ==============================================================
  // MAP
  // ==============================================================

  Widget _buildMapView(
      ThemeData theme,
      TechnicianProvider techProvider,
      Set<int> recommendedIds,
      ) {
    final isTablet = ResponsiveConstants.isTablet(context);
    final isDesktop = ResponsiveConstants.isDesktop(context);
    final hasOrigin = techProvider.hasSearchOrigin;

    final origin = hasOrigin
        ? LatLng(techProvider.searchLat!, techProvider.searchLng!)
        : NearbyConstants.defaultMapCenter;

    final technicians = hasOrigin ? _rankedTechs : const <Technician>[];

    Widget? overlay;
    if (!hasOrigin) {
      overlay = _emptyMapState(
        theme,
        Icons.map_outlined,
        NearbyStrings.searchForTechnicians,
      );
    } else if (technicians.isEmpty) {
      overlay = _emptyMapState(
        theme,
        Icons.person_search_rounded,
        NearbyStrings.noTechniciansNearby,
        showExpandRadius: true,
      );
    }

    // ---- Route polylines (cached) ----
    final polylineKey = Object.hash(
      hasOrigin,
      _techVersion,
      _routesVersion,
      _selectedTechnicianId,
    );
    if (polylineKey != _polylineKey) {
      _polylineKey = polylineKey;
      _polylineCache = buildRoutePolylines(
        routes: {
          for (final tech in technicians)
            if (_routesData[tech.id] != null) tech.id: _routesData[tech.id]!,
        },
        selectedId: _selectedTechnicianId,
        lineColor: AppTheme.primary,
        selectedColor: _gold,
      );
    }

    // ---- Technician markers (cached) ----
    final markerWidth = ResponsiveConstants.getMarkerWidth(context);
    final markerHeight = ResponsiveConstants.getMarkerHeight(context);
    final avatarSize = ResponsiveConstants.getAvatarSize(context);

    final markerKey = Object.hash(
      hasOrigin,
      _techVersion,
      _routesVersion,
      _selectedTechnicianId,
      markerWidth,
      markerHeight,
      avatarSize,
      origin.latitude,
      origin.longitude,
    );
    if (markerKey != _markerKey) {
      _markerKey = markerKey;
      _markerCache = _buildTechnicianMarkers(
        technicians: technicians,
        recommendedIds: recommendedIds,
        origin: origin,
        markerWidth: markerWidth,
        markerHeight: markerHeight,
        avatarSize: avatarSize,
      );
    }

    final originPulse = Marker(
      point: origin,
      width: 90,
      height: 90,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final v = _pulseController.value;
            return Center(
              child: Container(
                width: 28 + (v * 56),
                height: 28 + (v * 56),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.error.withValues(alpha: 0.22 * (1 - v)),
                  border: Border.all(
                    color: AppTheme.error.withValues(alpha: 0.5 * (1 - v)),
                    width: 1.5,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );

    final originMarker = Marker(
      point: origin,
      width: 60,
      height: 60,
      alignment: Alignment.bottomCenter,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.bottomCenter,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_on_rounded,
              color: AppTheme.error,
              size: isDesktop ? 48 : (isTablet ? 42 : 38),
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 6,
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.error,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                NearbyStrings.you,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    final map = FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: origin,
        initialZoom:
        hasOrigin ? (isDesktop ? 14 : (isTablet ? 13.5 : 13)) : 5.5,
        minZoom: 4,
        maxZoom: 18,
        onMapReady: () => _mapReady = true,
        onTap: (_, __) {
          if (_selectedTechnicianId != null) {
            setState(() => _selectedTechnicianId = null);
          }
          if (_showSuggestions) {
            setState(() => _showSuggestions = false);
            _locationFocus.unfocus();
          }
        },
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.nearbyfundi',
        ),
        // (search-radius circle intentionally removed)
        PolylineLayer(polylines: _polylineCache),
        MarkerLayer(
          markers: [
            if (hasOrigin) ...[originPulse, originMarker],
            ..._markerCache,
          ],
        ),
        RichAttributionWidget(
          alignment: AttributionAlignment.bottomLeft,
          attributions: [
            TextSourceAttribution(
              '© OpenStreetMap contributors',
              onTap: () {
                launchUrl(
                  Uri.parse('https://www.openstreetmap.org/copyright'),
                );
              },
            ),
          ],
        ),
      ],
    );

    return Stack(
      children: [
        Positioned.fill(child: map),
        if (overlay != null) Positioned.fill(child: overlay),
      ],
    );
  }

  List<Marker> _buildTechnicianMarkers({
    required List<Technician> technicians,
    required Set<int> recommendedIds,
    required LatLng origin,
    required double markerWidth,
    required double markerHeight,
    required double avatarSize,
  }) {
    // Best-ranked drawn last so it sits on top
    return technicians.reversed.map((tech) {
      final route = _routesData[tech.id];
      final distance = route?.distanceKm ?? tech.distanceKm;
      final selected = _selectedTechnicianId == tech.id;
      final isRecommended = recommendedIds.contains(tech.id);

      return Marker(
        point: LatLng(tech.latitude!, tech.longitude!),
        width: markerWidth,
        height: markerHeight,
        alignment: Alignment.bottomCenter,
        child: RepaintBoundary(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              setState(() {
                _selectedTechnicianId = selected ? null : tech.id;
              });
              if (!selected) _scrollCarouselTo(tech.id);
              _showTechnicianModal(context, tech, origin, isRecommended);
            },
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.bottomCenter,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (isRecommended)
                    _buildRecommendationPulse(tech, avatarSize)
                  else
                    Container(
                      padding: const EdgeInsets.all(2.5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: selected ? _gold : AppTheme.primary,
                      ),
                      child: _buildAvatar(
                        tech,
                        size: avatarSize,
                        iconSize: avatarSize * 0.5,
                      ),
                    ),
                  if (distance > 0) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isRecommended || selected
                            ? _gold
                            : AppTheme.primary,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.22),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        '${distance.toStringAsFixed(1)} km',
                        style: TextStyle(
                          color: isRecommended || selected
                              ? AppTheme.primary
                              : Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  // ==============================================================
  // EMPTY MAP
  // ==============================================================

  Widget _emptyMapState(
      ThemeData theme,
      IconData icon,
      String message, {
        bool showExpandRadius = false,
      }) {
    final ink = _ink(context);
    final nextStep = _nextExpandStep;
    final current = _activeRadiusKm;

    final String subtitle = showExpandRadius
        ? (nextStep == null
        ? 'No fundis within ${NearbyConstants.maxRadiusKm} km of this location. Try another place or service.'
        : 'No fundis within $current km of this location.')
        : 'Search a place or pick one on the map.';

    return Container(
      color: theme.scaffoldBackgroundColor,
      alignment: Alignment.center,
      padding: const EdgeInsets.only(top: 140, left: 24, right: 24),
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 170,
              height: 170,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 170,
                    height: 170,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primary.withValues(alpha: 0.04),
                    ),
                  ),
                  Container(
                    width: 125,
                    height: 125,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primary.withValues(alpha: 0.07),
                    ),
                  ),
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primary,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.30),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(icon, size: 38, color: _gold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              message,
              style: TextStyle(
                color: ink,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.hintColor, fontSize: 13.5),
            ),
            if (showExpandRadius && nextStep != null) ...[
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: _retryWithLargerRadius,
                icon: const Icon(Icons.add_location_alt_outlined, size: 18),
                label: Text(
                  '${NearbyStrings.expandSearchRadius} (up to $nextStep km)',
                  style: const TextStyle(fontSize: 13),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 48),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ==============================================================
  // ROUTE LOADING
  // ==============================================================

  Widget _routeLoadingBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: _gold,
            ),
          ),
          SizedBox(width: 10),
          Text(
            NearbyStrings.findingRoutes,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ==============================================================
  // TECHNICIAN MODAL
  // ==============================================================

  Widget _statTile(
      IconData icon,
      String value,
      String label,
      Color color,
      ) {
    final tone = _tone(context, color);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: tone.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Icon(icon, color: tone, size: 22),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: Theme.of(context).hintColor,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statRow(List<Widget> tiles) {
    return Row(
      children: [
        for (var i = 0; i < tiles.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          tiles[i],
        ],
      ],
    );
  }

  void _showTechnicianModal(
      BuildContext context,
      Technician tech,
      LatLng origin,
      bool recommended,
      ) {
    final theme = Theme.of(context);
    final ink = _ink(context);
    final goldText = _goldText(context);

    final route = _routesData[tech.id];
    final distance = route?.distanceKm ?? tech.distanceKm;
    final duration = route?.durationMin;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      constraints: const BoxConstraints(maxWidth: 640),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (sheetContext) {
        final mainStats = <Widget>[
          _statTile(
            Icons.directions_car_rounded,
            '${distance.toStringAsFixed(1)} km',
            'Distance',
            AppTheme.primary,
          ),
          if (duration != null)
            _statTile(
              Icons.access_time_rounded,
              '~${duration.toStringAsFixed(0)} min',
              'Drive time',
              AppTheme.accent,
            ),
          if (tech.rating > 0)
            _statTile(
              Icons.star_rounded,
              tech.rating.toStringAsFixed(1),
              'Rating',
              AppTheme.secondary,
            ),
        ];

        final proofStats = <Widget>[
          if (tech.completedJobsCount > 0)
            _statTile(
              Icons.task_alt_rounded,
              '${tech.completedJobsCount}',
              'Jobs done',
              AppTheme.accent,
            ),
          if (tech.requestsCount > 0)
            _statTile(
              Icons.assignment_turned_in_rounded,
              '${tech.requestsCount}',
              'Requests',
              AppTheme.primary,
            ),
          if (tech.reviewsCount > 0)
            _statTile(
              Icons.reviews_rounded,
              '${tech.reviewsCount}',
              'Reviews',
              AppTheme.secondary,
            ),
        ];

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.dividerColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // HEADER
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: _gold,
                      ),
                      child: _buildAvatar(tech, size: 62, iconSize: 30),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  tech.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 19,
                                    color: ink,
                                  ),
                                ),
                              ),
                              if (tech.verified) _verifiedBadge(19, 6),
                            ],
                          ),
                          if (tech.area != null && tech.area!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Row(
                                children: [
                                  const Icon(Icons.location_on_rounded,
                                      color: AppTheme.error, size: 15),
                                  const SizedBox(width: 3),
                                  Expanded(
                                    child: Text(
                                      tech.area!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: theme.hintColor,
                                        fontSize: 13.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    _SoftIconButton(
                      icon: Icons.close_rounded,
                      onTap: () => Navigator.pop(sheetContext),
                    ),
                  ],
                ),

                if (recommended)
                  Container(
                    margin: const EdgeInsets.only(top: 14),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: _gold.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.auto_awesome_rounded,
                            color: goldText, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            NearbyStrings.recommendedReason,
                            style: TextStyle(
                              color: goldText,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 16),

                // STATS
                _statRow(mainStats),
                if (proofStats.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _statRow(proofStats),
                ],

                if (tech.services.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: tech.services.map((service) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _softFill(context),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          service,
                          style: TextStyle(
                            color: ink,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],

                const SizedBox(height: 20),

                // BUTTONS
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(sheetContext);
                            Navigator.pushNamed(
                              context,
                              AppRoutes.technicianDetail,
                              arguments: tech.id,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            NearbyStrings.viewProfile,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (tech.latitude != null && tech.longitude != null) ...[
                      const SizedBox(width: 10),
                      SizedBox(
                        height: 52,
                        width: 56,
                        child: ElevatedButton(
                          onPressed: () {
                            _openDirectionsInGoogleMaps(
                              context,
                              origin: origin,
                              destination:
                              LatLng(tech.latitude!, tech.longitude!),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _gold,
                            foregroundColor: AppTheme.primary,
                            elevation: 0,
                            minimumSize: const Size(56, 52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: EdgeInsets.zero,
                          ),
                          child: const Tooltip(
                            message: NearbyStrings.directions,
                            child: Icon(Icons.directions_rounded, size: 26),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==============================================================
  // GOOGLE MAPS
  // ==============================================================

  Future<void> _openDirectionsInGoogleMaps(
      BuildContext context, {
        required LatLng origin,
        required LatLng destination,
      }) async {
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
          '&origin=${origin.latitude},${origin.longitude}'
          '&destination=${destination.latitude},${destination.longitude}'
          '&travelmode=driving',
    );

    bool launched = false;
    try {
      launched = await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {
      launched = false;
    }

    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(NearbyStrings.couldNotOpenMaps)),
      );
    }
  }

  // ==============================================================
  // CHIP
  // ==============================================================

  Widget _buildChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    bool outlined = false,
  }) {
    final theme = Theme.of(context);
    final ink = _ink(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color background = isSelected
        ? (outlined
        ? (isDark
        ? Colors.white.withValues(alpha: 0.18)
        : AppTheme.primary.withValues(alpha: 0.12))
        : AppTheme.primary)
        : _softFill(context);

    final Color foreground = isSelected
        ? (outlined ? ink : Colors.white)
        : theme.colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            if (!AuthGuard.ensure(context, message: _kFilterLoginMessage)) {
              return;
            }
            onTap();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSelected && !outlined) ...[
                  const Icon(Icons.check_rounded, size: 15, color: _gold),
                  const SizedBox(width: 5),
                ],
                Text(
                  label,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ================================================================
// SOFT ICON BUTTON (close / hide)
// ================================================================

class _SoftIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  final double size;
  final double iconSize;

  const _SoftIconButton({
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.size = 38,
    this.iconSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: _softFill(context),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, size: iconSize, color: _ink(context)),
        ),
      ),
    );

    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}

// ================================================================
// MAP CONTROL
// ================================================================

class _MapControlButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool highlighted;

  const _MapControlButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: highlighted
          ? AppTheme.primary
          : Theme.of(context).colorScheme.surface,
      shape: const CircleBorder(),
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.25),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: highlighted ? _gold : _ink(context),
          size: 22,
        ),
        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      ),
    );
  }
}

// ================================================================
// PILL BUTTON
// ================================================================

class _PillButton extends StatelessWidget {
  final IconData icon;
  final String? label;
  final String tooltip;
  final VoidCallback onPressed;
  final bool filled;

  const _PillButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.label,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final fg = filled ? Colors.white : _ink(context);

    return Tooltip(
      message: tooltip,
      child: Material(
        color:
        filled ? AppTheme.primary : Theme.of(context).colorScheme.surface,
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onPressed,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: label == null ? 12 : 16,
              vertical: 12,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: filled ? _gold : fg, size: 22),
                if (label != null) ...[
                  const SizedBox(width: 6),
                  Text(
                    label!,
                    style: TextStyle(
                      color: fg,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}