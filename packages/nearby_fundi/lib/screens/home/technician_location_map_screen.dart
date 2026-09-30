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
import '../../l10n/app_localizations.dart';

class TechnicianLocationMapScreen extends StatefulWidget {
  final Technician technician;
  const TechnicianLocationMapScreen({super.key, required this.technician});

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

  Technician get technician => widget.technician;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchOsrmRoute();
    });
  }

  Future<void> _fetchOsrmRoute() async {
    final techProvider = context.read<TechnicianProvider>();
    final lat = technician.latitude;
    final lng = technician.longitude;
    if (lat == null || lng == null || !techProvider.hasSearchOrigin) return;

    final origin = LatLng(techProvider.searchLat!, techProvider.searchLng!);
    final destination = LatLng(lat, lng);

    setState(() => _isLoadingRoute = true);

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
        if (data['routes'] != null && (data['routes'] as List).isNotEmpty) {
          final route = data['routes'][0];
          final geometry = route['geometry']['coordinates'] as List;
          final points = geometry
              .map<LatLng>(
                  (coord) => LatLng(coord[1].toDouble(), coord[0].toDouble()))
              .toList();
          final distanceMeters = (route['distance'] as num).toDouble();
          final durationSeconds = (route['duration'] as num).toDouble();

          setState(() {
            _routePoints = points;
            _osrmDistanceKm = distanceMeters / 1000.0;
            _osrmDurationMin = durationSeconds / 60.0;
            _isLoadingRoute = false;
          });
          _fitRouteBounds(origin, destination);
          return;
        }
      }
    } catch (e) {
      debugPrint('Error fetching OSRM route: $e');
    }

    setState(() {
      _routePoints = [origin, destination];
      _isLoadingRoute = false;
    });
  }

  void _fitRouteBounds(LatLng origin, LatLng destination) {
    final bounds = LatLngBounds.fromPoints([origin, destination]);
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(50),
      ),
    );
  }

  void _zoomBy(double delta) {
    final camera = _mapController.camera;
    final newZoom = (camera.zoom + delta).clamp(_minZoom, _maxZoom);
    _mapController.move(camera.center, newZoom);
  }

  void _recenter(LatLng point, double zoom) {
    _mapController.move(point, zoom);
  }

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

  Widget _buildAvatar(Technician tech,
      {double size = 56, double iconSize = 28}) {
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
            color: Colors.grey.shade600,
            size: iconSize,
          ),
        )
            : Icon(
          Icons.build_rounded,
          color: Colors.grey.shade600,
          size: iconSize,
        ),
      ),
    );
  }

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
            child: Text('Location not available for this technician.')),
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
              color: Colors.white, fontWeight: FontWeight.bold),
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
              onPressed: () {
                _routePoints.clear();
                _osrmDistanceKm = null;
                _osrmDurationMin = null;
                _fetchOsrmRoute();
              },
              tooltip: 'Refresh route',
            ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: destination,
              initialZoom: initialZoom,
              minZoom: _minZoom,
              maxZoom: _maxZoom,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.nearbyfundi',
                errorTileCallback: (tile, error, stackTrace) {
                  debugPrint('TILE ERROR: $error');
                },
              ),
              if (hasOrigin && _routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 10.0,
                      color: Colors.black.withOpacity(0.22),
                    ),
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 7.0,
                      color: AppTheme.primary,
                      borderColor: Colors.white.withOpacity(0.4),
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
                    _buildDistanceLabel(origin, destination, displayKm, theme,
                        isSmall, badgeFontSize),
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
          if (_isLoadingRoute)
            Positioned(
              top: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 13,
                        height: 13,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Calculating route…',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
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
                ),
              ],
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 14,
            child: GestureDetector(
              onTap: () => _showTechnicianDetailSheet(
                  context, origin, destination, l10n, displayKm),
              child: Container(
                padding: EdgeInsets.all(isSmall ? 12 : 14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        _buildAvatar(technician, size: 48, iconSize: 24),
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
                                          fontWeight: FontWeight.bold,
                                          fontSize: isSmall ? 14.5 : 15.5),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (technician.verified)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 4),
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(
                                            color: Colors.blue,
                                            shape: BoxShape.circle),
                                        child: const Icon(Icons.check_rounded,
                                            size: 10, color: Colors.white),
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
                                            fontSize: 12),
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
                                    fontWeight: FontWeight.bold,
                                    fontSize: isSmall ? 12.5 : 13.5,
                                  ),
                                ),
                                if (_osrmDurationMin != null)
                                  Text(
                                    '~${_osrmDurationMin!.toStringAsFixed(0)}m',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.hintColor,
                                      fontSize: 11,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        Icon(Icons.expand_less_rounded,
                            color: theme.hintColor, size: 20),
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
                            label: Text(l10n.viewProfile,
                                style: TextStyle(fontSize: isSmall ? 12.5 : 13.5)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.primary,
                              side: BorderSide(
                                  color: AppTheme.primary.withOpacity(0.4)),
                              padding: EdgeInsets.symmetric(
                                  vertical: isSmall ? 11 : 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(11)),
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
                                size: 17),
                            label: Text(
                              hasOrigin ? l10n.directions : 'Maps',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: isSmall ? 12.5 : 13.5),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                  vertical: isSmall ? 11 : 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(11)),
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

  Marker _buildOriginMarker(LatLng point, bool isSmall) {
    return Marker(
      point: point,
      width: isSmall ? 80 : 100,
      height: isSmall ? 80 : 100,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.location_pin,
            color: Colors.red.shade800,
            size: isSmall ? 48 : 62,
          ),
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
          _showTechnicianDetailSheet(
              context, origin, point, l10n, displayKm);
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.location_pin,
                  color: Colors.red.shade700,
                  size: pinSize,
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: pinSize * 0.32),
                  child: _buildAvatar(technician,
                      size: avatarSize, iconSize: avatarIconSize),
                ),
              ],
            ),
            const SizedBox(height: 2),
            if (technician.area != null)
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white, width: 0.6),
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
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.primary, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.13),
                      blurRadius: 3,
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
                        fontSize: isSmall ? 7.8 : 9.2,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                    if (_osrmDurationMin != null) ...[
                      const SizedBox(width: 1.5),
                      Text('•',
                          style: TextStyle(
                              fontSize: isSmall ? 7.8 : 9.2,
                              color: AppTheme.primary.withOpacity(0.5))),
                      const SizedBox(width: 1.5),
                      Icon(Icons.access_time_rounded,
                          size: isSmall ? 8.5 : 10, color: AppTheme.primary),
                      const SizedBox(width: 1),
                      Text(
                        '~${_osrmDurationMin!.toStringAsFixed(0)}m',
                        style: TextStyle(
                          fontSize: isSmall ? 7.5 : 8.8,
                          fontWeight: FontWeight.bold,
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
      width: isSmall ? 86 : 100,
      height: isSmall ? 26 : 30,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: AppTheme.primary.withOpacity(0.45), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.13),
              blurRadius: 3,
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
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
              ),
            ),
            if (_osrmDurationMin != null) ...[
              const SizedBox(width: 1.5),
              Text('•',
                  style: TextStyle(
                      fontSize: badgeFontSize,
                      color: AppTheme.primary.withOpacity(0.5))),
              const SizedBox(width: 1.5),
              Icon(Icons.access_time_rounded,
                  size: badgeFontSize + 0.8, color: AppTheme.primary),
              const SizedBox(width: 1),
              Text(
                '~${_osrmDurationMin!.toStringAsFixed(0)}m',
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
    );
  }

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
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 22),
                    onPressed: () => Navigator.pop(sheetContext),
                    tooltip: 'Close',
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  _buildAvatar(technician,
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
                                technician.name,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: isSmall ? 17 : 19,
                                  color: theme.colorScheme.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (technician.verified)
                              Container(
                                margin: const EdgeInsets.only(left: 5),
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                    color: Colors.blue, shape: BoxShape.circle),
                                child: const Icon(Icons.check_rounded,
                                    size: 13, color: Colors.white),
                              ),
                          ],
                        ),
                        if (technician.area != null)
                          Row(
                            children: [
                              Icon(Icons.location_on_rounded,
                                  size: 15, color: theme.hintColor),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  technician.area!,
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
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (technician.isOnline ? Colors.green : Colors.grey)
                          .withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      technician.isOnline ? 'Online' : 'Offline',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
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
              const SizedBox(height: 14),
              Row(
                children: [
                  if (technician.rating > 0) ...[
                    const Icon(Icons.star_rounded,
                        color: Colors.amber, size: 17),
                    const SizedBox(width: 3),
                    Text(
                      technician.rating.toStringAsFixed(1),
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 14),
                  ],
                  Icon(Icons.directions_car_rounded,
                      size: 17, color: theme.hintColor),
                  const SizedBox(width: 4),
                  Text(
                    '${displayKm.toStringAsFixed(1)} km',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                  if (_osrmDurationMin != null) ...[
                    const SizedBox(width: 6),
                    Text(
                      '• ~${_osrmDurationMin!.toStringAsFixed(0)}m',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.hintColor),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              if (technician.services.isNotEmpty) ...[
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: technician.services
                      .map(
                        (s) => Chip(
                      label: Text(
                        s,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: isSmall ? 11.5 : 12.5,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.primary,
                        ),
                      ),
                      backgroundColor: AppTheme.primary.withOpacity(0.08),
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 7),
                      materialTapTargetSize:
                      MaterialTapTargetSize.shrinkWrap,
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
                        Navigator.pushNamed(context, AppRoutes.technicianDetail,
                            arguments: technician.id);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(11)),
                        padding: EdgeInsets.symmetric(
                            vertical: isSmall ? 13 : 14),
                      ),
                      child: Text(
                        l10n.viewProfile,
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: isSmall ? 13.5 : 14.5),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (technician.latitude != null &&
                      technician.longitude != null)
                    Container(
                      height: 50,
                      width: isSmall ? 48 : 54,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.green.withOpacity(0.15)
                            : Colors.green.shade50,
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(
                          color: isDark
                              ? Colors.green.withOpacity(0.3)
                              : Colors.green.shade200,
                          width: 1.3,
                        ),
                      ),
                      child: IconButton(
                        icon: Icon(
                          hasOrigin
                              ? Icons.directions_rounded
                              : Icons.map_rounded,
                          color: isDark
                              ? Colors.green.shade300
                              : Colors.green.shade700,
                          size: isSmall ? 24 : 28,
                        ),
                        onPressed: () => _openInGoogleMaps(
                          context,
                          origin: origin,
                          destination: destination,
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