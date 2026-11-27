import 'package:flutter/material.dart';

import '../services/storage_service.dart';

/// "Continue as [User]" one-tap card with a cancel (X) affordance.
///
/// The whole card continues as the remembered account; the X in the
/// top-right corner cancels the remembered-account flow (calls [onSwitch],
/// which the parent wires to `forgetRemembered()` / show the normal form).
class ContinueAsCard extends StatelessWidget {
  final RememberedAccount account;
  final VoidCallback? onContinue;
  final VoidCallback? onSwitch;
  final bool loading;

  const ContinueAsCard({
    super.key,
    required this.account,
    required this.onContinue,
    required this.onSwitch,
    this.loading = false,
  });

  String _t(BuildContext c, String en, String sw) =>
      Localizations.localeOf(c).languageCode == 'sw' ? sw : en;

  String get _initial =>
      account.name.trim().isEmpty ? '?' : account.name.trim()[0].toUpperCase();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasPhoto = account.photo != null && account.photo!.startsWith('http');
    final firstName = account.name.trim().split(' ').first;
    final radius = BorderRadius.circular(18);

    return Material(
      color: isDark
          ? Colors.white.withValues(alpha: 0.06)
          : theme.primaryColor.withValues(alpha: 0.08),
      borderRadius: radius,
      child: Stack(
        children: [
          // Main "Continue as ..." tap target.
          InkWell(
            borderRadius: radius,
            onTap: loading ? null : onContinue,
            child: Padding(
              // Extra right padding reserves space for the X button.
              padding: const EdgeInsets.fromLTRB(14, 14, 44, 14),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: theme.primaryColor,
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
                          '${_t(context, 'Continue as', 'Endelea kama')} $firstName',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        if (account.email.isNotEmpty)
                          Text(
                            account.email,
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
                      : Icon(
                    Icons.arrow_forward_rounded,
                    color: theme.primaryColor,
                  ),
                ],
              ),
            ),
          ),

          // Cancel (X) — sits above the InkWell so its tap wins.
          Positioned(
            top: 2,
            right: 2,
            child: IconButton(
              onPressed: loading ? null : onSwitch,
              tooltip: _t(context, 'Cancel', 'Ghairi'),
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