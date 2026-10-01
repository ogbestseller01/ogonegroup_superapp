import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

import '../../config/app_routes.dart';
import '../../l10n/app_localizations.dart';
import '../../models/payment_method.dart';
import '../../models/rate_card.dart';
import '../../providers/subscription_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/loading_overlay.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  PaymentMethod? _selectedMethod;
  final TextEditingController _referenceController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  File? _paymentProof;
  bool _isSubmitting = false;
  late RateCard _selectedCard;
  bool _isLoading = true;
  String? _error;

  bool _instructionsShown = false;
  bool _isPaymentDetailsExpanded = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPaymentMethods();
    });
  }

  Future<void> _loadPaymentMethods() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final provider = context.read<SubscriptionProvider>();
      await provider.loadPaymentMethods();

      if (provider.paymentMethods.isEmpty) {
        setState(() {
          _error = 'No payment methods available. Please try again.';
        });
      } else {
        setState(() {
          _error = null;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load payment methods: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    try {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is RateCard) {
        _selectedCard = args;
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) Navigator.pop(context);
        });
      }
    } catch (e) {
      debugPrint('❌ Error getting arguments: $e');
    }
  }

  @override
  void dispose() {
    _referenceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickProofImage() async {
    try {
      final picker = ImagePicker();
      final result = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      if (result != null) {
        setState(() => _paymentProof = File(result.path));
      }
    } catch (e) {
      debugPrint('❌ Pick image error: $e');
    }
  }

  // ============================================================
  // PAYMENT INSTRUCTIONS WIDGET
  // ============================================================
  Widget _buildPaymentInstructionsWidget(BuildContext context, PaymentMethod method) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getMethodBgColor(method.slug),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getMethodColor(method.slug).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getMethodColor(method.slug).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: _getMethodIconWidget(method.slug, size: 24),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pay with ${method.name}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _getMethodColor(method.slug),
                      ),
                    ),
                    Text(
                      'Follow the instructions below',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _selectedMethod = null;
                    _isPaymentDetailsExpanded = false;
                  });
                },
                icon: Icon(
                  Icons.close,
                  color: Colors.grey.shade600,
                  size: 20,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: _getMethodColor(method.slug),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Payment Instructions',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _getMethodColor(method.slug),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '1. Send exactly ${_selectedCard.formattedPrice} to:',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_getMethodDisplayName(method.slug)}:',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  method.phoneNumber,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _getMethodColor(method.slug),
                  ),
                ),
                if (method.accountName != null && method.accountName!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Account: ${method.accountName}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '2. Enter the payment reference in the field below',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            '3. Upload a screenshot of your payment confirmation',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            '4. Submit your subscription for approval',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Please complete the payment before submitting. Your subscription will be approved after payment confirmation.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.orange.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _instructionsShown = true;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'I Understand, Continue',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SUBMIT WITH CONFIRMATION - CENTERED DIALOG
  // ============================================================
  Future<void> _submitSubscription() async {
    final l10n = AppLocalizations.of(context)!;

    if (_selectedMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.choosePaymentMethod), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    if (_paymentProof == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.uploadPaymentProof), backgroundColor: Colors.orange, behavior: SnackBarBehavior.floating),
      );
      return;
    }

    // ✅ Centered Confirmation Dialog
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        elevation: 8,
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Warning Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange,
                  size: 48,
                ),
              ),
              const SizedBox(height: 16),
              // Title
              Text(
                'Confirm Submission',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade700,
                ),
              ),
              const SizedBox(height: 12),
              // Confirmation message
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'You are about to submit a subscription request for:',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Plan Details
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Plan: ${_selectedCard.name}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text('Amount: ${_selectedCard.formattedPrice}'),
                    const SizedBox(height: 4),
                    Text('Payment Method: ${_selectedMethod!.name}'),
                    if (_referenceController.text.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Reference: ${_referenceController.text.trim()}',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Warning message
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Please ensure you have sent the payment before submitting.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: Colors.grey[300]!,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: const Text(
                        'Confirm & Submit',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true) return;

    // Submit
    setState(() => _isSubmitting = true);
    final provider = context.read<SubscriptionProvider>();
    final response = await provider.createSubscription(
      rateCardId: _selectedCard.id,
      paymentMethodId: _selectedMethod!.id,
      paymentProof: _paymentProof,
      paymentReference: _referenceController.text.trim().isNotEmpty ? _referenceController.text.trim() : null,
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (response.success) {
      _showSuccessDialog(context, l10n);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.message), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
      );
    }
  }

  // ============================================================
  // SUCCESS DIALOG - CENTERED
  // ============================================================
  void _showSuccessDialog(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        elevation: 8,
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 48,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.subscriptionCreated,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  children: [
                    Text(
                      l10n.subscriptionCreatedMessage,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[700],
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.waitForApproval,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pushReplacementNamed(context, AppRoutes.home);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    l10n.goToDashboard,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HELPER METHODS
  // ============================================================
  Widget _getMethodIconWidget(String slug, {double size = 40}) {
    String assetPath;
    switch (slug.toLowerCase()) {
      case 'mpesa':
      case 'm-pesa':
      case 'm-pesa-lipa-number':
        assetPath = 'assets/icons/mpesa.png';
        break;
      case 'airtel':
      case 'airtel-money':
        assetPath = 'assets/icons/airtel.png';
        break;
      case 'mixx-by-yas':
      case 'mix_by_yas':
      case 'mixx':
        assetPath = 'assets/icons/mixx_by_yas.png';
        break;
      default:
        return Icon(Icons.payment, size: size, color: Colors.grey.shade600);
    }
    return Image.asset(assetPath, width: size, height: size,
      errorBuilder: (context, error, stackTrace) => Icon(Icons.payment, size: size, color: Colors.grey.shade600),
    );
  }

  Color _getMethodColor(String slug) {
    final s = slug.toLowerCase();
    if (s.contains('mpesa') || s.contains('m-pesa')) return Colors.green.shade700;
    if (s.contains('airtel')) return Colors.red.shade700;
    if (s.contains('mix') || s.contains('yas')) return Colors.orange.shade700;
    return Colors.blue.shade700;
  }

  Color _getMethodBgColor(String slug) {
    final s = slug.toLowerCase();
    if (s.contains('mpesa') || s.contains('m-pesa')) return Colors.green.shade50;
    if (s.contains('airtel')) return Colors.red.shade50;
    if (s.contains('mix') || s.contains('yas')) return Colors.orange.shade50;
    return Colors.blue.shade50;
  }

  String _getMethodDisplayName(String slug) {
    final s = slug.toLowerCase();
    if (s.contains('mpesa') || s.contains('m-pesa')) return 'M-Pesa';
    if (s.contains('airtel')) return 'Airtel Money';
    if (s.contains('mix') || s.contains('yas')) return 'Mix by Yas';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final provider = context.watch<SubscriptionProvider>();

    if (_selectedCard == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text('No plan selected. Please go back and choose a plan.', textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    if (_isLoading || provider.isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.paymentMethods),
          elevation: 0,
          backgroundColor: theme.scaffoldBackgroundColor,
          foregroundColor: theme.colorScheme.onSurface,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: theme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading payment methods...'),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.paymentMethods),
          elevation: 0,
          backgroundColor: theme.scaffoldBackgroundColor,
          foregroundColor: theme.colorScheme.onSurface,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: theme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(_error!, style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _loadPaymentMethods,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.paymentMethods),
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: theme.primaryColor,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isSubmitting,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Selected Plan Summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.primaryColor.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.selectedPlan, style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
                        const SizedBox(height: 4),
                        Text(_selectedCard!.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Text(_selectedCard!.formattedPrice, style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold, color: theme.primaryColor,
                    )),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Text(l10n.choosePaymentMethod, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              ...provider.paymentMethods.map((method) => _buildMethodItem(
                context,
                method,
                _selectedMethod?.id == method.id,
                    () {
                  setState(() {
                    if (_selectedMethod?.id == method.id) {
                      _selectedMethod = null;
                      _isPaymentDetailsExpanded = false;
                    } else {
                      _selectedMethod = method;
                      _isPaymentDetailsExpanded = true;
                    }
                  });
                },
              )).toList(),

              const SizedBox(height: 24),

              if (_selectedMethod != null && !_instructionsShown)
                _buildPaymentInstructionsWidget(context, _selectedMethod!),

              if (_selectedMethod != null && _instructionsShown) ...[
                InkWell(
                  onTap: () {
                    setState(() {
                      _isPaymentDetailsExpanded = !_isPaymentDetailsExpanded;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _isPaymentDetailsExpanded
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                              color: _getMethodColor(_selectedMethod!.slug),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Pay with ${_selectedMethod!.name}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: _getMethodColor(_selectedMethod!.slug),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getMethodColor(_selectedMethod!.slug).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _selectedCard.formattedPrice,
                            style: TextStyle(
                              color: _getMethodColor(_selectedMethod!.slug),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                if (_isPaymentDetailsExpanded)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _getMethodBgColor(_selectedMethod!.slug),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getMethodColor(_selectedMethod!.slug).withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: _getMethodColor(_selectedMethod!.slug)),
                            const SizedBox(width: 8),
                            Text(
                              'Payment Details',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: _getMethodColor(_selectedMethod!.slug),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _getMethodIconWidget(_selectedMethod!.slug, size: 24),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${_getMethodDisplayName(_selectedMethod!.slug)}: ${_selectedMethod!.phoneNumber}',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: _getMethodColor(_selectedMethod!.slug),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_selectedMethod!.accountName != null && _selectedMethod!.accountName!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '${l10n.account}: ${_selectedMethod!.accountName}',
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                            ),
                          ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, size: 16, color: Colors.orange.shade700),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Send exactly ${_selectedCard.formattedPrice} to the number above',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.orange.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
              ],

              Text(l10n.paymentReference, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: _referenceController,
                decoration: InputDecoration(
                  hintText: l10n.paymentReferenceHint,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                ),
              ),
              const SizedBox(height: 16),

              Text(l10n.notes, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: l10n.notesHint,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                ),
              ),
              const SizedBox(height: 16),

              _buildProofUpload(context, l10n),
              const SizedBox(height: 24),

              CustomButton(
                text: l10n.submitSubscription,
                onPressed: _selectedMethod != null && _paymentProof != null && _instructionsShown ? _submitSubscription : null,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMethodItem(BuildContext context, PaymentMethod method, bool isSelected, VoidCallback onTap) {
    final theme = Theme.of(context);
    final color = _getMethodColor(method.slug);
    final bgColor = _getMethodBgColor(method.slug);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: isSelected ? 2 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isSelected ? color : Colors.transparent, width: 2),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isSelected ? color.withOpacity(0.15) : bgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(child: _getMethodIconWidget(method.slug, size: 28)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(method.name, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                    Text(method.formattedPhone, style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
                  ],
                ),
              ),
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? color : Colors.transparent,
                  border: Border.all(color: isSelected ? color : Colors.grey.shade400, width: 2),
                ),
                child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 14) : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProofUpload(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.uploadPaymentProof, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickProofImage,
          child: Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _paymentProof == null ? Colors.grey.shade300 : Colors.green, width: 2),
            ),
            child: _paymentProof != null
                ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(_paymentProof!, fit: BoxFit.cover))
                : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cloud_upload_outlined, size: 40, color: theme.hintColor),
                const SizedBox(height: 8),
                Text(l10n.tapToUpload, style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor)),
                Text(l10n.paymentProofFormats, style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
              ],
            ),
          ),
        ),
        if (_paymentProof != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('File: ${_paymentProof!.path.split('/').last}', style: theme.textTheme.bodySmall?.copyWith(color: Colors.green)),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => setState(() => _paymentProof = null),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
      ],
    );
  }
}