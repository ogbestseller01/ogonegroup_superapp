// lib/screens/auth/register_flow/register_review_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/app_routes.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/register_shell.dart';

class RegisterReviewScreen extends StatefulWidget {
  final int draftId;
  final Map<String, dynamic>? extra;
  const RegisterReviewScreen({
    super.key,
    required this.draftId,
    this.extra,
  });

  @override
  State<RegisterReviewScreen> createState() => _RegisterReviewScreenState();
}

class _RegisterReviewScreenState extends State<RegisterReviewScreen> {
  bool _isLoadingCheck = true;
  Map<String, dynamic> _status = {};

  @override
  void initState() {
    super.initState();
    _checkStepAccess();
  }

  Future<void> _restart() async {
    final auth = context.read<AuthProvider>();
    await auth.abandonDraft();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
        context, AppRoutes.registerStep1, (_) => false);
  }

  Future<void> _checkStepAccess() async {
    final auth = context.read<AuthProvider>();

    if (!auth.hasRegistrationToken) {
      await _restart();
      return;
    }

    final res = await auth.api.getRegistrationStatus(widget.draftId);
    if (!mounted) return;

    final data = (res.success && res.data is Map)
        ? Map<String, dynamic>.from(res.data as Map)
        : null;

    if (data == null || data['can_proceed'] == false) {
      await _restart();
      return;
    }

    final step = (data['registration_step'] as num?)?.toInt() ?? 0;
    if (step < 5) {
      final route = step <= 1
          ? AppRoutes.registerStep2
          : step == 2
          ? AppRoutes.registerStep3
          : step == 3
          ? AppRoutes.registerStep4
          : AppRoutes.registerStep5;
      Navigator.pushReplacementNamed(context, route,
          arguments: widget.draftId);
      return;
    }

    setState(() {
      _isLoadingCheck = false;
      _status = data;
    });
  }

  Future<void> _submitRegistration() async {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.read<AuthProvider>();
    auth.clearError();

    final success = await auth.submitTechnicianRegistration();
    if (!mounted) return;

    if (success) {
      final p = RegPalette.of(context);
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: p.card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          icon: const Icon(Icons.check_circle_rounded,
              color: Colors.green, size: 52),
          title: Text(l10n.regSubmittedTitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: p.text, fontWeight: FontWeight.w800)),
          content: Text(
            l10n.regSubmittedBody,
            textAlign: TextAlign.center,
            style: TextStyle(color: p.muted),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            FilledButton(
              onPressed: () => Navigator.pushNamedAndRemoveUntil(
                  context, AppRoutes.home, (_) => false),
              child: Text(l10n.regContinue),
            ),
          ],
        ),
      );
      return;
    }

    // Draft discarded (token expired) → nothing left to retry here.
    if (!auth.hasRegistrationToken) {
      regSnack(context, auth.errorMessage ?? l10n.regSessionExpired,
          error: true);
      await _restart();
      return;
    }

    regSnack(context, auth.errorMessage ?? l10n.regSubmitFailed, error: true);
  }

  Widget _checkRow(RegPalette p, {required bool done, required String label}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            done ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            size: 20,
            color: done ? Colors.green : p.muted,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14.5,
                color: done ? p.text : p.muted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _panel(RegPalette p, {required Widget child}) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: p.field,
      borderRadius: BorderRadius.circular(16),
    ),
    child: child,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.watch<AuthProvider>();
    final p = RegPalette.of(context);

    final step = (_status['registration_step'] as num?)?.toInt() ?? 0;
    final fingerprint = _status['fingerprint_enrolled'] == true;
    final face = _status['face_enrolled'] == true;
    final kin = widget.extra?['nextOfKinName'] as String?;
    final allComplete = step >= 5 && fingerprint && face;
    final busy = auth.isLoading || _isLoadingCheck;

    void goBack() => Navigator.pushReplacementNamed(
      context,
      AppRoutes.registerStep5,
      arguments: widget.draftId,
    );

    return RegisterShell(
      step: 6,
      total: 6,
      title: l10n.regReviewTitle,
      subtitle: l10n.regReviewHeading,
      isLoading: busy,
      onNext: (allComplete && !busy) ? _submitRegistration : null,
      nextLabel: l10n.regSubmit,
      onBack: auth.isLoading ? null : goBack,
      backEnabled: !auth.isLoading,
      bottom: OutlinedButton(
        onPressed: auth.isLoading ? null : goBack,
        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
        child: Text(l10n.regBackToStep5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _panel(
            p,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.regCompletedSteps,
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: p.text)),
                const SizedBox(height: 8),
                _checkRow(p, done: step >= 1, label: l10n.regAccountCreated),
                _checkRow(p, done: step >= 2, label: l10n.regIdentityVerified),
                _checkRow(p,
                    done: fingerprint, label: l10n.regFingerprintEnrolled),
                _checkRow(p, done: face, label: l10n.regFaceEnrolled),
                _checkRow(p, done: step >= 5, label: l10n.regKinSaved),
              ],
            ),
          ),
          if (kin != null && kin.isNotEmpty) ...[
            const SizedBox(height: 14),
            _panel(
              p,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.regKinTitle,
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: p.text)),
                  const SizedBox(height: 8),
                  Text('${l10n.name}: $kin', style: TextStyle(color: p.text)),
                  const SizedBox(height: 2),
                  Text(
                    '${l10n.phone}: ${widget.extra?['nextOfKinPhone'] ?? '-'}',
                    style: TextStyle(color: p.text),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${l10n.regRelationship}: '
                        '${widget.extra?['nextOfKinRelationship'] ?? '-'}',
                    style: TextStyle(color: p.text),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}