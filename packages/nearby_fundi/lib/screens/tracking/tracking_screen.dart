// screens/tracking/tracking_screen.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/request.dart';
import '../../models/technician.dart';
import '../../providers/request_provider.dart';
import '../../providers/technician_provider.dart';
import '../../services/api_service.dart';
import '../../config/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/image_utils.dart';

class TrackingScreen extends StatefulWidget {
  final int requestId;

  const TrackingScreen({super.key, required this.requestId});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  final MapController _mapController = MapController();
  final int _refreshIntervalSeconds = 5;

  ServiceRequest? _request;
  Technician? _technician;
  bool _isLoading = true;
  String? _error;
  List<LatLng> _routePoints = [];
  double? _distance;
  String? _eta;
  double? _technicianLat;
  double? _technicianLng;
  double? _customerLat;
  double? _customerLng;
  DateTime? _lastUpdate;
  double? _speedKmh;
  Timer? _timer;

  double? _prevTechnicianLat;
  double? _prevTechnicianLng;
  DateTime? _prevUpdate;

  int? _loadedTechnicianId;

  @override
  void initState() {
    super.initState();
    _loadTrackingData();
    _timer = Timer.periodic(
      Duration(seconds: _refreshIntervalSeconds),
          (_) => _loadTrackingData(animate: true),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadTrackingData({bool animate = false}) async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final api = ApiService();
    // ✅ Uses the new dedicated tracking endpoint
    final response = await api.getTrackingData(widget.requestId);
    if (response.success && response.data != null) {
      final data = response.data as Map<String, dynamic>;
      final techLoc = data['technician_location'] as Map<String, dynamic>?;
      final custLoc = data['customer_location'] as Map<String, dynamic>?;

      final newTechLat = techLoc?['lat']?.toDouble();
      final newTechLng = techLoc?['lng']?.toDouble();
      final newCustLat = custLoc?['lat']?.toDouble();
      final newCustLng = custLoc?['lng']?.toDouble();

      if (_prevTechnicianLat != null && _prevTechnicianLng != null &&
          newTechLat != null && newTechLng != null) {
        final prev = LatLng(_prevTechnicianLat!, _prevTechnicianLng!);
        final curr = LatLng(newTechLat, newTechLng);
        final dist = Distance().as(LengthUnit.Kilometer, prev, curr);
        if (_prevUpdate != null && dist > 0) {
          final timeDiff = DateTime.now().difference(_prevUpdate!).inSeconds;
          if (timeDiff > 0) {
            _speedKmh = (dist / (timeDiff / 3600)).abs();
          }
        }
      }

      _prevTechnicianLat = _technicianLat;
      _prevTechnicianLng = _technicianLng;
      _prevUpdate = DateTime.now();

      _technicianLat = newTechLat;
      _technicianLng = newTechLng;
      _customerLat = newCustLat;
      _customerLng = newCustLng;
      _distance = data['distance_km']?.toDouble();
      _eta = data['eta'];
      _lastUpdate = DateTime.now();

      await _resolveRequestAndTechnician(data);

      if (_technicianLat != null && _technicianLng != null &&
          _customerLat != null && _customerLng != null) {
        final origin = LatLng(_technicianLat!, _technicianLng!);
        final dest = LatLng(_customerLat!, _customerLng!);
        final shouldRefetch = _routePoints.isEmpty ||
            (Distance().as(LengthUnit.Kilometer, origin, LatLng(_technicianLat!, _technicianLng!)) > 0.1);
        if (shouldRefetch) {
          await _fetchOsrmRoute(origin, dest);
        }
      }
      setState(() => _error = null);
    } else {
      setState(() => _error = response.message ?? 'Failed to load tracking data');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _resolveRequestAndTechnician(Map<String, dynamic> data) async {
    final inlineTech = data['technician'] as Map<String, dynamic>?;
    if (inlineTech != null && inlineTech.isNotEmpty) {
      try {
        _technician = Technician.fromJson(inlineTech, isDetail: true);
        _loadedTechnicianId = _technician?.id;
      } catch (e) {
        debugPrint('TrackingScreen: failed to parse inline technician: $e');
      }
    }

    final reqProvider = context.read<RequestProvider>();
    try {
      await reqProvider.loadMyRequests();
    } catch (e) {
      debugPrint('TrackingScreen: loadMyRequests() failed: $e');
    }

    ServiceRequest? matchedRequest;
    try {
      matchedRequest = reqProvider.requests.firstWhere((r) => r.id == widget.requestId);
    } catch (_) {
      matchedRequest = null;
    }

    if (matchedRequest == null) {
      debugPrint('TrackingScreen: request ${widget.requestId} not found in loadMyRequests(). Keeping last known.');
      return;
    }

    _request = matchedRequest;
    if (_technician != null) return;

    final techId = _request!.technicianId;
    if (techId == null || techId <= 0) {
      debugPrint('TrackingScreen: request ${widget.requestId} has no valid technicianId (got $techId).');
      return;
    }

    if (_loadedTechnicianId == techId && _technician != null) return;

    try {
      final techProvider = context.read<TechnicianProvider>();
      await techProvider.fetchTechnicianWithPortfolios(techId);
      if (techProvider.currentTechnician != null) {
        _technician = techProvider.currentTechnician;
        _loadedTechnicianId = techId;
      } else {
        debugPrint('TrackingScreen: fetchTechnicianWithPortfolios($techId) returned null.');
      }
    } catch (e) {
      debugPrint('TrackingScreen: failed to fetch technician $techId: $e');
    }
  }

  Future<void> _fetchOsrmRoute(LatLng origin, LatLng destination) async {
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
          if (mounted) {
            setState(() => _routePoints = points);
            if (points.isNotEmpty) {
              final bounds = LatLngBounds.fromPoints([origin, destination]);
              _mapController.fitCamera(
                CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)),
              );
            }
          }
        }
      }
    } catch (_) {}
  }

  // ─── Map controls ──────────────────────────────────────────────────────
  void _zoomBy(double delta) {
    final camera = _mapController.camera;
    final newZoom = (camera.zoom + delta).clamp(4.0, 18.0);
    _mapController.move(camera.center, newZoom);
  }

  void _fitAllMarkers() {
    final allPoints = <LatLng>[];
    if (_technicianLat != null && _technicianLng != null) {
      allPoints.add(LatLng(_technicianLat!, _technicianLng!));
    }
    if (_customerLat != null && _customerLng != null) {
      allPoints.add(LatLng(_customerLat!, _customerLng!));
    }
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

  // ─── Avatar builder ──────────────────────────────────────────────────
  Widget _buildAvatar(Technician tech, {double size = 48, double iconSize = 26}) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(3),
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

  Widget _buildFallbackAvatar({double size = 48, double iconSize = 26}) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(3),
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
        child: Container(
          color: AppTheme.primary.withOpacity(0.1),
          child: Icon(Icons.build_rounded, color: Colors.grey.shade600, size: iconSize),
        ),
      ),
    );
  }

  void _showTechnicianDetails(BuildContext context) {
    if (_technician == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Technician details not available yet.')),
      );
      return;
    }
    final theme = Theme.of(context);
    final tech = _technician!;
    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: theme.colorScheme.surface,
      builder: (_) => SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'Close',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildAvatar(tech, size: 56, iconSize: 28),
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
                                  fontSize: 18,
                                  color: theme.colorScheme.onSurface,
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
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.check_rounded, size: 13, color: Colors.white),
                              ),
                          ],
                        ),
                        if (tech.area != null)
                          Row(
                            children: [
                              Icon(Icons.location_on_rounded, size: 15, color: theme.hintColor),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  tech.area!,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontSize: 14,
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
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (tech.rating > 0)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded, color: Colors.amber, size: 17),
                        const SizedBox(width: 3),
                        Text(
                          tech.rating.toStringAsFixed(1),
                          style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  if (tech.services.isNotEmpty)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.construction_rounded, size: 16, color: theme.hintColor),
                        const SizedBox(width: 4),
                        Text(
                          tech.services.take(2).join(', '),
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (tech.portfolios.isNotEmpty) ...[
                const Text(
                  'Portfolio',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: tech.portfolios.length,
                    itemBuilder: (ctx, i) {
                      final item = tech.portfolios[i];
                      return Container(
                        width: 80,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: NetworkImage(ImageUtils.getFullImageUrl(item.image)),
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('View Profile', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (tech.latitude != null && tech.longitude != null)
                    Container(
                      height: 56,
                      width: 60,
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade200, width: 1.5),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.directions_rounded,
                          color: Colors.green.shade700,
                          size: 30,
                        ),
                        onPressed: () {
                          final url = Uri.parse(
                            'https://www.google.com/maps/dir/?api=1'
                                '&destination=${tech.latitude},${tech.longitude}',
                          );
                          launchUrl(url, mode: LaunchMode.externalApplication);
                        },
                        tooltip: 'Directions',
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final statusColor = _getStatusColor(_request?.status ?? 'pending');
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 400;

    final pinSize = isSmall ? 56.0 : 72.0;
    final avatarSize = isSmall ? 44.0 : 58.0;
    final avatarIconSize = isSmall ? 22.0 : 28.0;
    final markerHeight = isSmall ? 120.0 : 140.0;
    final markerWidth = isSmall ? 100.0 : 120.0;

    final bool hasTechnicianLocation = _technicianLat != null && _technicianLng != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Tracking', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              onPressed: () => _loadTrackingData(animate: false),
              tooltip: 'Refresh',
            ),
        ],
      ),
      body: _isLoading && !hasTechnicianLocation
          ? const Center(child: CircularProgressIndicator())
          : _error != null && !hasTechnicianLocation
          ? Center(child: Text(_error!))
          : Stack(
        children: [
          // Map
          Column(
            children: [
              Expanded(
                flex: 3,
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: hasTechnicianLocation
                        ? LatLng(_technicianLat!, _technicianLng!)
                        : (_customerLat != null && _customerLng != null
                        ? LatLng(_customerLat!, _customerLng!)
                        : const LatLng(-6.7924, 39.2083)),
                    initialZoom: 13,
                    maxZoom: 18,
                    minZoom: 4,
                    onTap: (_, __) {},
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.nearbyfundi',
                    ),
                    if (_routePoints.isNotEmpty)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: _routePoints,
                            strokeWidth: 5,
                            color: AppTheme.primary.withOpacity(0.7),
                            borderColor: Colors.white.withOpacity(0.3),
                            borderStrokeWidth: 2,
                          ),
                        ],
                      ),
                    MarkerLayer(
                      markers: [
                        if (hasTechnicianLocation)
                          Marker(
                            point: LatLng(_technicianLat!, _technicianLng!),
                            width: markerWidth,
                            height: markerHeight,
                            child: GestureDetector(
                              onTap: () => _showTechnicianDetails(context),
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
                                        child: _technician != null
                                            ? _buildAvatar(_technician!, size: avatarSize, iconSize: avatarIconSize)
                                            : _buildFallbackAvatar(size: avatarSize, iconSize: avatarIconSize),
                                      ),
                                    ],
                                  ),
                                  if (_technician != null && _technician!.area != null)
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
                                              _technician!.area!,
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
                                    )
                                  else
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: Colors.black87,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'Technician',
                                        style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        if (_customerLat != null && _customerLng != null)
                          Marker(
                            point: LatLng(_customerLat!, _customerLng!),
                            width: 40,
                            height: 60,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.red,
                                    border: Border.all(color: Colors.white, width: 2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(Icons.person_pin_circle_rounded, color: Colors.white, size: 32),
                                ),
                                const SizedBox(height: 2),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: Colors.black87,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'You',
                                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (_routePoints.isNotEmpty && _distance != null)
                          Marker(
                            point: _routePoints[_routePoints.length ~/ 2],
                            width: 60,
                            height: 30,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                                border: Border.all(color: AppTheme.primary, width: 1.2),
                              ),
                              child: Text(
                                '${_distance!.toStringAsFixed(1)} km',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primary,
                                ),
                              ),
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
              ),
              // Live Info Card
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, -4),
                    ),
                  ],
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'LIVE',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          _lastUpdate != null
                              ? 'Updated ${DateTime.now().difference(_lastUpdate!).inSeconds}s ago'
                              : '--',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(
                          icon: Icons.route_rounded,
                          value: '${_distance?.toStringAsFixed(1) ?? '--'} km',
                          label: 'Distance',
                          theme: theme,
                        ),
                        _buildStatItem(
                          icon: Icons.timer_rounded,
                          value: _eta != null ? _eta!.substring(11, 16) : '--:--',
                          label: 'ETA',
                          theme: theme,
                        ),
                        _buildStatItem(
                          icon: Icons.speed_rounded,
                          value: _speedKmh != null ? '${_speedKmh!.toStringAsFixed(1)} km/h' : '--',
                          label: 'Speed',
                          theme: theme,
                        ),
                        _buildStatItem(
                          icon: Icons.circle_rounded,
                          value: (_request?.status ?? '--').toUpperCase(),
                          label: 'Status',
                          theme: theme,
                          color: statusColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_technician != null)
                      InkWell(
                        onTap: () => _showTechnicianDetails(context),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.primary.withOpacity(0.1)),
                          ),
                          child: Row(
                            children: [
                              _buildAvatar(_technician!, size: 32, iconSize: 16),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _technician!.name,
                                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                                    ),
                                    if (_technician!.area != null)
                                      Text(
                                        _technician!.area!,
                                        style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor, fontSize: 11),
                                      ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                            ],
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: theme.hintColor.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: theme.hintColor.withOpacity(0.1)),
                        ),
                        child: Row(
                          children: [
                            _buildFallbackAvatar(size: 32, iconSize: 16),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Loading technician details...',
                                style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _loadTrackingData(animate: false),
                        icon: _isLoading
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.refresh_rounded),
                        label: Text(_isLoading ? 'Updating...' : 'Refresh Now'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primary,
                          side: BorderSide(color: AppTheme.primary.withOpacity(0.4)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // ─── Zoom Controls ──────────────────────────────────────────────
          Positioned(
            right: 16,
            bottom: 160, // place above the info card
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
                  tooltip: 'Fit all markers',
                  onPressed: _fitAllMarkers,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required ThemeData theme,
    Color? color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color ?? AppTheme.primary, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor, fontSize: 11),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'accepted':
        return AppTheme.primary;
      case 'completed':
        return AppTheme.success;
      case 'rejected':
      case 'cancelled':
        return AppTheme.error;
      case 'in_progress':
        return Colors.purple.shade700;
      case 'on_the_way':
        return Colors.green;
      case 'arrived':
        return Colors.teal;
      default:
        return AppTheme.warning;
    }
  }
}

// ─── Map Control Button ──────────────────────────────────────────────────
class _MapControlButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _MapControlButton({
    super.key,
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