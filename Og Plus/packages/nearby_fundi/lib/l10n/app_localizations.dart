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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
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

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'NearbyFundi'**
  String get appTitle;

  /// No description provided for @nearby.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get nearby;

  /// No description provided for @nearbyMap.
  ///
  /// In en, this message translates to:
  /// **'Nearby Map'**
  String get nearbyMap;

  /// No description provided for @near.
  ///
  /// In en, this message translates to:
  /// **'Near'**
  String get near;

  /// No description provided for @blog.
  ///
  /// In en, this message translates to:
  /// **'Blog'**
  String get blog;

  /// No description provided for @requests.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get requests;

  /// No description provided for @myRequests.
  ///
  /// In en, this message translates to:
  /// **'My Requests'**
  String get myRequests;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @chat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chat;

  /// No description provided for @payments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get payments;

  /// No description provided for @jobs.
  ///
  /// In en, this message translates to:
  /// **'Jobs'**
  String get jobs;

  /// No description provided for @tickets.
  ///
  /// In en, this message translates to:
  /// **'Tickets'**
  String get tickets;

  /// No description provided for @soon.
  ///
  /// In en, this message translates to:
  /// **'Soon'**
  String get soon;

  /// No description provided for @becomeFundi.
  ///
  /// In en, this message translates to:
  /// **'Become a Fundi'**
  String get becomeFundi;

  /// No description provided for @otpDigitRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter 6-digit OTP'**
  String get otpDigitRequired;

  /// No description provided for @passwordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordMinLength;

  /// No description provided for @repeatPassword.
  ///
  /// In en, this message translates to:
  /// **'Repeat your password'**
  String get repeatPassword;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English 🇬🇧'**
  String get languageEnglish;

  /// No description provided for @languageSwahili.
  ///
  /// In en, this message translates to:
  /// **'Kiswahili 🇹🇿'**
  String get languageSwahili;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light ☀️'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark 🌙'**
  String get themeDark;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System ⚙️'**
  String get themeSystem;

  /// No description provided for @accountVerified.
  ///
  /// In en, this message translates to:
  /// **'Account verified!'**
  String get accountVerified;

  /// No description provided for @welcomeToApp.
  ///
  /// In en, this message translates to:
  /// **'Welcome to NearbyFundi'**
  String get welcomeToApp;

  /// No description provided for @welcomeToAppName.
  ///
  /// In en, this message translates to:
  /// **'Welcome to NearbyFundi, {name}'**
  String welcomeToAppName(String name);

  /// No description provided for @takingYouToDashboard.
  ///
  /// In en, this message translates to:
  /// **'Taking you to your dashboard…'**
  String get takingYouToDashboard;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @invalidOrExpiredCode.
  ///
  /// In en, this message translates to:
  /// **'Invalid or expired code. Please try again.'**
  String get invalidOrExpiredCode;

  /// No description provided for @couldNotSendCodeAuto.
  ///
  /// In en, this message translates to:
  /// **'We could not send your code automatically. Tap \"Resend code\" below.'**
  String get couldNotSendCodeAuto;

  /// No description provided for @codeSentBySms.
  ///
  /// In en, this message translates to:
  /// **'We sent a 6-digit code by SMS to\n{target}'**
  String codeSentBySms(String target);

  /// No description provided for @codeSentByEmail.
  ///
  /// In en, this message translates to:
  /// **'We sent a 6-digit code to your email\n{target}'**
  String codeSentByEmail(String target);

  /// No description provided for @newCodeSent.
  ///
  /// In en, this message translates to:
  /// **'A new code has been sent.'**
  String get newCodeSent;

  /// No description provided for @couldNotResendCode.
  ///
  /// In en, this message translates to:
  /// **'Could not resend the code. Try again.'**
  String get couldNotResendCode;

  /// No description provided for @resendCodeIn.
  ///
  /// In en, this message translates to:
  /// **'Resend code in {time}'**
  String resendCodeIn(String time);

  /// No description provided for @resendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get resendCode;

  /// No description provided for @changeMyDetails.
  ///
  /// In en, this message translates to:
  /// **'Change my details'**
  String get changeMyDetails;

  /// No description provided for @passwordResetSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password reset successfully'**
  String get passwordResetSuccess;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'you@example.com'**
  String get emailHint;

  /// No description provided for @registerPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'712345678'**
  String get registerPhoneHint;

  /// No description provided for @splashTagline.
  ///
  /// In en, this message translates to:
  /// **'Find trusted help, right where you need it.'**
  String get splashTagline;

  /// No description provided for @onboardFindFundisTitle.
  ///
  /// In en, this message translates to:
  /// **'Find Fundis'**
  String get onboardFindFundisTitle;

  /// No description provided for @onboardFindFundisDesc.
  ///
  /// In en, this message translates to:
  /// **'Discover trusted and verified technicians offering quality services near you.'**
  String get onboardFindFundisDesc;

  /// No description provided for @onboardConnectFastTitle.
  ///
  /// In en, this message translates to:
  /// **'Connect Fast'**
  String get onboardConnectFastTitle;

  /// No description provided for @onboardConnectFastDesc.
  ///
  /// In en, this message translates to:
  /// **'Browse technician profiles, check ratings and connect with the right professional.'**
  String get onboardConnectFastDesc;

  /// No description provided for @onboardGetItDoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Get It Done'**
  String get onboardGetItDoneTitle;

  /// No description provided for @onboardGetItDoneDesc.
  ///
  /// In en, this message translates to:
  /// **'Send your request, get accepted and follow your service from start to finish.'**
  String get onboardGetItDoneDesc;

  /// No description provided for @benefitVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get benefitVerified;

  /// No description provided for @benefitTrusted.
  ///
  /// In en, this message translates to:
  /// **'Trusted'**
  String get benefitTrusted;

  /// No description provided for @benefitFast.
  ///
  /// In en, this message translates to:
  /// **'Fast'**
  String get benefitFast;

  /// No description provided for @rememberMe.
  ///
  /// In en, this message translates to:
  /// **'Remember me'**
  String get rememberMe;

  /// No description provided for @orContinueWith.
  ///
  /// In en, this message translates to:
  /// **'or continue with'**
  String get orContinueWith;

  /// No description provided for @phoneHint.
  ///
  /// In en, this message translates to:
  /// **'679117291'**
  String get phoneHint;

  /// No description provided for @pleaseEnterPhone.
  ///
  /// In en, this message translates to:
  /// **'Please enter phone number'**
  String get pleaseEnterPhone;

  /// No description provided for @enterValidPhoneDigits.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid 9-digit number'**
  String get enterValidPhoneDigits;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @trustedTechniciansNearYou.
  ///
  /// In en, this message translates to:
  /// **'Trusted technicians near you'**
  String get trustedTechniciansNearYou;

  /// No description provided for @nearbyFundiTagline.
  ///
  /// In en, this message translates to:
  /// **'NearbyFundi • trusted technicians near you'**
  String get nearbyFundiTagline;

  /// No description provided for @registerNameTooShort.
  ///
  /// In en, this message translates to:
  /// **'Name is too short'**
  String get registerNameTooShort;

  /// No description provided for @registerEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get registerEmailRequired;

  /// No description provided for @registerPhoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Phone number is required'**
  String get registerPhoneRequired;

  /// No description provided for @registerValidTanzaniaPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid Tanzanian number, e.g. 0712 345 678'**
  String get registerValidTanzaniaPhone;

  /// No description provided for @registerValidPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid phone number'**
  String get registerValidPhone;

  /// No description provided for @registerPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get registerPasswordRequired;

  /// No description provided for @registerPasswordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get registerPasswordMinLength;

  /// No description provided for @registerPasswordStrength.
  ///
  /// In en, this message translates to:
  /// **'Use uppercase, lowercase and a number'**
  String get registerPasswordStrength;

  /// No description provided for @registerConfirmPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password'**
  String get registerConfirmPasswordRequired;

  /// No description provided for @registerPasswordsMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get registerPasswordsMismatch;

  /// No description provided for @registerFailedRetry.
  ///
  /// In en, this message translates to:
  /// **'Registration failed. Please try again.'**
  String get registerFailedRetry;

  /// No description provided for @registerOtpSendFailed.
  ///
  /// In en, this message translates to:
  /// **'Account created, but we could not send the code. Please try again.'**
  String get registerOtpSendFailed;

  /// No description provided for @registerPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Min 8 chars, upper + lower + number'**
  String get registerPasswordHint;

  /// No description provided for @registerRepeatPassword.
  ///
  /// In en, this message translates to:
  /// **'Repeat your password'**
  String get registerRepeatPassword;

  /// No description provided for @registerRuleLength.
  ///
  /// In en, this message translates to:
  /// **'8+ characters'**
  String get registerRuleLength;

  /// No description provided for @registerRuleUppercase.
  ///
  /// In en, this message translates to:
  /// **'Uppercase'**
  String get registerRuleUppercase;

  /// No description provided for @registerRuleLowercase.
  ///
  /// In en, this message translates to:
  /// **'Lowercase'**
  String get registerRuleLowercase;

  /// No description provided for @registerRuleNumber.
  ///
  /// In en, this message translates to:
  /// **'Number'**
  String get registerRuleNumber;

  /// No description provided for @registerAlreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get registerAlreadyHaveAccount;

  /// No description provided for @registerSearchCountry.
  ///
  /// In en, this message translates to:
  /// **'Search country...'**
  String get registerSearchCountry;

  /// No description provided for @registerNoCountryFound.
  ///
  /// In en, this message translates to:
  /// **'No country found'**
  String get registerNoCountryFound;

  /// No description provided for @findFundi.
  ///
  /// In en, this message translates to:
  /// **'Find Fundi'**
  String get findFundi;

  /// No description provided for @searchLocation.
  ///
  /// In en, this message translates to:
  /// **'📍 Search location...'**
  String get searchLocation;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @filterByService.
  ///
  /// In en, this message translates to:
  /// **'🔧 Filter by service...'**
  String get filterByService;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @allServices.
  ///
  /// In en, this message translates to:
  /// **'All Services'**
  String get allServices;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @noServicesFound.
  ///
  /// In en, this message translates to:
  /// **'No services found'**
  String get noServicesFound;

  /// No description provided for @noServicesMatch.
  ///
  /// In en, this message translates to:
  /// **'No services match your filter'**
  String get noServicesMatch;

  /// No description provided for @clearAllFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear All Filters'**
  String get clearAllFilters;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get clearFilters;

  /// No description provided for @filtered.
  ///
  /// In en, this message translates to:
  /// **'Filtered'**
  String get filtered;

  /// No description provided for @onlineOnly.
  ///
  /// In en, this message translates to:
  /// **'Online only'**
  String get onlineOnly;

  /// No description provided for @viewOnMap.
  ///
  /// In en, this message translates to:
  /// **'View on map'**
  String get viewOnMap;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @noFundisFound.
  ///
  /// In en, this message translates to:
  /// **'No Fundis Found'**
  String get noFundisFound;

  /// No description provided for @tryAdjustingSearch.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your search or location'**
  String get tryAdjustingSearch;

  /// No description provided for @fundisFound.
  ///
  /// In en, this message translates to:
  /// **'Fundis found'**
  String get fundisFound;

  /// No description provided for @searchingForFundis.
  ///
  /// In en, this message translates to:
  /// **'Searching for fundis...'**
  String get searchingForFundis;

  /// No description provided for @oopsSomethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Oops! Something went wrong'**
  String get oopsSomethingWentWrong;

  /// No description provided for @pleaseTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Please try again'**
  String get pleaseTryAgain;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @noResultsFor.
  ///
  /// In en, this message translates to:
  /// **'No Fundis for {service}'**
  String noResultsFor(String service);

  /// No description provided for @noResultsForServiceCategory.
  ///
  /// In en, this message translates to:
  /// **'No Fundis for {service} ({category})'**
  String noResultsForServiceCategory(String service, String category);

  /// No description provided for @tryDifferentCategoryOrService.
  ///
  /// In en, this message translates to:
  /// **'Try a different category or service'**
  String get tryDifferentCategoryOrService;

  /// No description provided for @tryDifferentService.
  ///
  /// In en, this message translates to:
  /// **'Try selecting a different service'**
  String get tryDifferentService;

  /// No description provided for @tryAdjustingLocation.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your search or location'**
  String get tryAdjustingLocation;

  /// No description provided for @suggestionClearFilters.
  ///
  /// In en, this message translates to:
  /// **'Try clearing your filters'**
  String get suggestionClearFilters;

  /// No description provided for @suggestionDifferentLocation.
  ///
  /// In en, this message translates to:
  /// **'Try a different location'**
  String get suggestionDifferentLocation;

  /// No description provided for @suggestionDifferentService.
  ///
  /// In en, this message translates to:
  /// **'Try a different service'**
  String get suggestionDifferentService;

  /// No description provided for @suggestionRemoveFilters.
  ///
  /// In en, this message translates to:
  /// **'Try removing service/category filters'**
  String get suggestionRemoveFilters;

  /// No description provided for @suggestionIncreaseRadius.
  ///
  /// In en, this message translates to:
  /// **'Try increasing the search radius'**
  String get suggestionIncreaseRadius;

  /// No description provided for @suggestionAllCategories.
  ///
  /// In en, this message translates to:
  /// **'Try selecting \'All Categories\''**
  String get suggestionAllCategories;

  /// No description provided for @suggestionAllServices.
  ///
  /// In en, this message translates to:
  /// **'Try selecting \'All Services\''**
  String get suggestionAllServices;

  /// No description provided for @kmAway.
  ///
  /// In en, this message translates to:
  /// **'km away'**
  String get kmAway;

  /// No description provided for @viewProfile.
  ///
  /// In en, this message translates to:
  /// **'View Profile'**
  String get viewProfile;

  /// No description provided for @directions.
  ///
  /// In en, this message translates to:
  /// **'Directions'**
  String get directions;

  /// No description provided for @online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// No description provided for @request.
  ///
  /// In en, this message translates to:
  /// **'Request'**
  String get request;

  /// No description provided for @requestThisFundi.
  ///
  /// In en, this message translates to:
  /// **'Request This Fundi'**
  String get requestThisFundi;

  /// No description provided for @requestAlreadySent.
  ///
  /// In en, this message translates to:
  /// **'Request Already Sent'**
  String get requestAlreadySent;

  /// No description provided for @hourlyRate.
  ///
  /// In en, this message translates to:
  /// **'Hourly Rate'**
  String get hourlyRate;

  /// No description provided for @tzs.
  ///
  /// In en, this message translates to:
  /// **'TZS'**
  String get tzs;

  /// No description provided for @socialMedia.
  ///
  /// In en, this message translates to:
  /// **'Social Media'**
  String get socialMedia;

  /// No description provided for @contact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get contact;

  /// No description provided for @call.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get call;

  /// No description provided for @items.
  ///
  /// In en, this message translates to:
  /// **'items'**
  String get items;

  /// No description provided for @sendingToTechnician.
  ///
  /// In en, this message translates to:
  /// **'Sending to technician...'**
  String get sendingToTechnician;

  /// No description provided for @awaitingResponse.
  ///
  /// In en, this message translates to:
  /// **'Awaiting response...'**
  String get awaitingResponse;

  /// No description provided for @noServicesSelected.
  ///
  /// In en, this message translates to:
  /// **'No services selected'**
  String get noServicesSelected;

  /// No description provided for @selectService.
  ///
  /// In en, this message translates to:
  /// **'Select a service'**
  String get selectService;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBack;

  /// No description provided for @signInToContinue.
  ///
  /// In en, this message translates to:
  /// **'Please sign in or create an account to continue.'**
  String get signInToContinue;

  /// No description provided for @signInManage.
  ///
  /// In en, this message translates to:
  /// **'Sign in to manage your services'**
  String get signInManage;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailAddress;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @joinCommunity.
  ///
  /// In en, this message translates to:
  /// **'Join the community of smart users'**
  String get joinCommunity;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @verificationCode.
  ///
  /// In en, this message translates to:
  /// **'Verification Code'**
  String get verificationCode;

  /// No description provided for @enterCodeSent.
  ///
  /// In en, this message translates to:
  /// **'Enter the code sent to'**
  String get enterCodeSent;

  /// No description provided for @enterOtp.
  ///
  /// In en, this message translates to:
  /// **'Enter OTP'**
  String get enterOtp;

  /// No description provided for @otpSent.
  ///
  /// In en, this message translates to:
  /// **'A 6-digit code has been sent to your email'**
  String get otpSent;

  /// No description provided for @verifyOtp.
  ///
  /// In en, this message translates to:
  /// **'Verify OTP'**
  String get verifyOtp;

  /// No description provided for @backToSignIn.
  ///
  /// In en, this message translates to:
  /// **'Back to Sign In'**
  String get backToSignIn;

  /// No description provided for @noWorries.
  ///
  /// In en, this message translates to:
  /// **'No worries — we\'ll send you a reset code'**
  String get noWorries;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword;

  /// No description provided for @enterEmailReset.
  ///
  /// In en, this message translates to:
  /// **'Enter your email to receive a verification code'**
  String get enterEmailReset;

  /// No description provided for @sendResetCode.
  ///
  /// In en, this message translates to:
  /// **'Send Reset Code'**
  String get sendResetCode;

  /// No description provided for @setNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Set New Password'**
  String get setNewPassword;

  /// No description provided for @otpSentTo.
  ///
  /// In en, this message translates to:
  /// **'OTP sent to'**
  String get otpSentTo;

  /// No description provided for @otpCode.
  ///
  /// In en, this message translates to:
  /// **'OTP Code'**
  String get otpCode;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @resetPasswordButton.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPasswordButton;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @logoutConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get logoutConfirmation;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountConfirmation.
  ///
  /// In en, this message translates to:
  /// **'This action is permanent. All your data will be lost. Are you sure?'**
  String get deleteAccountConfirmation;

  /// No description provided for @areYouSure.
  ///
  /// In en, this message translates to:
  /// **'Are you sure?'**
  String get areYouSure;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @enterEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter your email address'**
  String get enterEmail;

  /// No description provided for @enterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get enterValidEmail;

  /// No description provided for @enterPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get enterPassword;

  /// No description provided for @pleaseAcceptTerms.
  ///
  /// In en, this message translates to:
  /// **'Please accept the Terms & Conditions'**
  String get pleaseAcceptTerms;

  /// No description provided for @iAgreeToThe.
  ///
  /// In en, this message translates to:
  /// **'I agree to the'**
  String get iAgreeToThe;

  /// No description provided for @termsAndConditions.
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get termsAndConditions;

  /// No description provided for @and.
  ///
  /// In en, this message translates to:
  /// **'and'**
  String get and;

  /// No description provided for @or.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get or;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @yourAccount.
  ///
  /// In en, this message translates to:
  /// **'Your Account'**
  String get yourAccount;

  /// No description provided for @managePersonalAccount.
  ///
  /// In en, this message translates to:
  /// **'Manage your personal account'**
  String get managePersonalAccount;

  /// No description provided for @updatePersonalInfo.
  ///
  /// In en, this message translates to:
  /// **'Update your personal information'**
  String get updatePersonalInfo;

  /// No description provided for @manageAppPreferences.
  ///
  /// In en, this message translates to:
  /// **'Manage your app preferences'**
  String get manageAppPreferences;

  /// No description provided for @yourNearbyFundiAccount.
  ///
  /// In en, this message translates to:
  /// **'Your NearbyFundi account'**
  String get yourNearbyFundiAccount;

  /// No description provided for @accountActive.
  ///
  /// In en, this message translates to:
  /// **'Account active'**
  String get accountActive;

  /// No description provided for @accountReadyToUse.
  ///
  /// In en, this message translates to:
  /// **'Your account is ready to use.'**
  String get accountReadyToUse;

  /// No description provided for @dangerZone.
  ///
  /// In en, this message translates to:
  /// **'Danger Zone'**
  String get dangerZone;

  /// No description provided for @irreversibleActions.
  ///
  /// In en, this message translates to:
  /// **'Irreversible account actions'**
  String get irreversibleActions;

  /// No description provided for @deleteAccountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Permanently remove your account and data'**
  String get deleteAccountSubtitle;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete account?'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountWarning.
  ///
  /// In en, this message translates to:
  /// **'You will be signed out of this app immediately. You can sign in again at any time.'**
  String get deleteAccountWarning;

  /// No description provided for @manageSettings.
  ///
  /// In en, this message translates to:
  /// **'Manage your settings'**
  String get manageSettings;

  /// No description provided for @personalizeExperience.
  ///
  /// In en, this message translates to:
  /// **'Personalize your NearbyFundi experience.'**
  String get personalizeExperience;

  /// No description provided for @lightAppearance.
  ///
  /// In en, this message translates to:
  /// **'Light appearance'**
  String get lightAppearance;

  /// No description provided for @darkAppearance.
  ///
  /// In en, this message translates to:
  /// **'Dark appearance'**
  String get darkAppearance;

  /// No description provided for @followDeviceSettings.
  ///
  /// In en, this message translates to:
  /// **'Follow device settings'**
  String get followDeviceSettings;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @information.
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get information;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @manageYourAccount.
  ///
  /// In en, this message translates to:
  /// **'Manage your account'**
  String get manageYourAccount;

  /// No description provided for @refreshProfile.
  ///
  /// In en, this message translates to:
  /// **'Refresh profile'**
  String get refreshProfile;

  /// No description provided for @trustedConnection.
  ///
  /// In en, this message translates to:
  /// **'Your trusted connection to local technicians.'**
  String get trustedConnection;

  /// No description provided for @findTrustedNearby.
  ///
  /// In en, this message translates to:
  /// **'Find trusted technicians near you.'**
  String get findTrustedNearby;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get nameRequired;

  /// No description provided for @enterValidName.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid name'**
  String get enterValidName;

  /// No description provided for @enterFullName.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get enterFullName;

  /// No description provided for @enterPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number'**
  String get enterPhoneNumber;

  /// No description provided for @personalInformation.
  ///
  /// In en, this message translates to:
  /// **'Personal information'**
  String get personalInformation;

  /// No description provided for @editNameAndContact.
  ///
  /// In en, this message translates to:
  /// **'Edit your name and contact details.'**
  String get editNameAndContact;

  /// No description provided for @keepInfoUpdated.
  ///
  /// In en, this message translates to:
  /// **'Keep your personal information up to date.'**
  String get keepInfoUpdated;

  /// No description provided for @profileHeaderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your account details'**
  String get profileHeaderSubtitle;

  /// No description provided for @cancelActionLabel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelActionLabel;

  /// No description provided for @activeStatus.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get activeStatus;

  /// No description provided for @menu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get menu;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @minAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} min ago'**
  String minAgo(int count);

  /// No description provided for @hrAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} hr ago'**
  String hrAgo(int count);

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} days ago'**
  String daysAgo(int count);

  /// No description provided for @nearbyRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get nearbyRefresh;

  /// No description provided for @nearbyFitAll.
  ///
  /// In en, this message translates to:
  /// **'Fit all'**
  String get nearbyFitAll;

  /// No description provided for @nearbyNoTechniciansFound.
  ///
  /// In en, this message translates to:
  /// **'No technicians found'**
  String get nearbyNoTechniciansFound;

  /// No description provided for @nearbyTryAnotherLocation.
  ///
  /// In en, this message translates to:
  /// **'Try another location or a different service'**
  String get nearbyTryAnotherLocation;

  /// No description provided for @nearbyNearYou.
  ///
  /// In en, this message translates to:
  /// **'Near you'**
  String get nearbyNearYou;

  /// No description provided for @nearbyApproxMinShort.
  ///
  /// In en, this message translates to:
  /// **'~{value}m'**
  String nearbyApproxMinShort(String value);

  /// No description provided for @nearbyMapSummary.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 technician} other{{count} technicians}} • within {radius} km'**
  String nearbyMapSummary(int count, int radius);

  /// No description provided for @techMapLocationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Location not available for this technician.'**
  String get techMapLocationUnavailable;

  /// No description provided for @techMapRefreshRoute.
  ///
  /// In en, this message translates to:
  /// **'Refresh route'**
  String get techMapRefreshRoute;

  /// No description provided for @techMapCalculatingRoute.
  ///
  /// In en, this message translates to:
  /// **'Calculating route…'**
  String get techMapCalculatingRoute;

  /// No description provided for @techMapRecenter.
  ///
  /// In en, this message translates to:
  /// **'Recenter'**
  String get techMapRecenter;

  /// No description provided for @techMapMaps.
  ///
  /// In en, this message translates to:
  /// **'Maps'**
  String get techMapMaps;

  /// No description provided for @techMapOnline.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get techMapOnline;

  /// No description provided for @techMapOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get techMapOffline;

  /// No description provided for @pickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Pick location'**
  String get pickerTitle;

  /// No description provided for @pickerOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get pickerOk;

  /// No description provided for @pickerSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get pickerSettings;

  /// No description provided for @pickerEnableLocation.
  ///
  /// In en, this message translates to:
  /// **'Please enable location services.'**
  String get pickerEnableLocation;

  /// No description provided for @pickerPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission denied.'**
  String get pickerPermissionDenied;

  /// No description provided for @pickerPermissionDeniedForever.
  ///
  /// In en, this message translates to:
  /// **'Location permission permanently denied.'**
  String get pickerPermissionDeniedForever;

  /// No description provided for @pickerOutsideTanzania.
  ///
  /// In en, this message translates to:
  /// **'Your location is outside Tanzania.'**
  String get pickerOutsideTanzania;

  /// No description provided for @pickerLocationFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not get your location. Please try again.'**
  String get pickerLocationFailed;

  /// No description provided for @pickerPickInsideTanzania.
  ///
  /// In en, this message translates to:
  /// **'Please pick a location inside Tanzania.'**
  String get pickerPickInsideTanzania;

  /// No description provided for @pickerMyLocation.
  ///
  /// In en, this message translates to:
  /// **'My current location'**
  String get pickerMyLocation;

  /// No description provided for @pickerSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search a place in Tanzania…'**
  String get pickerSearchHint;

  /// No description provided for @pickerRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get pickerRecent;

  /// No description provided for @pickerClearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get pickerClearAll;

  /// No description provided for @pickerRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get pickerRemove;

  /// No description provided for @pickerGettingAddress.
  ///
  /// In en, this message translates to:
  /// **'Getting address…'**
  String get pickerGettingAddress;

  /// No description provided for @pickerTapMapHint.
  ///
  /// In en, this message translates to:
  /// **'Tap the map or search for a place'**
  String get pickerTapMapHint;

  /// No description provided for @pickerUseLocation.
  ///
  /// In en, this message translates to:
  /// **'Use this location'**
  String get pickerUseLocation;

  /// No description provided for @nearbyFindFundiTitle.
  ///
  /// In en, this message translates to:
  /// **'Find a fundi near you'**
  String get nearbyFindFundiTitle;

  /// No description provided for @nearbySearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get nearbySearch;

  /// No description provided for @nearbyShowSearch.
  ///
  /// In en, this message translates to:
  /// **'Show search'**
  String get nearbyShowSearch;

  /// No description provided for @nearbyHideSearch.
  ///
  /// In en, this message translates to:
  /// **'Hide search'**
  String get nearbyHideSearch;

  /// No description provided for @nearbyClearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get nearbyClearSearch;

  /// No description provided for @nearbyFilterByService.
  ///
  /// In en, this message translates to:
  /// **'Filter by service...'**
  String get nearbyFilterByService;

  /// No description provided for @nearbyChooseOnMap.
  ///
  /// In en, this message translates to:
  /// **'Choose location on map'**
  String get nearbyChooseOnMap;

  /// No description provided for @nearbyRecommendedReason.
  ///
  /// In en, this message translates to:
  /// **'Top ranked near you: rating, jobs and requests'**
  String get nearbyRecommendedReason;

  /// No description provided for @nearbyRecentSearches.
  ///
  /// In en, this message translates to:
  /// **'Recent searches'**
  String get nearbyRecentSearches;

  /// No description provided for @nearbyClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get nearbyClear;

  /// No description provided for @nearbyClearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get nearbyClearFilters;

  /// No description provided for @nearbyFindingRoutes.
  ///
  /// In en, this message translates to:
  /// **'Finding best routes...'**
  String get nearbyFindingRoutes;

  /// No description provided for @nearbySearchForTechnicians.
  ///
  /// In en, this message translates to:
  /// **'Search for technicians'**
  String get nearbySearchForTechnicians;

  /// No description provided for @nearbyNoTechniciansNearby.
  ///
  /// In en, this message translates to:
  /// **'No technicians found nearby'**
  String get nearbyNoTechniciansNearby;

  /// No description provided for @nearbyYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get nearbyYou;

  /// No description provided for @nearbyZoomIn.
  ///
  /// In en, this message translates to:
  /// **'Zoom in'**
  String get nearbyZoomIn;

  /// No description provided for @nearbyZoomOut.
  ///
  /// In en, this message translates to:
  /// **'Zoom out'**
  String get nearbyZoomOut;

  /// No description provided for @nearbyFitTechnicians.
  ///
  /// In en, this message translates to:
  /// **'Fit technicians'**
  String get nearbyFitTechnicians;

  /// No description provided for @nearbyShowList.
  ///
  /// In en, this message translates to:
  /// **'Show technician list'**
  String get nearbyShowList;

  /// No description provided for @nearbyShowFullMap.
  ///
  /// In en, this message translates to:
  /// **'Show full-screen map'**
  String get nearbyShowFullMap;

  /// No description provided for @nearbyViewProfile.
  ///
  /// In en, this message translates to:
  /// **'View Profile'**
  String get nearbyViewProfile;

  /// No description provided for @nearbyDirections.
  ///
  /// In en, this message translates to:
  /// **'Get directions'**
  String get nearbyDirections;

  /// No description provided for @nearbyCouldNotOpenMaps.
  ///
  /// In en, this message translates to:
  /// **'Could not open maps app.'**
  String get nearbyCouldNotOpenMaps;

  /// No description provided for @nearbyTopPick.
  ///
  /// In en, this message translates to:
  /// **'Top pick'**
  String get nearbyTopPick;

  /// No description provided for @nearbyAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get nearbyAll;

  /// No description provided for @nearbySearchFailed.
  ///
  /// In en, this message translates to:
  /// **'Search failed. Please check your connection and try again.'**
  String get nearbySearchFailed;

  /// No description provided for @nearbyInvalidLocation.
  ///
  /// In en, this message translates to:
  /// **'Invalid location selected. Please try again.'**
  String get nearbyInvalidLocation;

  /// No description provided for @nearbySearchLoginMessage.
  ///
  /// In en, this message translates to:
  /// **'Sign in or create an account to search for fundis near you.'**
  String get nearbySearchLoginMessage;

  /// No description provided for @nearbyFilterLoginMessage.
  ///
  /// In en, this message translates to:
  /// **'Sign in or create an account to filter fundis by service.'**
  String get nearbyFilterLoginMessage;

  /// No description provided for @nearbySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search a place or pick one on the map.'**
  String get nearbySearchHint;

  /// No description provided for @nearbyStatDistance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get nearbyStatDistance;

  /// No description provided for @nearbyStatDriveTime.
  ///
  /// In en, this message translates to:
  /// **'Drive time'**
  String get nearbyStatDriveTime;

  /// No description provided for @nearbyStatRating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get nearbyStatRating;

  /// No description provided for @nearbyStatJobsDone.
  ///
  /// In en, this message translates to:
  /// **'Jobs done'**
  String get nearbyStatJobsDone;

  /// No description provided for @nearbyStatRequests.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get nearbyStatRequests;

  /// No description provided for @nearbyStatReviews.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get nearbyStatReviews;

  /// No description provided for @nearbyKm.
  ///
  /// In en, this message translates to:
  /// **'{value} km'**
  String nearbyKm(String value);

  /// No description provided for @nearbyApproxMin.
  ///
  /// In en, this message translates to:
  /// **'~{value} min'**
  String nearbyApproxMin(String value);

  /// No description provided for @nearbyFoundWithRadius.
  ///
  /// In en, this message translates to:
  /// **'{count} found • {radius} km'**
  String nearbyFoundWithRadius(int count, int radius);

  /// No description provided for @nearbyExpandedNotice.
  ///
  /// In en, this message translates to:
  /// **'No fundis very close, so we searched up to {radius} km.'**
  String nearbyExpandedNotice(int radius);

  /// No description provided for @nearbyNoneWithinMax.
  ///
  /// In en, this message translates to:
  /// **'No fundis within {radius} km of this location. Try another place or service.'**
  String nearbyNoneWithinMax(int radius);

  /// No description provided for @nearbyNoneWithin.
  ///
  /// In en, this message translates to:
  /// **'No fundis within {radius} km of this location.'**
  String nearbyNoneWithin(int radius);

  /// No description provided for @nearbySearchWiderUpTo.
  ///
  /// In en, this message translates to:
  /// **'Search wider (up to {radius} km)'**
  String nearbySearchWiderUpTo(int radius);

  /// No description provided for @nearbyJobsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} jobs'**
  String nearbyJobsCount(int count);

  /// No description provided for @nearbyRequestsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} requests'**
  String nearbyRequestsCount(int count);

  /// No description provided for @nearbyJobsDone.
  ///
  /// In en, this message translates to:
  /// **'{count} jobs done'**
  String nearbyJobsDone(int count);

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @deleteMessageForEveryone.
  ///
  /// In en, this message translates to:
  /// **'Delete for everyone'**
  String get deleteMessageForEveryone;

  /// No description provided for @deleteMessageForMe.
  ///
  /// In en, this message translates to:
  /// **'Delete for me'**
  String get deleteMessageForMe;

  /// No description provided for @removedForBoth.
  ///
  /// In en, this message translates to:
  /// **'Removed for both of you'**
  String get removedForBoth;

  /// No description provided for @removedOnPhone.
  ///
  /// In en, this message translates to:
  /// **'Only removed on this phone'**
  String get removedOnPhone;

  /// No description provided for @deleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get deleted;

  /// No description provided for @forwarded.
  ///
  /// In en, this message translates to:
  /// **'Forwarded'**
  String get forwarded;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copied;

  /// No description provided for @typingEllipsis.
  ///
  /// In en, this message translates to:
  /// **'typing…'**
  String get typingEllipsis;

  /// No description provided for @pinnedMessage.
  ///
  /// In en, this message translates to:
  /// **'Pinned message'**
  String get pinnedMessage;

  /// No description provided for @pinnedCount.
  ///
  /// In en, this message translates to:
  /// **'Pinned {count} of {total}'**
  String pinnedCount(int count, int total);

  /// No description provided for @msgDeleted.
  ///
  /// In en, this message translates to:
  /// **'This message was deleted'**
  String get msgDeleted;

  /// No description provided for @tapToRetry.
  ///
  /// In en, this message translates to:
  /// **'Tap to retry'**
  String get tapToRetry;

  /// No description provided for @notSent.
  ///
  /// In en, this message translates to:
  /// **'Not sent'**
  String get notSent;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @editProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfileTitle;

  /// No description provided for @updateInfo.
  ///
  /// In en, this message translates to:
  /// **'Update Your Info'**
  String get updateInfo;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get name;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated'**
  String get profileUpdated;

  /// No description provided for @updateFailed.
  ///
  /// In en, this message translates to:
  /// **'Update failed'**
  String get updateFailed;

  /// No description provided for @guest.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get guest;

  /// No description provided for @technician.
  ///
  /// In en, this message translates to:
  /// **'Technician'**
  String get technician;

  /// No description provided for @technicianNotFound.
  ///
  /// In en, this message translates to:
  /// **'Technician not found'**
  String get technicianNotFound;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @bio.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get bio;

  /// No description provided for @experience.
  ///
  /// In en, this message translates to:
  /// **'Experience'**
  String get experience;

  /// No description provided for @years.
  ///
  /// In en, this message translates to:
  /// **'years'**
  String get years;

  /// No description provided for @area.
  ///
  /// In en, this message translates to:
  /// **'Area'**
  String get area;

  /// No description provided for @accountStatus.
  ///
  /// In en, this message translates to:
  /// **'Account Status'**
  String get accountStatus;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @onlineStatus.
  ///
  /// In en, this message translates to:
  /// **'Online Status'**
  String get onlineStatus;

  /// No description provided for @youAreOnline.
  ///
  /// In en, this message translates to:
  /// **'You are online'**
  String get youAreOnline;

  /// No description provided for @youAreOffline.
  ///
  /// In en, this message translates to:
  /// **'You are offline'**
  String get youAreOffline;

  /// No description provided for @servicesIOffer.
  ///
  /// In en, this message translates to:
  /// **'Services I Offer'**
  String get servicesIOffer;

  /// No description provided for @selectServicesDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Services'**
  String get selectServicesDialogTitle;

  /// No description provided for @selectAtLeastOneService.
  ///
  /// In en, this message translates to:
  /// **'Please select at least one service'**
  String get selectAtLeastOneService;

  /// No description provided for @servicesUpdated.
  ///
  /// In en, this message translates to:
  /// **'Services updated'**
  String get servicesUpdated;

  /// No description provided for @pushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Push Notifications'**
  String get pushNotifications;

  /// No description provided for @receiveAlerts.
  ///
  /// In en, this message translates to:
  /// **'Receive alerts about requests and updates'**
  String get receiveAlerts;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @aboutUs.
  ///
  /// In en, this message translates to:
  /// **'About Us'**
  String get aboutUs;

  /// No description provided for @faq.
  ///
  /// In en, this message translates to:
  /// **'FAQ'**
  String get faq;

  /// No description provided for @terms.
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get terms;

  /// No description provided for @contactUs.
  ///
  /// In en, this message translates to:
  /// **'Contact Us'**
  String get contactUs;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @noRequestsYet.
  ///
  /// In en, this message translates to:
  /// **'You have no requests yet'**
  String get noRequestsYet;

  /// No description provided for @requestsWillAppear.
  ///
  /// In en, this message translates to:
  /// **'Your service requests will appear here.'**
  String get requestsWillAppear;

  /// No description provided for @cancelRequest.
  ///
  /// In en, this message translates to:
  /// **'Cancel Request'**
  String get cancelRequest;

  /// No description provided for @areYouSureCancel.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel this request?'**
  String get areYouSureCancel;

  /// No description provided for @requestSent.
  ///
  /// In en, this message translates to:
  /// **'Request sent successfully!'**
  String get requestSent;

  /// No description provided for @preparingRequest.
  ///
  /// In en, this message translates to:
  /// **'Preparing your request...'**
  String get preparingRequest;

  /// No description provided for @validatingDetails.
  ///
  /// In en, this message translates to:
  /// **'Validating details...'**
  String get validatingDetails;

  /// No description provided for @creatingRequest.
  ///
  /// In en, this message translates to:
  /// **'Creating service request...'**
  String get creatingRequest;

  /// No description provided for @failedToSubmit.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit request.'**
  String get failedToSubmit;

  /// No description provided for @describeIssue.
  ///
  /// In en, this message translates to:
  /// **'Describe your issue'**
  String get describeIssue;

  /// No description provided for @describeHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. My AC is not cooling...'**
  String get describeHint;

  /// No description provided for @submitRequest.
  ///
  /// In en, this message translates to:
  /// **'Submit Request'**
  String get submitRequest;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @pleaseSelectService.
  ///
  /// In en, this message translates to:
  /// **'Please select a service'**
  String get pleaseSelectService;

  /// No description provided for @newRequest.
  ///
  /// In en, this message translates to:
  /// **'New Request'**
  String get newRequest;

  /// No description provided for @requestAccepted.
  ///
  /// In en, this message translates to:
  /// **'Request Accepted'**
  String get requestAccepted;

  /// No description provided for @requestRejected.
  ///
  /// In en, this message translates to:
  /// **'Request Rejected'**
  String get requestRejected;

  /// No description provided for @requestInProgress.
  ///
  /// In en, this message translates to:
  /// **'Request In Progress'**
  String get requestInProgress;

  /// No description provided for @requestCompleted.
  ///
  /// In en, this message translates to:
  /// **'Request Completed'**
  String get requestCompleted;

  /// No description provided for @noBlogPosts.
  ///
  /// In en, this message translates to:
  /// **'No blog posts yet.'**
  String get noBlogPosts;

  /// No description provided for @noCommentsYet.
  ///
  /// In en, this message translates to:
  /// **'No comments yet. Be the first!'**
  String get noCommentsYet;

  /// No description provided for @writeComment.
  ///
  /// In en, this message translates to:
  /// **'Write a comment...'**
  String get writeComment;

  /// No description provided for @comments.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get comments;

  /// No description provided for @postedOn.
  ///
  /// In en, this message translates to:
  /// **'Posted on'**
  String get postedOn;

  /// No description provided for @likes.
  ///
  /// In en, this message translates to:
  /// **'Likes'**
  String get likes;

  /// No description provided for @like.
  ///
  /// In en, this message translates to:
  /// **'Like'**
  String get like;

  /// No description provided for @unlike.
  ///
  /// In en, this message translates to:
  /// **'Unlike'**
  String get unlike;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @deletePost.
  ///
  /// In en, this message translates to:
  /// **'Delete Post'**
  String get deletePost;

  /// No description provided for @areYouSureDeletePost.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this post?'**
  String get areYouSureDeletePost;

  /// No description provided for @postDeleted.
  ///
  /// In en, this message translates to:
  /// **'Post deleted'**
  String get postDeleted;

  /// No description provided for @postCreated.
  ///
  /// In en, this message translates to:
  /// **'Post created'**
  String get postCreated;

  /// No description provided for @postUpdated.
  ///
  /// In en, this message translates to:
  /// **'Post updated'**
  String get postUpdated;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @content.
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get content;

  /// No description provided for @image.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get image;

  /// No description provided for @createPost.
  ///
  /// In en, this message translates to:
  /// **'Create Post'**
  String get createPost;

  /// No description provided for @updatePost.
  ///
  /// In en, this message translates to:
  /// **'Update Post'**
  String get updatePost;

  /// No description provided for @myPosts.
  ///
  /// In en, this message translates to:
  /// **'My Posts'**
  String get myPosts;

  /// No description provided for @portfolio.
  ///
  /// In en, this message translates to:
  /// **'Portfolio'**
  String get portfolio;

  /// No description provided for @noPortfolioItems.
  ///
  /// In en, this message translates to:
  /// **'No portfolio items available.'**
  String get noPortfolioItems;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @markAllAsRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get markAllAsRead;

  /// No description provided for @noNotificationsYet.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get noNotificationsYet;

  /// No description provided for @notification.
  ///
  /// In en, this message translates to:
  /// **'Notification'**
  String get notification;

  /// No description provided for @noConversationsYet.
  ///
  /// In en, this message translates to:
  /// **'No conversations yet'**
  String get noConversationsYet;

  /// No description provided for @startChattingWithFundis.
  ///
  /// In en, this message translates to:
  /// **'Start chatting with technicians near you'**
  String get startChattingWithFundis;

  /// No description provided for @noMessagesYet.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get noMessagesYet;

  /// No description provided for @sayHelloToStart.
  ///
  /// In en, this message translates to:
  /// **'Say hello to start chatting'**
  String get sayHelloToStart;

  /// No description provided for @typeAMessage.
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get typeAMessage;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @messageCopied.
  ///
  /// In en, this message translates to:
  /// **'Message copied'**
  String get messageCopied;

  /// No description provided for @messageDeleted.
  ///
  /// In en, this message translates to:
  /// **'Message deleted'**
  String get messageDeleted;

  /// No description provided for @deleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete Message'**
  String get deleteMessage;

  /// No description provided for @areYouSureDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this message?'**
  String get areYouSureDeleteMessage;

  /// No description provided for @failedToSend.
  ///
  /// In en, this message translates to:
  /// **'Failed to send message'**
  String get failedToSend;

  /// No description provided for @failedToSendImage.
  ///
  /// In en, this message translates to:
  /// **'Failed to send image'**
  String get failedToSendImage;

  /// No description provided for @failedToSendFile.
  ///
  /// In en, this message translates to:
  /// **'Failed to send file'**
  String get failedToSendFile;

  /// No description provided for @voiceRecordingComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Voice recording coming soon!'**
  String get voiceRecordingComingSoon;

  /// No description provided for @messageReactionAdded.
  ///
  /// In en, this message translates to:
  /// **'Reaction added'**
  String get messageReactionAdded;

  /// No description provided for @messageReactionRemoved.
  ///
  /// In en, this message translates to:
  /// **'Reaction removed'**
  String get messageReactionRemoved;

  /// No description provided for @typing.
  ///
  /// In en, this message translates to:
  /// **'Typing...'**
  String get typing;

  /// No description provided for @download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// No description provided for @fileDownloaded.
  ///
  /// In en, this message translates to:
  /// **'File downloaded'**
  String get fileDownloaded;

  /// No description provided for @fileDownloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to download file'**
  String get fileDownloadFailed;

  /// No description provided for @conversationDeleted.
  ///
  /// In en, this message translates to:
  /// **'Conversation deleted'**
  String get conversationDeleted;

  /// No description provided for @areYouSureDeleteConversation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this conversation?'**
  String get areYouSureDeleteConversation;

  /// No description provided for @noInternetConnection.
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get noInternetConnection;

  /// No description provided for @connecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting...'**
  String get connecting;

  /// No description provided for @disconnected.
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get disconnected;

  /// No description provided for @reconnecting.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting...'**
  String get reconnecting;

  /// No description provided for @noContent.
  ///
  /// In en, this message translates to:
  /// **'No content available.'**
  String get noContent;

  /// No description provided for @getInTouch.
  ///
  /// In en, this message translates to:
  /// **'Get in Touch'**
  String get getInTouch;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @website.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get website;

  /// No description provided for @phoneNumbers.
  ///
  /// In en, this message translates to:
  /// **'Phone Numbers'**
  String get phoneNumbers;

  /// No description provided for @noFaqs.
  ///
  /// In en, this message translates to:
  /// **'No FAQs available.'**
  String get noFaqs;

  /// No description provided for @welcomeFundi.
  ///
  /// In en, this message translates to:
  /// **'Find Trusted Fundis'**
  String get welcomeFundi;

  /// No description provided for @findTrustedDesc.
  ///
  /// In en, this message translates to:
  /// **'Connect with verified, experienced fundis near you. Request services like AC repair, plumbing, and more.'**
  String get findTrustedDesc;

  /// No description provided for @requestTrack.
  ///
  /// In en, this message translates to:
  /// **'Request & Track'**
  String get requestTrack;

  /// No description provided for @requestTrackDesc.
  ///
  /// In en, this message translates to:
  /// **'Post a service request, get accepted by a fundi, and track the status in real time. Simple, fast, and reliable.'**
  String get requestTrackDesc;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @failed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get failed;

  /// No description provided for @services.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get services;

  /// No description provided for @generalServices.
  ///
  /// In en, this message translates to:
  /// **'General Services'**
  String get generalServices;

  /// No description provided for @fundi.
  ///
  /// In en, this message translates to:
  /// **'Fundi'**
  String get fundi;

  /// No description provided for @rate.
  ///
  /// In en, this message translates to:
  /// **'Rate'**
  String get rate;

  /// No description provided for @aboutFundi.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutFundi;

  /// No description provided for @servicesAndRate.
  ///
  /// In en, this message translates to:
  /// **'Services & Rate'**
  String get servicesAndRate;

  /// No description provided for @searchPlaceFirst.
  ///
  /// In en, this message translates to:
  /// **'Search a place first to see it on the map.'**
  String get searchPlaceFirst;

  /// No description provided for @searchPlaceHint.
  ///
  /// In en, this message translates to:
  /// **'Go back and search for a location to see technicians nearby.'**
  String get searchPlaceHint;

  /// No description provided for @aiAssistant.
  ///
  /// In en, this message translates to:
  /// **'AI Assistant'**
  String get aiAssistant;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'coming soon!'**
  String get comingSoon;

  /// No description provided for @pleaseEnterLocation.
  ///
  /// In en, this message translates to:
  /// **'Please enter a location'**
  String get pleaseEnterLocation;

  /// No description provided for @searchServiceHint.
  ///
  /// In en, this message translates to:
  /// **'Search for services (e.g. plumbing, electrician...)'**
  String get searchServiceHint;

  /// No description provided for @noFundisForService.
  ///
  /// In en, this message translates to:
  /// **'No fundis for {service}'**
  String noFundisForService(String service);

  /// No description provided for @refreshed.
  ///
  /// In en, this message translates to:
  /// **'Refreshed successfully'**
  String get refreshed;

  /// No description provided for @refreshFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to refresh data'**
  String get refreshFailed;

  /// No description provided for @pullToRefresh.
  ///
  /// In en, this message translates to:
  /// **'Pull to refresh'**
  String get pullToRefresh;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @showList.
  ///
  /// In en, this message translates to:
  /// **'Show List'**
  String get showList;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @jobsCompleted.
  ///
  /// In en, this message translates to:
  /// **'jobs completed'**
  String get jobsCompleted;

  /// No description provided for @rating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get rating;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @noJobsYet.
  ///
  /// In en, this message translates to:
  /// **'No jobs yet'**
  String get noJobsYet;

  /// No description provided for @noJobsHint.
  ///
  /// In en, this message translates to:
  /// **'Accepted requests you mark as a job appear here.'**
  String get noJobsHint;

  /// No description provided for @activeJobs.
  ///
  /// In en, this message translates to:
  /// **'Active Jobs'**
  String get activeJobs;

  /// No description provided for @completedJobs.
  ///
  /// In en, this message translates to:
  /// **'Completed Jobs'**
  String get completedJobs;

  /// No description provided for @markComplete.
  ///
  /// In en, this message translates to:
  /// **'Mark Complete'**
  String get markComplete;

  /// No description provided for @jobCompletedMsg.
  ///
  /// In en, this message translates to:
  /// **'Job completed. Ticket closed.'**
  String get jobCompletedMsg;

  /// No description provided for @couldNotStartCompletion.
  ///
  /// In en, this message translates to:
  /// **'Could not start completion.'**
  String get couldNotStartCompletion;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetails;

  /// No description provided for @statusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get statusInProgress;

  /// No description provided for @statusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusCompleted;

  /// No description provided for @noJobsMatchFilter.
  ///
  /// In en, this message translates to:
  /// **'No jobs match your filters'**
  String get noJobsMatchFilter;

  /// No description provided for @noContactDetails.
  ///
  /// In en, this message translates to:
  /// **'No contact details available for this fundi.'**
  String get noContactDetails;

  /// No description provided for @rateThisJob.
  ///
  /// In en, this message translates to:
  /// **'Rate this job'**
  String get rateThisJob;

  /// No description provided for @contactFundi.
  ///
  /// In en, this message translates to:
  /// **'Contact Fundi'**
  String get contactFundi;

  /// No description provided for @noTicketsYet.
  ///
  /// In en, this message translates to:
  /// **'No tickets yet'**
  String get noTicketsYet;

  /// No description provided for @noTicketsHint.
  ///
  /// In en, this message translates to:
  /// **'A ticket is created when you mark a request as a job.'**
  String get noTicketsHint;

  /// No description provided for @fundiLabel.
  ///
  /// In en, this message translates to:
  /// **'Fundi'**
  String get fundiLabel;

  /// No description provided for @createdOn.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get createdOn;

  /// No description provided for @completedOn.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completedOn;

  /// No description provided for @searchByFundiName.
  ///
  /// In en, this message translates to:
  /// **'Search by fundi name...'**
  String get searchByFundiName;

  /// No description provided for @checkBackLater.
  ///
  /// In en, this message translates to:
  /// **'Check back later for updates from our technicians.'**
  String get checkBackLater;

  /// No description provided for @noPostsMatch.
  ///
  /// In en, this message translates to:
  /// **'No posts match'**
  String get noPostsMatch;

  /// No description provided for @imageNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Image not available'**
  String get imageNotAvailable;

  /// No description provided for @video.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get video;

  /// No description provided for @tapToPlayVideo.
  ///
  /// In en, this message translates to:
  /// **'Tap to play video'**
  String get tapToPlayVideo;

  /// No description provided for @startedOn.
  ///
  /// In en, this message translates to:
  /// **'Started'**
  String get startedOn;

  /// No description provided for @completedOnLabel.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completedOnLabel;

  /// No description provided for @descriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get descriptionLabel;

  /// No description provided for @ticketLabel.
  ///
  /// In en, this message translates to:
  /// **'Ticket'**
  String get ticketLabel;

  /// No description provided for @payForJob.
  ///
  /// In en, this message translates to:
  /// **'Pay for Job'**
  String get payForJob;

  /// No description provided for @confirmCompletion.
  ///
  /// In en, this message translates to:
  /// **'Confirm Completion'**
  String get confirmCompletion;

  /// No description provided for @sendingSmsCode.
  ///
  /// In en, this message translates to:
  /// **'Sending SMS Code…'**
  String get sendingSmsCode;

  /// No description provided for @jobCompletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Job completed successfully!'**
  String get jobCompletedSuccess;

  /// No description provided for @jobNotFound.
  ///
  /// In en, this message translates to:
  /// **'Job not found'**
  String get jobNotFound;

  /// No description provided for @couldNotSendSms.
  ///
  /// In en, this message translates to:
  /// **'Could not send verification code via SMS.'**
  String get couldNotSendSms;

  /// No description provided for @enterSixDigitCode.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code received via SMS.'**
  String get enterSixDigitCode;

  /// No description provided for @invalidCodeTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Invalid code. Check SMS and try again.'**
  String get invalidCodeTryAgain;

  /// No description provided for @couldNotResendSms.
  ///
  /// In en, this message translates to:
  /// **'Could not resend SMS code.'**
  String get couldNotResendSms;

  /// No description provided for @enterSmsCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code sent by SMS to your phone to confirm completion.'**
  String get enterSmsCodeHint;

  /// No description provided for @verifyAndComplete.
  ///
  /// In en, this message translates to:
  /// **'Verify & Complete'**
  String get verifyAndComplete;

  /// No description provided for @resendIn.
  ///
  /// In en, this message translates to:
  /// **'Resend in {seconds}s'**
  String resendIn(int seconds);

  /// No description provided for @sending.
  ///
  /// In en, this message translates to:
  /// **'Sending…'**
  String get sending;

  /// No description provided for @confirmCompletionTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Completion'**
  String get confirmCompletionTitle;

  /// No description provided for @confirmCompletionBody.
  ///
  /// In en, this message translates to:
  /// **'Would you like to send the 6-digit verification code via SMS to complete this job?'**
  String get confirmCompletionBody;

  /// No description provided for @sendSmsCode.
  ///
  /// In en, this message translates to:
  /// **'Send SMS Code'**
  String get sendSmsCode;

  /// No description provided for @completionCodeHint.
  ///
  /// In en, this message translates to:
  /// **'------'**
  String get completionCodeHint;

  /// No description provided for @filterByFundiOrService.
  ///
  /// In en, this message translates to:
  /// **'Filter by fundi or service...'**
  String get filterByFundiOrService;

  /// No description provided for @allLabel.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allLabel;

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statusPending;

  /// No description provided for @statusAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get statusAccepted;

  /// No description provided for @statusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get statusRejected;

  /// No description provided for @statusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;

  /// No description provided for @statTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get statTotal;

  /// No description provided for @statClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get statClosed;

  /// No description provided for @noRequestsMatchFilter.
  ///
  /// In en, this message translates to:
  /// **'No requests match your filter'**
  String get noRequestsMatchFilter;

  /// No description provided for @sectionActiveRequests.
  ///
  /// In en, this message translates to:
  /// **'Active Requests'**
  String get sectionActiveRequests;

  /// No description provided for @sectionClosedRequests.
  ///
  /// In en, this message translates to:
  /// **'Closed Requests'**
  String get sectionClosedRequests;

  /// No description provided for @cancelAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelAction;

  /// No description provided for @viewJob.
  ///
  /// In en, this message translates to:
  /// **'View Job'**
  String get viewJob;

  /// No description provided for @chatAction.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chatAction;

  /// No description provided for @detailsAction.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get detailsAction;

  /// No description provided for @couldNotCancelRequest.
  ///
  /// In en, this message translates to:
  /// **'Could not cancel request.'**
  String get couldNotCancelRequest;

  /// No description provided for @markAsJob.
  ///
  /// In en, this message translates to:
  /// **'Mark as job'**
  String get markAsJob;

  /// No description provided for @markAsJobConfirm.
  ///
  /// In en, this message translates to:
  /// **'Start this job with {name}? A ticket will be created.'**
  String markAsJobConfirm(String name);

  /// No description provided for @couldNotCreateJob.
  ///
  /// In en, this message translates to:
  /// **'Could not create the job.'**
  String get couldNotCreateJob;

  /// No description provided for @timeAgoJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get timeAgoJustNow;

  /// No description provided for @timeAgoMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count}m ago'**
  String timeAgoMinutes(int count);

  /// No description provided for @timeAgoHours.
  ///
  /// In en, this message translates to:
  /// **'{count}h ago'**
  String timeAgoHours(int count);

  /// No description provided for @timeAgoDays.
  ///
  /// In en, this message translates to:
  /// **'{count}d ago'**
  String timeAgoDays(int count);

  /// No description provided for @requestDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Request Details'**
  String get requestDetailsTitle;

  /// No description provided for @fieldService.
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get fieldService;

  /// No description provided for @fieldCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get fieldCategory;

  /// No description provided for @fieldDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get fieldDescription;

  /// No description provided for @fieldFundi.
  ///
  /// In en, this message translates to:
  /// **'Fundi'**
  String get fieldFundi;

  /// No description provided for @fieldArea.
  ///
  /// In en, this message translates to:
  /// **'Area'**
  String get fieldArea;

  /// No description provided for @fieldRequestedOn.
  ///
  /// In en, this message translates to:
  /// **'Requested On'**
  String get fieldRequestedOn;

  /// No description provided for @fieldStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get fieldStatus;

  /// No description provided for @closeAction.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeAction;

  /// No description provided for @signInToReadBlog.
  ///
  /// In en, this message translates to:
  /// **'Sign in or create an account to read our blog and tips.'**
  String get signInToReadBlog;

  /// No description provided for @signInToRequests.
  ///
  /// In en, this message translates to:
  /// **'Sign in or create an account to send and track your service requests.'**
  String get signInToRequests;

  /// No description provided for @signInToJobs.
  ///
  /// In en, this message translates to:
  /// **'Sign in or create an account to view and manage your jobs.'**
  String get signInToJobs;

  /// No description provided for @signInToProfile.
  ///
  /// In en, this message translates to:
  /// **'Sign in or create an account to see and edit your profile.'**
  String get signInToProfile;

  /// No description provided for @signInToTickets.
  ///
  /// In en, this message translates to:
  /// **'Sign in or create an account to view your tickets.'**
  String get signInToTickets;

  /// No description provided for @signInToChat.
  ///
  /// In en, this message translates to:
  /// **'Sign in or create an account to chat with fundis.'**
  String get signInToChat;

  /// No description provided for @signInToNotifications.
  ///
  /// In en, this message translates to:
  /// **'Sign in or create an account to see your notifications.'**
  String get signInToNotifications;

  /// No description provided for @signInToRefresh.
  ///
  /// In en, this message translates to:
  /// **'Sign in or create an account to refresh your data.'**
  String get signInToRefresh;

  /// No description provided for @guestUser.
  ///
  /// In en, this message translates to:
  /// **'Guest User'**
  String get guestUser;

  /// No description provided for @notLoggedIn.
  ///
  /// In en, this message translates to:
  /// **'Not logged in'**
  String get notLoggedIn;

  /// No description provided for @caughtUp.
  ///
  /// In en, this message translates to:
  /// **'You are all caught up'**
  String get caughtUp;

  /// No description provided for @notifyWhenNew.
  ///
  /// In en, this message translates to:
  /// **'We will notify you when there is something new.'**
  String get notifyWhenNew;

  /// No description provided for @chatLabel.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chatLabel;

  /// No description provided for @newRequestLabel.
  ///
  /// In en, this message translates to:
  /// **'New Request'**
  String get newRequestLabel;

  /// No description provided for @requestAcceptedLabel.
  ///
  /// In en, this message translates to:
  /// **'Request Accepted'**
  String get requestAcceptedLabel;

  /// No description provided for @requestRejectedLabel.
  ///
  /// In en, this message translates to:
  /// **'Request Rejected'**
  String get requestRejectedLabel;

  /// No description provided for @notificationLabel.
  ///
  /// In en, this message translates to:
  /// **'Notification'**
  String get notificationLabel;

  /// No description provided for @unreadNotifications.
  ///
  /// In en, this message translates to:
  /// **'unread notifications'**
  String get unreadNotifications;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'sw'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'sw': return AppLocalizationsSw();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
