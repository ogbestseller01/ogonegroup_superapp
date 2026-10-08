// lib/config/app_strings.dart

import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

// Re-export so `context.t` works in any file that imports this.
export '../l10n/app_localizations.dart';

/// `context.t.someKey`
extension AppL10n on BuildContext {
  AppLocalizations get t => AppLocalizations.of(this)!;
}

/// `t.serviceTitle(slug)`
extension ServiceTitles on AppLocalizations {
  String serviceTitle(String slug) {
    switch (slug) {
      case 'nearbyfundi':
        return nearbyFundi;
      case 'fundiapp':
        return fundiApp;
      case 'msosi':
        return msosi;
      case 'health':
        return nearbyHealth;
      case 'laundry':
        return laundry;
      case 'osha':
        return osha;
      case 'hama':
        return hama;
      case 'checkspace':
        return checkspace;
      case 'nimepoteza':
        return nimepoteza;
      case 'coming_soon':
      default:
        return comingSoon;
    }
  }
}