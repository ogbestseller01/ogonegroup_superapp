import 'package:flutter/material.dart';
import 'package:fundiapp_sdk/fundi_app_mini.dart';

// ── FIXED IMPORTS ──
import '../config/app_routes.dart';
import '../config/app_theme.dart';
// Go up two directories (../../) to reach lib/, then into l10n/
import '../../l10n/app_localizations.dart';

/// Shows the "Who's logging in?" card.
/// The dialog closes itself BEFORE navigating, so it never stays in the
/// back stack. Back from any login screen lands on Home, not on this dialog.
Future<void> showLoginRoleDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black54,
    builder: (_) => const _LoginRoleDialog(),
  );
}

class _LoginRoleDialog extends StatelessWidget {
  const _LoginRoleDialog();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    // ── FIX: Use AppLocalizations directly if the extension isn't found ──
    final t = AppLocalizations.of(context)!;

    return Dialog(
      backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 26, 22, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primary.withOpacity(0.10),
                ),
                child: const Icon(Icons.lock_outline_rounded,
                    color: AppTheme.primary, size: 28),
              ),
              const SizedBox(height: 16),
              Text(
                t.loginRequiredTitle, // <-- LOCALIZED
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: onSurface,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                t.loginChooseContinue, // <-- LOCALIZED
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 22),

              _RoleButton(
                icon: Icons.person_search_rounded,
                title: t.loginAsCustomer, // <-- LOCALIZED
                subtitle: t.loginCustomerSub, // <-- LOCALIZED
                filled: true,
                onTap: () => _goCustomer(context),
              ),
              const SizedBox(height: 12),
              _RoleButton(
                icon: Icons.handyman_rounded,
                title: t.loginAsFundi, // <-- LOCALIZED
                subtitle: t.loginFundiSub, // <-- LOCALIZED
                filled: false,
                onTap: () => _goFundi(context),
              ),
              const SizedBox(height: 6),
              TextButton.icon(
                onPressed: () => Navigator.of(context).pop(), // Go Home
                icon: const Icon(Icons.home_rounded, size: 20),
                label: Text(
                  t.goHome, // <-- LOCALIZED
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _goCustomer(BuildContext context) {
    final nav = Navigator.of(context);
    nav.pop(); // close dialog first
    nav.pushNamed(AppRoutes.login);
  }

  void _goFundi(BuildContext context) {
    final root = Navigator.of(context, rootNavigator: true);
    Navigator.of(context).pop(); // close dialog first
    root.push(
      MaterialPageRoute<void>(
        builder: (_) => const FundiMiniApp(
          initialRoute: FundiMiniApp.loginRoute,
        ),
      ),
    );
  }
}

class _RoleButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool filled;
  final VoidCallback onTap;

  const _RoleButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final fg = filled ? Colors.white : onSurface;

    return Material(
      color: filled ? AppTheme.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: filled
                ? null
                : Border.all(color: AppTheme.primary.withOpacity(0.5), width: 1.4),
          ),
          child: Row(
            children: [
              Icon(icon, color: filled ? Colors.white : AppTheme.primary, size: 26),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            color: fg)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: TextStyle(
                            fontSize: 12.5, color: fg.withOpacity(0.75))),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 15, color: fg.withOpacity(0.7)),
            ],
          ),
        ),
      ),
    );
  }
}