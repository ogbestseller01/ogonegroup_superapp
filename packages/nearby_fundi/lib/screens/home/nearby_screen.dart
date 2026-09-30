// FILE: lib/screens/home/nearby_screen.dart
// Nearby Fundi - Fully Responsive with NO Overflow (iOS / Android / Tablet / Web)

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
import 'nearby_map_screen.dart';
import 'map_location_picker_screen.dart';

// ================================================================
// ROUTE DATA
// ================================================================

class TechnicianRouteData {
  final List<LatLng> points;
  final double distanceKm;
  final double durationMin;

  TechnicianRouteData({
    required this.points,
    required this.distanceKm,
    required this.durationMin,
  });
}

// ================================================================
// RESPONSIVE CONSTANTS
// ================================================================

class ResponsiveConstants {
  static const double mobileBreakpoint = 480;
  static const double tabletBreakpoint = 768;
  static const double desktopBreakpoint = 1024;

  static double getPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) return 6.0;
    if (width < desktopBreakpoint) return 10.0;
    return 16.0;
  }

  static double getSmallPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) return 3.0;
    if (width < desktopBreakpoint) return 5.0;
    return 8.0;
  }

  static double getFontSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) return 9.0;
    if (width < desktopBreakpoint) return 11.0;
    return 13.0;
  }

  static double getTitleSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) return 13.0;
    if (width < desktopBreakpoint) return 15.0;
    return 18.0;
  }

  static double getAvatarSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) return 34.0;
    if (width < desktopBreakpoint) return 42.0;
    return 50.0;
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
    if (width < mobileBreakpoint) return 84.0;
    if (width < desktopBreakpoint) return 104.0;
    return 124.0;
  }

  static double getMarkerHeight(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) return 118.0;
    if (width < desktopBreakpoint) return 144.0;
    return 164.0;
  }
}

// ================================================================
// CONSTANTS  — colors now come from AppTheme
// ================================================================

class NearbyConstants {
  // Legacy aliases kept so existing references still compile,
  // but they now point to the new brand palette.
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
  static const Duration routeSearchTimeout = Duration(seconds: 8);

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
  final MapController _mapController = MapController();

  late AnimationController _pulseController;

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

  List<String> _searchHistory = [];
  List<Map<String, dynamic>> _placeSuggestions = [];

  bool _showSuggestions = false;
  bool _isLoadingSuggestions = false;

  Timer? _suggestionDebounce;
  int _suggestionRequestId = 0;

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
    _pulseController.dispose();
    _suggestionDebounce?.cancel();

    _locationController.dispose();
    _serviceSearchController.dispose();
    _locationFocus.dispose();

    _serviceChipScrollController.dispose();
    _categoryChipScrollController.dispose();

    super.dispose();
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

    setState(() {
      _isSearching = true;
      _searchedArea = name;
      _routesData.clear();
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
  }

  // ==============================================================
  // SEARCH
  // ==============================================================

  Future<void> _performSearch() async {
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
      _routesData.clear();
      _selectedTechnicianId = null;
      _searchedArea = place;
    });

    await _saveToHistory(place);

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
  // ROUTES
  // ==============================================================

  Future<void> _fetchRoutesForTechnicians() async {
    final techProvider = context.read<TechnicianProvider>();

    if (!techProvider.hasSearchOrigin) return;

    final origin = LatLng(techProvider.searchLat!, techProvider.searchLng!);

    final technicians = techProvider.technicians
        .where((t) => t.latitude != null && t.longitude != null)
        .toList();

    if (technicians.isEmpty) return;

    if (!mounted) return;

    setState(() {
      _isFetchingRoutes = true;
    });

    final targets = technicians.take(NearbyConstants.maxRouteTargets).toList();
    final Map<int, TechnicianRouteData> fetched = {};

    for (var i = 0; i < targets.length; i += NearbyConstants.routeFetchBatchSize) {
      final batch = targets.skip(i).take(NearbyConstants.routeFetchBatchSize);

      await Future.wait(
        batch.map((tech) async {
          final destination = LatLng(tech.latitude!, tech.longitude!);
          final route = await _getOsrmRouteData(
            origin,
            destination,
            tech.distanceKm,
          );

          if (route != null) {
            fetched[tech.id] = route;
          }
        }),
      );
    }

    if (!mounted) return;

    setState(() {
      _routesData.addAll(fetched);
      _isFetchingRoutes = false;
    });

    _updateMapBounds();
  }

