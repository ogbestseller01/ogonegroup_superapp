import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart'; // Adjust path if needed

export '../l10n/app_localizations.dart';

extension AppL10n on BuildContext {
  AppLocalizations get t => AppLocalizations.of(this)!;
}

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