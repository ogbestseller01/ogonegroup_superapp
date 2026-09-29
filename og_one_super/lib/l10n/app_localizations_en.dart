// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'OG ONE GROUP';

  @override
  String get miniApps => 'Mini Apps';

  @override
  String get settings => 'Settings';

  @override
  String get chooseService => 'Choose the service you want and continue';

  @override
  String get services => 'Services';

  @override
  String get continueText => 'Continue';

  @override
  String get comingSoonMessage => 'This service is coming soon 🚀';

  @override
  String get soon => 'Soon';

  @override
  String opening(String name) {
    return 'Opening $name...';
  }

  @override
  String get nearbyFundi => 'NearbyFundi';

  @override
  String get fundiApp => 'Fundi App';

  @override
  String get msosi => 'Msosi Chap Chap';

  @override
  String get nearbyHealth => 'Nearby Health';

  @override
  String get nearbyHotel => 'Nearby Hotel';

  @override
  String get laundry => 'Laundry';

  @override
  String get comingSoon => 'Coming Soon';

  @override
  String get appearance => 'Appearance';

  @override
  String get system => 'System';

  @override
  String get followDevice => 'Follow device setting';

  @override
  String get light => 'Light';

  @override
  String get lightMode => 'Light mode';

  @override
  String get dark => 'Dark';

  @override
  String get darkMode => 'Dark mode';

  @override
  String get about => 'About';

  @override
  String get version => 'Version';

  @override
  String get welcome => 'Welcome';

  @override
  String get searchHint => 'Search services';

  @override
  String get bannerTitle => 'All your services, one app';

  @override
  String get bannerSubtitle => 'Fundis, food, health, hotels and laundry';

  @override
  String get allServices => 'All services';

  @override
  String get noResults => 'No services found';
}