  Future<TechnicianRouteData?> _getOsrmRouteData(
      LatLng origin,
      LatLng destination,
      double fallbackKm,
      ) async {
    try {
      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
            '${origin.longitude},${origin.latitude};'
            '${destination.longitude},${destination.latitude}'
            '?overview=full&geometries=geojson',
      );

      final response = await http.get(url).timeout(NearbyConstants.routeSearchTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final routes = data['routes'];

        if (routes is List && routes.isNotEmpty) {
          final route = routes.first as Map<String, dynamic>;
          final geometry = route['geometry'] as Map<String, dynamic>;
          final coordinates = geometry['coordinates'] as List<dynamic>;

          final points = coordinates.map<LatLng>((coord) {
            final values = coord as List<dynamic>;
            return LatLng(
              (values[1] as num).toDouble(),
              (values[0] as num).toDouble(),
            );
          }).toList();

          final distanceMeters = (route['distance'] as num).toDouble();
          final durationSeconds = (route['duration'] as num).toDouble();

          return TechnicianRouteData(
            points: points,
            distanceKm: distanceMeters / 1000,
            durationMin: durationSeconds / 60,
          );
        }
      }
    } catch (e) {
      debugPrint('OSRM error: $e');
    }

    final straightKm = fallbackKm > 0
        ? fallbackKm
        : const Distance().as(LengthUnit.Kilometer, origin, destination);

    const assumedAverageSpeedKmh = 30.0;

