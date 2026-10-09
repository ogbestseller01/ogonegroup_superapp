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
      case 'laundry':
        return laundry;
      case 'osha':
        return osha;
      case 'hama':
        return hama;
      case 'nimepoteza':
        return nimepoteza;
      case 'duma':
        return duma;
      case 'coming_soon':
      default:
        return comingSoon;
    }
  }
}