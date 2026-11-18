// packages/nearby_fundi/lib/mini_apps/nf_mini_app.dart
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// A mini app hosted INSIDE NearbyFundi (same idea as the super app's MiniApp).
class NfMiniApp {
  const NfMiniApp({
    required this.slug,
    required this.icon,
    required this.color,
    required this.label,
    required this.builder,
    this.comingSoon = false,
  });

  final String slug;
  final IconData icon;
  final Color color;

  /// Localized drawer / tile label.
  final String Function(AppLocalizations l10n) label;

  /// Builds the mini app widget when it is opened.
  final WidgetBuilder builder;

  final bool comingSoon;
}