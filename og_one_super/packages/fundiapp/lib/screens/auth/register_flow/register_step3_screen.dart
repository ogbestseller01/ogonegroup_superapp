// lib/screens/auth/register_flow/register_step3_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/app_routes.dart';
import '../../../config/app_theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/register_step_scaffold.dart';
import '../../map_logics/map_location_picker_screen.dart';

class RegisterStep3Screen extends StatefulWidget {
  final int technicianId;
  const RegisterStep3Screen({super.key, required this.technicianId});

  @override
  State<RegisterStep3Screen> createState() => _RegisterStep3ScreenState();
}

class _RegisterStep3ScreenState extends State<RegisterStep3Screen> {
  final _areaC = TextEditingController();
  double? _lat;
  double? _lng;

  @override
  void initState() {
    super.initState();
    _checkAccess();
  }

  @override
  void dispose() {
    _areaC.dispose();
    super.dispose();
  }

  Future<void> _checkAccess() async {
    final step =
    await context.read<AuthProvider>().getRegistrationStep(widget.technicianId);
    if (!mounted) return;
    if (step == null) {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    } else if (step < 2) {
      Navigator.pushReplacementNamed(context, AppRoutes.registerStep2,
          arguments: widget.technicianId);
    }
  }

  Future<void> _openMap() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const MapLocationPickerScreen()),
    );
    if (result != null && mounted) {
      setState(() {
        _areaC.text = result['name'] as String;
        _lat = result['lat'] as double;
        _lng = result['lng'] as double;
      });
    }
  }

  Future<void> _next() async {
    final auth = context.read<AuthProvider>();
    auth.clearError();

    final ok = await auth.registerTechnicianStep3(
      technicianId: widget.technicianId,
      area: _areaC.text.trim(),
      latitude: _lat,
      longitude: _lng,
    );
    if (!mounted) return;

    if (ok) {
      Navigator.pushReplacementNamed(context, AppRoutes.registerStep4,
          arguments: widget.technicianId);
    } else if (auth.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.errorMessage!), backgroundColor: AppTheme.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);

    return RegisterStepScaffold(
      step: 3,
      total: 5,
      title: 'Where do you work?',
      subtitle: 'Customers near this area will find you first.',
      isLoading: auth.isLoading,
      onNext: _areaC.text.trim().isNotEmpty ? _next : null,
      onBack: () => Navigator.pushReplacementNamed(context, AppRoutes.registerStep2,
          arguments: widget.technicianId),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _areaC,
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => setState(() {
              // typed manually: drop old map coordinates, backend will geocode
              _lat = null;
              _lng = null;
            }),
            decoration: InputDecoration(
              hintText: 'e.g. Sinza, Dar es Salaam',
              prefixIcon: const Icon(Icons.location_on_outlined),
              suffixIcon: IconButton(
                icon: Icon(Icons.map_rounded, color: theme.colorScheme.primary),
                tooltip: 'Pick on map',
                onPressed: _openMap,
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (_lat != null && _lng != null)
            Row(
              children: [
                const Icon(Icons.check_circle, size: 16, color: Colors.green),
                const SizedBox(width: 6),
                Text('Location set on map',
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.green)),
              ],
            )
          else
            Text('Tip: use the map icon for the most accurate location.',
                style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}