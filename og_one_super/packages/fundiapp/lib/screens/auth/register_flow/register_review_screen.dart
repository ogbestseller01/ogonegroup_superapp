// lib/screens/auth/register_flow/register_review_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/app_theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../config/app_routes.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/loading_overlay.dart';
import '../../../services/storage_service.dart';

class RegisterReviewScreen extends StatefulWidget {
  final Map<String, dynamic> registrationData;
  const RegisterReviewScreen({super.key, required this.registrationData});

  @override
  State<RegisterReviewScreen> createState() => _RegisterReviewScreenState();
}

class _RegisterReviewScreenState extends State<RegisterReviewScreen> {
  bool _isLoadingCheck = false;

  @override
  void initState() {
    super.initState();
    _checkStepAccess();
  }

  Future<void> _checkStepAccess() async {
    final auth = context.read<AuthProvider>();
    final technicianId = widget.registrationData['technicianId'] as int;
    final step = await auth.getRegistrationStep(technicianId);
    if (!mounted) return;
    if (step == null) {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
      return;
    }
    // Allow if Step 4 is completed (step >= 4)
    if (step < 4) {
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.registerStep4,
        arguments: technicianId,
      );
    }
    // Otherwise stay
  }

  Future<void> _submitRegistration() async {
    final auth = context.read<AuthProvider>();
    auth.clearError();

    final success = await auth.submitTechnicianRegistration(
      widget.registrationData['technicianId'] as int,
    );
    if (!mounted) return;

    if (success) {
      await StorageService.clearTechnicianData();
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Registration Submitted!'),
          content: const Text(
            'Your account is pending admin verification. You will receive an email once approved.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
              },
              child: const Text('Go to Login'),
            ),
          ],
        ),
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
      AppRoutes.registerStep4,
      arguments: widget.registrationData['technicianId'],
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);
    final data = widget.registrationData;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Review & Submit'),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: auth.isLoading ? null : _goBack,
          tooltip: 'Back to Step 4',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: auth.isLoading ? null : _submitRegistration,
            tooltip: 'Submit',
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: auth.isLoading || _isLoadingCheck,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Please review your registration details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),

              const Text('Selected Services & Prices:', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              ...(data['services'] as List<Map<String, dynamic>>).map((s) {
                return Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Service #${s['service_id']}'),
                      Text('TZS ${s['min_price']} - TZS ${s['max_price']}'),
                    ],
                  ),
                );
              }).toList(),

              const SizedBox(height: 32),

              CustomButton(
                text: 'Submit Registration',
                onPressed: _submitRegistration,
                isLoading: auth.isLoading,
                isDisabled: auth.isLoading,
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: _goBack,
                child: const Text('Back to Step 4'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}