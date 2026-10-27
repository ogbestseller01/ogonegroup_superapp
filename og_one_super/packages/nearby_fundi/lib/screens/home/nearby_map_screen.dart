// screens/home/nearby_map_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/technician_provider.dart';
import '../../models/technician.dart';
import '../../config/app_routes.dart';
import '../../config/app_theme.dart';
import '../../utils/image_utils.dart';
import '../../l10n/app_localizations.dart';
import '../../services/route_service.dart'; // ← ROUTE
import '../../widgets/route_polylines.dart'; // ← ROUTE

const Color _gold = Color(0xFFF2B93B);

/// Text/icon color that stays readable in both light and dark mode.
Color _ink(ThemeData theme) =>
    theme.brightness == Brightness.dark ? Colors.white : AppTheme.primary;

class NearbyMapScreen extends StatefulWidget {
  const NearbyMapScreen({super.key});

  @override
  State<NearbyMapScreen> createState() => _NearbyMapScreenState();
}

class _NearbyMapScreenState extends State<NearbyMapScreen>
    with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  static const double _minZoom = 4;
  static const double _maxZoom = 18;
  static const int _routeBatchSize = 4;
  static const int _maxRouteTargets = 12;
  static const double _cardGap = 12;

  final Map<int, TechnicianRouteData> _routesData = {};
  bool _isFetchingRoutes = false;
  int? _selectedTechId;

  // ← ROUTE: lets a refresh cancel routes still loading
  int _routeRequestId = 0;

  late AnimationController _pulseController;
  final ScrollController _bottomScrollController = ScrollController();

  // Latest values from build(), used to scroll the card list to a fundi.
  List<Technician> _lastSorted = [];
  double _lastCardWidth = 260;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _fetchRoutesForTechnicians();
    });
  }

  @override
  void dispose() {
    _routeRequestId++; // ← ROUTE: stop any route loading
    _pulseController.dispose();
    _bottomScrollController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  // ── Routes ──────────────────────────────────────────────────────────────
  // ← ROUTE: road lines from the picked point to each technician.
  // Lines appear one by one; the nearest fundi is selected straight away.
  Future<void> _fetchRoutesForTechnicians() async {
    final techProvider = context.read<TechnicianProvider>();
    if (!techProvider.hasSearchOrigin) return;

    final origin = LatLng(techProvider.searchLat!, techProvider.searchLng!);
    final techPoints = techProvider.technicians
        .where((t) => t.latitude != null && t.longitude != null)
        .toList()
      ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

    if (techPoints.isEmpty) return;

    final requestId = ++_routeRequestId;

    setState(() {
      _isFetchingRoutes = true;
      // Select nearest by default
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

  void _fitAllMarkers(LatLng? searchPoint, List<Technician> techPoints) {
    final List<LatLng> allPoints = [];
    if (searchPoint != null) allPoints.add(searchPoint);
    allPoints.addAll(techPoints.map((t) => LatLng(t.latitude!, t.longitude!)));

    if (allPoints.isEmpty) return;
    if (allPoints.length == 1) {
      _mapController.move(allPoints.first, 14);
      return;
    }

    final bounds = LatLngBounds.fromPoints(allPoints);
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.fromLTRB(50, 90, 50, 200),
      ),
    );
  }

  /// Slides the bottom card list so the chosen fundi's card is visible.
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
      _mapController.fitCamera(
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
        'https://www.google.com/maps/search/?api=1&query=${destination.latitude},${destination.longitude}',
      );
    }

    try {
      final launched = await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open maps app.')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open maps app.')),
        );
      }
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────
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

    // Nearest first. Sorted by the provider distance so the list does not
    // jump around while road routes are still loading.
    final sortedTechs = [...techPoints]
      ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

    _lastSorted = sortedTechs;

    final LatLng center;
    double zoom = 13;

    if (searchPoint != null) {
      center = searchPoint;
    } else if (techPoints.isNotEmpty) {
      center = LatLng(techPoints.first.latitude!, techPoints.first.longitude!);
      if (techPoints.length > 1) zoom = 12;
    } else {
      center = const LatLng(-6.7924, 39.2083);
      zoom = 11;
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
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
        ),
        elevation: 0,
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _refresh,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: techProvider.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : techPoints.isEmpty
          ? _buildEmptyState(context, theme)
          : _buildMap(
        context,
        theme,
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
            Icon(Icons.map_outlined, size: 64, color: theme.hintColor.withOpacity(0.4)),
            const SizedBox(height: 16),
            Text(
              'No technicians found',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or location',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMap(
      BuildContext context,
      ThemeData theme,
      List<Technician> sortedTechs,
      LatLng? searchPoint,
      LatLng center,
      double zoom,
      ) {
    final mq = MediaQuery.of(context);
    final ink = _ink(theme);
    final safeBottom = mq.padding.bottom;

    // Responsive card width, remembered so the list can scroll to a card.
    final cardWidth = (mq.size.width * 0.78).clamp(250.0, 320.0);
    _lastCardWidth = cardWidth;

    const cardsHeight = 118.0;
    final cardsBottom = 26.0 + safeBottom;
    final controlsBottom = cardsHeight + cardsBottom + 14;

    return Stack(
      children: [
        // ── Map ───────────────────────────────────────────────────────
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: center,
            initialZoom: zoom,
            minZoom: _minZoom,
            maxZoom: _maxZoom,
            onTap: (_, __) {
              if (_selectedTechId != null) {
                setState(() => _selectedTechId = null);
              }
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.nearbyfundi',
            ),

            if (searchPoint != null)
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: searchPoint,
                    radius: 20000,
                    useRadiusInMeter: true,
                    color: AppTheme.primary.withOpacity(0.04),
                    borderColor: AppTheme.primary.withOpacity(0.2),
                    borderStrokeWidth: 1.5,
                  ),
                ],
              ),

            // ← ROUTE: road lines from the picked point to each technician
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
                ...sortedTechs.map(
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
                  onTap: () => launchUrl(Uri.parse('https://www.openstreetmap.org/copyright')),
                ),
              ],
            ),
          ],
        ),

        // ── Top bar ───────────────────────────────────────────────────
        Positioned(
          top: 12,
          left: 16,
          right: 16,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.10),
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
                    '${sortedTechs.length} technician${sortedTechs.length > 1 ? 's' : ''} on map',
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
                      child: CircularProgressIndicator(strokeWidth: 2, color: _gold),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),

        // ── Map controls ──────────────────────────────────────────────
        Positioned(
          right: 14,
          bottom: controlsBottom,
          child: Column(
            children: [
              _MapControlButton(
                icon: Icons.add_rounded,
                tooltip: 'Zoom in',
                onPressed: () => _zoomBy(1),
              ),
              const SizedBox(height: 10),
              _MapControlButton(
                icon: Icons.remove_rounded,
                tooltip: 'Zoom out',
                onPressed: () => _zoomBy(-1),
              ),
              const SizedBox(height: 10),
              _MapControlButton(
                icon: Icons.center_focus_strong_rounded,
                tooltip: 'Fit all',
                onPressed: () => _fitAllMarkers(searchPoint, sortedTechs),
                highlighted: true,
              ),
            ],
          ),
        ),

        // ── HORIZONTAL LIST OF ALL TECHNICIANS ────────────────────────
        Positioned(
          left: 0,
          right: 0,
          bottom: cardsBottom,
          child: SizedBox(
            height: cardsHeight,
            child: ListView.separated(
              controller: _bottomScrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: sortedTechs.length,
              separatorBuilder: (_, __) => const SizedBox(width: _cardGap),
              itemBuilder: (context, index) {
                final tech = sortedTechs[index];
                final isSelected = _selectedTechId == tech.id;
                return _buildHorizontalCard(
                  tech,
                  searchPoint,
                  isSelected,
                  cardWidth,
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  // ── Origin ──────────────────────────────────────────────────────────────
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
                  color: AppTheme.error.withOpacity(0.22 * (1 - v)),
                  border: Border.all(
                    color: AppTheme.error.withOpacity(0.5 * (1 - v)),
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
            shadows: [Shadow(color: Colors.black.withOpacity(0.3), blurRadius: 6)],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.error,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'You',
              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  // ── Map Marker ──────────────────────────────────────────────────────────
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
                      color: Colors.black.withOpacity(0.18),
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
                    errorBuilder: (_, __, ___) =>
                    const Icon(Icons.build_rounded, color: AppTheme.primary, size: 22),
                  ),
                )
                    : const Icon(Icons.build_rounded, color: AppTheme.primary, size: 22),
              ),
              const SizedBox(height: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isSelected ? _gold : AppTheme.primary,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  '${distance.toStringAsFixed(1)} km',
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

  // ── HORIZONTAL CARD ─────────────────────────────────────────────────────
  Widget _buildHorizontalCard(
      Technician tech,
      LatLng? searchPoint,
      bool isSelected,
      double cardWidth,
      ) {
    final theme = Theme.of(context);
    final ink = _ink(theme);
    final route = _routesData[tech.id];
    final distance = route?.distanceKm ?? tech.distanceKm;
    final duration = route?.durationMin;

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
              color: Colors.black.withOpacity(isSelected ? 0.16 : 0.08),
              blurRadius: isSelected ? 14 : 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar / Icon
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: isSelected ? _gold : AppTheme.primary, width: 2),
              ),
              child: tech.profilePhoto != null
                  ? ClipOval(
                child: Image.network(
                  ImageUtils.getFullImageUrl(tech.profilePhoto!),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                  const Icon(Icons.build_rounded, color: AppTheme.primary, size: 22),
                ),
              )
                  : const Icon(Icons.build_rounded, color: AppTheme.primary, size: 22),
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
                          child: Icon(Icons.verified_rounded, color: Color(0xFF3B9BE8), size: 14),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tech.area ?? 'Near you',
                    style: TextStyle(fontSize: 11.5, color: theme.hintColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Wrap(
                    spacing: 5,
                    runSpacing: 4,
                    children: [
                      _miniChip(Icons.directions_car_rounded, '${distance.toStringAsFixed(1)} km'),
                      if (duration != null)
                        _miniChip(Icons.access_time_rounded, '~${duration.toStringAsFixed(0)}m'),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 6),

            // Actions: profile + directions
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Tooltip(
                  message: 'View profile',
                  child: Material(
                    color: AppTheme.primary.withOpacity(0.10),
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
                        child: Icon(Icons.arrow_forward_ios_rounded, color: ink, size: 16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Tooltip(
                  message: 'Get directions',
                  child: Material(
                    color: _gold,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _openDirectionsInGoogleMaps(
                        context,
                        origin: searchPoint,
                        destination: LatLng(tech.latitude!, tech.longitude!),
                      ),
                      child: const SizedBox(
                        width: 38,
                        height: 38,
                        child: Icon(Icons.directions_rounded, color: AppTheme.primary, size: 20),
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
        color: AppTheme.primary.withOpacity(0.08),
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
      shadowColor: Colors.black.withOpacity(0.2),
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