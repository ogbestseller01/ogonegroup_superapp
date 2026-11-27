// lib/screens/auth/otp_verification_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import 'registration_success_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  /// Used as the identifier for /verify-otp and /resend-otp.
  final String email;

  /// Where the backend actually sent the code (phone or email). Optional.
  final String? sentTo;

  /// 'sms' | 'email' | 'none' (from the register response). Optional.
  final String? channel;

  /// false when the backend created the account but delivery failed.
  final bool otpSent;

  const OtpVerificationScreen({
    super.key,
    required this.email,
    this.sentTo,
    this.channel,
    this.otpSent = true,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  static const int _resendCooldown = 60; // matches backend 1-minute rule

  final _codeController = TextEditingController();
  final _focusNode = FocusNode();

  Timer? _timer;
  int _secondsLeft = _resendCooldown;
  bool _isLoading = false;
  bool _resending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startCountdown();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codeController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _timer?.cancel();
    _secondsLeft = _resendCooldown;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_secondsLeft <= 1) {
        t.cancel();
        setState(() => _secondsLeft = 0);
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  String _formatTime(int s) =>
      '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';

  String _mask(String v) {
    if (v.contains('@')) {
      final parts = v.split('@');
      final name = parts.first;
      final visible = name.length <= 2 ? name.substring(0, 1) : name.substring(0, 2);
      return '$visible***@${parts.last}';
    }
    if (v.length > 7) {
      return '${v.substring(0, 4)}••••${v.substring(v.length - 3)}';
    }
    return v;
  }

  String _infoText(AppLocalizations l10n) {
    if (!widget.otpSent || widget.channel == 'none') {
      return l10n.couldNotSendCodeAuto;
    }
    final to = _mask(widget.sentTo ?? widget.email);
    if (widget.channel == 'sms') {
      return l10n.codeSentBySms(to);
    }
    return l10n.codeSentByEmail(to);
  }

  void _snack(String message, {bool error = true}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: error ? AppTheme.error : AppTheme.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          margin: const EdgeInsets.all(16),
        ),
      );
  }

  Future<void> _handleVerify() async {
    if (_isLoading) return;

    final l10n = AppLocalizations.of(context)!;
    final code = _codeController.text.trim();
    if (code.length != 6) {
      setState(() => _error = l10n.enterOtp);
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final auth = context.read<AuthProvider>();
    auth.clearError();

    final ok = await auth.verifyOtp(widget.email, code);
    if (!mounted) return;

    if (ok) {
      // Account verified + session saved by AuthProvider -> success splash,
      // which then opens the dashboard as a logged-in user.
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const RegistrationSuccessScreen()),
            (_) => false,
      );
      return;
    }

    final message = auth.errorMessage ??
        AppLocalizations.of(context)!.invalidOrExpiredCode;
    auth.clearError();

    setState(() {
      _isLoading = false;
      _error = message;
    });
    _codeController.clear();
    _focusNode.requestFocus();
  }

  Future<void> _handleResend() async {
    if (_secondsLeft > 0 || _resending || _isLoading) return;

    setState(() {
      _resending = true;
      _error = null;
    });

    final auth = context.read<AuthProvider>();
    auth.clearError();

    final ok = await auth.resendOtp(widget.email);
    if (!mounted) return;

    setState(() => _resending = false);

    final l10n = AppLocalizations.of(context)!;
    if (ok) {
      _codeController.clear();
      _startCountdown();
      setState(() {});
      _snack(l10n.newCodeSent, error: false);
      _focusNode.requestFocus();
    } else {
      _snack(auth.errorMessage ?? l10n.couldNotResendCode);
      auth.clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isSmall = MediaQuery.of(context).size.width < 380;
    final accent = isDark ? AppTheme.secondary : AppTheme.primary;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [AppTheme.darkBackground, AppTheme.darkSurface, AppTheme.navy900]
                : [AppTheme.scaffoldLight, AppTheme.navy50, AppTheme.light],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: -80,
                right: -60,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primary.withOpacity(isDark ? 0.12 : 0.06),
                  ),
                ),
              ),
              Positioned(
                bottom: -100,
                left: -80,
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primary.withOpacity(isDark ? 0.08 : 0.05),
                  ),
                ),
              ),

              // Back button
              Positioned(
                top: 8,
                left: 8,
                child: IconButton(
                  onPressed: _isLoading ? null : () => Navigator.maybePop(context),
                  icon: Icon(Icons.arrow_back_rounded,
                      color: theme.colorScheme.onSurface),
                ),
              ),

              Center(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmall ? 18 : 24,
                    vertical: 20,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.fromLTRB(
                          isSmall ? 22 : 28, 28, isSmall ? 22 : 28, 28),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkSurface : Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(isDark ? 0.35 : 0.08),
                            blurRadius: 40,
                            offset: const Offset(0, 16),
                            spreadRadius: -4,
                          ),
                          BoxShadow(
                            color: AppTheme.primary.withOpacity(0.06),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: AutofillGroup(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Center(
                              child: Container(
                                width: 88,
                                height: 88,
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withOpacity(0.09),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.verified_rounded,
                                    size: 42, color: accent),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              l10n.verificationCode,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: isSmall ? 26 : 28,
                                fontWeight: FontWeight.w800,
                                color: theme.colorScheme.onSurface,
                                letterSpacing: -0.6,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _infoText(l10n),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
                                height: 1.4,
                                color: widget.otpSent
                                    ? theme.hintColor
                                    : Colors.orange.shade700,
                              ),
                            ),
                            const SizedBox(height: 28),

                            // Code field (paste + SMS autofill friendly)
                            TextField(
                              controller: _codeController,
                              focusNode: _focusNode,
                              enabled: !_isLoading,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              maxLength: 6,
                              autofillHints: const [AutofillHints.oneTimeCode],
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 14,
                                color: theme.colorScheme.onSurface,
                              ),
                              decoration: InputDecoration(
                                counterText: '',
                                hintText: '······',
                                hintStyle: TextStyle(
                                  fontSize: 30,
                                  letterSpacing: 14,
                                  color: theme.hintColor.withOpacity(0.5),
                                ),
                                errorText: _error,
                                errorMaxLines: 3,
                                filled: true,
                                fillColor: isDark
                                    ? Colors.white.withOpacity(0.05)
                                    : AppTheme.navy50,
                                contentPadding: const EdgeInsets.only(
                                    left: 14, top: 18, bottom: 18),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: accent, width: 2),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                      color: AppTheme.error, width: 1.5),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                      color: AppTheme.error, width: 2),
                                ),
                              ),
                              onChanged: (v) {
                                if (_error != null) setState(() => _error = null);
                                if (v.length == 6) _handleVerify(); // auto-submit
                              },
                              onSubmitted: (_) => _handleVerify(),
                            ),
                            const SizedBox(height: 28),

                            // Verify
                            SizedBox(
                              height: 54,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleVerify,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primary,
                                  disabledBackgroundColor:
                                  AppTheme.primary.withOpacity(0.55),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.6,
                                    valueColor:
                                    AlwaysStoppedAnimation(Colors.white),
                                  ),
                                )
                                    : Text(
                                  l10n.verifyOtp,
                                  style: const TextStyle(
                                    fontSize: 16.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),

                            // Resend
                            Center(
                              child: _secondsLeft > 0
                                  ? Text(
                                l10n.resendCodeIn(_formatTime(_secondsLeft)),
                                style: TextStyle(
                                    color: theme.hintColor, fontSize: 14.5),
                              )
                                  : TextButton(
                                onPressed:
                                (_resending || _isLoading) ? null : _handleResend,
                                child: _resending
                                    ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                )
                                    : Text(
                                  l10n.resendCode,
                                  style: TextStyle(
                                    color: accent,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),

                            // Wrong details
                            Center(
                              child: TextButton(
                                onPressed:
                                _isLoading ? null : () => Navigator.maybePop(context),
                                child: Text(
                                  l10n.changeMyDetails,
                                  style: TextStyle(
                                    color: theme.hintColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
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
}