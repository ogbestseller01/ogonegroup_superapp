// packages/nearby_fundi/lib/nearby_fundi_gate.dart
//
// The wall dialog shown BEFORE NearbyFundi opens. The host app (Og Plus)
// imports only this file and calls `NearbyFundiGate.open(context)` when the
// NearbyFundi tile is tapped.
//
//   Login as Customer -> opens NearbyFundi (customer app)
//   Login as Fundi    -> opens FundiApp (technician app)
//   Go Home           -> closes the dialog, user stays on the Og Plus dashboard
//
// The dialog closes first and returns a choice; navigation happens afterwards
// on the host's root navigator. So pressing back inside either app lands on
// the Og Plus dashboard, never on this dialog again.

import 'package:flutter/material.dart';
import 'package:fundiapp_sdk/fundi_app_mini.dart';

import 'nearby_fundi_mini.dart' show NearbyFundiMiniApp;

enum NearbyFundiRole { customer, fundi }

/// Override these to localise the dialog from the host app.
class NearbyFundiGateLabels {
  const NearbyFundiGateLabels({
    this.title = 'Login required',
    this.subtitle = 'Choose how you want to continue',
    this.customerTitle = 'Login as Customer',
    this.customerSubtitle = 'Book a Fundi near you',
    this.fundiTitle = 'Login as Fundi',
    this.fundiSubtitle = 'Manage jobs, requests & portfolio',
    this.goHome = 'Go Home',
  });

  final String title;
  final String subtitle;
  final String customerTitle;
  final String customerSubtitle;
  final String fundiTitle;
  final String fundiSubtitle;
  final String goHome;
}

abstract final class NearbyFundiGate {
  /// Shows the wall, then opens the chosen app and waits until it is closed.
  ///
  /// Returns `true` if an app was opened, or `false` when the user chose
  /// "Go Home" or dismissed the dialog.
  static Future<bool> open(
      BuildContext context, {
        NearbyFundiGateLabels labels = const NearbyFundiGateLabels(),
      }) async {
    final role = await showDialog<NearbyFundiRole>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => _GateDialog(labels: labels),
    );

    if (role == null || !context.mounted) return false;

    final Widget page = switch (role) {
      NearbyFundiRole.customer => const NearbyFundiMiniApp(),
      NearbyFundiRole.fundi => const FundiMiniApp(),
    };

    await Navigator.of(context, rootNavigator: true).push<void>(
      MaterialPageRoute<void>(builder: (_) => page),
    );
    return true;
  }
}

// ============================================================
// DIALOG
// ============================================================

class _GateDialog extends StatelessWidget {
  const _GateDialog({required this.labels});

  final NearbyFundiGateLabels labels;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final primary = theme.colorScheme.primary;

    void choose(NearbyFundiRole? role) => Navigator.of(context).pop(role);

    return Dialog(
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
                  color: primary.withOpacity(0.10),
                ),
                child: Icon(
                  Icons.lock_outline_rounded,
                  color: primary,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                labels.title,
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
                labels.subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 22),
              _RoleButton(
                icon: Icons.person_search_rounded,
                title: labels.customerTitle,
                subtitle: labels.customerSubtitle,
                filled: true,
                onTap: () => choose(NearbyFundiRole.customer),
              ),
              const SizedBox(height: 12),
              _RoleButton(
                icon: Icons.handyman_rounded,
                title: labels.fundiTitle,
                subtitle: labels.fundiSubtitle,
                filled: false,
                onTap: () => choose(NearbyFundiRole.fundi),
              ),
              const SizedBox(height: 6),
              TextButton.icon(
                onPressed: () => choose(null),
                icon: const Icon(Icons.home_rounded, size: 20),
                label: Text(
                  labels.goHome,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleButton extends StatelessWidget {
  const _RoleButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.filled,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final fg = filled ? Colors.white : theme.colorScheme.onSurface;

    return Material(
      color: filled ? primary : Colors.transparent,
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
                : Border.all(color: primary.withOpacity(0.5), width: 1.4),
          ),
          child: Row(
            children: [
              Icon(icon, color: filled ? Colors.white : primary, size: 26),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: fg,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: fg.withOpacity(0.75),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 15,
                color: fg.withOpacity(0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}