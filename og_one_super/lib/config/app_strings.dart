import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

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
      case 'health':
        return nearbyHealth;
      case 'hotel':
        return nearbyHotel;
      case 'laundry':
        return laundry;
      default:
        return comingSoon;
    }
  }
}