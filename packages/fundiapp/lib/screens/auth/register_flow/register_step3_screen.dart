// lib/screens/auth/register_flow/register_step3_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/app_theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../config/app_routes.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/loading_overlay.dart';
import '../../map_logics/map_location_picker_screen.dart';

class RegisterStep3Screen extends StatefulWidget {
  final int technicianId;
  const RegisterStep3Screen({super.key, required this.technicianId});

  @override
  State<RegisterStep3Screen> createState() => _RegisterStep3ScreenState();
}

class _RegisterStep3ScreenState extends State<RegisterStep3Screen> {
  final _formKey = GlobalKey<FormState>();
  final _areaController = TextEditingController();
  double? _lat;
  double? _lng;
  bool _isLoadingCheck = false;

  @override
  void initState() {
    super.initState();
    _checkStepAccess();
  }

  Future<void> _checkStepAccess() async {
    final auth = context.read<AuthProvider>();
    final step = await auth.getRegistrationStep(widget.technicianId);
    if (!mounted) return;
    if (step == null) {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
      return;
    }
    // Allow if Step 2 is completed (step >= 2)
    if (step < 2) {
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.registerStep2,
        arguments: widget.technicianId,
      );
    }
    // Otherwise stay
  }

  @override
  void dispose() {
    _areaController.dispose();
    super.dispose();
  }

  bool get _isFormValid => _formKey.currentState?.validate() ?? false;

  Future<void> _openMapPicker() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const MapLocationPickerScreen()),
    );
    if (result != null && mounted) {
      setState(() {
        _areaController.text = result['name'] as String;
        _lat = result['lat'] as double;
        _lng = result['lng'] as double;
      });
    }
  }

  Future<void> _nextStep() async {
    if (!_isFormValid) return;
    final auth = context.read<AuthProvider>();
    auth.clearError();
    final success = await auth.registerTechnicianStep3(
      technicianId: widget.technicianId,
      area: _areaController.text.trim(),
      latitude: _lat,
      longitude: _lng,
    );
    if (!mounted) return;
    if (success) {
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.registerStep4,
        arguments: widget.technicianId,
      );
    } else {
      if (auth.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(auth.errorMessage!), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  void _goBack() {
    Navigator.pushReplacementNamed(
      context,
      AppRoutes.registerStep2,
      arguments: widget.technicianId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Step 3: Working Area'),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: auth.isLoading ? null : _goBack,
          tooltip: 'Back to Step 2',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: (auth.isLoading || _isLoadingCheck || !_isFormValid) ? null : _nextStep,
            tooltip: 'Next',
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: auth.isLoading || _isLoadingCheck,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            onChanged: () => setState(() {}),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _areaController,
                  decoration: InputDecoration(
                    hintText: 'Enter working area name',
                    prefixIcon: const Icon(Icons.location_on_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.map_rounded, color: theme.colorScheme.primary),
                      onPressed: _openMapPicker,
                      tooltip: 'Pick on map',
                    ),
                  ),
                  validator: (v) => v != null && v.trim().isNotEmpty ? null : 'Area is required',
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 8),
                if (_lat != null && _lng != null)
                  Text(
                    '📍 Coordinates: ${_lat!.toStringAsFixed(4)}, ${_lng!.toStringAsFixed(4)}',
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.green),
                  ),
                const SizedBox(height: 32),

                CustomButton(
                  text: 'Next →',
                  onPressed: _nextStep,
                  isLoading: auth.isLoading,
                  isDisabled: !_isFormValid || auth.isLoading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}