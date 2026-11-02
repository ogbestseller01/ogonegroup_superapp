// FILE: lib/screens/home/technician_location_map_screen.dart
// Single technician location + route map
// Clean, modern, consistent with NearbyScreen design language

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/technician_provider.dart';
import '../../models/technician.dart';
import '../../config/app_routes.dart';
import '../../config/app_theme.dart';
import '../../utils/image_utils.dart';
import '../../widgets/safe_network_image.dart';
import '../../l10n/app_localizations.dart';

// ================================================================
// UI HELPERS (match NearbyScreen)
// ================================================================

const Color _gold = Color(0xFFF2B93B);

Color _ink(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : AppTheme.primary;

Color _softFill(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFFF1F5F9);

// ================================================================
// SCREEN
// ================================================================

class TechnicianLocationMapScreen extends StatefulWidget {
  final Technician technician;

  const TechnicianLocationMapScreen({
    super.key,
    required this.technician,
  });

  @override
  State<TechnicianLocationMapScreen> createState() =>
      _TechnicianLocationMapScreenState();
}

class _TechnicianLocationMapScreenState
    extends State<TechnicianLocationMapScreen> {
  final MapController _mapController = MapController();

  static const double _minZoom = 4;
  static const double _maxZoom = 18;

  List<LatLng> _routePoints = [];
  bool _isLoadingRoute = false;
  double? _osrmDistanceKm;
  double? _osrmDurationMin;

  bool _mapReady = false;

  // A fit requested before the map was ready is applied in onMapReady
  bool _pendingFit = false;
  LatLng? _fitOrigin;
  LatLng? _fitDestination;

  Technician get technician => widget.technician;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _fetchOsrmRoute();
    });
  }

  @override
  void dispose() {
    _mapReady = false;
    _mapController.dispose();
    super.dispose();
  }

  // ==============================================================
  // MAP READY
  // ==============================================================

  void _onMapReady() {
    _mapReady = true;

    final origin = _fitOrigin;
    final destination = _fitDestination;
    if (_pendingFit && origin != null && destination != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _fitRouteBounds(origin, destination);
      });
    }
  }

  // ==============================================================
  // ROUTE
  // ==============================================================

  Future<void> _fetchOsrmRoute() async {
    if (_isLoadingRoute || !mounted) return;

    final techProvider = context.read<TechnicianProvider>();
    final lat = technician.latitude;
    final lng = technician.longitude;

    if (lat == null || lng == null || !techProvider.hasSearchOrigin) return;

    final origin = LatLng(techProvider.searchLat!, techProvider.searchLng!);
    final destination = LatLng(lat, lng);

    setState(() => _isLoadingRoute = true);

    List<LatLng>? points;
    double? distanceKm;
    double? durationMin;

    try {
      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
            '${origin.longitude},${origin.latitude};'
            '${destination.longitude},${destination.latitude}'
            '?overview=full&geometries=geojson',
      );

      final response =
      await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final routes = data is Map ? data['routes'] : null;

        if (routes is List && routes.isNotEmpty) {
          final route = routes.first as Map;
          final coordinates = (route['geometry']['coordinates'] as List);

          points = coordinates
              .map<LatLng>((c) => LatLng(
            (c[1] as num).toDouble(),
            (c[0] as num).toDouble(),
          ))
              .toList();

          distanceKm = (route['distance'] as num).toDouble() / 1000.0;
          durationMin = (route['duration'] as num).toDouble() / 60.0;
        }
      }
    } catch (e) {
      debugPrint('Error fetching OSRM route: $e');
    }

    if (!mounted) return;

    setState(() {
      // Straight line when the routing service is unreachable
      _routePoints = (points != null && points.isNotEmpty)
          ? points
          : [origin, destination];
      _osrmDistanceKm = distanceKm;
      _osrmDurationMin = durationMin;
      _isLoadingRoute = false;
    });

    _fitRouteBounds(origin, destination);
  }

  void _fitRouteBounds(LatLng origin, LatLng destination) {
    _fitOrigin = origin;
    _fitDestination = destination;

    if (!_mapReady || !mounted) {
      _pendingFit = true;
      return;
    }
    _pendingFit = false;

    final points =
    _routePoints.length > 1 ? _routePoints : [origin, destination];

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(points),
        // Extra room at the bottom for the technician card
        padding: const EdgeInsets.fromLTRB(50, 90, 50, 270),
        maxZoom: 16,
      ),
    );
  }

  void _refreshRoute() {
    if (_isLoadingRoute) return;
    setState(() {
      _routePoints = [];
      _osrmDistanceKm = null;
      _osrmDurationMin = null;
    });
    _fetchOsrmRoute();
  }

  void _zoomBy(double delta) {
    if (!_mapReady) return;
    final camera = _mapController.camera;
    final newZoom = (camera.zoom + delta).clamp(_minZoom, _maxZoom).toDouble();
    _mapController.move(camera.center, newZoom);
  }

  void _recenter(LatLng point, double zoom) {
    if (!_mapReady) return;
    _mapController.move(point, zoom);
  }

  // ==============================================================
  // GOOGLE MAPS
  // ==============================================================

  Future<void> _openInGoogleMaps(
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

    try {
      final launched =
      await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!launched && context.mounted) _showLaunchError(context);
    } catch (_) {
      if (context.mounted) _showLaunchError(context);
    }
  }

  void _showLaunchError(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Could not open maps app.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ==============================================================
  // AVATAR
  // ==============================================================

  Widget _buildAvatar(
      Technician tech, {
        double size = 56,
        double iconSize = 28,
      }) {
    final fallback = Center(
      child: Icon(
        Icons.build_rounded,
        color: Colors.grey.shade600,
        size: iconSize,
      ),
    );

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipOval(
        child: SafeNetworkImage(
          url: tech.profilePhoto == null
              ? null
              : ImageUtils.getFullImageUrl(tech.profilePhoto!),
          size: size,
          fallback: fallback,
        ),
      ),
    );
  }

  // ==============================================================
  // BUILD
  // ==============================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final techProvider = context.watch<TechnicianProvider>();
    final lat = technician.latitude;
    final lng = technician.longitude;

    if (lat == null || lng == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(technician.name),
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('Location not available for this technician.'),
        ),
      );
    }

    final destination = LatLng(lat, lng);
    final origin = techProvider.hasSearchOrigin
        ? LatLng(techProvider.searchLat!, techProvider.searchLng!)
        : null;
    final hasOrigin = origin != null;

    final fallbackKm = hasOrigin
        ? const Distance().as(LengthUnit.Kilometer, origin, destination)
        : 0.0;

    final displayKm = _osrmDistanceKm ??
        (technician.distanceKm > 0 ? technician.distanceKm : fallbackKm);

    const initialZoom = 14.0;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 400;

    final pinSize = isSmall ? 58.0 : 74.0;
    final avatarSize = isSmall ? 46.0 : 60.0;
    final avatarIconSize = isSmall ? 24.0 : 30.0;
    final badgeFontSize = isSmall ? 7.8 : 9.2;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          technician.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        elevation: 0,
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (hasOrigin)
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              onPressed: _isLoadingRoute ? null : _refreshRoute,
              tooltip: 'Refresh route',
            ),
        ],
      ),
      body: Stack(
        children: [
          // MAP
          RepaintBoundary(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: destination,
                initialZoom: initialZoom,
                minZoom: _minZoom,
                maxZoom: _maxZoom,
                onMapReady: _onMapReady,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.nearbyfundi',
                ),
                if (hasOrigin && _routePoints.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      // Shadow
                      Polyline(
                        points: _routePoints,
                        strokeWidth: 10.0,
                        color: Colors.black.withValues(alpha: 0.22),
                      ),
                      // Main route
                      Polyline(
                        points: _routePoints,
                        strokeWidth: 6.5,
                        color: AppTheme.primary,
                        borderColor: Colors.white.withValues(alpha: 0.45),
                        borderStrokeWidth: 2.0,
                      ),
                    ],
                  ),
                MarkerLayer(
                  markers: [
                    if (hasOrigin) _buildOriginMarker(origin, isSmall),
                    _buildTechnicianMarker(
                      context,
                      destination,
                      isDark,
                      isSmall,
                      pinSize,
                      avatarSize,
                      avatarIconSize,
                    ),
                    if (hasOrigin)
                      _buildDistanceLabel(
                        origin,
                        destination,
                        displayKm,
                        theme,
                        isSmall,
                        badgeFontSize,
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
          ),

          // LOADING BADGE
          if (_isLoadingRoute)
            Positioned(
              top: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                        'Calculating route…',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ZOOM CONTROLS
          Positioned(
            right: 14,
            bottom: hasOrigin ? 210 : 180,
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
                  icon: Icons.my_location_rounded,
                  tooltip: 'Recenter',
                  onPressed: () => _recenter(destination, initialZoom),
                  highlighted: true,
                ),
              ],
            ),
          ),

          // BOTTOM CARD
          Positioned(
            left: 12,
            right: 12,
            bottom: 14,
            child: GestureDetector(
              onTap: () => _showTechnicianDetailSheet(
                context,
                origin,
                destination,
                l10n,
                displayKm,
              ),
              child: Container(
                padding: EdgeInsets.all(isSmall ? 12 : 14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.16),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2.5),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: _gold,
                          ),
                          child: _buildAvatar(technician,
                              size: 46, iconSize: 23),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      technician.name,
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        fontSize: isSmall ? 14.5 : 15.5,
                                        color: _ink(context),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (technician.verified)
                                    const Padding(
                                      padding: EdgeInsets.only(left: 4),
                                      child: Icon(
                                        Icons.verified_rounded,
                                        size: 16,
                                        color: Color(0xFF3B9BE8),
                                      ),
                                    ),
                                ],
                              ),
                              if (technician.area != null)
                                Row(
                                  children: [
                                    Icon(Icons.location_on_rounded,
                                        size: 13, color: theme.hintColor),
                                    const SizedBox(width: 3),
                                    Flexible(
                                      child: Text(
                                        technician.area!,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                          color: theme.hintColor,
                                          fontSize: 12,
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
                        if (displayKm > 0)
                          Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${displayKm.toStringAsFixed(1)} km',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.primary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: isSmall ? 12.5 : 13.5,
                                  ),
                                ),
                                if (_osrmDurationMin != null)
                                  Text(
                                    '~${_osrmDurationMin!.toStringAsFixed(0)} min',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.hintColor,
                                      fontSize: 11,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        Icon(Icons.expand_less_rounded,
                            color: theme.hintColor, size: 22),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.pushNamed(
                              context,
                              AppRoutes.technicianDetail,
                              arguments: technician.id,
                            ),
                            icon: const Icon(Icons.person_rounded, size: 17),
                            label: Text(
                              l10n.viewProfile,
                              style:
                              TextStyle(fontSize: isSmall ? 12.5 : 13.5),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.primary,
                              side: BorderSide(
                                  color:
                                  AppTheme.primary.withValues(alpha: 0.35)),
                              padding: EdgeInsets.symmetric(
                                  vertical: isSmall ? 11 : 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _openInGoogleMaps(
                              context,
                              origin: origin,
                              destination: destination,
                            ),
                            icon: Icon(
                              hasOrigin
                                  ? Icons.directions_rounded
                                  : Icons.map_rounded,
                              size: 17,
                            ),
                            label: Text(
                              hasOrigin ? l10n.directions : 'Maps',
                              overflow: TextOverflow.ellipsis,
                              style:
                              TextStyle(fontSize: isSmall ? 12.5 : 13.5),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                  vertical: isSmall ? 11 : 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
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

  // ==============================================================
  // MARKERS
  // ==============================================================

  Marker _buildOriginMarker(LatLng point, bool isSmall) {
    return Marker(
      point: point,
      width: isSmall ? 80 : 100,
      height: isSmall ? 80 : 100,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.location_on_rounded,
            color: AppTheme.error,
            size: isSmall ? 44 : 56,
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
              'You',
              style: TextStyle(
                color: Colors.white,
                fontSize: isSmall ? 10 : 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Marker _buildTechnicianMarker(
      BuildContext context,
      LatLng point,
      bool isDark,
      bool isSmall,
      double pinSize,
      double avatarSize,
      double avatarIconSize,
      ) {
    final techProvider = context.read<TechnicianProvider>();
    final origin = techProvider.hasSearchOrigin
        ? LatLng(techProvider.searchLat!, techProvider.searchLng!)
        : null;

    final fallbackKm = origin != null
        ? const Distance().as(LengthUnit.Kilometer, origin, point)
        : 0.0;

    final displayKm = _osrmDistanceKm ??
        (technician.distanceKm > 0 ? technician.distanceKm : fallbackKm);

    return Marker(
      point: point,
      width: isSmall ? 104 : 124,
      height: isSmall ? 138 : 158,
      child: GestureDetector(
        onTap: () {
          final l10n = AppLocalizations.of(context)!;
          _showTechnicianDetailSheet(context, origin, point, l10n, displayKm);
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.location_on_rounded,
                  color: AppTheme.error,
                  size: pinSize,
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: pinSize * 0.32),
                  child: Container(
                    padding: const EdgeInsets.all(2.5),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: _gold,
                    ),
                    child: _buildAvatar(
                      technician,
                      size: avatarSize,
                      iconSize: avatarIconSize,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            if (technician.area != null)
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on_rounded,
                        size: 9, color: Colors.white70),
                    const SizedBox(width: 2),
                    Flexible(
                      child: Text(
                        technician.area!,
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
            if (displayKm > 0)
              Container(
                margin: const EdgeInsets.only(top: 3),
                padding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.primary, width: 1.3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.13),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${displayKm.toStringAsFixed(1)} km',
                      style: TextStyle(
                        fontSize: isSmall ? 8 : 9.5,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primary,
                      ),
                    ),
                    if (_osrmDurationMin != null) ...[
                      const SizedBox(width: 3),
                      Text(
                        '•',
                        style: TextStyle(
                          fontSize: isSmall ? 8 : 9.5,
                          color: AppTheme.primary.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(width: 3),
                      Icon(Icons.access_time_rounded,
                          size: isSmall ? 9 : 10.5, color: AppTheme.primary),
                      const SizedBox(width: 1),
                      Text(
                        '~${_osrmDurationMin!.toStringAsFixed(0)}m',
                        style: TextStyle(
                          fontSize: isSmall ? 7.5 : 9,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Marker _buildDistanceLabel(
      LatLng origin,
      LatLng destination,
      double km,
      ThemeData theme,
      bool isSmall,
      double badgeFontSize,
      ) {
    final midpoint = _routePoints.isNotEmpty
        ? _routePoints[_routePoints.length ~/ 2]
        : LatLng(
      (origin.latitude + destination.latitude) / 2,
      (origin.longitude + destination.longitude) / 2,
    );

    return Marker(
      point: midpoint,
      width: isSmall ? 90 : 105,
      height: isSmall ? 28 : 32,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.primary.withValues(alpha: 0.4),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${km.toStringAsFixed(1)} km',
              style: TextStyle(
                fontSize: badgeFontSize,
                fontWeight: FontWeight.w800,
                color: AppTheme.primary,
              ),
            ),
            if (_osrmDurationMin != null) ...[
              const SizedBox(width: 3),
              Text(
                '•',
                style: TextStyle(
                  fontSize: badgeFontSize,
                  color: AppTheme.primary.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(width: 3),
              Icon(Icons.access_time_rounded,
                  size: badgeFontSize + 1, color: AppTheme.primary),
              const SizedBox(width: 1),
              Text(
                '~${_osrmDurationMin!.toStringAsFixed(0)}m',
                style: TextStyle(
                  fontSize: badgeFontSize - 0.3,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ==============================================================
  // DETAIL SHEET
  // ==============================================================

  void _showTechnicianDetailSheet(
      BuildContext context,
      LatLng? origin,
      LatLng destination,
      AppLocalizations l10n,
      double displayKm,
      ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasOrigin = origin != null;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 400;
    final ink = _ink(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
                isSmall ? 16 : 20, 12, isSmall ? 16 : 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle + close
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.dividerColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    Material(
                      color: _softFill(context),
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => Navigator.pop(sheetContext),
                        child: const SizedBox(
                          width: 36,
                          height: 36,
                          child: Icon(Icons.close_rounded, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: _gold,
                      ),
                      child: _buildAvatar(
                        technician,
                        size: isSmall ? 54 : 62,
                        iconSize: isSmall ? 26 : 30,
                      ),
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
                                  technician.name,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    fontSize: isSmall ? 17 : 19,
                                    color: ink,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (technician.verified)
                                const Padding(
                                  padding: EdgeInsets.only(left: 5),
                                  child: Icon(
                                    Icons.verified_rounded,
                                    size: 18,
                                    color: Color(0xFF3B9BE8),
                                  ),
                                ),
                            ],
                          ),
                          if (technician.area != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Row(
                                children: [
                                  const Icon(Icons.location_on_rounded,
                                      size: 14, color: AppTheme.error),
                                  const SizedBox(width: 3),
                                  Flexible(
                                    child: Text(
                                      technician.area!,
                                      style:
                                      theme.textTheme.bodyMedium?.copyWith(
                                        fontSize: isSmall ? 13 : 14,
                                        color: theme.hintColor,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color:
                        (technician.isOnline ? Colors.green : Colors.grey)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        technician.isOnline ? 'Online' : 'Offline',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: technician.isOnline
                              ? (isDark
                              ? Colors.green.shade300
                              : Colors.green.shade700)
                              : theme.hintColor,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Stats row
                Row(
                  children: [
                    if (technician.rating > 0) ...[
                      const Icon(Icons.star_rounded,
                          color: AppTheme.secondary, size: 18),
                      const SizedBox(width: 3),
                      Text(
                        technician.rating.toStringAsFixed(1),
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 16),
                    ],
                    Icon(Icons.directions_car_rounded,
                        size: 17, color: theme.hintColor),
                    const SizedBox(width: 4),
                    Text(
                      '${displayKm.toStringAsFixed(1)} km',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primary,
                      ),
                    ),
                    if (_osrmDurationMin != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        '• ~${_osrmDurationMin!.toStringAsFixed(0)} min',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.hintColor),
                      ),
                    ],
                  ],
                ),

                // Services
                if (technician.services.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: technician.services.map((s) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _softFill(context),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          s,
                          style: TextStyle(
                            fontSize: isSmall ? 12 : 13,
                            fontWeight: FontWeight.w700,
                            color: ink,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],

                const SizedBox(height: 18),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(sheetContext);
                            Navigator.pushNamed(
                              context,
                              AppRoutes.technicianDetail,
                              arguments: technician.id,
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
                          child: Text(
                            l10n.viewProfile,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: isSmall ? 14 : 15,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (technician.latitude != null &&
                        technician.longitude != null) ...[
                      const SizedBox(width: 10),
                      SizedBox(
                        height: 50,
                        width: isSmall ? 52 : 56,
                        child: ElevatedButton(
                          onPressed: () => _openInGoogleMaps(
                            context,
                            origin: origin,
                            destination: destination,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _gold,
                            foregroundColor: AppTheme.primary,
                            elevation: 0,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Icon(
                            hasOrigin
                                ? Icons.directions_rounded
                                : Icons.map_rounded,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ],
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
    return Material(
      color: highlighted
          ? AppTheme.primary
          : Theme.of(context).colorScheme.surface,
      shape: const CircleBorder(),
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.22),
      child: IconButton(
        icon: Icon(
          icon,
          color: highlighted ? _gold : AppTheme.primary,
          size: 21,
        ),
        tooltip: tooltip,
        onPressed: onPressed,
        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      ),
    );
  }
}