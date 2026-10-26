import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fundiapp_sdk/fundi_app_mini.dart';
import 'package:nearbyfundi_sdk/nearby_fundi_mini.dart';
import 'package:provider/provider.dart';

import '../../../config/app_strings.dart';
import '../../../config/app_theme.dart';
import '../../../models/mini_app.dart';
import '../../../services/mini_app_service.dart';
import '../../scanner/qr_scanner_screen.dart';
import 'app_usage_provider.dart';

/// Opens mini apps and the QR scanner for every tab.
///
/// Both mini apps share one global navigatorKey, so opening one twice would
/// throw "Multiple widgets used the same GlobalKey". [_busy] blocks a second
/// tap while a mini app (or the scanner) is opening / closing.
class AppLauncher {
  AppLauncher._();

  static bool _busy = false;

  static void snack(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppTheme.primary,
          behavior: SnackBarBehavior.floating,
          elevation: 6,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        ),
      );
  }

  static Future<void> open(BuildContext context, MiniApp app) async {
    final t = context.t;
    FocusScope.of(context).unfocus();

    if (app.isComingSoon) return snack(context, t.comingSoonMessage);

    final Widget? page = switch (app.slug) {
      'fundiapp' => const FundiAppMiniApp(),
      'nearbyfundi' => const NearbyFundiMiniApp(),
      _ => null,
    };

    if (page == null) {
      return snack(context, t.opening(t.serviceTitle(app.slug)));
    }
    if (_busy) return;
    _busy = true;

    final navigator = Navigator.of(context);
    context.read<AppUsageProvider>().markOpened(app.slug);

    try {
      await navigator.push(MaterialPageRoute(builder: (_) => page));
      // Let the pop animation finish so the shared navigatorKey is released.
      await Future<void>.delayed(const Duration(milliseconds: 450));
    } finally {
      _busy = false;
    }
  }

  /// Opens the scanner, then opens the mini app whose QR code was scanned.
  static Future<void> scan(BuildContext context) async {
    if (_busy) return;
    FocusScope.of(context).unfocus();
    _busy = true;

    String? slug;
    try {
      slug = await Navigator.of(context).push<String>(
        MaterialPageRoute(builder: (_) => const QrScannerScreen()),
      );
    } finally {
      _busy = false;
    }
    if (!context.mounted || slug == null) return;

    final app = MiniAppService.instance.bySlug(slug);
    if (app == null) {
      // Valid OG ONE code, but the server switched this app off.
      snack(context, context.t.comingSoonMessage);
      return;
    }
    // Give the scanner's pop animation time to release the camera/route.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!context.mounted) return;
    await open(context, app);
  }

  static Future<void> toggleFavorite(BuildContext context, MiniApp app) async {
    final usage = context.read<AppUsageProvider>();
    final t = context.t;
    HapticFeedback.mediumImpact();
    final nowFav = await usage.toggleFavorite(app.slug);
    if (!context.mounted) return;
    snack(context, nowFav ? t.addedFavorite : t.removedFavorite);
  }
}