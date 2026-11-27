// lib/widgets/continue_as_card.dart

import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../services/fundi_remember_store.dart';

/// "Continue as [User]" one-tap card with a cancel (X) button.
/// All text is passed in by the screen so this widget holds no language.
class ContinueAsCard extends StatelessWidget {
  final RememberedAccount account;
  final String title; // e.g. "Continue as Juma"
  final String cancelTooltip;
  final VoidCallback? onContinue;
  final VoidCallback? onSwitch;
  final bool loading;

  const ContinueAsCard({
    super.key,
    required this.account,
    required this.title,
    required this.cancelTooltip,
    required this.onContinue,
    required this.onSwitch,
    this.loading = false,
  });

  String get _initial =>
      account.name.trim().isEmpty ? '?' : account.name.trim()[0].toUpperCase();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasPhoto = account.photo != null && account.photo!.startsWith('http');
    final radius = BorderRadius.circular(18);

    return Material(
      color: isDark
          ? Colors.white.withOpacity(0.06)
          : AppTheme.primary.withOpacity(0.08),
      borderRadius: radius,
      child: Stack(
        children: [
          InkWell(
            borderRadius: radius,
            onTap: loading ? null : onContinue,
            child: Padding(
              // Right padding reserves space for the X button.
              padding: const EdgeInsets.fromLTRB(14, 14, 44, 14),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppTheme.primary,
                    backgroundImage:
                    hasPhoto ? NetworkImage(account.photo!) : null,
                    child: hasPhoto
                        ? null
                        : Text(
                      _initial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        if (account.identifier.isNotEmpty)
                          Text(
                            account.identifier,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: theme.hintColor),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  loading
                      ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  )
                      : const Icon(
                    Icons.arrow_forward_rounded,
                    color: AppTheme.primary,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 2,
            right: 2,
            child: IconButton(
              onPressed: loading ? null : onSwitch,
              tooltip: cancelTooltip,
              visualDensity: VisualDensity.compact,
              icon: Icon(
                Icons.close_rounded,
                size: 20,
                color: theme.hintColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}