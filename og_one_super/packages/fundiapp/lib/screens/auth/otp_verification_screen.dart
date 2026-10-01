// otp_verification_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../config/app_routes.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/loading_overlay.dart';
import '../../l10n/app_localizations.dart';
import '../../services/storage_service.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;
  final bool redirectToStep2;
  final int? technicianId;

  const OtpVerificationScreen({
    super.key,
    required this.email,
    this.redirectToStep2 = false,
    this.technicianId,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _otpControllers =
  List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isResending = false;
  int _resendCountdown = 0;
  Timer? _timer;

  String get _otp => _otpControllers.map((c) => c.text).join();

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    for (var c in _otpControllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    setState(() => _resendCountdown = 60);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_resendCountdown > 0) {
          _resendCountdown--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  Future<void> _handleVerify() async {
    if (_otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.enterOtp),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    auth.clearError();

    final success = await auth.verifyOtp(widget.email, _otp);
    if (!mounted) return;

    if (success) {
      if (widget.redirectToStep2 && widget.technicianId != null) {
        await StorageService.saveTechnicianId(widget.technicianId!);
        await StorageService.saveTechnicianEmail(widget.email);
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.registerStep2,
          arguments: widget.technicianId,
        );
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.pushReplacementNamed(context, AppRoutes.home);
          }
        });
      }
    } else if (auth.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage!),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      auth.clearError();
    }
  }

  Future<void> _resendOtp() async {
    if (_resendCountdown > 0) return;

    setState(() => _isResending = true);
    final auth = context.read<AuthProvider>();
    auth.clearError();

    final success = await auth.resendOtp(widget.email);
    if (!mounted) return;

    setState(() => _isResending = false);

    if (success) {
      _startCountdown();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('OTP resent to ${widget.email}'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Failed to resend OTP'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      body: Consumer<AuthProvider>(
        builder: (context, auth, _) => LoadingOverlay(
          isLoading: auth.isLoading || _isResending,
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  Container(
                    width: 88,
                    height: 88,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: theme.primaryColor.withOpacity(0.12),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                      border: Border.all(
                        color: theme.dividerColor.withOpacity(0.4),
                      ),
                    ),
                    child: Image.asset(
                      'assets/images/nearbyfundi-logov2.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l10n.verificationCode,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${l10n.enterCodeSent}\n${widget.email}',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.hintColor,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 36),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(
                      6,
                          (i) => SizedBox(
                        width: 46,
                        child: TextFormField(
                          controller: _otpControllers[i],
                          focusNode: _focusNodes[i],
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          maxLength: 1,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                          decoration: InputDecoration(
                            counterText: '',
                            contentPadding:
                            const EdgeInsets.symmetric(vertical: 14),
                            filled: true,
                            fillColor: theme.colorScheme.surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onChanged: (val) {
                            if (val.isNotEmpty && i < 5) {
                              _focusNodes[i + 1].requestFocus();
                            } else if (val.isEmpty && i > 0) {
                              _focusNodes[i - 1].requestFocus();
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _resendCountdown > 0
                            ? 'Resend available in ${_resendCountdown}s'
                            : "Didn't receive the code?",
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _resendCountdown > 0 || _isResending
                            ? null
                            : _resendOtp,
                        child: Text(
                          _isResending
                              ? 'Sending...'
                              : _resendCountdown > 0
                              ? 'Wait...'
                              : 'Resend',
                          style: TextStyle(
                            color: (_resendCountdown > 0 || _isResending)
                                ? theme.hintColor
                                : theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  CustomButton(
                    text: l10n.verifyOtp,
                    onPressed: _handleVerify,
                    isLoading: auth.isLoading,
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      l10n.backToSignIn,
                      style: TextStyle(color: theme.colorScheme.primary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}