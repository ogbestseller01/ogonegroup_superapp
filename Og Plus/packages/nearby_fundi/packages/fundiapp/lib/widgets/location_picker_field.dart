// lib/widgets/location_picker_field.dart
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../screens/map_logics/map_location_picker_screen.dart';
import '../services/location_service.dart';
import 'register_shell.dart';

class LocationPickerField extends StatefulWidget {
  final String? areaName;
  final double? latitude;
  final double? longitude;
  final bool enabled;
  final bool autoDetectOnMount;

  /// Called whenever the user picks a new location. `area` is the human
  /// friendly name; `lat`/`lng` are the coordinates.
  final void Function(String area, double lat, double lng) onChanged;

  const LocationPickerField({
    super.key,
    required this.areaName,
    required this.latitude,
    required this.longitude,
    required this.onChanged,
    this.enabled = true,
    this.autoDetectOnMount = true,
  });

  @override
  State<LocationPickerField> createState() => _LocationPickerFieldState();
}

class _LocationPickerFieldState extends State<LocationPickerField> {
  bool _detecting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // On first mount, if no location is set yet, auto-detect the device.
    // This is the "set once the app is installed" behaviour.
    if (widget.autoDetectOnMount &&
        (widget.latitude == null || widget.longitude == null)) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _useCurrentLocation(silent: true));
    }
  }

  Future<void> _useCurrentLocation({bool silent = false}) async {
    setState(() {
      _detecting = true;
      _error = null;
    });

    final point = await LocationService.getCurrentLocation();
    if (!mounted) return;

    if (point == null) {
      setState(() {
        _detecting = false;
        if (!silent) {
          _error = 'Could not get your location. Enable GPS or pick on the map.';
        }
      });
      return;
    }

    final area = await LocationService.reverseGeocode(point);
    if (!mounted) return;

    setState(() => _detecting = false);
    widget.onChanged(area ?? 'Current location', point.latitude, point.longitude);
  }

  Future<void> _pickOnMap() async {
    final initial = (widget.latitude != null && widget.longitude != null)
        ? LatLng(widget.latitude!, widget.longitude!)
        : null;

    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => MapLocationPickerScreen(initialCenter: initial),
      ),
    );
    if (result == null) return;

    widget.onChanged(
      result['name'] as String? ?? 'Selected location',
      (result['lat'] as num).toDouble(),
      (result['lng'] as num).toDouble(),
    );
  }

  Future<void> _searchPlace() async {
    final controller = TextEditingController(text: widget.areaName ?? '');
    final query = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enter location'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'e.g. Sinza, Dar es Salaam',
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: const Text('Search')),
        ],
      ),
    );
    if (query == null || query.isEmpty) return;

    setState(() {
      _detecting = true;
      _error = null;
    });

    final result = await LocationService.geocode(query);
    if (!mounted) return;

    if (result == null) {
      setState(() {
        _detecting = false;
        _error = 'Could not find "$query". Try a different spelling or pick on the map.';
      });
      return;
    }

    setState(() => _detecting = false);
    widget.onChanged(
      result.displayName,
      result.latLng.latitude,
      result.latLng.longitude,
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = RegPalette.of(context);
    final hasLocation = widget.latitude != null && widget.longitude != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Service location',
            style: TextStyle(
                fontWeight: FontWeight.w700, fontSize: 15, color: p.text)),
        const SizedBox(height: 4),
        Text('Where do you offer your services?',
            style: TextStyle(fontSize: 12.5, color: p.muted)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: p.field,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: Theme.of(context).dividerColor.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(
                _detecting ? Icons.hourglass_bottom : Icons.place_outlined,
                color: p.link,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _detecting
                          ? 'Detecting location…'
                          : (widget.areaName ?? 'No location selected'),
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14.5,
                          color: p.text),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (hasLocation && !_detecting)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          '${widget.latitude!.toStringAsFixed(5)}, '
                              '${widget.longitude!.toStringAsFixed(5)}',
                          style: TextStyle(fontSize: 11.5, color: p.muted),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            OutlinedButton.icon(
              onPressed: widget.enabled && !_detecting
                  ? () => _useCurrentLocation(silent: false)
                  : null,
              icon: const Icon(Icons.my_location, size: 18),
              label: const Text('Current'),
            ),
            OutlinedButton.icon(
              onPressed: widget.enabled && !_detecting ? _pickOnMap : null,
              icon: const Icon(Icons.map_outlined, size: 18),
              label: const Text('Map'),
            ),
            OutlinedButton.icon(
              onPressed: widget.enabled && !_detecting ? _searchPlace : null,
              icon: const Icon(Icons.search, size: 18),
              label: const Text('Search'),
            ),
          ],
        ),
        if (_error != null) ...[
          const SizedBox(height: 6),
          Text(
            _error!,
            style: TextStyle(
                color: Theme.of(context).colorScheme.error, fontSize: 12.5),
          ),
        ],
      ],
    );
  }
}