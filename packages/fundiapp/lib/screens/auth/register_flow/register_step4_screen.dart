// lib/screens/auth/register_flow/register_step4_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/app_theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/service_provider.dart';
import '../../../config/app_routes.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/loading_overlay.dart';

class RegisterStep4Screen extends StatefulWidget {
  final int technicianId;
  const RegisterStep4Screen({super.key, required this.technicianId});

  @override
  State<RegisterStep4Screen> createState() => _RegisterStep4ScreenState();
}

class _RegisterStep4ScreenState extends State<RegisterStep4Screen> {
  final Map<int, Map<String, TextEditingController>> _priceControllers = {};
  final Set<int> _selectedServiceIds = {};
  bool _isLoadingCheck = false;

  @override
  void initState() {
    super.initState();
    _checkStepAccess();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ServiceProvider>().fetchServices();
    });
  }

  Future<void> _checkStepAccess() async {
    final auth = context.read<AuthProvider>();
    final step = await auth.getRegistrationStep(widget.technicianId);
    if (!mounted) return;
    if (step == null) {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
      return;
    }
    // Allow if Step 3 is completed (step >= 3)
    if (step < 3) {
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.registerStep3,
        arguments: widget.technicianId,
      );
    }
    // Otherwise stay
  }

  @override
  void dispose() {
    for (var controllers in _priceControllers.values) {
      controllers['min']?.dispose();
      controllers['max']?.dispose();
    }
    super.dispose();
  }

  bool get _isFormValid {
    if (_selectedServiceIds.isEmpty) return false;
    for (var id in _selectedServiceIds) {
      final min = double.tryParse(_priceControllers[id]!['min']!.text.trim());
      final max = double.tryParse(_priceControllers[id]!['max']!.text.trim());
      if (min == null || max == null || min < 0 || max < 0 || max < min) {
        return false;
      }
    }
    return true;
  }

  void _toggleService(int id, bool selected) {
    setState(() {
      if (selected) {
        _selectedServiceIds.add(id);
        _priceControllers[id] = {
          'min': TextEditingController(),
          'max': TextEditingController(),
        };
      } else {
        _selectedServiceIds.remove(id);
        _priceControllers[id]?.forEach((key, c) => c.dispose());
        _priceControllers.remove(id);
      }
    });
  }

  Future<void> _nextStep() async {
    if (!_isFormValid) return;
    final auth = context.read<AuthProvider>();
    auth.clearError();

    final List<Map<String, dynamic>> services = [];
    for (var id in _selectedServiceIds) {
      services.add({
        'service_id': id,
        'min_price': double.parse(_priceControllers[id]!['min']!.text.trim()),
        'max_price': double.parse(_priceControllers[id]!['max']!.text.trim()),
      });
    }

    final success = await auth.registerTechnicianStep4(
      technicianId: widget.technicianId,
      services: services,
    );
    if (!mounted) return;
    if (success) {
      final Map<String, dynamic> reviewData = {
        'technicianId': widget.technicianId,
        'services': services,
      };
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.registerReview,
        arguments: reviewData,
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
      AppRoutes.registerStep3,
      arguments: widget.technicianId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final serviceProvider = context.watch<ServiceProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Step 4: Services & Pricing'),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: auth.isLoading ? null : _goBack,
          tooltip: 'Back to Step 3',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: (auth.isLoading || serviceProvider.isLoading || _isLoadingCheck || !_isFormValid)
                ? null
                : _nextStep,
            tooltip: 'Next',
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: auth.isLoading || serviceProvider.isLoading || _isLoadingCheck,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Select services and set your price ranges:', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),

              if (serviceProvider.isLoading)
                const Center(child: CircularProgressIndicator())
              else if (serviceProvider.services.isEmpty)
                const Center(child: Text('No services available. Please try again later.'))
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: serviceProvider.services.map((service) {
                    final isSelected = _selectedServiceIds.contains(service.id);
                    return ChoiceChip(
                      label: Text(service.name),
                      selected: isSelected,
                      onSelected: (selected) => _toggleService(service.id, selected),
                      selectedColor: theme.colorScheme.primary,
                      backgroundColor: theme.colorScheme.surface,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                      ),
                    );
                  }).toList(),
                ),

              if (_selectedServiceIds.isNotEmpty) ...[
                const SizedBox(height: 24),
                const Text('Set price ranges for selected services:', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                ..._selectedServiceIds.map((id) {
                  final service = serviceProvider.services.firstWhere((s) => s.id == id);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(service.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _priceControllers[id]!['min'],
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(
                                  labelText: 'Min Price (TZS)',
                                  prefixText: 'TZS ',
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _priceControllers[id]!['max'],
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(
                                  labelText: 'Max Price (TZS)',
                                  prefixText: 'TZS ',
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],

              const SizedBox(height: 32),

              CustomButton(
                text: 'Review & Submit',
                onPressed: _nextStep,
                isLoading: auth.isLoading || serviceProvider.isLoading,
                isDisabled: !_isFormValid || auth.isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}