    return TechnicianRouteData(
      points: [origin, destination],
      distanceKm: straightKm,
      durationMin: (straightKm / assumedAverageSpeedKmh) * 60,
    );
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
      _routesData.clear();
      _searchedArea = '';
      _showSuggestions = false;
      _placeSuggestions = [];
      _searchRadiusKm = NearbyConstants.defaultRadiusKm;
    });

    context.read<TechnicianProvider>().clearTechnicians();

    _locationFocus.unfocus();

    _mapController.move(NearbyConstants.defaultMapCenter, 11);
  }

  // ==============================================================
  // MAP BOUNDS
  // ==============================================================

  void _updateMapBounds() {
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
        padding: EdgeInsets.all(ResponsiveConstants.getPadding(context) * 5),
      ),
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
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.20),
            blurRadius: 8,
            offset: const Offset(0, 3),
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
        final opacity = 0.40 * (1 - value);

        return Stack(
          alignment: Alignment.center,
          children: [
            Transform.scale(
              scale: scale,
              child: Container(
                width: size + 22,
                height: size + 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.primary
                        .withOpacity(opacity.clamp(0.0, 1.0)),
                    width: 3,
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primary,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.35),
                    blurRadius: 14,
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: _buildAvatar(tech, size: size, iconSize: size * 0.48),
            ),
          ],
        );
      },
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

    final sorted = [...technicians]
      ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: isDesktop ? 0.6 : (isTablet ? 0.7 : 0.78),
          minChildSize: isDesktop ? 0.3 : (isTablet ? 0.4 : 0.45),
          maxChildSize: isDesktop ? 0.85 : (isTablet ? 0.9 : 0.95),
          expand: false,
          builder: (context, controller) {
            final columns = ResponsiveConstants.getGridColumns(context);

            return Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    ResponsiveConstants.getPadding(context),
                    16,
                    ResponsiveConstants.getPadding(context),
                    12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${sorted.length} ${l10n.fundisFound}',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize:
                            ResponsiveConstants.isMobile(context) ? 18 : 22,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: MaterialLocalizations.of(context)
                            .closeButtonTooltip,
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: columns > 1
                      ? Padding(
                    padding: EdgeInsets.all(
                      ResponsiveConstants.getPadding(context),
                    ),
                    child: GridView.builder(
                      controller: controller,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing:
                        ResponsiveConstants.getPadding(context),
                        mainAxisSpacing:
                        ResponsiveConstants.getPadding(context),
                        childAspectRatio: isDesktop ? 1.05 : 0.92,
                      ),
                      itemCount: sorted.length,
                      itemBuilder: (_, index) {
                        final tech = sorted[index];
                        return _buildListTile(
                          context,
                          tech,
                          recommendedIds.contains(tech.id),
                          isGrid: true,
                        );
                      },
                    ),
                  )
                      : ListView.builder(
                    controller: controller,
                    padding: EdgeInsets.all(
                      ResponsiveConstants.getPadding(context),
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
      bool recommended, {
        bool isGrid = false,
      }) {
    final theme = Theme.of(context);
    final isTablet = ResponsiveConstants.isTablet(context);
    final isDesktop = ResponsiveConstants.isDesktop(context);
    final fontSize = ResponsiveConstants.getFontSize(context);
    final isMobile = ResponsiveConstants.isMobile(context);

    final route = _routesData[tech.id];
    final distance = route?.distanceKm ?? tech.distanceKm;
    final duration = route?.durationMin;
    final selected = _selectedTechnicianId == tech.id;

    if (isGrid) {
      return Card(
        margin: const EdgeInsets.all(4),
        elevation: selected ? 5 : 1,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: selected
                ? AppTheme.accent
                : recommended
                ? AppTheme.primary.withOpacity(0.35)
                : Colors.transparent,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
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
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: EdgeInsets.all(ResponsiveConstants.getPadding(context)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildAvatar(
                  tech,
                  size: ResponsiveConstants.getAvatarSize(context) * 0.8,
                  iconSize: ResponsiveConstants.getAvatarSize(context) * 0.4,
                ),
                const SizedBox(height: 6),
                Text(
                  tech.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: isDesktop ? 16 : (isTablet ? 14 : 12),
                  ),
                ),
                if (tech.area != null && tech.area!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          size: fontSize + 2,
                          color: AppTheme.error,
                        ),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            tech.area!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: theme.hintColor,
                              fontSize: fontSize,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  alignment: WrapAlignment.center,
                  children: [
                    if (tech.rating > 0)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: AppTheme.secondary,
                            size: 12,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            tech.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    _infoBadge(
                      Icons.directions_car_rounded,
                      '${distance.toStringAsFixed(1)} km',
                      fontSize,
                    ),
                    if (duration != null)
                      _infoBadge(
                        Icons.access_time_rounded,
                        '~${duration.toStringAsFixed(0)}m',
                        fontSize,
                      ),
                  ],
                ),
                if (recommended)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      'Near you',
                      style: TextStyle(
                        color: AppTheme.primary,
                        fontSize: fontSize - 1,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: selected ? 5 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: selected
              ? AppTheme.accent
              : recommended
              ? AppTheme.primary.withOpacity(0.35)
              : Colors.transparent,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAvatar(
                tech,
                size: isMobile ? 40.0 : (isDesktop ? 52.0 : 46.0),
                iconSize: isMobile ? 20.0 : (isDesktop ? 26.0 : 22.0),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            tech.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: isDesktop ? 16 : (isTablet ? 15 : 13),
                            ),
                          ),
                        ),
                        if (tech.verified)
                          const Padding(
                            padding: EdgeInsets.only(left: 5),
                            child: Icon(
                              Icons.verified_rounded,
                              color: AppTheme.accent,
                              size: 16,
                            ),
                          ),
                      ],
                    ),
                    if (recommended)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          NearbyStrings.recommendedNearYou,
                          style: TextStyle(
                            color: AppTheme.primary,
                            fontSize: isMobile ? 9 : 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    if (tech.area != null && tech.area!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              size: 14,
                              color: AppTheme.error,
                            ),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                tech.area!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: theme.hintColor,
                                  fontSize: isMobile ? 10 : 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      runSpacing: 3,
                      children: [
                        if (tech.rating > 0)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: AppTheme.secondary,
                                size: 12,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                tech.rating.toStringAsFixed(1),
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: isMobile ? 10 : 12,
                                ),
                              ),
                            ],
                          ),
                        _infoBadge(
                          Icons.directions_car_rounded,
                          '${distance.toStringAsFixed(1)} km',
                          isMobile ? 9 : 11,
                        ),
                        if (duration != null)
                          _infoBadge(
                            Icons.access_time_rounded,
                            '~${duration.toStringAsFixed(0)}m',
                            isMobile ? 9 : 11,
                          ),
                      ],
                    ),
                    if (tech.services.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: tech.services.take(3).map((service) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                service,
                                style: TextStyle(
                                  color: AppTheme.primary,
                                  fontSize: isMobile ? 8 : 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                color: selected ? AppTheme.accent : theme.hintColor,
                size: isMobile ? 18 : 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoBadge(IconData icon, String text, double fontSize) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.accent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: fontSize + 1, color: AppTheme.accent),
          const SizedBox(width: 2),
          Text(
            text,
            style: TextStyle(
              color: AppTheme.accent,
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
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
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final isMobile = ResponsiveConstants.isMobile(context);
    final isTablet = ResponsiveConstants.isTablet(context);
    final isDesktop = ResponsiveConstants.isDesktop(context);

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

    final mq = MediaQuery.of(context);
    final clampedScaler = mq.textScaler.clamp(
      minScaleFactor: 0.9,
      maxScaleFactor: 1.2,
    );

    return MediaQuery(
      data: mq.copyWith(textScaler: clampedScaler),
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,

        appBar: AppBar(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: isTablet || isDesktop,
          title: Text(
            l10n.findFundi,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: isDesktop ? 22 : (isTablet ? 20 : 18),
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          actionsIconTheme: const IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              tooltip: _isHeaderVisible ? 'Hide search' : 'Show search',
              icon: Icon(
                _isHeaderVisible
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                color: Colors.white,
              ),
              onPressed: () {
                setState(() {
                  _isHeaderVisible = !_isHeaderVisible;
                });
              },
            ),
            if (techProvider.technicians.isNotEmpty)
              IconButton(
                tooltip: NearbyStrings.showList,
                icon: const Icon(Icons.list_rounded, color: Colors.white),
                onPressed: () => _showTechniciansList(
                  context,
                  techProvider.technicians,
                  recommendedIds,
                ),
              ),
            if (techProvider.technicians.isNotEmpty)
              IconButton(
                tooltip: NearbyStrings.showFullMap,
                icon: const Icon(Icons.fullscreen_rounded, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NearbyMapScreen()),
                  );
                },
              ),
            if (_locationController.text.isNotEmpty || _selectedServiceId != null)
              IconButton(
                tooltip: NearbyStrings.clearFilters,
                icon: const Icon(Icons.clear_all_rounded, color: Colors.white),
                onPressed: _clearAllFilters,
              ),
            IconButton(
              tooltip: l10n.search,
              icon: techProvider.isLoading
                  ? SizedBox(
                width: isDesktop ? 24 : 20,
                height: isDesktop ? 24 : 20,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : const Icon(Icons.refresh_rounded, color: Colors.white),
              onPressed: techProvider.isLoading ? null : _performSearch,
            ),
          ],
        ),

        body: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _isHeaderVisible
                  ? _buildSearchPanel(
                context,
                theme,
                l10n,
                services,
                categories,
                techProvider,
                isMobile,
                isTablet,
                isDesktop,
              )
                  : const SizedBox.shrink(key: ValueKey('hidden-search')),
            ),
            Expanded(
              child: Stack(
                children: [
                  _buildMapView(theme, techProvider, recommendedIds),
                  Positioned(
                    right: 12,
                    bottom: 20,
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
                        ),
                      ],
                    ),
                  ),
                  if (_isFetchingRoutes)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: _routeLoadingBadge(),
                    ),
                ],
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

  Widget _buildSearchPanel(
      BuildContext context,
      ThemeData theme,
      AppLocalizations l10n,
      List<Service> services,
      List<ServiceCategory> categories,
      TechnicianProvider techProvider,
      bool isMobile,
      bool isTablet,
      bool isDesktop,
      ) {
    final padding = ResponsiveConstants.getPadding(context);

    return Container(
      key: const ValueKey('visible-search'),
      padding: EdgeInsets.fromLTRB(
        padding,
        isDesktop ? 10 : 6,
        padding,
        isDesktop ? 12 : (isMobile ? 6 : 10),
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // LOCATION SEARCH
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: theme.dividerColor.withOpacity(0.35)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _locationController,
                    focusNode: _locationFocus,
                    style: TextStyle(
                      fontSize: isDesktop ? 16 : (isTablet ? 15 : 13),
                    ),
                    decoration: InputDecoration(
                      hintText: l10n.searchLocation,
                      hintStyle: TextStyle(
                        color: theme.hintColor,
                        fontSize: isMobile ? 11 : 14,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: AppTheme.primary,
                        size: 18,
                      ),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_locationController.text.isNotEmpty)
                            IconButton(
                              tooltip: 'Clear',
                              icon: const Icon(Icons.clear_rounded, size: 16),
                              onPressed: () {
                                _locationController.clear();
                                _suggestionDebounce?.cancel();

                                setState(() {
                                  _placeSuggestions = [];
                                  _showSuggestions = _searchHistory.isNotEmpty;
                                });
                              },
                            ),
                          Tooltip(
                            message: NearbyStrings.chooseOnMap,
                            child: IconButton(
                              icon: const Icon(
                                Icons.map_rounded,
                                color: AppTheme.primary,
                                size: 18,
                              ),
                              onPressed: _openMapPicker,
                            ),
                          ),
                        ],
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        vertical: isMobile ? 8 : 11,
                        horizontal: 6,
                      ),
                    ),
                    onChanged: _onLocationQueryChanged,
                    onTap: () {
                      setState(() {
                        _showSuggestions = true;
                      });
                    },
                    onSubmitted: (_) => _performSearch(),
                  ),
                ),

                // SEARCH BUTTON
                Container(
                  margin: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        AppTheme.primary,
                        AppTheme.primaryLight,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _isSearching ? null : _performSearch,
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isDesktop ? 14 : (isTablet ? 12 : 8),
                          vertical: isDesktop ? 12 : (isTablet ? 11 : 8),
                        ),
                        child: _isSearching
                            ? SizedBox(
                          width: isDesktop ? 22 : 18,
                          height: isDesktop ? 22 : 18,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.search_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                            if (!isDesktop && !isTablet) ...[
                              const SizedBox(width: 3),
                              Text(
                                l10n.search,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // SUGGESTIONS
          if (_showSuggestions)
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: isMobile ? 160 : 220,
              ),
              child: _buildSuggestions(context, theme),
            ),

          // SEARCH RESULT SUMMARY
          if (_searchedArea.isNotEmpty && techProvider.technicians.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 6 : 10,
                  vertical: isMobile ? 4 : 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      color: AppTheme.error,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        _searchedArea,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: isMobile ? 10 : 12,
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 5 : 7,
                        vertical: isMobile ? 1 : 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${techProvider.technicians.length}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isMobile ? 9 : 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 6),

          // SERVICE SEARCH
          TextField(
            controller: _serviceSearchController,
            decoration: InputDecoration(
              hintText: NearbyStrings.filterByService,
              hintStyle: TextStyle(fontSize: isMobile ? 11 : 13),
              prefixIcon: const Icon(
                Icons.build_rounded,
                color: AppTheme.primary,
                size: 18,
              ),
              suffixIcon: _serviceSearchQuery.isNotEmpty
                  ? IconButton(
                tooltip: 'Clear',
                icon: const Icon(Icons.clear_rounded, size: 16),
                onPressed: () {
                  _serviceSearchController.clear();
                  setState(() {
                    _serviceSearchQuery = '';
                  });
                },
              )
                  : null,
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.symmetric(
                vertical: isMobile ? 6 : 9,
                horizontal: 10,
              ),
            ),
            onChanged: (value) {
              setState(() {
                _serviceSearchQuery = value;
              });
            },
          ),

          // SERVICES
          if (services.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: SizedBox(
                height: isDesktop ? 42 : (isMobile ? 34 : 38),
                child: ListView(
                  controller: _serviceChipScrollController,
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildServiceChip(
                      label: 'All',
                      icon: Icons.apps_rounded,
                      isSelected: _selectedServiceId == null,
                      onTap: () {
                        setState(() {
                          _selectedServiceId = null;
                          _selectedCategoryId = null;
                        });
                      },
                      isMobile: isMobile,
                      isDesktop: isDesktop,
                    ),
                    const SizedBox(width: 4),
                    ...services.map((service) {
                      final selected = _selectedServiceId == service.id;

                      return Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: _buildServiceChip(
                          label: service.name,
                          isSelected: selected,
                          onTap: () {
                            setState(() {
                              _selectedServiceId = selected ? null : service.id;
                              _selectedCategoryId = null;
                            });
                          },
                          isMobile: isMobile,
                          isDesktop: isDesktop,
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

          // CATEGORIES
          if (categories.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: SizedBox(
                height: isDesktop ? 38 : (isMobile ? 30 : 34),
                child: ListView(
                  controller: _categoryChipScrollController,
                  scrollDirection: Axis.horizontal,
                  children: categories.map((category) {
                    final selected = _selectedCategoryId == category.id;

                    return Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: _buildCategoryChip(
                        label: category.name,
                        isSelected: selected,
                        onTap: () {
                          setState(() {
                            _selectedCategoryId = selected ? null : category.id;
                          });
                        },
                        isMobile: isMobile,
                        isDesktop: isDesktop,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ==============================================================
  // SUGGESTIONS
  // ==============================================================

  Widget _buildSuggestions(BuildContext context, ThemeData theme) {
    final isMobile = ResponsiveConstants.isMobile(context);
    final showHistoryHeader =
        _searchHistory.isNotEmpty && _placeSuggestions.isEmpty && !_isLoadingSuggestions;

    return Container(
      margin: const EdgeInsets.only(top: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor.withOpacity(0.25)),
      ),
      child: ListView(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        children: [
          if (showHistoryHeader)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 6, 2),
              child: Row(
                children: [
                  Text(
                    NearbyStrings.recentSearches,
                    style: TextStyle(
                      color: theme.hintColor,
                      fontWeight: FontWeight.w700,
                      fontSize: isMobile ? 10 : 11,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _clearHistory,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      minimumSize: const Size(0, 20),
                    ),
                    child: Text(
                      NearbyStrings.clear,
                      style: TextStyle(
                        color: AppTheme.primary,
                        fontSize: isMobile ? 10 : 11,
                      ),
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
                    color: theme.hintColor, size: 16),
                title: Text(
                  place,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: isMobile ? 12 : 13),
                ),
                onTap: () {
                  _locationController.text = place;
                  setState(() {
                    _showSuggestions = false;
                  });
                  _performSearch();
                },
              ),
            ),
          if (_isLoadingSuggestions)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ..._placeSuggestions.map((suggestion) {
            return ListTile(
              dense: true,
              leading: const Icon(
                Icons.location_on_rounded,
                color: AppTheme.error,
                size: 16,
              ),
              title: Text(
                suggestion['name'].toString(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: isMobile ? 12 : 13),
              ),
              subtitle: Text(
                suggestion['full'].toString(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: isMobile ? 9 : 11),
              ),
              onTap: () async {
                final name = suggestion['name'].toString();
                _locationController.text = name;

                setState(() {
                  _showSuggestions = false;
                });

                await _saveToHistory(name);
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
    final isMobile = ResponsiveConstants.isMobile(context);
    final isTablet = ResponsiveConstants.isTablet(context);
    final isDesktop = ResponsiveConstants.isDesktop(context);

    if (!techProvider.hasSearchOrigin) {
      return _emptyMapState(
        theme,
        Icons.map_outlined,
        NearbyStrings.searchForTechnicians,
      );
    }

    final origin = LatLng(techProvider.searchLat!, techProvider.searchLng!);

    final technicians = techProvider.technicians
        .where((t) => t.latitude != null && t.longitude != null)
        .toList();

    if (technicians.isEmpty) {
      return _emptyMapState(
        theme,
        Icons.person_search_rounded,
        NearbyStrings.noTechniciansNearby,
        showExpandRadius: true,
      );
    }

    // ROAD POLYLINES
    final List<Polyline> polylines = [];

    for (final tech in technicians) {
      final route = _routesData[tech.id];
      if (route == null || route.points.length < 2) continue;

      final selected = _selectedTechnicianId == tech.id;

      polylines.add(
        Polyline(
          points: route.points,
          strokeWidth:
          selected ? (isDesktop ? 12.0 : 10.0) : (isDesktop ? 10.0 : 8.0),
          color: Colors.white.withOpacity(0.85),
        ),
      );

      polylines.add(
        Polyline(
          points: route.points,
          strokeWidth:
          selected ? (isDesktop ? 8.0 : 6.5) : (isDesktop ? 6.0 : 5.0),
          color: selected ? AppTheme.accent : AppTheme.primary,
        ),
      );
    }

    // TECHNICIAN MARKERS
    final markerWidth = ResponsiveConstants.getMarkerWidth(context);
    final markerHeight = ResponsiveConstants.getMarkerHeight(context);
    final avatarSize = ResponsiveConstants.getAvatarSize(context);

    final markers = technicians.map((tech) {
      final route = _routesData[tech.id];
      final distance = route?.distanceKm ?? tech.distanceKm;
      final duration = route?.durationMin;
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
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected ? AppTheme.accent : Colors.white,
                        width: 2.5,
                      ),
                    ),
                    child: _buildAvatar(
                      tech,
                      size: avatarSize,
                      iconSize: avatarSize * 0.5,
                    ),
                  ),
                const SizedBox(height: 2),
                if (isRecommended)
                  Container(
                    constraints: BoxConstraints(maxWidth: markerWidth - 8.0),
                    padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.18),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.near_me_rounded,
                            color: Colors.white, size: 10),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            'Near you',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (isRecommended) const SizedBox(height: 2),
                if (tech.area != null && tech.area!.trim().isNotEmpty)
                  Container(
                    constraints: BoxConstraints(maxWidth: markerWidth - 8.0),
                    padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppTheme.error, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.10),
                          blurRadius: 3,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          size: 9,
                          color: AppTheme.error,
                        ),
                        const SizedBox(width: 1),
                        Flexible(
                          child: Text(
                            tech.area!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppTheme.error,
                              fontSize: 7.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 2),
                if (distance > 0)
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.accent, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.10),
                          blurRadius: 3,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${distance.toStringAsFixed(1)} km',
                          style: const TextStyle(
                            color: AppTheme.accent,
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (duration != null) ...[
                          const SizedBox(width: 2),
                          const Text(
                            '•',
                            style: TextStyle(color: AppTheme.accent),
                          ),
                          const SizedBox(width: 1),
                          const Icon(
                            Icons.access_time_rounded,
                            color: AppTheme.accent,
                            size: 9,
                          ),
                          const SizedBox(width: 1),
                          Text(
                            '~${duration.toStringAsFixed(0)}m',
                            style: const TextStyle(
                              color: AppTheme.accent,
                              fontSize: 7.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }).toList();

    // USER MARKER
    final originMarker = Marker(
      point: origin,
      width: isDesktop ? 90.0 : (isTablet ? 70.0 : 60.0),
      height: isDesktop ? 90.0 : (isTablet ? 70.0 : 60.0),
      alignment: Alignment.bottomCenter,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.bottomCenter,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.error.withOpacity(0.35),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                Icons.location_on_rounded,
                color: AppTheme.error,
                size: isDesktop ? 48 : (isTablet ? 38 : 32),
              ),
            ),
            const SizedBox(height: 1),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: AppTheme.error,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                NearbyStrings.you,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isDesktop ? 9 : 7,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    // MAP
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: origin,
        initialZoom: isDesktop ? 14 : (isTablet ? 13.5 : 13),
        minZoom: 4,
        maxZoom: 18,
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
        PolylineLayer(polylines: polylines),
        MarkerLayer(markers: [originMarker, ...markers]),
        RichAttributionWidget(
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
    final isDesktop = ResponsiveConstants.isDesktop(context);
    final iconSize = isDesktop ? 44.0 : 34.0;

    return Container(
      color: theme.colorScheme.surfaceContainerLowest,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: isDesktop ? 80.0 : 64.0,
              height: isDesktop ? 80.0 : 64.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primary.withOpacity(0.08),
              ),
              child: Icon(icon, size: iconSize, color: AppTheme.primary),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              style: TextStyle(
                color: theme.hintColor,
                fontSize: isDesktop ? 16 : 13,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              'Within your area.',
              style: TextStyle(
                color: theme.hintColor,
                fontSize: isDesktop ? 13 : 11,
              ),
            ),
            if (showExpandRadius &&
                _searchRadiusKm < NearbyConstants.maxRadiusKm) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _retryWithLargerRadius,
                icon: const Icon(Icons.add_location_alt_outlined, size: 16),
                label: Text(
                  '${NearbyStrings.expandSearchRadius} (+${NearbyConstants.radiusStepKm} km)',
                  style: TextStyle(fontSize: isDesktop ? 14 : 12),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primary,
                  side: const BorderSide(color: AppTheme.primary),
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 20.0 : 12.0,
                    vertical: isDesktop ? 14.0 : 10.0,
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
    final isMobile = ResponsiveConstants.isMobile(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 8 : 10,
        vertical: isMobile ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: isMobile ? 12 : 14,
            height: isMobile ? 12 : 14,
            child: const CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          ),
          SizedBox(width: isMobile ? 4 : 6),
          Text(
            NearbyStrings.findingRoutes,
            style: TextStyle(
              color: Colors.white,
              fontSize: isMobile ? 9 : 11,
              fontWeight: FontWeight.w600,
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
    final camera = _mapController.camera;
    final zoom = (camera.zoom + amount).clamp(4.0, 18.0);
    _mapController.move(camera.center, zoom);
  }

  // ==============================================================
  // TECHNICIAN MODAL
  // ==============================================================

  void _showTechnicianModal(
      BuildContext context,
      Technician tech,
      LatLng origin,
      bool recommended,
      ) {
    final theme = Theme.of(context);
    final isMobile = ResponsiveConstants.isMobile(context);
    final isDesktop = ResponsiveConstants.isDesktop(context);

    final route = _routesData[tech.id];
    final distance = route?.distanceKm ?? tech.distanceKm;
    final duration = route?.durationMin;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              isMobile ? 14 : 18,
              10,
              isMobile ? 14 : 18,
              isDesktop ? 20 : 14,
            ),
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
                const SizedBox(height: 14),

                // HEADER
                Row(
                  children: [
                    _buildAvatar(
                      tech,
                      size: isMobile ? 48.0 : (isDesktop ? 64.0 : 56.0),
                      iconSize: isMobile ? 24.0 : (isDesktop ? 32.0 : 28.0),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  tech.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    fontSize:
                                    isDesktop ? 20 : (isMobile ? 16 : 18),
                                  ),
                                ),
                              ),
                              if (tech.verified)
                                Icon(
                                  Icons.verified_rounded,
                                  color: AppTheme.accent,
                                  size: isDesktop ? 20 : 16,
                                ),
                            ],
                          ),
                          if (recommended)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                NearbyStrings.recommendedReason,
                                style: TextStyle(
                                  color: AppTheme.primary,
                                  fontSize:
                                  isDesktop ? 12 : (isMobile ? 9 : 11),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          if (tech.area != null && tech.area!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.location_on_rounded,
                                    color: AppTheme.error,
                                    size: 13,
                                  ),
                                  const SizedBox(width: 3),
                                  Expanded(
                                    child: Text(
                                      tech.area!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: theme.hintColor,
                                        fontSize: isDesktop
                                            ? 13
                                            : (isMobile ? 10 : 12),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: MaterialLocalizations.of(context)
                          .closeButtonTooltip,
                      onPressed: () => Navigator.pop(sheetContext),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // DISTANCE CARD
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.accent.withOpacity(0.18),
                    ),
                  ),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 6,
                    children: [
                      _modalInfo(
                        Icons.directions_car_rounded,
                        '${distance.toStringAsFixed(1)} km',
                        isDesktop,
                      ),
                      if (duration != null)
                        _modalInfo(
                          Icons.access_time_rounded,
                          '~${duration.toStringAsFixed(0)} min',
                          isDesktop,
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                if (tech.rating > 0)
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          color: AppTheme.secondary, size: 16),
                      const SizedBox(width: 3),
                      Text(
                        tech.rating.toStringAsFixed(1),
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: isDesktop ? 14 : (isMobile ? 12 : 13),
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 10),

                if (tech.services.isNotEmpty)
                  Wrap(
                    spacing: 5,
                    runSpacing: 5,
                    children: tech.services.map((service) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          service,
                          style: TextStyle(
                            color: AppTheme.primary,
                            fontSize: isDesktop ? 13 : (isMobile ? 9 : 11),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                const SizedBox(height: 14),

                // BUTTONS
                Row(
                  children: [
                    Expanded(
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
                          padding: EdgeInsets.symmetric(
                            vertical:
                            isDesktop ? 14 : (isMobile ? 10 : 12),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          NearbyStrings.viewProfile,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: isDesktop ? 15 : (isMobile ? 12 : 13),
                          ),
                        ),
                      ),
                    ),
                    if (tech.latitude != null && tech.longitude != null) ...[
                      const SizedBox(width: 8),
                      SizedBox(
                        height: isDesktop ? 52 : (isMobile ? 40 : 44),
                        width: isDesktop ? 54 : (isMobile ? 42 : 46),
                        child: OutlinedButton(
                          onPressed: () {
                            _openDirectionsInGoogleMaps(
                              context,
                              origin: origin,
                              destination:
                              LatLng(tech.latitude!, tech.longitude!),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.accent,
                            side: const BorderSide(color: AppTheme.accent),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: EdgeInsets.zero,
                          ),
                          child: const Tooltip(
                            message: NearbyStrings.directions,
                            child: Icon(Icons.directions_rounded),
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

  Widget _modalInfo(IconData icon, String value, bool isDesktop) {
    final isMobile = ResponsiveConstants.isMobile(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon,
            color: AppTheme.accent, size: isDesktop ? 18 : 14),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            color: AppTheme.accent,
            fontWeight: FontWeight.w800,
            fontSize: isDesktop ? 14 : (isMobile ? 11 : 12),
          ),
        ),
      ],
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
  // SERVICE CHIP
  // ==============================================================

  Widget _buildServiceChip({
    required String label,
    IconData? icon,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isMobile,
    bool isDesktop = false,
  }) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 14.0 : (isMobile ? 6.0 : 10.0),
            vertical: isDesktop ? 8.0 : (isMobile ? 3.0 : 5.0),
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primary
                : theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? AppTheme.primary
                  : theme.dividerColor.withOpacity(0.25),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: isDesktop ? 14.0 : (isMobile ? 10.0 : 12.0),
                  color: isSelected ? Colors.white : theme.hintColor,
                ),
                const SizedBox(width: 3),
              ],
              Text(
                label,
                style: TextStyle(
                  color:
                  isSelected ? Colors.white : theme.colorScheme.onSurface,
                  fontSize: isDesktop ? 13 : (isMobile ? 9 : 10.5),
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==============================================================
  // CATEGORY CHIP
  // ==============================================================

  Widget _buildCategoryChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isMobile,
    bool isDesktop = false,
  }) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 12.0 : (isMobile ? 6.0 : 10.0),
            vertical: isDesktop ? 6.0 : (isMobile ? 2.0 : 4.0),
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primary.withOpacity(0.10)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppTheme.primary
                  : theme.dividerColor.withOpacity(0.25),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelected) ...[
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppTheme.primary,
                  size: 10,
                ),
                const SizedBox(width: 3),
              ],
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? AppTheme.primary
                      : theme.colorScheme.onSurface,
                  fontSize: isDesktop ? 13 : (isMobile ? 9 : 10),
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
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

  const _MapControlButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveConstants.isDesktop(context);
    final iconSize = isDesktop ? 26.0 : 20.0;

    return Material(
      color: Theme.of(context).colorScheme.surface,
      shape: const CircleBorder(),
      elevation: 4,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon, color: AppTheme.primary, size: iconSize),
        padding: EdgeInsets.all(isDesktop ? 8 : 6),
        constraints: BoxConstraints(
          minWidth: isDesktop ? 44 : 36,
          minHeight: isDesktop ? 44 : 36,
        ),
      ),
    );
  }
}