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

class NearbyMapScreen extends StatefulWidget {
  const NearbyMapScreen({super.key});

  @override
  State<NearbyMapScreen> createState() => _NearbyMapScreenState();
}

class _NearbyMapScreenState extends State<NearbyMapScreen> {
  final MapController _mapController = MapController();
  static const double _minZoom = 4;
  static const double _maxZoom = 18;

  final Map<int, TechnicianRouteData> _routesData = {};
  bool _isFetchingRoutes = false;
  int? _selectedTechId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchRoutesForTechnicians();
    });
  }

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
    final targets = techPoints.take(10);

    await Future.wait(targets.map((tech) async {
      final dest = LatLng(tech.latitude!, tech.longitude!);
      final routeData = await _getOsrmRouteData(origin, dest, tech.distanceKm);
      if (routeData != null) {
        fetched[tech.id] = routeData;
      }
    }));

    if (mounted) {
      setState(() {
        _routesData.addAll(fetched);
        _isFetchingRoutes = false;
      });
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
              .map<LatLng>(
                  (coord) => LatLng(coord[1].toDouble(), coord[0].toDouble()))
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
      durationMin: straightKm * 2,
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
      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(60)),
    );
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

  Widget _buildAvatar(Technician tech, {double size = 56, double iconSize = 28}) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(3.5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
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
          width: size,
          height: size,
          errorBuilder: (_, __, ___) => Icon(
            Icons.build_rounded,
            color: AppTheme.greyText,
            size: iconSize,
          ),
        )
            : Icon(
          Icons.build_rounded,
          color: AppTheme.greyText,
          size: iconSize,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final techProvider = context.watch<TechnicianProvider>();
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final searchPoint = techProvider.hasSearchOrigin
        ? LatLng(techProvider.searchLat!, techProvider.searchLng!)
        : null;

    final techPoints = techProvider.technicians
        .where((t) => t.latitude != null && t.longitude != null)
        .toList();

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

    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 400;

    final pinSize = isSmall ? 58.0 : 74.0;
    final avatarSize = isSmall ? 46.0 : 60.0;
    final avatarIconSize = isSmall ? 24.0 : 30.0;
    final badgeFontSize = isSmall ? 7.8 : 9.2;
    final markerHeight = isSmall ? 148.0 : 172.0;
    final markerWidth = isSmall ? 108.0 : 128.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          techProvider.searchPlace != null
              ? '${l10n.near} "${techProvider.searchPlace}"'
              : l10n.nearbyMap,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
              techProvider.refreshLastSearch();
              _fetchRoutesForTechnicians();
            },
            tooltip: 'Refresh search',
          ),
        ],
      ),
      body: techProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : techPoints.isEmpty
          ? _buildEmptyState(context, theme, techProvider)
          : _buildMap(
        context,
        theme,
        isDark,
        techProvider,
        techPoints,
        searchPoint,
        center,
        zoom,
        pinSize,
        avatarSize,
        avatarIconSize,
        badgeFontSize,
        markerHeight,
        markerWidth,
        isSmall,
      ),
    );
  }

  Widget _buildEmptyState(
      BuildContext context,
      ThemeData theme,
      TechnicianProvider techProvider,
      ) {
    final hasTechnicians = techProvider.technicians.isNotEmpty;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map_outlined, size: 56, color: theme.hintColor.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              hasTechnicians ? 'No technicians with location' : 'No technicians found',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              hasTechnicians
                  ? 'Some technicians are missing location data'
                  : 'Try adjusting your search or location',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
            ),
            if (!hasTechnicians) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => techProvider.refreshLastSearch(),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMap(
      BuildContext context,
      ThemeData theme,
      bool isDark,
      TechnicianProvider techProvider,
      List<Technician> techPoints,
      LatLng? searchPoint,
      LatLng center,
      double zoom,
      double pinSize,
      double avatarSize,
      double avatarIconSize,
      double badgeFontSize,
      double markerHeight,
      double markerWidth,
      bool isSmall,
      ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: AppTheme.primary.withOpacity(0.08),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_on, size: 15, color: AppTheme.primary),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  '${techPoints.length} technician${techPoints.length > 1 ? 's' : ''} on map',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: AppTheme.primary,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (_isFetchingRoutes) ...[
                const SizedBox(width: 8),
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
            ],
          ),
        ),

        Expanded(
          child: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: center,
                  initialZoom: zoom,
                  minZoom: _minZoom,
                  maxZoom: _maxZoom,
                  onTap: (_, __) => setState(() => _selectedTechId = null),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.nearbyfundi',
                  ),

                  if (searchPoint != null)
                    PolylineLayer(
                      polylines: techPoints.expand((tech) {
                        final isSelected = _selectedTechId == tech.id;
                        final route = _routesData[tech.id];
                        final points = route?.points ??
                            [searchPoint, LatLng(tech.latitude!, tech.longitude!)];

                        final color = isSelected
                            ? AppTheme.accent
                            : AppTheme.primary.withOpacity(0.55);
                        final width = isSelected ? 8.0 : 5.5;

                        return [
                          Polyline(
                            points: points,
                            strokeWidth: width + 3,
                            color: Colors.black.withOpacity(0.22),
                          ),
                          Polyline(
                            points: points,
                            strokeWidth: width,
                            color: color,
                            borderColor: Colors.white.withOpacity(0.4),
                            borderStrokeWidth: 2.0,
                          ),
                        ];
                      }).toList(),
                    ),

                  MarkerLayer(
                    markers: [
                      if (searchPoint != null) _buildOriginMarker(searchPoint, isSmall),
                      ...techPoints.map(
                            (tech) => _buildTechnicianMarker(
                          context,
                          tech,
                          isDark,
                          searchPoint,
                          isSelected: _selectedTechId == tech.id,
                          pinSize: pinSize,
                          avatarSize: avatarSize,
                          avatarIconSize: avatarIconSize,
                          badgeFontSize: badgeFontSize,
                          markerHeight: markerHeight,
                          markerWidth: markerWidth,
                          isSmall: isSmall,
                        ),
                      ),
                      if (searchPoint != null)
                        ...techPoints
                            .where((tech) => _routesData.containsKey(tech.id))
                            .map(
                              (tech) => _buildRouteDistanceBadge(
                            tech,
                            searchPoint,
                            theme,
                            isSmall,
                            badgeFontSize,
                            isSelected: _selectedTechId == tech.id,
                          ),
                        ),
                    ],
                  ),

                  RichAttributionWidget(
                    attributions: [
                      TextSourceAttribution(
                        '© OpenStreetMap contributors',
                        onTap: () => launchUrl(
                          Uri.parse('https://www.openstreetmap.org/copyright'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              Positioned(
                right: 14,
                bottom: 20,
                child: Column(
                  children: [
                    _MapControlButton(
                      icon: Icons.add_rounded,
                      tooltip: 'Zoom in',
                      onPressed: () => _zoomBy(1),
                    ),
                    const SizedBox(height: 8),
                    _MapControlButton(
                      icon: Icons.remove_rounded,
                      tooltip: 'Zoom out',
                      onPressed: () => _zoomBy(-1),
                    ),
                    const SizedBox(height: 8),
                    _MapControlButton(
                      icon: Icons.center_focus_strong_rounded,
                      tooltip: 'Fit all',
                      onPressed: () => _fitAllMarkers(searchPoint, techPoints),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Marker _buildOriginMarker(LatLng point, bool isSmall) {
    return Marker(
      point: point,
      width: isSmall ? 80 : 100,
      height: isSmall ? 80 : 100,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.location_pin, color: AppTheme.error, size: isSmall ? 48 : 62),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white, width: 1),
            ),
            child: Text(
              'You',
              style: TextStyle(
                color: Colors.white,
                fontSize: isSmall ? 10 : 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Marker _buildTechnicianMarker(
      BuildContext context,
      Technician tech,
      bool isDark,
      LatLng? searchPoint, {
        required bool isSelected,
        required double pinSize,
        required double avatarSize,
        required double avatarIconSize,
        required double badgeFontSize,
        required double markerHeight,
        required double markerWidth,
        required bool isSmall,
      }) {
    final routeData = _routesData[tech.id];
    final distance = routeData?.distanceKm ?? tech.distanceKm;
    final durationMin = routeData?.durationMin;

    String label = tech.area ?? '';
    if (label.length > 15) label = '${label.substring(0, 15)}…';

    return Marker(
      point: LatLng(tech.latitude!, tech.longitude!),
      width: markerWidth,
      height: markerHeight,
      child: GestureDetector(
        onTap: () {
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
          _showTechnicianSheet(context, tech, searchPoint);
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.location_pin,
                  color: isSelected ? AppTheme.secondary : AppTheme.error,
                  size: pinSize,
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: pinSize * 0.32),
                  child: _buildAvatar(tech, size: avatarSize, iconSize: avatarIconSize),
                ),
              ],
            ),
            const SizedBox(height: 2),
            if (label.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white, width: 0.6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on_rounded, size: 9, color: Colors.white70),
                    const SizedBox(width: 2),
                    Flexible(
                      child: Text(
                        label,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isSmall ? 8 : 10,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 2),
            ],
            if (distance > 0)
              Container(
                margin: const EdgeInsets.only(top: 1),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.secondary : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? AppTheme.secondary : AppTheme.primary,
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.13),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${distance.toStringAsFixed(1)} km',
                        style: TextStyle(
                          fontSize: badgeFontSize,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? AppTheme.primary : AppTheme.primary,
                        ),
                      ),
                      if (durationMin != null) ...[
                        const SizedBox(width: 1.5),
                        Text(
                          '•',
                          style: TextStyle(
                            fontSize: badgeFontSize,
                            color: AppTheme.primary.withOpacity(0.5),
                          ),
                        ),
                        const SizedBox(width: 1.5),
                        Icon(
                          Icons.access_time_rounded,
                          size: badgeFontSize + 0.8,
                          color: AppTheme.primary,
                        ),
                        const SizedBox(width: 1),
                        Text(
                          '~${durationMin.toStringAsFixed(0)}m',
                          style: TextStyle(
                            fontSize: badgeFontSize - 0.3,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Marker _buildRouteDistanceBadge(
      Technician tech,
      LatLng origin,
      ThemeData theme,
      bool isSmall,
      double badgeFontSize, {
        required bool isSelected,
      }) {
    final routeData = _routesData[tech.id];
    if (routeData == null || routeData.points.isEmpty) {
      return Marker(point: origin, child: const SizedBox());
    }

    final midIndex = routeData.points.length ~/ 2;
    final midPoint = routeData.points[midIndex];
    final distance = routeData.distanceKm;
    final duration = routeData.durationMin;

    return Marker(
      point: midPoint,
      width: isSmall ? 86 : 100,
      height: isSmall ? 26 : 30,
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedTechId = tech.id);
          _showTechnicianSheet(context, tech, origin);
        },
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.secondary : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppTheme.secondary
                  : AppTheme.primary.withOpacity(0.45),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.13),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${distance.toStringAsFixed(1)} km',
                  style: TextStyle(
                    fontSize: badgeFontSize,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                ),
                if (duration != null) ...[
                  const SizedBox(width: 1.5),
                  Text(
                    '•',
                    style: TextStyle(
                      fontSize: badgeFontSize,
                      color: AppTheme.primary.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(width: 1.5),
                  Icon(
                    Icons.access_time_rounded,
                    size: badgeFontSize + 0.8,
                    color: AppTheme.primary,
                  ),
                  const SizedBox(width: 1),
                  Text(
                    '~${duration.toStringAsFixed(0)}m',
                    style: TextStyle(
                      fontSize: badgeFontSize - 0.3,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
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

  void _showTechnicianSheet(
      BuildContext context,
      Technician tech,
      LatLng? searchPoint,
      ) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isDark = theme.brightness == Brightness.dark;
    final hasOrigin = searchPoint != null;
    final isSmall = MediaQuery.of(context).size.width < 400;

    final routeData = _routesData[tech.id];
    final displayDistanceKm = routeData?.distanceKm ?? tech.distanceKm;
    final duration = routeData?.durationMin;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      backgroundColor: theme.colorScheme.surface,
      builder: (sheetContext) => SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(isSmall ? 14 : 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.dividerColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 22),
                    onPressed: () => Navigator.pop(sheetContext),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  _buildAvatar(tech,
                      size: isSmall ? 52 : 60, iconSize: isSmall ? 26 : 30),
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
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: isSmall ? 17 : 19,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (tech.verified)
                              Container(
                                margin: const EdgeInsets.only(left: 5),
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: AppTheme.accent,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.check_rounded,
                                    size: 13, color: Colors.white),
                              ),
                          ],
                        ),
                        if (tech.area != null)
                          Row(
                            children: [
                              Icon(Icons.location_on_rounded,
                                  size: 15, color: theme.hintColor),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  tech.area!,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontSize: isSmall ? 13 : 14,
                                    color: theme.hintColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  if (tech.rating > 0) ...[
                    const Icon(Icons.star_rounded,
                        color: AppTheme.secondary, size: 17),
                    const SizedBox(width: 3),
                    Text(
                      tech.rating.toStringAsFixed(1),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 14),
                  ],
                  Icon(Icons.directions_car_rounded,
                      size: 17, color: theme.hintColor),
                  const SizedBox(width: 4),
                  Text(
                    '${displayDistanceKm.toStringAsFixed(1)} km',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                  if (duration != null) ...[
                    const SizedBox(width: 6),
                    Text(
                      '• ~${duration.toStringAsFixed(0)}m',
                      style: TextStyle(color: theme.hintColor, fontSize: 13),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              if (tech.services.isNotEmpty) ...[
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: tech.services
                      .map(
                        (s) => Chip(
                      label: Text(
                        s,
                        style: TextStyle(
                          fontSize: isSmall ? 11.5 : 12.5,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.primary,
                        ),
                      ),
                      backgroundColor: AppTheme.primary.withOpacity(0.08),
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 7),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  )
                      .toList(),
                ),
                const SizedBox(height: 14),
              ],
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
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(11),
                        ),
                        padding:
                        EdgeInsets.symmetric(vertical: isSmall ? 13 : 14),
                      ),
                      child: Text(
                        l10n.viewProfile,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: isSmall ? 13.5 : 14.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (tech.latitude != null && tech.longitude != null)
                    Container(
                      height: 50,
                      width: isSmall ? 48 : 54,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppTheme.accent.withOpacity(0.15)
                            : AppTheme.bolt50,
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(
                          color: isDark
                              ? AppTheme.accent.withOpacity(0.3)
                              : AppTheme.bolt200,
                          width: 1.3,
                        ),
                      ),
                      child: IconButton(
                        icon: Icon(
                          hasOrigin
                              ? Icons.directions_rounded
                              : Icons.map_rounded,
                          color: AppTheme.accent,
                          size: isSmall ? 24 : 28,
                        ),
                        onPressed: () => _openDirectionsInGoogleMaps(
                          context,
                          origin: searchPoint,
                          destination: LatLng(tech.latitude!, tech.longitude!),
                        ),
                        tooltip: hasOrigin ? l10n.directions : 'View on map',
                        padding: EdgeInsets.zero,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
            ],
          ),
        ),
      ),
    );
  }
}

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
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      shape: const CircleBorder(),
      elevation: 3,
      child: IconButton(
        icon: Icon(icon, color: AppTheme.primary, size: 20),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }
}