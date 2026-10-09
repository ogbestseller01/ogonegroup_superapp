import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_sw.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('sw')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'OG ONEGROUP'**
  String get appName;

  /// No description provided for @superApps.
  ///
  /// In en, this message translates to:
  /// **'Super App'**
  String get superApps;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select language'**
  String get selectLanguage;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @swahili.
  ///
  /// In en, this message translates to:
  /// **'Swahili'**
  String get swahili;

  /// No description provided for @chooseService.
  ///
  /// In en, this message translates to:
  /// **'Choose the service you want and continue'**
  String get chooseService;

  /// No description provided for @services.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get services;

  /// No description provided for @continueText.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueText;

  /// No description provided for @comingSoonMessage.
  ///
  /// In en, this message translates to:
  /// **'This service is coming soon 🚀'**
  String get comingSoonMessage;

  /// No description provided for @soon.
  ///
  /// In en, this message translates to:
  /// **'Soon'**
  String get soon;

  /// No description provided for @opening.
  ///
  /// In en, this message translates to:
  /// **'Opening {name}...'**
  String opening(String name);

  /// No description provided for @nearbyFundi.
  ///
  /// In en, this message translates to:
  /// **'NearbyFundi'**
  String get nearbyFundi;

  /// No description provided for @fundiApp.
  ///
  /// In en, this message translates to:
  /// **'Fundi App'**
  String get fundiApp;

  /// No description provided for @msosi.
  ///
  /// In en, this message translates to:
  /// **'Msosi Chap Chap'**
  String get msosi;

  /// No description provided for @nearbyHealth.
  ///
  /// In en, this message translates to:
  /// **'Nearby Health Facility'**
  String get nearbyHealth;

  /// No description provided for @laundry.
  ///
  /// In en, this message translates to:
  /// **'Laundry'**
  String get laundry;

  /// No description provided for @osha.
  ///
  /// In en, this message translates to:
  /// **'Osha Papo Hapo'**
  String get osha;

  /// No description provided for @hama.
  ///
  /// In en, this message translates to:
  /// **'Hama Chap Chap'**
  String get hama;

  /// No description provided for @checkspace.
  ///
  /// In en, this message translates to:
  /// **'CheckSpace App'**
  String get checkspace;

  /// No description provided for @nimepoteza.
  ///
  /// In en, this message translates to:
  /// **'Nimepoteza App'**
  String get nimepoteza;

  /// Service title for the Duma mini app
  ///
  /// In en, this message translates to:
  /// **'Duma App'**
  String get duma;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get comingSoon;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// No description provided for @followDevice.
  ///
  /// In en, this message translates to:
  /// **'Follow device setting'**
  String get followDevice;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @lightMode.
  ///
  /// In en, this message translates to:
  /// **'Light mode'**
  String get lightMode;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark mode'**
  String get darkMode;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @contactUs.
  ///
  /// In en, this message translates to:
  /// **'Contact Us'**
  String get contactUs;

  /// No description provided for @termsConditions.
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get termsConditions;

  /// No description provided for @rateApp.
  ///
  /// In en, this message translates to:
  /// **'Rate App'**
  String get rateApp;

  /// No description provided for @others.
  ///
  /// In en, this message translates to:
  /// **'Others'**
  String get others;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search services'**
  String get searchHint;

  /// No description provided for @bannerTitle.
  ///
  /// In en, this message translates to:
  /// **'All your services, one app'**
  String get bannerTitle;

  /// No description provided for @bannerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Fundis, hama chap chap, osha papo hapo, laundry and more'**
  String get bannerSubtitle;

  /// No description provided for @allServices.
  ///
  /// In en, this message translates to:
  /// **'All services'**
  String get allServices;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No services found'**
  String get noResults;

  /// No description provided for @adsBannersTitle.
  ///
  /// In en, this message translates to:
  /// **'Ads/Banners'**
  String get adsBannersTitle;

  /// No description provided for @adsBannersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Coming soon — grow with us'**
  String get adsBannersSubtitle;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get error;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @pushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Push Notifications'**
  String get pushNotifications;

  /// No description provided for @receivePushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Receive push notifications'**
  String get receivePushNotifications;

  /// No description provided for @orderUpdates.
  ///
  /// In en, this message translates to:
  /// **'Order Updates'**
  String get orderUpdates;

  /// No description provided for @orderUpdatesDesc.
  ///
  /// In en, this message translates to:
  /// **'Get notified about your orders and bookings'**
  String get orderUpdatesDesc;

  /// No description provided for @promotions.
  ///
  /// In en, this message translates to:
  /// **'Promotions & Offers'**
  String get promotions;

  /// No description provided for @promotionsDesc.
  ///
  /// In en, this message translates to:
  /// **'Receive special offers and discounts'**
  String get promotionsDesc;

  /// No description provided for @systemUpdates.
  ///
  /// In en, this message translates to:
  /// **'System Updates'**
  String get systemUpdates;

  /// No description provided for @systemUpdatesDesc.
  ///
  /// In en, this message translates to:
  /// **'Important app updates and announcements'**
  String get systemUpdatesDesc;

  /// No description provided for @privacyData.
  ///
  /// In en, this message translates to:
  /// **'Privacy & Data'**
  String get privacyData;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @clearCache.
  ///
  /// In en, this message translates to:
  /// **'Clear Cache'**
  String get clearCache;

  /// No description provided for @clearCacheConfirm.
  ///
  /// In en, this message translates to:
  /// **'This will clear temporary files and free up space. Continue?'**
  String get clearCacheConfirm;

  /// No description provided for @cacheCleared.
  ///
  /// In en, this message translates to:
  /// **'Cache cleared successfully'**
  String get cacheCleared;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @helpFeedback.
  ///
  /// In en, this message translates to:
  /// **'Help & Feedback'**
  String get helpFeedback;

  /// No description provided for @helpCenter.
  ///
  /// In en, this message translates to:
  /// **'Help Center'**
  String get helpCenter;

  /// No description provided for @sendFeedback.
  ///
  /// In en, this message translates to:
  /// **'Send Feedback'**
  String get sendFeedback;

  /// No description provided for @bannerFundiTitle.
  ///
  /// In en, this message translates to:
  /// **'Trusted fundis, near you'**
  String get bannerFundiTitle;

  /// No description provided for @bannerFundiSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Book verified technicians in a few taps'**
  String get bannerFundiSubtitle;

  /// No description provided for @bannerFoodTitle.
  ///
  /// In en, this message translates to:
  /// **'Food & laundry, delivered'**
  String get bannerFoodTitle;

  /// No description provided for @bannerFoodSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Msosi Chap Chap and Mfua Nguo at your door'**
  String get bannerFoodSubtitle;

  /// No description provided for @faqs.
  ///
  /// In en, this message translates to:
  /// **'FAQs'**
  String get faqs;

  /// No description provided for @searchFaqs.
  ///
  /// In en, this message translates to:
  /// **'Search FAQs'**
  String get searchFaqs;

  /// No description provided for @noFaqs.
  ///
  /// In en, this message translates to:
  /// **'No FAQs available yet.'**
  String get noFaqs;

  /// No description provided for @couldNotOpen.
  ///
  /// In en, this message translates to:
  /// **'Could not open this link.'**
  String get couldNotOpen;

  /// No description provided for @getInTouch.
  ///
  /// In en, this message translates to:
  /// **'Get in touch'**
  String get getInTouch;

  /// No description provided for @getInTouchSub.
  ///
  /// In en, this message translates to:
  /// **'We are happy to help. Reach us any way you like.'**
  String get getInTouchSub;

  /// No description provided for @emailWebsite.
  ///
  /// In en, this message translates to:
  /// **'EMAIL & WEBSITE'**
  String get emailWebsite;

  /// No description provided for @phoneNumbers.
  ///
  /// In en, this message translates to:
  /// **'PHONE NUMBERS'**
  String get phoneNumbers;

  /// No description provided for @whatsappSection.
  ///
  /// In en, this message translates to:
  /// **'WHATSAPP'**
  String get whatsappSection;

  /// No description provided for @call.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get call;

  /// No description provided for @chat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chat;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @website.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get website;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @helpUsImprove.
  ///
  /// In en, this message translates to:
  /// **'Help us improve'**
  String get helpUsImprove;

  /// No description provided for @helpUsImproveSub.
  ///
  /// In en, this message translates to:
  /// **'Tell us what you like, what is broken or what you would love to see next.'**
  String get helpUsImproveSub;

  /// No description provided for @feedbackTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'FEEDBACK TYPE'**
  String get feedbackTypeLabel;

  /// No description provided for @rateAppLabel.
  ///
  /// In en, this message translates to:
  /// **'HOW WOULD YOU RATE THE APP?'**
  String get rateAppLabel;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullName;

  /// No description provided for @yourFeedback.
  ///
  /// In en, this message translates to:
  /// **'Your feedback'**
  String get yourFeedback;

  /// No description provided for @sendFeedbackBtn.
  ///
  /// In en, this message translates to:
  /// **'Send feedback'**
  String get sendFeedbackBtn;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get required;

  /// No description provided for @validEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get validEmail;

  /// No description provided for @suggestion.
  ///
  /// In en, this message translates to:
  /// **'Suggestion'**
  String get suggestion;

  /// No description provided for @bugReport.
  ///
  /// In en, this message translates to:
  /// **'Bug report'**
  String get bugReport;

  /// No description provided for @compliment.
  ///
  /// In en, this message translates to:
  /// **'Compliment'**
  String get compliment;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @nothingToShow.
  ///
  /// In en, this message translates to:
  /// **'Nothing to show yet.'**
  String get nothingToShow;

  /// No description provided for @menu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get menu;

  /// No description provided for @aiAssistant.
  ///
  /// In en, this message translates to:
  /// **'AI Assistant'**
  String get aiAssistant;

  /// No description provided for @partnerships.
  ///
  /// In en, this message translates to:
  /// **'Partnerships'**
  String get partnerships;

  /// No description provided for @welcomePartnerships.
  ///
  /// In en, this message translates to:
  /// **'Welcome for partnerships'**
  String get welcomePartnerships;

  /// No description provided for @featured.
  ///
  /// In en, this message translates to:
  /// **'Featured App\'s'**
  String get featured;

  /// No description provided for @partnerApps.
  ///
  /// In en, this message translates to:
  /// **'Partner\'s Apps'**
  String get partnerApps;

  /// No description provided for @partnerAppsHint.
  ///
  /// In en, this message translates to:
  /// **'Partner apps will appear here'**
  String get partnerAppsHint;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @scan.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get scan;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'sw'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'sw':
      return AppLocalizationsSw();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
