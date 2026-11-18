// lib/screens/jobs/confirm_completion_modal.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/job_provider.dart';

class ConfirmCompletionModal extends StatefulWidget {
  const ConfirmCompletionModal({super.key, required this.jobId});

  final int jobId;

  static Future<bool?> show(BuildContext context, int jobId) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ConfirmCompletionModal(jobId: jobId),
    );
  }

  @override
  State<ConfirmCompletionModal> createState() => _ConfirmCompletionModalState();
}

class _ConfirmCompletionModalState extends State<ConfirmCompletionModal> {
  static const int _resendSeconds = 60;

  final TextEditingController _code = TextEditingController();
  Timer? _timer;
  int _secondsLeft = _resendSeconds;
  bool _verifying = false;
  bool _resending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _code.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _secondsLeft = _resendSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      if (_secondsLeft <= 1) {
        t.cancel();
        setState(() => _secondsLeft = 0);
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  Future<void> _verify() async {
    final l10n = AppLocalizations.of(context)!;
    final value = _code.text.trim();
    if (value.length != 6) {
      setState(() => _error = l10n.enterSixDigitCode);
      return;
    }

    final provider = context.read<JobProvider>();
    setState(() {
      _verifying = true;
      _error = null;
    });

    final ok = await provider.verifyCompletion(widget.jobId, value);
    if (!mounted) return;

    if (ok) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _verifying = false;
        _error = provider.error ?? l10n.invalidCodeTryAgain;
      });
    }
  }

  Future<void> _resend() async {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.read<JobProvider>();
    setState(() {
      _resending = true;
      _error = null;
    });

    final ok = await provider.requestCompletion(widget.jobId);
    if (!mounted) return;

    setState(() {
      _resending = false;
      if (!ok) _error = provider.error ?? l10n.couldNotResendSms;
    });
    if (ok) {
      _code.clear();
      _startCountdown();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final busy = _verifying || _resending;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    final resendLabel = _secondsLeft > 0
        ? l10n.resendIn(_secondsLeft)
        : l10n.resendCode;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: bottomInset + 20,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (busy) ...[
              LinearProgressIndicator(
                backgroundColor: Colors.transparent,
                color: colors.primary,
                minHeight: 3,
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                Icon(Icons.verified_rounded, color: colors.primary, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.confirmCompletionTitle,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.onSurface,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: busy ? null : () => Navigator.pop(context, false),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              l10n.enterSmsCodeHint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _code,
              enabled: !busy,
              autofocus: true,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 6,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 10,
                color: colors.onSurface,
              ),
              decoration: InputDecoration(
                counterText: '',
                hintText: l10n.completionCodeHint,
                errorText: _error,
                filled: true,
                fillColor: colors.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: colors.outline),
                ),
              ),
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
              onSubmitted: (_) => _verify(),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: busy ? null : () => Navigator.pop(context, false),
                  child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
                ),
                TextButton(
                  onPressed: (_secondsLeft == 0 && !busy) ? _resend : null,
                  child: Text(_resending ? l10n.sending : resendLabel),
                ),
              ],
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: busy ? null : _verify,
              style: FilledButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _verifying
                  ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colors.onPrimary,
                ),
              )
                  : Text(
                l10n.verifyAndComplete,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}