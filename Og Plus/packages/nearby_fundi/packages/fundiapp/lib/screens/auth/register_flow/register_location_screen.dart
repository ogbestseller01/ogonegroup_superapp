// lib/screens/auth/register_flow/register_location_screen.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/app_routes.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/fcm_service.dart';
import '../../../services/storage_service.dart';
import '../../../widgets/location_picker_field.dart';
import '../../../widgets/register_shell.dart';

class RegisterLocationScreen extends StatefulWidget {
  /// Account + service data forwarded from the Services screen.
  final Map<String, dynamic> args;

  const RegisterLocationScreen({super.key, required this.args});

  @override
  State<RegisterLocationScreen> createState() =>
      _RegisterLocationScreenState();
}

class _RegisterLocationScreenState extends State<RegisterLocationScreen> {
  String? _areaName;
  double? _latitude;
  double? _longitude;

  String? _error;

  @override
  void initState() {
    super.initState();
    // Restore previously selected location if the user is coming back here.
    _areaName = widget.args['area']?.toString();
    final lat = widget.args['latitude'];
    final lng = widget.args['longitude'];
    if (lat is num) _latitude = lat.toDouble();
    if (lng is num) _longitude = lng.toDouble();
  }

  bool get _isValid =>
      _areaName != null &&
          _areaName!.trim().isNotEmpty &&
          _latitude != null &&
          _longitude != null;

  Future<void> _next() async {
    if (!_isValid) {
      setState(() => _error = 'Please set your location first.');
      return;
    }

    await StorageService.clearTechnicianData();
    if (!mounted) return;

    final auth = context.read<AuthProvider>();
    auth.clearError();
    setState(() => _error = null);

    // FCM token (non-blocking — API still works if this fails)
    String? fcmToken;
    try {
      fcmToken = await FcmService.getToken();
      debugPrint(
          '🔔 Step 1 FCM: ${fcmToken != null ? "acquired" : "null"}');
    } catch (e) {
      debugPrint('⚠️ FCM unavailable: $e');
    }
    if (!mounted) return;

    final args = widget.args;
    final email = args['email']?.toString() ?? '';
    final fullPhone = args['phone_full']?.toString() ?? '';
    final serviceIds =
        (args['service_ids'] as List?)?.whereType<int>().toList() ?? const [];

    final id = await auth.registerTechnicianStep1({
      'name': args['name']?.toString() ?? '',
      if (email.isNotEmpty) 'email': email,
      'password': args['password']?.toString() ?? '',
      'password_confirmation':
      args['password_confirmation']?.toString() ?? '',
      'phone': fullPhone,
      'area': _areaName!.trim(),
      'latitude': _latitude,
      'longitude': _longitude,
      'service_ids': serviceIds,
      if (args['profile_photo'] != null)
        'profile_photo': args['profile_photo'].toString(),
      if (fcmToken != null && fcmToken.isNotEmpty)
        'fcm_device_token': fcmToken,
    });

    if (!mounted) return;

    if (id == null) {
      final msg = auth.errorMessage ??
          AppLocalizations.of(context)!.regSubmitFailed;
      setState(() => _error = msg);
      return;
    }

    Navigator.pushReplacementNamed(
      context,
      AppRoutes.otp,
      arguments: {
        'identifier': email.isNotEmpty ? email : fullPhone,
        'email': email,
        'phone': fullPhone,
        'technicianId': id,
        'redirectToStep2': true,
      },
    );
  }

  void _back() {
    Navigator.pushReplacementNamed(
      context,
      AppRoutes.registerServices,
      arguments: widget.args,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final p = RegPalette.of(context);
    final busy = auth.isLoading;

    return RegisterShell(
      step: 3,
      total: 8,
      title: 'Set your location',
      subtitle:
      'We use this to match you with nearby customers. Defaults to where you are now.',
      isLoading: busy,
      onNext: (_isValid && !busy) ? _next : null,
      nextLabel: 'Continue',
      onBack: busy ? null : _back,
      backEnabled: !busy,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Summary card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: p.field,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: Theme.of(context).dividerColor.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.person_outline_rounded,
                        size: 18, color: p.link),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.args['name']?.toString() ?? 'Account',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: p.text),
                      ),
                    ),
                    Icon(Icons.check_circle_rounded,
                        size: 18, color: Colors.green.shade600),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.work_outline_rounded,
                        size: 18, color: p.link),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${(widget.args['service_ids'] as List?)?.length ?? 0} service(s) selected',
                        style: TextStyle(fontSize: 13, color: p.text),
                      ),
                    ),
                    Icon(Icons.check_circle_rounded,
                        size: 18, color: Colors.green.shade600),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          LocationPickerField(
            areaName: _areaName,
            latitude: _latitude,
            longitude: _longitude,
            enabled: !busy,
            autoDetectOnMount: _areaName == null,
            onChanged: (area, lat, lng) {
              setState(() {
                _areaName = area;
                _latitude = lat;
                _longitude = lng;
                _error = null;
              });
            },
          ),

          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }
}