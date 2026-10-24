// screens/home/nearby_map_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../../providers/technician_provider.dart';
import '../../models/technician.dart';
import '../../config/app_routes.dart';
import '../../config/app_theme.dart';
import '../../utils/image_utils.dart';
import '../../l10n/app_localizations.dart';

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

const Color _gold = Color(0xFFF2B93B);

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

  final Map<int, TechnicianRouteData> _routesData = {};
  bool _isFetchingRoutes = false;
  int? _selectedTechId;

  late AnimationController _pulseController;
  final ScrollController _bottomScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchRoutesForTechnicians();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _bottomScrollController.dispose();
    super.dispose();
  }

  // ── Routes ──────────────────────────────────────────────────────────────
  Future<void> _fetchRoutesForTechnicians() async {
    final techProvider = context.read<TechnicianProvider>();
    if (!techProvider.hasSearchOrigin) return;

    final origin = LatLng(techProvider.searchLat!, techProvider.searchLng!);
    final techPoints = techProvider.technicians
        .where((t) => t.latitude != null && t.longitude != null)
        .toList();

    if (techPoints.isEmpty) return;

    setState(() => _isFetchingRoutes = true);

    final Map<int, TechnicianRouteData> fetched = {};
    final targets = techPoints.take(12);

    await Future.wait(targets.map((tech) async {
      final dest = LatLng(tech.latitude!, tech.longitude!);
      final routeData = await _getOsrmRouteData(origin, dest, tech.distanceKm);
      if (routeData != null) {
        fetched[tech.id] = routeData;
      }
    }));

    if (mounted) {
      // Sort by distance so nearest comes first in the horizontal list
      final sorted = [...techPoints]
        ..sort((a, b) {
          final da = fetched[a.id]?.distanceKm ?? a.distanceKm;
          final db = fetched[b.id]?.distanceKm ?? b.distanceKm;
          return da.compareTo(db);
        });

      setState(() {
        _routesData.addAll(fetched);
        _isFetchingRoutes = false;
        // Select nearest by default
        if (_selectedTechId == null && sorted.isNotEmpty) {
          _selectedTechId = sorted.first.id;
        }
      });

      _fitAllMarkers(origin, techPoints);
    }
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

      final response = await http.get(url).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['routes'] != null && (data['routes'] as List).isNotEmpty) {
          final route = data['routes'][0];
          final geometry = route['geometry']['coordinates'] as List;

          final points = geometry
              .map<LatLng>((coord) => LatLng(coord[1].toDouble(), coord[0].toDouble()))
              .toList();

          final distanceMeters = (route['distance'] as num).toDouble();
          final durationSeconds = (route['duration'] as num).toDouble();

          return TechnicianRouteData(
            points: points,
            distanceKm: distanceMeters / 1000.0,
            durationMin: durationSeconds / 60.0,
          );
        }
      }
    } catch (e) {
      debugPrint('Error fetching OSRM route: $e');
    }

    final straightKm = fallbackKm > 0
        ? fallbackKm
        : const Distance().as(LengthUnit.Kilometer, origin, destination);

    return TechnicianRouteData(
      points: [origin, destination],
      distanceKm: straightKm,
      durationMin: (straightKm / 30) * 60,
    );
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
        padding: const EdgeInsets.fromLTRB(50, 90, 50, 180),
      ),
    );
  }

  void _selectTechnician(Technician tech, LatLng? searchPoint) {
    setState(() => _selectedTechId = tech.id);

    if (searchPoint != null) {
      final bounds = LatLngBounds.fromPoints([
        searchPoint,
        LatLng(tech.latitude!, tech.longitude!),
      ]);
      _mapController.fitCamera(
        CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(70)),
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

    // Keep them sorted by distance for the horizontal list
    final sortedTechs = [...techPoints]
      ..sort((a, b) {
        final da = _routesData[a.id]?.distanceKm ?? a.distanceKm;
        final db = _routesData[b.id]?.distanceKm ?? b.distanceKm;
        return da.compareTo(db);
      });

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
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
        ),
        elevation: 0,
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: () {
              _routesData.clear();
              _selectedTechId = null;
              techProvider.refreshLastSearch();
              _fetchRoutesForTechnicians();
            },
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
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
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
            onTap: (_, __) {},
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

            // Route lines
            if (searchPoint != null)
              PolylineLayer(
                polylines: sortedTechs.expand((tech) {
                  final isSelected = _selectedTechId == tech.id;
                  final route = _routesData[tech.id];
                  final points = route?.points ??
                      [searchPoint, LatLng(tech.latitude!, tech.longitude!)];

                  return [
                    Polyline(
                      points: points,
                      strokeWidth: isSelected ? 9 : 5.5,
                      color: Colors.black.withOpacity(0.16),
                    ),
                    Polyline(
                      points: points,
                      strokeWidth: isSelected ? 6.5 : 4.2,
                      color: isSelected ? AppTheme.accent : AppTheme.primary.withOpacity(0.65),
                      borderColor: Colors.white.withOpacity(0.3),
                      borderStrokeWidth: 1.4,
                    ),
                  ];
                }).toList(),
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
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_on_rounded, size: 16, color: AppTheme.primary),
                const SizedBox(width: 6),
                Text(
                  '${sortedTechs.length} technician${sortedTechs.length > 1 ? 's' : ''} on map',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
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

        // ── Map controls ──────────────────────────────────────────────
        Positioned(
          right: 14,
          bottom: 175,
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
          bottom: 16,
          child: SizedBox(
            height: 118,
            child: ListView.separated(
              controller: _bottomScrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: sortedTechs.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final tech = sortedTechs[index];
                final isSelected = _selectedTechId == tech.id;
                return _buildHorizontalCard(tech, searchPoint, isSelected);
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
        onTap: () => _selectTechnician(tech, searchPoint),
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
    );
  }

  // ── HORIZONTAL CARD ─────────────────────────────────────────────────────
  Widget _buildHorizontalCard(Technician tech, LatLng? searchPoint, bool isSelected) {
    final route = _routesData[tech.id];
    final distance = route?.distanceKm ?? tech.distanceKm;
    final duration = route?.durationMin;

    return GestureDetector(
      onTap: () => _selectTechnician(tech, searchPoint),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 260,
        padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? _gold : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isSelected ? 0.14 : 0.08),
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
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: AppTheme.primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (tech.verified)
                        const Padding(
                          padding: EdgeInsets.only(left: 3),
                          child: Icon(Icons.verified_rounded, color: AppTheme.accent, size: 14),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tech.area ?? 'Near you',
                    style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      _miniChip(Icons.directions_car_rounded, '${distance.toStringAsFixed(1)} km'),
                      if (duration != null) ...[
                        const SizedBox(width: 5),
                        _miniChip(Icons.access_time_rounded, '~${duration.toStringAsFixed(0)}m'),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Profile button
            Material(
              color: AppTheme.primary.withOpacity(0.08),
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
                child: const SizedBox(
                  width: 38,
                  height: 38,
                  child: Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.primary, size: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: AppTheme.primary),
          const SizedBox(width: 3),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.primary,
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
    return Material(
      color: highlighted ? AppTheme.primary : Colors.white,
      shape: const CircleBorder(),
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.2),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: highlighted ? _gold : AppTheme.primary,
          size: 22,
        ),
        constraints: const BoxConstraints(minWidth: 46, minHeight: 46),
      ),
    );
  }
}