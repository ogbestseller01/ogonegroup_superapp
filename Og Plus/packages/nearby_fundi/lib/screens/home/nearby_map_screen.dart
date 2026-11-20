// lib/screens/home/nearby_map_screen.dart
//
// Full-screen nearby map with ranked technicians, road routes and
// horizontal card list.
//
// All user-facing strings come from AppLocalizations (en / sw).

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/app_routes.dart';
import '../../config/app_theme.dart';
import '../../config/tanzania_map.dart';
import '../../l10n/app_localizations.dart';
import '../../models/technician.dart';
import '../../providers/technician_provider.dart';
import '../../services/route_service.dart';
import '../../utils/image_utils.dart';
import '../../widgets/route_polylines.dart';

// ================================================================
// LOCALIZATION SHORTCUT
// ================================================================

extension _NearbyMapL10n on BuildContext {
  AppLocalizations get t => AppLocalizations.of(this)!;
}

// ================================================================
// CONSTANTS / HELPERS
// ================================================================

const Color _gold = Color(0xFFF2B93B);

// IMPORTANT: use your real package name (not com.example.*)
const String _userAgentPackageName = 'com.ogonegroup.nearbyfundi';

Color _ink(ThemeData theme) =>
    theme.brightness == Brightness.dark ? Colors.white : AppTheme.primary;

// ================================================================
// SCREEN
// ================================================================

class NearbyMapScreen extends StatefulWidget {
  const NearbyMapScreen({super.key});

  @override
  State<NearbyMapScreen> createState() => _NearbyMapScreenState();
}

