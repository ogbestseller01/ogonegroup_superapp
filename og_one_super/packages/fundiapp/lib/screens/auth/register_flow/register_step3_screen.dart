// lib/screens/auth/register_flow/register_step3_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../config/app_routes.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/storage_service.dart';
import '../../../widgets/register_shell.dart';

class RegisterStep3Screen extends StatefulWidget {
  final int draftId;
  const RegisterStep3Screen({super.key, required this.draftId});

  @override
  State<RegisterStep3Screen> createState() => _RegisterStep3ScreenState();
}

enum _ScanPhase { idle, scanning, success, failed }

class _RegisterStep3ScreenState extends State<RegisterStep3Screen> {
  _ScanPhase _phase = _ScanPhase.idle;
  String? _serverError;
  bool _isSubmitting = false;
  String? _cachedFingerprintData;

  Future<void> _onFingerPressed() async {
    if (_isSubmitting ||
        _phase == _ScanPhase.scanning ||
        _phase == _ScanPhase.success) {
      return;
    }

    await HapticFeedback.heavyImpact();

    setState(() {
      _phase = _ScanPhase.scanning;
      _serverError = null;
    });

    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    await HapticFeedback.mediumImpact();

    final deviceId = await StorageService.getOrCreateDeviceId();
    _cachedFingerprintData = [
      'method=kiganja_ink_simulation',
      'device=$deviceId',
      'verified_at=${DateTime.now().toUtc().toIso8601String()}',
    ].join('|');

    if (!mounted) return;
    setState(() => _phase = _ScanPhase.success);
  }

  Future<void> _submitCapturedFingerprint() async {
    if (_cachedFingerprintData == null) return;

    setState(() => _isSubmitting = true);

    final auth = context.read<AuthProvider>();
    final ok = await auth.registerTechnicianStep3(
      fingerprintData: _cachedFingerprintData!,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (ok) {
      Navigator.of(context).pushReplacementNamed(
        AppRoutes.registerStep4,
        arguments: {'draftId': widget.draftId},
      );
    } else {
      setState(() {
        _phase = _ScanPhase.failed;
        _serverError = auth.errorMessage;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final p = RegPalette.of(context);

    final ink = p.isDark ? const Color(0xFF9575CD) : const Color(0xFF4A148C);
    final scanning = _phase == _ScanPhase.scanning;
    final success = _phase == _ScanPhase.success;
    final failed = _phase == _ScanPhase.failed;

    return RegisterShell(
      step: 3,
      total: 6,
      title: l10n.regFingerprintTitle,
      subtitle: success
          ? l10n.regFingerprintDescDone
          : l10n.regFingerprintDescIdle,
      showNext: false,
      isLoading: false,
      backEnabled: !(_isSubmitting || scanning),
      bottom: _buildAction(l10n, ink),
      child: Column(
        children: [
          Chip(
            backgroundColor: p.field,
            side: BorderSide.none,
            avatar: Icon(success ? Icons.verified_rounded : Icons.touch_app_rounded,
                size: 18, color: success ? ink : p.link),
            label: Text(
              success ? l10n.regFingerprintChipDone : l10n.regFingerprintChipIdle,
              style: TextStyle(color: p.text, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            success ? l10n.regFingerprintHeadDone : l10n.regFingerprintHeadIdle,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700, color: p.text),
          ),
          const SizedBox(height: 24),
          _buildStamp(theme, p, ink),
          if (failed) ...[
            const SizedBox(height: 16),
            Text(
              _serverError ?? l10n.regFingerprintSaveFailed,
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildStamp(ThemeData theme, RegPalette p, Color ink) {
    final scanning = _phase == _ScanPhase.scanning;
    final success = _phase == _ScanPhase.success;
    final failed = _phase == _ScanPhase.failed;

    final active = success
        ? ink
        : failed
        ? theme.colorScheme.error
        : p.link;

    return GestureDetector(
      onTapDown: (_) => _onFingerPressed(),
      child: SizedBox(
        width: 220,
        height: 220,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (scanning)
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.85, end: 1.0),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeInOut,
                builder: (_, scale, child) =>
                    Transform.scale(scale: scale, child: child),
                child: Container(
                  width: 210,
                  height: 210,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: ink.withOpacity(0.5), width: 5),
                  ),
                ),
              ),
            Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (scanning || success)
                    ? ink.withOpacity(0.55)
                    : active.withOpacity(0.12),
                border: Border.all(color: active, width: 4),
                boxShadow: (scanning || success)
                    ? [
                  BoxShadow(
                      color: ink.withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 6)
                ]
                    : const [],
              ),
              child: Icon(
                success
                    ? Icons.thumb_up_alt_rounded
                    : scanning
                    ? Icons.fingerprint
                    : Icons.touch_app_rounded,
                size: 85,
                color: (success || scanning) ? Colors.white : active,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAction(AppLocalizations l10n, Color ink) {
    if (_isSubmitting) {
      return const FilledButton(
        onPressed: null,
        child: SizedBox(
          height: 22,
          width: 22,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        ),
      );
    }

    if (_phase == _ScanPhase.scanning) {
      return FilledButton.icon(
        onPressed: null,
        icon: const SizedBox(
          height: 18,
          width: 18,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        ),
        label: Text(l10n.regFingerprintScanning),
      );
    }

    if (_phase == _ScanPhase.success) {
      return FilledButton.icon(
        onPressed: _submitCapturedFingerprint,
        style: FilledButton.styleFrom(
          backgroundColor: ink,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
        ),
        icon: const Icon(Icons.arrow_forward_rounded),
        label: Text(l10n.regFingerprintSubmit),
      );
    }

    return FilledButton.icon(
      onPressed: _onFingerPressed,
      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
      icon: const Icon(Icons.fingerprint),
      label: Text(_phase == _ScanPhase.failed
          ? l10n.regFingerprintRetry
          : l10n.regFingerprintStamp),
    );
  }
}