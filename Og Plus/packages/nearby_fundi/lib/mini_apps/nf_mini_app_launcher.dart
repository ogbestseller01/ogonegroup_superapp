// packages/nearby_fundi/lib/mini_apps/nf_mini_app_launcher.dart
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'nf_mini_app.dart';

/// Opens mini apps from inside NearbyFundi.
///
/// Mirrors the super app's AppLauncher: [_busy] blocks a second tap while a
/// mini app is opening/closing so its navigator key is never attached twice.
class NfMiniAppLauncher {
  NfMiniAppLauncher._();

  static bool _busy = false;

  static Future<void> open(BuildContext context, NfMiniApp app) async {
    if (app.comingSoon) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text('${app.label(l10n)} ${l10n.comingSoon}'),
          behavior: SnackBarBehavior.floating,
        ));
      return;
    }
    if (_busy) return;
    _busy = true;

    // Root navigator -> above NearbyFundi's own nested MaterialApp.
    final navigator = Navigator.of(context, rootNavigator: true);

    try {
      await navigator.push<void>(
        MaterialPageRoute<void>(builder: app.builder),
      );
      // Let the pop animation finish so the mini app's key is released.
      await Future<void>.delayed(const Duration(milliseconds: 450));
    } finally {
      _busy = false;
    }
  }
}