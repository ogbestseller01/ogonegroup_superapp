// packages/nearby_fundi/lib/mini_apps/nf_mini_apps.dart
import 'package:flutter/material.dart';
import 'package:fundiapp_sdk/fundi_app_mini.dart';

import 'nf_mini_app.dart';

/// Registry of mini apps available inside NearbyFundi.
/// Add a new entry here to expose another mini app in the drawer.
class NfMiniApps {
  NfMiniApps._();

  static final NfMiniApp fundiApp = NfMiniApp(
    slug: 'fundiapp',
    icon: Icons.handyman_rounded,
    color: const Color(0xFFF2B93B),
    label: (l10n) => l10n.becomeFundi,
    // Opens straight on the Fundi login screen.
    builder: (_) =>
    const FundiMiniApp(initialRoute: FundiMiniApp.loginRoute),
  );

  static final List<NfMiniApp> all = [fundiApp];

  static NfMiniApp? bySlug(String slug) {
    final s = slug.trim().toLowerCase();
    for (final app in all) {
      if (app.slug == s) return app;
    }
    return null;
  }
}