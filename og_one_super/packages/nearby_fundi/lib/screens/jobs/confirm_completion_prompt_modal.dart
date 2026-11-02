// lib/screens/jobs/confirm_completion_prompt_modal.dart
import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../l10n/app_localizations.dart';

class ConfirmCompletionPromptModal extends StatelessWidget {
  const ConfirmCompletionPromptModal._({
    required this.title,
    required this.body,
    required this.cancelLabel,
    required this.confirmLabel,
  });

  final String title;
  final String body;
  final String cancelLabel;
  final String confirmLabel;

  /// Opens the dialog.
  ///
  /// Localizations are resolved here, from the CALLER's context (which sits
  /// under MaterialApp/Localizations), and passed into the dialog as plain
  /// strings. The dialog itself never calls AppLocalizations.of(context), so
  /// it can never throw "Null check operator used on a null value" — even if
  /// the dialog route's context cannot see the Localizations ancestor.
  static Future<bool?> show(BuildContext context) {
    // `of` may return null if the delegate isn't visible — we don't use `!`.
    final l10n = AppLocalizations.of(context);

    return showDialog<bool>(
      context: context,
      builder: (_) => ConfirmCompletionPromptModal._(
        title: l10n?.confirmCompletionTitle ?? 'Confirm Completion',
        body: l10n?.confirmCompletionBody ??
            'Would you like to send the 6-digit verification code via SMS to complete this job?',
        cancelLabel: l10n?.cancel ?? 'Cancel',
        confirmLabel: l10n?.sendSmsCode ?? 'Send SMS Code',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.success.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.verified_user_rounded,
              color: AppTheme.success,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
      content: Text(
        body,
        style: TextStyle(
          fontSize: 14,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          height: 1.4,
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context, false),
          style: OutlinedButton.styleFrom(
            foregroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            side: BorderSide(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          child: Text(cancelLabel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.success,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: Text(
            confirmLabel,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}