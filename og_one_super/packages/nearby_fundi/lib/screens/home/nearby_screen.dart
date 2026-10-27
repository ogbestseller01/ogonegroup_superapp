// FILE: lib/screens/home/nearby_screen.dart
// Nearby Fundi - Clean, borderless UI (login-guarded actions + road routes)

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
import '../../services/route_service.dart'; // ← ROUTE
import '../../widgets/route_polylines.dart'; // ← ROUTE
import 'nearby_map_screen.dart';
import 'map_location_picker_screen.dart';

// ================================================================
// RESPONSIVE CONSTANTS
// ================================================================

class ResponsiveConstants {
  static const double mobileBreakpoint = 480;
  static const double tabletBreakpoint = 768;
  static const double desktopBreakpoint = 1024;

  static double getPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) return 12.0;
    if (width < desktopBreakpoint) return 14.0;
    return 16.0;
  }

  static double getSmallPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) return 4.0;
    if (width < desktopBreakpoint) return 6.0;
    return 8.0;
  }

  static double getFontSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) return 12.0;
    if (width < desktopBreakpoint) return 12.5;
    return 13.0;
  }

  static double getTitleSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) return 15.0;
    if (width < desktopBreakpoint) return 16.0;
    return 18.0;
  }

  static double getAvatarSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) return 40.0;
    if (width < desktopBreakpoint) return 46.0;
    return 52.0;
  }

  static int getGridColumns(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) return 1;
    if (width < desktopBreakpoint) return 2;
    return 3;
  }

  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < desktopBreakpoint;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktopBreakpoint;
  }

  static double getMarkerWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) return 80.0;
    if (width < desktopBreakpoint) return 90.0;
    return 100.0;
  }

  static double getMarkerHeight(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) return 84.0;
    if (width < desktopBreakpoint) return 96.0;
    return 108.0;
  }
}

// ================================================================
// CONSTANTS
// ================================================================

class NearbyConstants {
  static const Color primaryGreen = AppTheme.primary;
  static const Color lightGreen = AppTheme.primaryLight;
  static const Color selectedColor = AppTheme.accent;
  static const Color locationRed = AppTheme.error;
  static const Color technicianGreen = AppTheme.accent;
  static const Color distanceGreen = AppTheme.accent;
  static const Color verifiedBlue = AppTheme.accent;
  static const LatLng defaultMapCenter = LatLng(-6.7924, 39.2083);

  static const int maxHistoryEntries = 10;
  static const int recommendedCount = 2;
  static const int maxRouteTargets = 10;
  static const int routeFetchBatchSize = 4;
  static const int defaultRadiusKm = 20;
  static const int maxRadiusKm = 100;
  static const int radiusStepKm = 20;
  static const Duration suggestionDebounce = Duration(milliseconds: 400);
  static const Duration placeSearchTimeout = Duration(seconds: 6);

  static const String historyPrefsKey = 'location_search_history';
}

class NearbyStrings {
  static const filterByService = 'Filter by service...';
  static const chooseOnMap = 'Choose location on map';
  static const recommendedNearYou = 'Recommended • Near you';
  static const recommendedReason = 'Recommended because this fundi is near you';
  static const recentSearches = 'Recent searches';
  static const clear = 'Clear';
  static const findingRoutes = 'Finding best routes...';
  static const searchForTechnicians = 'Search for technicians';
  static const noTechniciansNearby = 'No technicians found nearby';
  static const expandSearchRadius = 'Expand search radius';
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

/// Warm accent used for highlights (search button, rings, badges).
const Color _gold = Color(0xFFF2B93B);

/// Readable brown for text placed on a soft gold background.
const Color _goldInk = Color(0xFF8A6200);

/// Text/icon color that stays readable in both light and dark mode.
Color _ink(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : AppTheme.primary;

/// Soft fill used for inputs and unselected chips (no borders needed).
Color _softFill(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFFF1F5F9);

/// Borderless input border.
const InputBorder _noBorder = InputBorder.none;

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

  late AnimationController _pulseController;

  /// True once FlutterMap has been rendered and attached to the controller.
  /// Using the controller before this throws an exception.
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

  final Map<int, TechnicianRouteData> _routesData = {};

  // ← ROUTE: lets a new search cancel routes still loading from the old one
  int _routeRequestId = 0;

  List<String> _searchHistory = [];
  List<Map<String, dynamic>> _placeSuggestions = [];

  bool _showSuggestions = false;
  bool _isLoadingSuggestions = false;

  Timer? _suggestionDebounce;
  int _suggestionRequestId = 0;

  // Latest carousel data from build(), used to scroll to a selected fundi.
  List<Technician> _carouselTechs = [];
  double _carouselCardWidth = 264;
  static const double _carouselGap = 10;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();

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
    _routeRequestId++; // ← ROUTE: stop any route loading
    _mapReady = false;
    _pulseController.dispose();
    _suggestionDebounce?.cancel();

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

  /// Moves the map only if FlutterMap is rendered.
  void _moveMap(LatLng center, double zoom) {
    if (!_mapReady || !mounted) return;
    _mapController.move(center, zoom);
  }

  // ==============================================================
  // SEARCH HISTORY
  // ==============================================================

  Future<void> _loadSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    setState(() {
      _searchHistory = prefs.getStringList(NearbyConstants.historyPrefsKey) ?? [];
    });
  }

