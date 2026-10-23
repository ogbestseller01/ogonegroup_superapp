// FILE: lib/screens/home/nearby_screen.dart
// Nearby Fundi - Simple UI (logic unchanged)

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
        padding: const EdgeInsets.fromLTRB(60, 260, 60, 120),
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
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
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
        final opacity = 0.40 * (1 - value);

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
                    color: AppTheme.primary
                        .withOpacity(opacity.clamp(0.0, 1.0)),
                    width: 3,
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primary,
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                  padding: EdgeInsets.fromLTRB(pad + 4, 14, pad - 4, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${sorted.length} ${l10n.fundisFound}',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
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
                    const SizedBox(height: 10),
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
  // LIST TILE (one simple card for list + grid)
  // ==============================================================

  Widget _buildListTile(
      BuildContext context,
      Technician tech,
      bool recommended, {
        bool inGrid = false,
      }) {
    final theme = Theme.of(context);

    final route = _routesData[tech.id];
    final distance = route?.distanceKm ?? tech.distanceKm;
    final duration = route?.durationMin;
    final selected = _selectedTechnicianId == tech.id;

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
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
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? AppTheme.accent
                  : recommended
                  ? AppTheme.primary.withOpacity(0.4)
                  : theme.dividerColor.withOpacity(0.35),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              _buildAvatar(tech, size: 48, iconSize: 24),
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
                            ),
                          ),
                        ),
                        if (tech.verified)
                          const Padding(
                            padding: EdgeInsets.only(left: 5),
                            child: Icon(Icons.verified_rounded,
                                color: AppTheme.accent, size: 16),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      [
                        if (tech.area != null && tech.area!.isNotEmpty)
                          tech.area!,
                        '${distance.toStringAsFixed(1)} km',
                        if (duration != null)
                          '~${duration.toStringAsFixed(0)} min',
                      ].join('  •  '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.hintColor,
                        fontSize: 12.5,
                      ),
                    ),
                    if (recommended || tech.rating > 0) ...[
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
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          if (recommended)
                            const Flexible(
                              child: Text(
                                'Near you',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: AppTheme.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: selected ? AppTheme.accent : theme.hintColor,
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

    final hasFilters =
        _locationController.text.isNotEmpty || _selectedServiceId != null;
    final hasTechnicians = techProvider.technicians.isNotEmpty;

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

            // LIST + FULL MAP BUTTONS
            if (hasTechnicians)
              Positioned(
                left: 12,
                bottom: 20,
                child: Row(
                  children: [
                    _PillButton(
                      icon: Icons.list_rounded,
                      label: '${techProvider.technicians.length}',
                      tooltip: NearbyStrings.showList,
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

            // ROUTE LOADING
            if (_isFetchingRoutes)
              Positioned(
                bottom: 80,
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

    return Container(
      key: const ValueKey('visible-search'),
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // LOCATION SEARCH
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest
                        .withOpacity(0.6),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: TextField(
                    controller: _locationController,
                    focusNode: _locationFocus,
                    textInputAction: TextInputAction.search,
                    style: const TextStyle(fontSize: 14.5),
                    decoration: InputDecoration(
                      hintText: l10n.searchLocation,
                      hintStyle:
                      TextStyle(color: theme.hintColor, fontSize: 14),
                      prefixIcon: const Icon(Icons.search_rounded,
                          color: AppTheme.primary, size: 22),
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
                            icon: const Icon(Icons.map_outlined,
                                color: AppTheme.primary, size: 22),
                            onPressed: _openMapPicker,
                          ),
                        ],
                      ),
                      border: InputBorder.none,
                      contentPadding:
                      const EdgeInsets.symmetric(vertical: 12),
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
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 46,
                width: 46,
                child: ElevatedButton(
                  onPressed: _isSearching ? null : _performSearch,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isSearching
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Icon(Icons.search_rounded, size: 22),
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
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  const Icon(Icons.location_on_rounded,
                      color: AppTheme.error, size: 16),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _searchedArea,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Text(
                    '${techProvider.technicians.length} found',
                    style: TextStyle(
                      color: theme.hintColor,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 8),

          // SERVICE FILTER
          SizedBox(
            height: 40,
            child: TextField(
              controller: _serviceSearchController,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: NearbyStrings.filterByService,
                hintStyle: const TextStyle(fontSize: 13.5),
                prefixIcon: const Icon(Icons.build_outlined,
                    color: AppTheme.primary, size: 18),
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
                fillColor:
                theme.colorScheme.surfaceContainerHighest.withOpacity(0.6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10),
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
              padding: const EdgeInsets.only(top: 8),
              child: SizedBox(
                height: 36,
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
              padding: const EdgeInsets.only(top: 6),
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

          // FOOTER: clear + hide
          Row(
            children: [
              if (hasFilters)
                TextButton.icon(
                  onPressed: _clearAllFilters,
                  icon: const Icon(Icons.clear_all_rounded, size: 18),
                  label: const Text(NearbyStrings.clearFilters),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                    visualDensity: VisualDensity.compact,
                    textStyle: const TextStyle(
                        fontSize: 12.5, fontWeight: FontWeight.w700),
                  ),
                ),
              const Spacer(),
              IconButton(
                tooltip: 'Hide search',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.keyboard_arrow_up_rounded),
                color: theme.hintColor,
                onPressed: () => setState(() => _isHeaderVisible = false),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==============================================================
  // SUGGESTIONS
  // ==============================================================

  Widget _buildSuggestions(BuildContext context, ThemeData theme) {
    final showHistoryHeader = _searchHistory.isNotEmpty &&
        _placeSuggestions.isEmpty &&
        !_isLoadingSuggestions;

    return Container(
      margin: const EdgeInsets.only(top: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor.withOpacity(0.3)),
      ),
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
                    child: const Text(
                      NearbyStrings.clear,
                      style: TextStyle(color: AppTheme.primary, fontSize: 12),
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
          strokeWidth: selected ? 9.0 : 7.0,
          color: Colors.white.withOpacity(0.85),
        ),
      );

      polylines.add(
        Polyline(
          points: route.points,
          strokeWidth: selected ? 6.0 : 4.5,
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
                if (distance > 0) ...[
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: isRecommended ? AppTheme.primary : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Text(
                      '${distance.toStringAsFixed(1)} km',
                      style: TextStyle(
                        color:
                        isRecommended ? Colors.white : AppTheme.primary,
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

    // USER MARKER
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
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: AppTheme.error,
                borderRadius: BorderRadius.circular(6),
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
    return Container(
      color: theme.colorScheme.surfaceContainerLowest,
      alignment: Alignment.center,
      padding: const EdgeInsets.only(top: 140, left: 24, right: 24),
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primary.withOpacity(0.08),
              ),
              child: Icon(icon, size: 36, color: AppTheme.primary),
            ),
            const SizedBox(height: 14),
            Text(
              message,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              'Within your area.',
              style: TextStyle(color: theme.hintColor, fontSize: 13),
            ),
            if (showExpandRadius &&
                _searchRadiusKm < NearbyConstants.maxRadiusKm) ...[
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: _retryWithLargerRadius,
                icon: const Icon(Icons.add_location_alt_outlined, size: 18),
                label: Text(
                  '${NearbyStrings.expandSearchRadius} (+${NearbyConstants.radiusStepKm} km)',
                  style: const TextStyle(fontSize: 13),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primary,
                  side: const BorderSide(color: AppTheme.primary),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          ),
          SizedBox(width: 8),
          Text(
            NearbyStrings.findingRoutes,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
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

    final route = _routesData[tech.id];
    final distance = route?.distanceKm ?? tech.distanceKm;
    final duration = route?.durationMin;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
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
                    _buildAvatar(tech, size: 56, iconSize: 28),
                    const SizedBox(width: 12),
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
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                              if (tech.verified)
                                const Padding(
                                  padding: EdgeInsets.only(left: 6),
                                  child: Icon(Icons.verified_rounded,
                                      color: AppTheme.accent, size: 18),
                                ),
                            ],
                          ),
                          if (tech.area != null && tech.area!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Row(
                                children: [
                                  const Icon(Icons.location_on_rounded,
                                      color: AppTheme.error, size: 14),
                                  const SizedBox(width: 3),
                                  Expanded(
                                    child: Text(
                                      tech.area!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: theme.hintColor,
                                        fontSize: 13,
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

                if (recommended)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      NearbyStrings.recommendedReason,
                      style: const TextStyle(
                        color: AppTheme.primary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),

                const SizedBox(height: 14),

                // INFO ROW
                Wrap(
                  spacing: 18,
                  runSpacing: 8,
                  children: [
                    _modalInfo(Icons.directions_car_rounded,
                        '${distance.toStringAsFixed(1)} km'),
                    if (duration != null)
                      _modalInfo(Icons.access_time_rounded,
                          '~${duration.toStringAsFixed(0)} min'),
                    if (tech.rating > 0)
                      _modalInfo(Icons.star_rounded,
                          tech.rating.toStringAsFixed(1),
                          color: AppTheme.secondary),
                  ],
                ),

                if (tech.services.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: tech.services.map((service) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          service,
                          style: const TextStyle(
                            color: AppTheme.primary,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],

                const SizedBox(height: 18),

                // BUTTONS
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
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
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            NearbyStrings.viewProfile,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (tech.latitude != null && tech.longitude != null) ...[
                      const SizedBox(width: 10),
                      SizedBox(
                        height: 48,
                        width: 52,
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
                            foregroundColor: AppTheme.primary,
                            side: const BorderSide(color: AppTheme.primary),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
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

  Widget _modalInfo(IconData icon, String value, {Color? color}) {
    final c = color ?? AppTheme.accent;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: c, size: 18),
        const SizedBox(width: 5),
        Text(
          value,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w700,
            fontSize: 14,
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
  // CHIP (used for services and categories)
  // ==============================================================

  Widget _buildChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    bool outlined = false,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: isSelected
                  ? (outlined
                  ? AppTheme.primary.withOpacity(0.10)
                  : AppTheme.primary)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isSelected
                    ? AppTheme.primary
                    : theme.dividerColor.withOpacity(0.5),
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? (outlined ? AppTheme.primary : Colors.white)
                    : theme.colorScheme.onSurface,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
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

  const _MapControlButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      shape: const CircleBorder(),
      elevation: 3,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon, color: AppTheme.primary, size: 22),
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

  const _PillButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        elevation: 3,
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
                Icon(icon, color: AppTheme.primary, size: 22),
                if (label != null) ...[
                  const SizedBox(width: 6),
                  Text(
                    label!,
                    style: const TextStyle(
                      color: AppTheme.primary,
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