class _NearbyMapScreenState extends State<NearbyMapScreen>
    with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  final ScrollController _bottomScrollController = ScrollController();

  static const double _minZoom = TanzaniaMap.minZoom;
  static const double _maxZoom = TanzaniaMap.maxZoom;
  static const int _routeBatchSize = 4;
  static const int _maxRouteTargets = 12;
  static const double _cardGap = 12;
  static const int _fallbackRadiusKm = 15;

  final Map<int, TechnicianRouteData> _routesData = {};
  bool _isFetchingRoutes = false;
  int? _selectedTechId;
  int _routeRequestId = 0;

  late final AnimationController _pulseController;

  // Used to scroll the card list to a selected technician
  List<Technician> _lastSorted = [];
  double _lastCardWidth = 260;

  // Cache to avoid re-sorting on every build
  List<Technician> _cachedSortedTechs = [];
  List<Technician> _cachedSourceTechs = [];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _fetchRoutesForTechnicians();
    });
  }

  @override
  void dispose() {
    _routeRequestId++; // cancel any in-flight route loading
    _pulseController.dispose();
    _bottomScrollController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  // ==============================================================
  // ROUTES
  // ==============================================================

  Future<void> _fetchRoutesForTechnicians() async {
    final techProvider = context.read<TechnicianProvider>();
    if (!techProvider.hasSearchOrigin) return;

    final origin = LatLng(techProvider.searchLat!, techProvider.searchLng!);

    // Best ranked first so top picks get their road line first
    final techPoints = techProvider.technicians
        .where((t) => t.latitude != null && t.longitude != null)
        .toList()
      ..sort(Technician.byRank);

    if (techPoints.isEmpty) return;

    final requestId = ++_routeRequestId;

    setState(() {
      _isFetchingRoutes = true;
      _selectedTechId ??= techPoints.first.id;
    });

    final targets = techPoints
        .take(_maxRouteTargets)
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
      batchSize: _routeBatchSize,
      isCancelled: cancelled,
      onRoute: (id, route) {
        if (cancelled()) return;
        setState(() => _routesData[id] = route);
      },
    );

    if (cancelled()) return;

    setState(() => _isFetchingRoutes = false);
    _fitAllMarkers(origin, techPoints);
  }

  Future<void> _refresh() async {
    final techProvider = context.read<TechnicianProvider>();

    setState(() {
      _routeRequestId++;
      _routesData.clear();
      _isFetchingRoutes = false;
      _selectedTechId = null;
      _cachedSortedTechs = [];
      _cachedSourceTechs = [];
    });

    await techProvider.refreshLastSearch();
    if (!mounted) return;

    await _fetchRoutesForTechnicians();
  }

  void _zoomBy(double delta) {
    final camera = _mapController.camera;
    final newZoom = (camera.zoom + delta).clamp(_minZoom, _maxZoom);
    _mapController.move(camera.center, newZoom);
  }

  /// fitCamera guarded so a bad bounds/constraint combination can never
  /// crash the screen.
  void _safeFit(CameraFit fit) {
    if (!mounted) return;
    try {
      _mapController.fitCamera(fit);
    } catch (e) {
      debugPrint('NearbyMapScreen fitCamera failed: $e');
    }
  }

  void _fitAllMarkers(LatLng? searchPoint, List<Technician> techPoints) {
    final List<LatLng> allPoints = [];
    if (searchPoint != null) allPoints.add(searchPoint);
    allPoints.addAll(
        techPoints.map((t) => LatLng(t.latitude!, t.longitude!)));

    if (allPoints.isEmpty) return;
    if (allPoints.length == 1) {
      _mapController.move(allPoints.first, 14);
      return;
    }

    final bounds = LatLngBounds.fromPoints(allPoints);
    _safeFit(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.fromLTRB(50, 90, 50, 200),
      ),
    );
  }

  void _scrollCardIntoView(int techId) {
    if (!_bottomScrollController.hasClients) return;
    final index = _lastSorted.indexWhere((t) => t.id == techId);
    if (index < 0) return;

    final target = index * (_lastCardWidth + _cardGap);
    final max = _bottomScrollController.position.maxScrollExtent;

    _bottomScrollController.animateTo(
      target.clamp(0.0, max),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _selectTechnician(Technician tech, LatLng? searchPoint) {
    setState(() => _selectedTechId = tech.id);
    _scrollCardIntoView(tech.id);

    if (searchPoint != null) {
      final bounds = LatLngBounds.fromPoints([
        searchPoint,
        LatLng(tech.latitude!, tech.longitude!),
      ]);
      _safeFit(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.fromLTRB(70, 110, 70, 230),
        ),
      );
    }
  }

  Future<void> _openDirectionsInGoogleMaps(
      BuildContext context, {
        required LatLng? origin,
        required LatLng destination,
      }) async {
    final Uri url;
    if (origin != null) {
      url = Uri.parse(
        'https://www.google.com/maps/dir/?api=1'
            '&origin=${origin.latitude},${origin.longitude}'
            '&destination=${destination.latitude},${destination.longitude}'
            '&travelmode=driving',
      );
    } else {
      url = Uri.parse(
        'https://www.google.com/maps/search/?api=1'
            '&query=${destination.latitude},${destination.longitude}',
      );
    }

    // Resolve the message before any await so context is never used
    // across an async gap.
    final failMessage = context.t.nearbyCouldNotOpenMaps;
    final messenger = ScaffoldMessenger.of(context);

    bool launched = false;
    try {
      launched = await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {
      launched = false;
    }

    if (!launched && mounted) {
      messenger.showSnackBar(SnackBar(content: Text(failMessage)));
    }
  }

  // ==============================================================
  // BUILD
  // ==============================================================

  @override
  Widget build(BuildContext context) {
    final techProvider = context.watch<TechnicianProvider>();
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final searchPoint = techProvider.hasSearchOrigin
        ? LatLng(techProvider.searchLat!, techProvider.searchLng!)
        : null;

    final techPoints = techProvider.technicians
        .where((t) => t.latitude != null && t.longitude != null)
        .toList();

    // Cache sorting: only re-sort when the list identity changes
    if (!identical(techPoints, _cachedSourceTechs)) {
      _cachedSourceTechs = techPoints;
      _cachedSortedTechs = [...techPoints]..sort(Technician.byRank);
    }
    final sortedTechs = _cachedSortedTechs;
    _lastSorted = sortedTechs;

    final LatLng center;
    double zoom = 13;

    if (searchPoint != null) {
      center = searchPoint;
    } else if (techPoints.isNotEmpty) {
      center = LatLng(techPoints.first.latitude!, techPoints.first.longitude!);
      if (techPoints.length > 1) zoom = 12;
    } else {
      center = TanzaniaMap.center;
      zoom = TanzaniaMap.defaultZoom;
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          techProvider.searchPlace != null
              ? '${l10n.near} "${techProvider.searchPlace}"'
              : l10n.nearbyMap,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
        elevation: 0,
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _refresh,
            tooltip: context.t.nearbyRefresh,
          ),
        ],
      ),
      body: techProvider.isLoading
          ? const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      )
          : techPoints.isEmpty
          ? _buildEmptyState(context, theme)
          : _buildMap(
        context,
        theme,
        techProvider,
        sortedTechs,
        searchPoint,
        center,
        zoom,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map_outlined,
                size: 64, color: theme.hintColor.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text(
              context.t.nearbyNoTechniciansFound,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              context.t.nearbyTryAnotherLocation,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.hintColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMap(
      BuildContext context,
      ThemeData theme,
      TechnicianProvider techProvider,
      List<Technician> sortedTechs,
      LatLng? searchPoint,
      LatLng center,
      double zoom,
      ) {
    final mq = MediaQuery.of(context);
    final ink = _ink(theme);
    final safeBottom = mq.padding.bottom;

    final cardWidth = (mq.size.width * 0.78).clamp(250.0, 320.0);
    _lastCardWidth = cardWidth;

    const cardsHeight = 118.0;
    final cardsBottom = 26.0 + safeBottom;
    final controlsBottom = cardsHeight + cardsBottom + 14;

    final radiusKmValue = techProvider.searchRadiusKm ?? _fallbackRadiusKm;
    final radiusMeters = radiusKmValue * 1000.0;

    return Stack(
      children: [
        // MAP
        RepaintBoundary(
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: zoom,
              minZoom: _minZoom,
              maxZoom: _maxZoom,
              cameraConstraint: TanzaniaMap.constraint,
              onTap: (_, __) {
                if (_selectedTechId != null) {
                  setState(() => _selectedTechId = null);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: _userAgentPackageName,
                maxZoom: 19,
              ),

              if (searchPoint != null)
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: searchPoint,
                      radius: radiusMeters,
                      useRadiusInMeter: true,
                      color: AppTheme.primary.withValues(alpha: 0.04),
                      borderColor:
                      AppTheme.primary.withValues(alpha: 0.2),
                      borderStrokeWidth: 1.5,
                    ),
                  ],
                ),

              if (searchPoint != null)
                PolylineLayer(
                  polylines: buildRoutePolylines(
                    routes: {
                      for (final tech in sortedTechs)
                        if (_routesData[tech.id] != null)
                          tech.id: _routesData[tech.id]!,
                    },
                    selectedId: _selectedTechId,
                    lineColor: AppTheme.primary,
                    selectedColor: _gold,
                  ),
                ),

              MarkerLayer(
                markers: [
                  if (searchPoint != null) ...[
                    _buildOriginPulse(searchPoint),
                    _buildOriginMarker(searchPoint),
                  ],
                  // Drawn worst-to-best so top picks sit on top
                  ...sortedTechs.reversed.map(
                        (tech) => _buildTechnicianMarker(
                      tech,
                      searchPoint,
                      isSelected: _selectedTechId == tech.id,
                    ),
                  ),
                ],
              ),

              RichAttributionWidget(
                alignment: AttributionAlignment.bottomLeft,
                attributions: [
                  TextSourceAttribution(
                    '© OpenStreetMap contributors',
                    onTap: () => launchUrl(
                      Uri.parse(
                          'https://www.openstreetmap.org/copyright'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // TOP INFO BAR
        Positioned(
          top: 12,
          left: 16,
          right: 16,
          child: Center(
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.10),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.location_on_rounded, size: 16, color: ink),
                  const SizedBox(width: 6),
                  Text(
                    context.t.nearbyMapSummary(
                      sortedTechs.length,
                      radiusKmValue,
                    ),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: ink,
                      fontSize: 13,
                    ),
                  ),
                  if (_isFetchingRoutes) ...[
                    const SizedBox(width: 10),
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _gold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),

        // MAP CONTROLS
        Positioned(
          right: 14,
          bottom: controlsBottom,
          child: Column(
            children: [
              _MapControlButton(
                icon: Icons.add_rounded,
                tooltip: context.t.nearbyZoomIn,
                onPressed: () => _zoomBy(1),
              ),
              const SizedBox(height: 10),
              _MapControlButton(
                icon: Icons.remove_rounded,
                tooltip: context.t.nearbyZoomOut,
                onPressed: () => _zoomBy(-1),
              ),
              const SizedBox(height: 10),
              _MapControlButton(
                icon: Icons.center_focus_strong_rounded,
                tooltip: context.t.nearbyFitAll,
                onPressed: () => _fitAllMarkers(searchPoint, sortedTechs),
                highlighted: true,
              ),
            ],
          ),
        ),

        // HORIZONTAL CARD LIST
        Positioned(
          left: 0,
          right: 0,
          bottom: cardsBottom,
          child: SizedBox(
            height: cardsHeight,
            child: RepaintBoundary(
              child: ListView.separated(
                controller: _bottomScrollController,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                itemCount: sortedTechs.length,
                cacheExtent: 400,
                separatorBuilder: (_, __) =>
                const SizedBox(width: _cardGap),
                itemBuilder: (context, index) {
                  final tech = sortedTechs[index];
                  final isSelected = _selectedTechId == tech.id;
                  return RepaintBoundary(
                    child: _buildHorizontalCard(
                      tech,
                      index + 1,
                      searchPoint,
                      isSelected,
                      cardWidth,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ==============================================================
  // ORIGIN MARKERS
  // ==============================================================

  Marker _buildOriginPulse(LatLng point) {
    return Marker(
      point: point,
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
  }

  Marker _buildOriginMarker(LatLng point) {
    return Marker(
      point: point,
      width: 60,
      height: 70,
      alignment: Alignment.bottomCenter,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.location_on_rounded,
            color: AppTheme.error,
            size: 40,
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
            child: Text(
              context.t.nearbyYou,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==============================================================
  // TECHNICIAN MARKER
  // ==============================================================

  Marker _buildTechnicianMarker(
      Technician tech,
      LatLng? searchPoint, {
        required bool isSelected,
      }) {
    final routeData = _routesData[tech.id];
    final distance = routeData?.distanceKm ?? tech.distanceKm;

    return Marker(
      point: LatLng(tech.latitude!, tech.longitude!),
      width: 90,
      height: 110,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _selectTechnician(tech, searchPoint),
        child: AnimatedScale(
          scale: isSelected ? 1.12 : 1.0,
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.bottomCenter,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(
                    color: isSelected ? _gold : AppTheme.primary,
                    width: isSelected ? 2.8 : 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: tech.profilePhoto != null
                    ? ClipOval(
                  child: Image.network(
                    ImageUtils.getFullImageUrl(tech.profilePhoto!),
                    fit: BoxFit.cover,
                    cacheWidth: 96,
                    cacheHeight: 96,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.build_rounded,
                      color: AppTheme.primary,
                      size: 22,
                    ),
                  ),
                )
                    : const Icon(Icons.build_rounded,
                    color: AppTheme.primary, size: 22),
              ),
              const SizedBox(height: 5),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isSelected ? _gold : AppTheme.primary,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  context.t.nearbyKm(distance.toStringAsFixed(1)),
                  style: TextStyle(
                    color: isSelected ? AppTheme.primary : Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==============================================================
  // HORIZONTAL CARD
  // ==============================================================

  Widget _buildHorizontalCard(
      Technician tech,
      int position,
      LatLng? searchPoint,
      bool isSelected,
      double cardWidth,
      ) {
    final theme = Theme.of(context);
    final ink = _ink(theme);
    final route = _routesData[tech.id];
    final distance = route?.distanceKm ?? tech.distanceKm;
    final duration = route?.durationMin;
    final isTop = position == 1;

    return GestureDetector(
      onTap: () => _selectTechnician(tech, searchPoint),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: cardWidth,
        padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? _gold : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isSelected ? 0.16 : 0.08),
              blurRadius: isSelected ? 14 : 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar + rank badge
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(
                      color: isSelected || isTop ? _gold : AppTheme.primary,
                      width: 2,
                    ),
                  ),
                  child: tech.profilePhoto != null
                      ? ClipOval(
                    child: Image.network(
                      ImageUtils.getFullImageUrl(tech.profilePhoto!),
                      fit: BoxFit.cover,
                      cacheWidth: 92,
                      cacheHeight: 92,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.build_rounded,
                        color: AppTheme.primary,
                        size: 22,
                      ),
                    ),
                  )
                      : const Icon(Icons.build_rounded,
                      color: AppTheme.primary, size: 22),
                ),
                Positioned(
                  left: -4,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: isTop ? _gold : AppTheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '#$position',
                      style: TextStyle(
                        color: isTop ? AppTheme.primary : Colors.white,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(width: 10),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          tech.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: ink,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (tech.verified)
                        const Padding(
                          padding: EdgeInsets.only(left: 3),
                          child: Icon(
                            Icons.verified_rounded,
                            color: Color(0xFF3B9BE8),
                            size: 14,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (tech.rating > 0) ...[
                        const Icon(
                          Icons.star_rounded,
                          color: AppTheme.secondary,
                          size: 14,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          tech.rating.toStringAsFixed(1),
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 11.5),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Expanded(
                        child: Text(
                          tech.completedJobsCount > 0
                              ? context.t.nearbyJobsDone(
                              tech.completedJobsCount)
                              : (tech.area ?? context.t.nearbyNearYou),
                          style: TextStyle(
                              fontSize: 11.5, color: theme.hintColor),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Wrap(
                    spacing: 5,
                    runSpacing: 4,
                    children: [
                      _miniChip(
                        Icons.directions_car_rounded,
                        context.t.nearbyKm(distance.toStringAsFixed(1)),
                      ),
                      if (duration != null)
                        _miniChip(
                          Icons.access_time_rounded,
                          context.t.nearbyApproxMinShort(
                              duration.toStringAsFixed(0)),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 6),

            // Actions
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Tooltip(
                  message: context.t.nearbyViewProfile,
                  child: Material(
                    color: AppTheme.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.technicianDetail,
                          arguments: tech.id,
                        );
                      },
                      child: SizedBox(
                        width: 38,
                        height: 38,
                        child: Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: ink,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Tooltip(
                  message: context.t.nearbyDirections,
                  child: Material(
                    color: _gold,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _openDirectionsInGoogleMaps(
                        context,
                        origin: searchPoint,
                        destination:
                        LatLng(tech.latitude!, tech.longitude!),
                      ),
                      child: const SizedBox(
                        width: 38,
                        height: 38,
                        child: Icon(
                          Icons.directions_rounded,
                          color: AppTheme.primary,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniChip(IconData icon, String text) {
    final theme = Theme.of(context);
    final ink = _ink(theme);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: ink),
          const SizedBox(width: 3),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: ink,
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// MAP CONTROL BUTTON
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
    final theme = Theme.of(context);

    return Material(
      color: highlighted ? AppTheme.primary : theme.colorScheme.surface,
      shape: const CircleBorder(),
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.2),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: highlighted ? _gold : _ink(theme),
          size: 22,
        ),
        constraints: const BoxConstraints(minWidth: 46, minHeight: 46),
      ),
    );
  }
}