  Future<void> _saveToHistory(String place) async {
    if (place.trim().isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList(NearbyConstants.historyPrefsKey) ?? [];

    history.remove(place);
    history.insert(0, place);

    if (history.length > NearbyConstants.maxHistoryEntries) {
      history.removeLast();
    }

    await prefs.setStringList(NearbyConstants.historyPrefsKey, history);

    if (!mounted) return;
    setState(() {
      _searchHistory = history;
    });
  }

  Future<void> _clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(NearbyConstants.historyPrefsKey);

    if (!mounted) return;
    setState(() {
      _searchHistory = [];
    });
  }

  // ==============================================================
  // PLACE SUGGESTIONS
  // ==============================================================

  void _onLocationQueryChanged(String value) {
    setState(() {});

    _suggestionDebounce?.cancel();

    if (value.trim().length < 2) {
      setState(() {
        _placeSuggestions = [];
        _showSuggestions = _searchHistory.isNotEmpty;
        _isLoadingSuggestions = false;
      });
      return;
    }

    _suggestionDebounce = Timer(
      NearbyConstants.suggestionDebounce,
          () => _fetchPlaceSuggestions(value),
    );
  }

  Future<void> _fetchPlaceSuggestions(String query) async {
    final requestId = ++_suggestionRequestId;

    if (!mounted) return;

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

      final response = await http.get(
        url,
        headers: {'User-Agent': 'NearbyFundi/1.0'},
      ).timeout(NearbyConstants.placeSearchTimeout);

      if (requestId != _suggestionRequestId) return;

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;

        if (!mounted) return;

        setState(() {
          _placeSuggestions = data.map((dynamic item) {
            final value = item as Map<String, dynamic>;
            final display = value['display_name']?.toString() ?? '';
            final short = display.split(',').take(3).join(',').trim();

            return {
              'name': short,
              'full': display,
              'lat': double.tryParse(value['lat']?.toString() ?? '') ?? 0.0,
              'lng': double.tryParse(value['lon']?.toString() ?? '') ?? 0.0,
            };
          }).toList();
        });
      }
    } catch (e) {
      debugPrint('Place suggestion error: $e');
    }

    if (requestId != _suggestionRequestId) return;
    if (!mounted) return;

    setState(() {
      _isLoadingSuggestions = false;
    });
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
    await _saveToHistory(name);

    if (!mounted) return;

    setState(() {
      _isSearching = true;
      _searchedArea = name;
      _resetRoutes(); // ← ROUTE
      _selectedTechnicianId = null;
      _showSuggestions = false;
    });

    techProvider.clearTechnicians();

    var searchSucceeded = true;

    try {
      await techProvider.searchByCoordinates(
        lat: lat,
        lng: lng,
        serviceId: _selectedServiceId,
        categoryId: _selectedCategoryId,
        radius: _searchRadiusKm,
        search: _serviceSearchQuery.isNotEmpty ? _serviceSearchQuery : null,
        locale: _currentLocale,
      );
    } catch (e) {
      debugPrint('Coordinate search failed: $e');

      try {
        await techProvider.searchByPlace(
          place: name,
          serviceId: _selectedServiceId,
          categoryId: _selectedCategoryId,
          radius: _searchRadiusKm,
          search: _serviceSearchQuery.isNotEmpty ? _serviceSearchQuery : null,
          locale: _currentLocale,
        );
      } catch (e2) {
        debugPrint('Fallback place search failed: $e2');
        searchSucceeded = false;
      }
    }

    if (!mounted) return;

    setState(() {
      _isSearching = false;
    });

    if (!searchSucceeded) {
      _showErrorSnackBar(NearbyStrings.searchFailed);
      return;
    }

    await _fetchRoutesForTechnicians();
    _collapsePanelIfResults();
  }

  // ==============================================================
  // SEARCH
  // ==============================================================

  Future<void> _performSearch() async {
    // Covers search button, keyboard submit, suggestions,
    // history taps and "expand radius".
    if (!AuthGuard.ensure(context, message: _kSearchLoginMessage)) return;

    final place = _locationController.text.trim();
    final l10n = AppLocalizations.of(context)!;

    if (place.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.pleaseEnterLocation),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    setState(() {
      _showSuggestions = false;
      _isSearching = true;
      _resetRoutes(); // ← ROUTE
      _selectedTechnicianId = null;
      _searchedArea = place;
    });

    await _saveToHistory(place);

    if (!mounted) return;

    final techProvider = context.read<TechnicianProvider>();
    techProvider.clearTechnicians();

    var searchSucceeded = true;

    try {
      await techProvider.searchByPlace(
        place: place,
        serviceId: _selectedServiceId,
        categoryId: _selectedCategoryId,
        radius: _searchRadiusKm,
        search: _serviceSearchQuery.isNotEmpty ? _serviceSearchQuery : null,
        locale: _currentLocale,
      );
    } catch (e) {
      debugPrint('Search error: $e');
      searchSucceeded = false;
    }

    if (!mounted) return;

    setState(() {
      _isSearching = false;
    });

    _locationFocus.unfocus();

    if (!searchSucceeded) {
      _showErrorSnackBar(NearbyStrings.searchFailed);
      return;
    }

    await _fetchRoutesForTechnicians();
    _collapsePanelIfResults();
  }

  /// After a successful search, tuck the search panel away so the map and
  /// the fundi cards are fully visible.
  void _collapsePanelIfResults() {
    if (!mounted) return;
    if (context.read<TechnicianProvider>().technicians.isNotEmpty) {
      setState(() => _isHeaderVisible = false);
    }
  }

  Future<void> _retryWithLargerRadius() async {
    if (_searchRadiusKm >= NearbyConstants.maxRadiusKm) return;

    setState(() {
      _searchRadiusKm = (_searchRadiusKm + NearbyConstants.radiusStepKm)
          .clamp(0, NearbyConstants.maxRadiusKm);
    });

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
  // ROAD ROUTES  ← ROUTE
  // ==============================================================

  /// Cancels any route loading and removes the drawn lines.
  /// Call inside setState.
  void _resetRoutes() {
    _routeRequestId++;
    _routesData.clear();
    _isFetchingRoutes = false;
  }

  /// Draws a road line from the picked point to each technician.
  /// Lines appear one by one as they arrive.
  Future<void> _fetchRoutesForTechnicians() async {
    if (!mounted) return;

    final techProvider = context.read<TechnicianProvider>();

    if (!techProvider.hasSearchOrigin) return;

    final origin = LatLng(techProvider.searchLat!, techProvider.searchLng!);

    final technicians = techProvider.technicians
        .where((t) => t.latitude != null && t.longitude != null)
        .toList()
      ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

    if (technicians.isEmpty) {
      // No fundis found: still show the searched place on the map.
      _moveMap(origin, 13);
      return;
    }

    final requestId = ++_routeRequestId;

    setState(() {
      _isFetchingRoutes = true;
    });

    // Nearest first, so the closest fundis get their line first.
    final targets = technicians
        .take(NearbyConstants.maxRouteTargets)
        .map((t) => RouteTarget(
      id: t.id,
      point: LatLng(t.latitude!, t.longitude!),
      fallbackKm: t.distanceKm,
    ))
        .toList();

    bool cancelled() => !mounted || requestId != _routeRequestId;

    await RouteService.instance.fetchMany(
      origin: origin,
      targets: targets,
      batchSize: NearbyConstants.routeFetchBatchSize,
      isCancelled: cancelled,
      onRoute: (id, route) {
        if (cancelled()) return;
        setState(() => _routesData[id] = route);
      },
    );

    if (cancelled()) return;

    setState(() {
      _isFetchingRoutes = false;
    });

    _updateMapBounds();
  }

  // ==============================================================
  // CLEAR
  // ==============================================================

  void _clearAllFilters() {
    _locationController.clear();
    _serviceSearchController.clear();

    setState(() {
      _selectedServiceId = null;
      _selectedCategoryId = null;
      _selectedTechnicianId = null;
      _serviceSearchQuery = '';
      _resetRoutes(); // ← ROUTE
      _searchedArea = '';
      _showSuggestions = false;
      _placeSuggestions = [];
      _searchRadiusKm = NearbyConstants.defaultRadiusKm;
    });

    context.read<TechnicianProvider>().clearTechnicians();

    _locationFocus.unfocus();

    _moveMap(NearbyConstants.defaultMapCenter, 11);
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

    final all = <LatLng>[origin, ...techPoints];
    final bounds = LatLngBounds.fromPoints(all);

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.fromLTRB(60, 260, 60, 200),
      ),
    );
  }

  /// Slides the bottom carousel so the given fundi's card is on screen.
  void _scrollCarouselTo(int techId) {
    if (!_carouselController.hasClients) return;

    final index = _carouselTechs.indexWhere((t) => t.id == techId);
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
  // RECOMMENDED TECHNICIANS
  // ==============================================================

  List<Technician> _getRecommendedTechnicians(List<Technician> technicians) {
    final valid = technicians
        .where((t) => t.latitude != null && t.longitude != null)
        .toList()
      ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

    return valid.take(NearbyConstants.recommendedCount).toList();
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
        child: tech.profilePhoto != null
            ? Image.network(
          ImageUtils.getFullImageUrl(tech.profilePhoto!),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Icon(
            Icons.build_rounded,
            size: contextIconSize,
            color: AppTheme.greyText,
          ),
        )
            : Icon(
          Icons.build_rounded,
          size: contextIconSize,
          color: AppTheme.greyText,
        ),
      ),
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
            Container(
              padding: const EdgeInsets.all(2.5),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: _gold,
              ),
              child: _buildAvatar(tech, size: size, iconSize: size * 0.48),
            ),
          ],
        );
      },
    );
  }

  // ==============================================================
  // SMALL INFO CHIP (distance / time / rating)
  // ==============================================================

  Widget _infoChip(IconData icon, String text, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Navy tones are unreadable on dark surfaces, so lift them.
    Color tone = color;
    if (isDark && color == AppTheme.primary) tone = Colors.white;
    if (isDark && color == AppTheme.accent) tone = const Color(0xFF6DB6F2);

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

    final sorted = [...technicians]
      ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

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
                      Material(
                        color: _softFill(context),
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => Navigator.pop(context),
                          child: SizedBox(
                            width: 38,
                            height: 38,
                            child: Icon(Icons.close_rounded,
                                size: 20, color: ink),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: columns > 1
                      ? GridView.builder(
                    controller: controller,
                    padding: EdgeInsets.all(pad),
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
                        inGrid: true,
                      );
                    },
                  )
                      : ListView.separated(
                    controller: controller,
                    padding: EdgeInsets.all(pad),
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
  // LIST TILE (one card for list + grid)
  // ==============================================================

  Widget _buildListTile(
      BuildContext context,
      Technician tech,
      bool recommended, {
        bool inGrid = false,
      }) {
    final theme = Theme.of(context);
    final ink = _ink(context);

    final route = _routesData[tech.id];
    final distance = route?.distanceKm ?? tech.distanceKm;
    final duration = route?.durationMin;
    final selected = _selectedTechnicianId == tech.id;

    return Material(
      // Selection is shown with a soft gold tint instead of an outline.
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
          setState(() {
            _selectedTechnicianId = tech.id;
          });

          Navigator.pop(context);
          Navigator.pushNamed(
            context,
            AppRoutes.technicianDetail,
            arguments: tech.id,
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              recommended
                  ? Container(
                padding: const EdgeInsets.all(2.5),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: _gold,
                ),
                child: _buildAvatar(tech, size: 50, iconSize: 24),
              )
                  : _buildAvatar(tech, size: 54, iconSize: 26),
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
                        if (tech.verified)
                          const Padding(
                            padding: EdgeInsets.only(left: 5),
                            child: Icon(Icons.verified_rounded,
                                color: Color(0xFF3B9BE8), size: 16),
                          ),
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
                        if (recommended)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _gold.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'Near you',
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
                child: Icon(Icons.chevron_right_rounded,
                    color: ink, size: 22),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==============================================================
  // BOTTOM CAROUSEL CARD (tap = same as tapping a map marker)
  // Responsive: width adapts to the screen, content scales down
  // instead of ever overflowing.
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

    final subtitle = recommended
        ? 'Near you'
        : (tech.area != null && tech.area!.isNotEmpty ? tech.area! : '');

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTechnicianId = selected ? null : tech.id;
        });

        // Bring the fundi into view on the map, then show details.
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
          // Selection = soft gold tint + stronger shadow (no outline).
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
            recommended
                ? Container(
              padding: const EdgeInsets.all(2.5),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: _gold,
              ),
              child: _buildAvatar(
                tech,
                size: avatarSize,
                iconSize: avatarSize * 0.5,
              ),
            )
                : _buildAvatar(
              tech,
              size: avatarSize + 4,
              iconSize: avatarSize * 0.5,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: LayoutBuilder(
                builder: (context, box) {
                  // FittedBox scales the text block down if the card is
                  // ever shorter than its content (large fonts, small phones)
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
                              if (tech.verified)
                                const Padding(
                                  padding: EdgeInsets.only(left: 4),
                                  child: Icon(Icons.verified_rounded,
                                      color: Color(0xFF3B9BE8), size: 15),
                                ),
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
                                        ? (theme.brightness == Brightness.dark
                                        ? _gold
                                        : _goldInk)
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

    final validTechnicians = techProvider.technicians
        .where((t) => t.latitude != null && t.longitude != null)
        .toList();
    final recommendedIds = _getRecommendedTechnicians(validTechnicians)
        .map((t) => t.id)
        .toSet();

    final sortedByDistance = [...validTechnicians]
      ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

    final mq = MediaQuery.of(context);
    final clampedScaler = mq.textScaler.clamp(
      minScaleFactor: 0.9,
      maxScaleFactor: 1.2,
    );

    final hasFilters =
        _locationController.text.isNotEmpty || _selectedServiceId != null;
    final hasTechnicians = techProvider.technicians.isNotEmpty;

    final showCarousel =
        techProvider.hasSearchOrigin && sortedByDistance.isNotEmpty;
    final carouselOrigin = showCarousel
        ? LatLng(techProvider.searchLat!, techProvider.searchLng!)
        : NearbyConstants.defaultMapCenter;

    // responsive carousel sizing (grows with the user's font size)
    final fontScale = clampedScaler.scale(1.0);
    final carouselHeight = (116.0 * fontScale).clamp(116.0, 142.0);
    final cardWidth = (mq.size.width * 0.8).clamp(264.0, 340.0);

    // remembered so a marker tap can slide the carousel to that fundi
    _carouselTechs = sortedByDistance;
    _carouselCardWidth = cardWidth;

    // lifts the map controls above the carousel when it is visible
    final controlsBottom = showCarousel ? carouselHeight + 20 : 20.0;

    return MediaQuery(
      data: mq.copyWith(textScaler: clampedScaler),
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Stack(
          children: [
            // MAP (full screen)
            Positioned.fill(
              child: _buildMapView(theme, techProvider, recommendedIds),
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
                          ? _buildSearchPanel(
                        context,
                        theme,
                        services,
                        categories,
                        techProvider,
                        hasFilters,
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
                  padding: const EdgeInsets.fromLTRB(12, 4, 2, 8),
                  itemCount: sortedByDistance.length,
                  itemBuilder: (_, index) {
                    final tech = sortedByDistance[index];
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
                child: Center(child: _routeLoadingBadge()),
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

    // Guests get read-only fields that open the modal on tap
    final loggedIn = AuthGuard.isLoggedIn(context);

    // The panel never grows taller than the space left above the keyboard.
    final availableHeight = media.size.height - media.viewInsets.bottom;

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
        constraints: BoxConstraints(
          maxHeight: availableHeight * 0.58,
        ),
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
                  Tooltip(
                    message: 'Hide search',
                    child: Material(
                      color: _softFill(context),
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => setState(() => _isHeaderVisible = false),
                        child: SizedBox(
                          width: 34,
                          height: 34,
                          child: Icon(Icons.keyboard_arrow_up_rounded,
                              color: ink, size: 22),
                        ),
                      ),
                    ),
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
                        hintStyle: TextStyle(color: theme.hintColor, fontSize: 14),
                        prefixIcon: Icon(Icons.search_rounded,
                            color: ink, size: 22),
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

                                  setState(() {
                                    _placeSuggestions = [];
                                    _showSuggestions = _searchHistory.isNotEmpty;
                                  });
                                },
                              ),
                            IconButton(
                              tooltip: NearbyStrings.chooseOnMap,
                              icon: Icon(Icons.map_outlined,
                                  color: ink, size: 22),
                              onPressed: _openMapPicker, // guarded inside
                            ),
                          ],
                        ),
                        filled: true,
                        fillColor: _softFill(context),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
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
                        setState(() {
                          _showSuggestions = true;
                        });
                      },
                      onSubmitted: (_) => _performSearch(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 50,
                    width: 50,
                    child: ElevatedButton(
                      onPressed: _isSearching ? null : _performSearch, // guarded inside
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
              if (_searchedArea.isNotEmpty && techProvider.technicians.isNotEmpty)
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
                        padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _gold.withValues(alpha: 0.20),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${techProvider.technicians.length} found',
                          style: TextStyle(
                            color: theme.brightness == Brightness.dark
                                ? _gold
                                : _goldInk,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
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
                    hintStyle: TextStyle(color: theme.hintColor, fontSize: 13.5),
                    prefixIcon: Icon(Icons.build_outlined,
                        color: ink, size: 18),
                    suffixIcon: _serviceSearchQuery.isNotEmpty
                        ? IconButton(
                      tooltip: NearbyStrings.clear,
                      icon: const Icon(Icons.close_rounded, size: 16),
                      onPressed: () {
                        _serviceSearchController.clear();
                        setState(() {
                          _serviceSearchQuery = '';
                        });
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
                    setState(() {
                      _serviceSearchQuery = value;
                    });
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
                                _selectedServiceId = selected ? null : service.id;
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
                              _selectedCategoryId = selected ? null : category.id;
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

  /// Rounded input shape without any outline.
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
                  setState(() {
                    _showSuggestions = false;
                  });
                  _performSearch(); // guarded inside
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
                suggestion['name'].toString(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14),
              ),
              subtitle: Text(
                suggestion['full'].toString(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11.5),
              ),
              onTap: () async {
                final name = suggestion['name'].toString();
                _locationController.text = name;

                setState(() {
                  _showSuggestions = false;
                });

                await _saveToHistory(name);
                if (!mounted) return;
                _performSearch(); // guarded inside
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

  /// FlutterMap is ALWAYS rendered, so the zoom / fit buttons and the
  /// MapController always work. The empty states are shown as an overlay
  /// on top of the map instead of replacing it.
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

    final technicians = hasOrigin
        ? techProvider.technicians
        .where((t) => t.latitude != null && t.longitude != null)
        .toList()
        : <Technician>[];

    // Which empty state (if any) to draw over the map.
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

    // ROAD LINES: picked point -> each technician  ← ROUTE
    final polylines = buildRoutePolylines(
      routes: {
        for (final tech in technicians)
          if (_routesData[tech.id] != null) tech.id: _routesData[tech.id]!,
      },
      selectedId: _selectedTechnicianId,
      lineColor: AppTheme.primary,
      selectedColor: _gold,
    );

    // TECHNICIAN MARKERS
    final markerWidth = ResponsiveConstants.getMarkerWidth(context);
    final markerHeight = ResponsiveConstants.getMarkerHeight(context);
    final avatarSize = ResponsiveConstants.getAvatarSize(context);

    final markers = technicians.map((tech) {
      final route = _routesData[tech.id];
      final distance = route?.distanceKm ?? tech.distanceKm;
      final selected = _selectedTechnicianId == tech.id;
      final isRecommended = recommendedIds.contains(tech.id);

      return Marker(
        point: LatLng(tech.latitude!, tech.longitude!),
        width: markerWidth,
        height: markerHeight,
        alignment: Alignment.bottomCenter,
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
                    padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
      );
    }).toList();

    // USER MARKER (pulse)
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

    // USER MARKER (pin)
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
        initialZoom: hasOrigin
            ? (isDesktop ? 14 : (isTablet ? 13.5 : 13))
            : 11,
        minZoom: 4,
        maxZoom: 18,
        // The controller can be used safely only after this fires.
        onMapReady: () {
          _mapReady = true;
        },
        onTap: (_, __) {
          if (_selectedTechnicianId != null) {
            setState(() {
              _selectedTechnicianId = null;
            });
          }

          if (_showSuggestions) {
            setState(() {
              _showSuggestions = false;
            });
            _locationFocus.unfocus();
          }
        },
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.nearbyfundi',
        ),
        // search radius ring
        if (hasOrigin)
          CircleLayer(
            circles: [
              CircleMarker(
                point: origin,
                radius: _searchRadiusKm * 1000.0,
                useRadiusInMeter: true,
                color: AppTheme.primary.withValues(alpha: 0.05),
                borderColor: AppTheme.primary.withValues(alpha: 0.25),
                borderStrokeWidth: 1.5,
              ),
            ],
          ),
        PolylineLayer(polylines: polylines),
        MarkerLayer(
          markers: [
            if (hasOrigin) ...[originPulse, originMarker],
            ...markers,
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

    // Same widget structure every time, so the map is never rebuilt
    // from scratch when the overlay appears or disappears.
    return Stack(
      children: [
        Positioned.fill(child: map),
        if (overlay != null) Positioned.fill(child: overlay),
      ],
    );
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
            const SizedBox(height: 4),
            Text(
              'Within your area.',
              style: TextStyle(color: theme.hintColor, fontSize: 13.5),
            ),
            if (showExpandRadius &&
                _searchRadiusKm < NearbyConstants.maxRadiusKm) ...[
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: _retryWithLargerRadius,
                icon: const Icon(Icons.add_location_alt_outlined, size: 18),
                label: Text(
                  '${NearbyStrings.expandSearchRadius} (+${NearbyConstants.radiusStepKm} km)',
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
  // ZOOM
  // ==============================================================

  void _zoomBy(double amount) {
    if (!_mapReady || !mounted) return;

    final camera = _mapController.camera;
    final zoom = (camera.zoom + amount).clamp(4.0, 18.0);
    _mapController.move(camera.center, zoom);
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color tone = color;
    if (isDark && color == AppTheme.primary) tone = Colors.white;
    if (isDark && color == AppTheme.accent) tone = const Color(0xFF6DB6F2);

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

  void _showTechnicianModal(
      BuildContext context,
      Technician tech,
      LatLng origin,
      bool recommended,
      ) {
    final theme = Theme.of(context);
    final ink = _ink(context);
    final isDark = theme.brightness == Brightness.dark;

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
        final stats = <Widget>[
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
                              if (tech.verified)
                                const Padding(
                                  padding: EdgeInsets.only(left: 6),
                                  child: Icon(Icons.verified_rounded,
                                      color: Color(0xFF3B9BE8), size: 19),
                                ),
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
                    Material(
                      color: _softFill(context),
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => Navigator.pop(sheetContext),
                        child: SizedBox(
                          width: 38,
                          height: 38,
                          child: Icon(Icons.close_rounded,
                              size: 20, color: ink),
                        ),
                      ),
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
                            color: isDark ? _gold : _goldInk, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            NearbyStrings.recommendedReason,
                            style: TextStyle(
                              color: isDark ? _gold : _goldInk,
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
                Row(
                  children: [
                    for (var i = 0; i < stats.length; i++) ...[
                      if (i > 0) const SizedBox(width: 10),
                      stats[i],
                    ],
                  ],
                ),

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

    try {
      final launched =
      await launchUrl(url, mode: LaunchMode.externalApplication);

      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(NearbyStrings.couldNotOpenMaps)),
        );
      }
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(NearbyStrings.couldNotOpenMaps)),
      );
    }
  }

  // ==============================================================
  // CHIP (used for services and categories) - borderless
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

    // `outlined` is kept for the category row: it uses a soft tint instead
    // of the solid navy fill, but still has no border.
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
          // Guests see the modal instead of changing filters
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
      color: highlighted ? AppTheme.primary : Theme.of(context).colorScheme.surface,
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
// PILL BUTTON (list / full map / show search)
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
        color: filled ? AppTheme.primary : Theme.of(context).colorScheme.surface,
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