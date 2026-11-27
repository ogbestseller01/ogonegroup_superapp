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
  /// **'NETSAF FUNDI APP'**
  String get appTitle;

  /// No description provided for @fundiAppTitle.
  ///
  /// In en, this message translates to:
  /// **'NETSAF FUNDI APP'**
  String get fundiAppTitle;

  /// No description provided for @hello.
  ///
  /// In en, this message translates to:
  /// **'Hello'**
  String get hello;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

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

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logout;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @aiAssistant.
  ///
  /// In en, this message translates to:
  /// **'AI Assistant'**
  String get aiAssistant;

  /// No description provided for @chat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chat;

  /// No description provided for @blog.
  ///
  /// In en, this message translates to:
  /// **'Blog'**
  String get blog;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon!'**
  String get comingSoon;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// Shown when the registration draft is missing during OTP step
  ///
  /// In en, this message translates to:
  /// **'Registration session lost. Please start again.'**
  String get registrationSessionLost;

  /// Confirmation after resending OTP
  ///
  /// In en, this message translates to:
  /// **'OTP resent to {identifier}'**
  String otpResentTo(String identifier);

  /// Error when OTP resend fails
  ///
  /// In en, this message translates to:
  /// **'Failed to resend OTP.'**
  String get failedToResendOtp;

  /// Countdown before OTP can be resent
  ///
  /// In en, this message translates to:
  /// **'Resend available in {seconds}s'**
  String resendAvailableIn(int seconds);

  /// Prompt to resend OTP
  ///
  /// In en, this message translates to:
  /// **'Didn\'t receive the code?'**
  String get didntReceiveCode;

  /// No description provided for @sending.
  ///
  /// In en, this message translates to:
  /// **'Sending…'**
  String sending(String percent);

  /// Shown while resend countdown is active
  ///
  /// In en, this message translates to:
  /// **'Wait'**
  String get wait;

  /// Resend OTP action label
  ///
  /// In en, this message translates to:
  /// **'Resend'**
  String get resend;

  /// Validation message for OTP field
  ///
  /// In en, this message translates to:
  /// **'Enter 6-digit OTP'**
  String get enter6DigitOtp;

  /// Validation message for password field
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get passwordMinLength;

  /// Validation message for confirm password
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// Validation message for email field
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get enterValidEmail;

  /// No description provided for @regStep1Failed.
  ///
  /// In en, this message translates to:
  /// **'Could not create your account. Please check your details and try again.'**
  String get regStep1Failed;

  /// No description provided for @regOtpDeliveryFailed.
  ///
  /// In en, this message translates to:
  /// **'Account created, but we could not send the code right now. Tap Resend on the next screen.'**
  String get regOtpDeliveryFailed;

  /// No description provided for @regOtpSentSms.
  ///
  /// In en, this message translates to:
  /// **'We sent a 6-digit verification code via SMS to {recipient}'**
  String regOtpSentSms(String recipient);

  /// No description provided for @regOtpSentEmail.
  ///
  /// In en, this message translates to:
  /// **'We sent a 6-digit verification code to your email {recipient}'**
  String regOtpSentEmail(String recipient);

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBack;

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

  /// No description provided for @becomeFundi.
  ///
  /// In en, this message translates to:
  /// **'Become a Fundi'**
  String get becomeFundi;

  /// No description provided for @joinProvider.
  ///
  /// In en, this message translates to:
  /// **'Join as a service provider'**
  String get joinProvider;

  /// No description provided for @fundiRegistration.
  ///
  /// In en, this message translates to:
  /// **'Fundi Registration'**
  String get fundiRegistration;

  /// No description provided for @fillDetails.
  ///
  /// In en, this message translates to:
  /// **'Fill in your details to start serving customers'**
  String get fillDetails;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @serviceArea.
  ///
  /// In en, this message translates to:
  /// **'Service Area'**
  String get serviceArea;

  /// No description provided for @selectServices.
  ///
  /// In en, this message translates to:
  /// **'Select Services'**
  String get selectServices;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @registerAsFundi.
  ///
  /// In en, this message translates to:
  /// **'Register as Fundi'**
  String get registerAsFundi;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

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
  /// **'Enter the 6-digit OTP'**
  String get enterOtp;

  /// No description provided for @otpSent.
  ///
  /// In en, this message translates to:
  /// **'A 6-digit code has been sent to your email'**
  String get otpSent;

  /// No description provided for @verifyOtp.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
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

  /// No description provided for @loginBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get loginBack;

  /// No description provided for @loginTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get loginTheme;

  /// No description provided for @loginThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get loginThemeLight;

  /// No description provided for @loginThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get loginThemeDark;

  /// No description provided for @loginEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get loginEmail;

  /// No description provided for @loginPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get loginPhone;

  /// No description provided for @loginEmailHint.
  ///
  /// In en, this message translates to:
  /// **'you@example.com'**
  String get loginEmailHint;

  /// No description provided for @loginPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'712345678'**
  String get loginPhoneHint;

  /// No description provided for @loginEnterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get loginEnterValidEmail;

  /// No description provided for @loginEnterPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter phone number'**
  String get loginEnterPhone;

  /// No description provided for @loginPhoneDigits.
  ///
  /// In en, this message translates to:
  /// **'7–15 digits required'**
  String get loginPhoneDigits;

  /// No description provided for @loginPasswordMin.
  ///
  /// In en, this message translates to:
  /// **'Min 6 characters'**
  String get loginPasswordMin;

  /// No description provided for @loginSearchCountry.
  ///
  /// In en, this message translates to:
  /// **'Search country...'**
  String get loginSearchCountry;

  /// No description provided for @loginNoCountry.
  ///
  /// In en, this message translates to:
  /// **'No country found'**
  String get loginNoCountry;

  /// No description provided for @loginIAgree.
  ///
  /// In en, this message translates to:
  /// **'I agree to the'**
  String get loginIAgree;

  /// No description provided for @loginTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get loginTerms;

  /// No description provided for @loginAnd.
  ///
  /// In en, this message translates to:
  /// **'and'**
  String get loginAnd;

  /// No description provided for @loginPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get loginPrivacy;

  /// No description provided for @loginAcceptTerms.
  ///
  /// In en, this message translates to:
  /// **'Please accept the Terms & Conditions to continue'**
  String get loginAcceptTerms;

  /// No description provided for @loginBrandTagline.
  ///
  /// In en, this message translates to:
  /// **'Hire. Manage. Get it done.'**
  String get loginBrandTagline;

  /// No description provided for @loginHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get loginHome;

  /// No description provided for @loginRememberMe.
  ///
  /// In en, this message translates to:
  /// **'Remember me'**
  String get loginRememberMe;

  /// No description provided for @loginContinueAs.
  ///
  /// In en, this message translates to:
  /// **'Continue as {name}'**
  String loginContinueAs(String name);

  /// No description provided for @loginUseAnother.
  ///
  /// In en, this message translates to:
  /// **'Use another account'**
  String get loginUseAnother;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed. Please try again.'**
  String get loginFailed;

  /// No description provided for @loginNetworkError.
  ///
  /// In en, this message translates to:
  /// **'Network error. Check your connection and try again.'**
  String get loginNetworkError;

  /// No description provided for @loginNotFundiAccount.
  ///
  /// In en, this message translates to:
  /// **'This account is not a Fundi account. Please use the NearbyFundi customer app.'**
  String get loginNotFundiAccount;

  /// No description provided for @loginSavedLoginInvalid.
  ///
  /// In en, this message translates to:
  /// **'Saved login is no longer valid. Please sign in again.'**
  String get loginSavedLoginInvalid;

  /// No description provided for @loginSessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Session expired. Please sign in again.'**
  String get loginSessionExpired;

  /// No description provided for @loginRegistrationExpired.
  ///
  /// In en, this message translates to:
  /// **'Registration session expired. Please start over.'**
  String get loginRegistrationExpired;

  /// No description provided for @loginPhoneTaken.
  ///
  /// In en, this message translates to:
  /// **'This phone number is already registered. Please log in or use a different number.'**
  String get loginPhoneTaken;

  /// No description provided for @loginPhoneDeleted.
  ///
  /// In en, this message translates to:
  /// **'This phone number belongs to a deleted account. Contact support to restore it, or use a different number.'**
  String get loginPhoneDeleted;

  /// No description provided for @loginEmailTaken.
  ///
  /// In en, this message translates to:
  /// **'This email is already registered. Please log in or use a different email.'**
  String get loginEmailTaken;

  /// No description provided for @loginIdTaken.
  ///
  /// In en, this message translates to:
  /// **'This ID number has already been registered. Contact support if you believe this is a mistake.'**
  String get loginIdTaken;

  /// No description provided for @loginStepsIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Some registration steps are incomplete. Please go back and complete them before submitting.'**
  String get loginStepsIncomplete;

  /// No description provided for @loginSubmitFailed.
  ///
  /// In en, this message translates to:
  /// **'Registration submission failed. Please try again.'**
  String get loginSubmitFailed;

  /// No description provided for @myProfile.
  ///
  /// In en, this message translates to:
  /// **' Profile'**
  String get myProfile;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @profileDetails.
  ///
  /// In en, this message translates to:
  /// **'Profile Details'**
  String get profileDetails;

  /// No description provided for @updateInfo.
  ///
  /// In en, this message translates to:
  /// **'Update Your Info'**
  String get updateInfo;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @bio.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get bio;

  /// No description provided for @hourlyRate.
  ///
  /// In en, this message translates to:
  /// **'Hourly Rate (TZS)'**
  String get hourlyRate;

  /// No description provided for @area.
  ///
  /// In en, this message translates to:
  /// **'Area'**
  String get area;

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

  /// No description provided for @tzs.
  ///
  /// In en, this message translates to:
  /// **'TZS'**
  String get tzs;

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

  /// No description provided for @servicesIOffer.
  ///
  /// In en, this message translates to:
  /// **'Services I offer'**
  String get servicesIOffer;

  /// No description provided for @noServicesSelected.
  ///
  /// In en, this message translates to:
  /// **'No services selected'**
  String get noServicesSelected;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @updateFailed.
  ///
  /// In en, this message translates to:
  /// **'Update failed. Please try again.'**
  String get updateFailed;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @newPost.
  ///
  /// In en, this message translates to:
  /// **'New Post'**
  String get newPost;

  /// No description provided for @photos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get photos;

  /// No description provided for @addAtLeastOnePhoto.
  ///
  /// In en, this message translates to:
  /// **'Add at least one photo.'**
  String get addAtLeastOnePhoto;

  /// No description provided for @failedToSavePost.
  ///
  /// In en, this message translates to:
  /// **'Failed to save post'**
  String get failedToSavePost;

  /// No description provided for @deleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete file'**
  String get deleteFailed;

  /// No description provided for @imageNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Image not available'**
  String get imageNotAvailable;

  /// No description provided for @portfolioEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Share your work with photos to build your portfolio.'**
  String get portfolioEmptySubtitle;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m ago'**
  String minutesAgo(int minutes);

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{hours}h ago'**
  String hoursAgo(int hours);

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{days}d ago'**
  String daysAgo(int days);

  /// No description provided for @editPost.
  ///
  /// In en, this message translates to:
  /// **'Edit Post'**
  String get editPost;

  /// No description provided for @deletePostAction.
  ///
  /// In en, this message translates to:
  /// **'Delete Post'**
  String get deletePostAction;

  /// No description provided for @addPost.
  ///
  /// In en, this message translates to:
  /// **'Add Post'**
  String get addPost;

  /// No description provided for @portfolioFailedToLoad.
  ///
  /// In en, this message translates to:
  /// **'Failed to load portfolio'**
  String get portfolioFailedToLoad;

  /// No description provided for @portfolioUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update portfolio'**
  String get portfolioUpdateFailed;

  /// No description provided for @portfolioDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete post'**
  String get portfolioDeleteFailed;

  /// No description provided for @requests.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get requests;

  /// No description provided for @filterByCustomerService.
  ///
  /// In en, this message translates to:
  /// **'Filter by customer or service...'**
  String get filterByCustomerService;

  /// No description provided for @noRequests.
  ///
  /// In en, this message translates to:
  /// **'No requests yet.'**
  String get noRequests;

  /// No description provided for @noMatchingRequests.
  ///
  /// In en, this message translates to:
  /// **'No matching requests'**
  String get noMatchingRequests;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @requestAccepted.
  ///
  /// In en, this message translates to:
  /// **'Request accepted'**
  String get requestAccepted;

  /// No description provided for @requestRejected.
  ///
  /// In en, this message translates to:
  /// **'Request rejected'**
  String get requestRejected;

  /// No description provided for @failedToAccept.
  ///
  /// In en, this message translates to:
  /// **'Failed to accept'**
  String get failedToAccept;

  /// No description provided for @failedToReject.
  ///
  /// In en, this message translates to:
  /// **'Failed to reject'**
  String get failedToReject;

  /// No description provided for @viewJob.
  ///
  /// In en, this message translates to:
  /// **'View Job'**
  String get viewJob;

  /// No description provided for @chatWithCustomer.
  ///
  /// In en, this message translates to:
  /// **'Chat with Customer'**
  String get chatWithCustomer;

  /// No description provided for @jobLabel.
  ///
  /// In en, this message translates to:
  /// **'Job {number}'**
  String jobLabel(String number);

  /// No description provided for @jobWithStatus.
  ///
  /// In en, this message translates to:
  /// **'Job {number} • {status}'**
  String jobWithStatus(String number, String status);

  /// No description provided for @requestRejectedBanner.
  ///
  /// In en, this message translates to:
  /// **'Request Rejected'**
  String get requestRejectedBanner;

  /// No description provided for @requestCancelledBanner.
  ///
  /// In en, this message translates to:
  /// **'Request Cancelled'**
  String get requestCancelledBanner;

  /// No description provided for @failedToStartChat.
  ///
  /// In en, this message translates to:
  /// **'Failed to start chat: {error}'**
  String failedToStartChat(String error);

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

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @statTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get statTotal;

  /// No description provided for @statPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statPending;

  /// No description provided for @statAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get statAccepted;

  /// No description provided for @typing.
  ///
  /// In en, this message translates to:
  /// **'Typing...'**
  String get typing;

  /// No description provided for @sayHelloToStart.
  ///
  /// In en, this message translates to:
  /// **'Say hello to start chatting!'**
  String get sayHelloToStart;

  /// No description provided for @replyEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Reply…'**
  String get replyEllipsis;

  /// No description provided for @message.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get message;

  /// No description provided for @attach.
  ///
  /// In en, this message translates to:
  /// **'Attach'**
  String get attach;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copied;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @forwarded.
  ///
  /// In en, this message translates to:
  /// **'Forwarded'**
  String get forwarded;

  /// No description provided for @deleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get deleted;

  /// No description provided for @starred.
  ///
  /// In en, this message translates to:
  /// **'Starred'**
  String get starred;

  /// No description provided for @removedFromStarred.
  ///
  /// In en, this message translates to:
  /// **'Removed from starred'**
  String get removedFromStarred;

  /// No description provided for @messagePinned.
  ///
  /// In en, this message translates to:
  /// **'Message pinned'**
  String get messagePinned;

  /// No description provided for @messageUnpinned.
  ///
  /// In en, this message translates to:
  /// **'Message unpinned'**
  String get messageUnpinned;

  /// No description provided for @deleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete message?'**
  String get deleteMessage;

  /// No description provided for @deleteMessages.
  ///
  /// In en, this message translates to:
  /// **'Delete {count} messages?'**
  String deleteMessages(int count);

  /// No description provided for @deleteForEveryone.
  ///
  /// In en, this message translates to:
  /// **'Delete for everyone'**
  String get deleteForEveryone;

  /// No description provided for @deleteForEveryoneSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Removed for both of you'**
  String get deleteForEveryoneSubtitle;

  /// No description provided for @deleteForMe.
  ///
  /// In en, this message translates to:
  /// **'Delete for me'**
  String get deleteForMe;

  /// No description provided for @deleteForMeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Only removed on this phone'**
  String get deleteForMeSubtitle;

  /// No description provided for @deleteEveryoneFailed.
  ///
  /// In en, this message translates to:
  /// **'{count} message(s) could not be deleted for everyone.'**
  String deleteEveryoneFailed(int count);

  /// No description provided for @originalMessageUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The original message is no longer available.'**
  String get originalMessageUnavailable;

  /// No description provided for @fileTypeNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'This file type is not allowed.'**
  String get fileTypeNotAllowed;

  /// No description provided for @fileTooLarge.
  ///
  /// In en, this message translates to:
  /// **'File too large. Max {limit} MB for this type.'**
  String fileTooLarge(int limit);

  /// No description provided for @attachCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get attachCamera;

  /// No description provided for @attachPhotos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get attachPhotos;

  /// No description provided for @attachVideo.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get attachVideo;

  /// No description provided for @attachDocument.
  ///
  /// In en, this message translates to:
  /// **'Document'**
  String get attachDocument;

  /// No description provided for @attachSizeHint.
  ///
  /// In en, this message translates to:
  /// **'Photos 5 MB · Videos 20 MB · Files 15 MB'**
  String get attachSizeHint;

  /// No description provided for @pinnedMessage.
  ///
  /// In en, this message translates to:
  /// **'Pinned message'**
  String get pinnedMessage;

  /// No description provided for @pinnedXofY.
  ///
  /// In en, this message translates to:
  /// **'Pinned {i} of {n}'**
  String pinnedXofY(int i, int n);

  /// No description provided for @you.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get you;

  /// No description provided for @mediaLinksDocs.
  ///
  /// In en, this message translates to:
  /// **'Media, links & docs'**
  String get mediaLinksDocs;

  /// No description provided for @starredMessages.
  ///
  /// In en, this message translates to:
  /// **'Starred messages'**
  String get starredMessages;

  /// No description provided for @mediaTab.
  ///
  /// In en, this message translates to:
  /// **'Media'**
  String get mediaTab;

  /// No description provided for @docsTab.
  ///
  /// In en, this message translates to:
  /// **'Docs'**
  String get docsTab;

  /// No description provided for @linksTab.
  ///
  /// In en, this message translates to:
  /// **'Links'**
  String get linksTab;

  /// No description provided for @noMedia.
  ///
  /// In en, this message translates to:
  /// **'No media'**
  String get noMedia;

  /// No description provided for @noDocuments.
  ///
  /// In en, this message translates to:
  /// **'No documents'**
  String get noDocuments;

  /// No description provided for @noLinks.
  ///
  /// In en, this message translates to:
  /// **'No links'**
  String get noLinks;

  /// No description provided for @noStarredMessages.
  ///
  /// In en, this message translates to:
  /// **'No starred messages'**
  String get noStarredMessages;

  /// No description provided for @file.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get file;

  /// No description provided for @customers.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get customers;

  /// No description provided for @archivedChats.
  ///
  /// In en, this message translates to:
  /// **'Archived Chats'**
  String get archivedChats;

  /// No description provided for @viewActiveChats.
  ///
  /// In en, this message translates to:
  /// **'View Active Chats'**
  String get viewActiveChats;

  /// No description provided for @viewArchivedChats.
  ///
  /// In en, this message translates to:
  /// **'View Archived Chats'**
  String get viewArchivedChats;

  /// No description provided for @searchCustomers.
  ///
  /// In en, this message translates to:
  /// **'Search customers'**
  String get searchCustomers;

  /// No description provided for @filterUnread.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get filterUnread;

  /// No description provided for @filterUnreadCount.
  ///
  /// In en, this message translates to:
  /// **'Unread {count}'**
  String filterUnreadCount(int count);

  /// No description provided for @filterPinned.
  ///
  /// In en, this message translates to:
  /// **'Pinned'**
  String get filterPinned;

  /// No description provided for @pinChat.
  ///
  /// In en, this message translates to:
  /// **'Pin chat'**
  String get pinChat;

  /// No description provided for @unpinChat.
  ///
  /// In en, this message translates to:
  /// **'Unpin chat'**
  String get unpinChat;

  /// No description provided for @archiveChat.
  ///
  /// In en, this message translates to:
  /// **'Archive chat'**
  String get archiveChat;

  /// No description provided for @unarchiveChat.
  ///
  /// In en, this message translates to:
  /// **'Unarchive chat'**
  String get unarchiveChat;

  /// No description provided for @deleteChat.
  ///
  /// In en, this message translates to:
  /// **'Delete chat'**
  String get deleteChat;

  /// No description provided for @deleteChatWith.
  ///
  /// In en, this message translates to:
  /// **'Delete chat with {name}?'**
  String deleteChatWith(String name);

  /// No description provided for @deleteChatWarning.
  ///
  /// In en, this message translates to:
  /// **'All messages and files will be removed for both of you.'**
  String get deleteChatWarning;

  /// No description provided for @noMatchingConversations.
  ///
  /// In en, this message translates to:
  /// **'No matching conversations'**
  String get noMatchingConversations;

  /// No description provided for @noArchivedChats.
  ///
  /// In en, this message translates to:
  /// **'No archived chats'**
  String get noArchivedChats;

  /// No description provided for @reply.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get reply;

  /// No description provided for @noConversationsYet.
  ///
  /// In en, this message translates to:
  /// **'No conversations yet'**
  String get noConversationsYet;

  /// No description provided for @customersWillAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Customers will appear here when they message you'**
  String get customersWillAppearHere;

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

  /// No description provided for @photoEmoji.
  ///
  /// In en, this message translates to:
  /// **'📷 Photo'**
  String get photoEmoji;

  /// No description provided for @fileEmoji.
  ///
  /// In en, this message translates to:
  /// **'📁 File'**
  String get fileEmoji;

  /// No description provided for @replyChip.
  ///
  /// In en, this message translates to:
  /// **'↩ {sender}: {text}'**
  String replyChip(String sender, String text);

  /// No description provided for @backTooltip.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get backTooltip;

  /// No description provided for @refreshTooltip.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refreshTooltip;

  /// No description provided for @noCustomersYet.
  ///
  /// In en, this message translates to:
  /// **'No customers yet'**
  String get noCustomersYet;

  /// No description provided for @customersWillAppear.
  ///
  /// In en, this message translates to:
  /// **'Customers will appear here when they message you'**
  String get customersWillAppear;

  /// No description provided for @deleteChatConfirmation.
  ///
  /// In en, this message translates to:
  /// **'All messages and files will be removed for both of you.'**
  String get deleteChatConfirmation;

  /// No description provided for @chatDeleted.
  ///
  /// In en, this message translates to:
  /// **'Chat deleted'**
  String get chatDeleted;

  /// No description provided for @failedToDeleteChat.
  ///
  /// In en, this message translates to:
  /// **'Could not delete the chat'**
  String get failedToDeleteChat;

  /// No description provided for @chatArchived.
  ///
  /// In en, this message translates to:
  /// **'Chat archived'**
  String get chatArchived;

  /// No description provided for @chatUnarchived.
  ///
  /// In en, this message translates to:
  /// **'Chat unarchived'**
  String get chatUnarchived;

  /// No description provided for @forward.
  ///
  /// In en, this message translates to:
  /// **'Forward'**
  String get forward;

  /// No description provided for @star.
  ///
  /// In en, this message translates to:
  /// **'Star'**
  String get star;

  /// No description provided for @unstar.
  ///
  /// In en, this message translates to:
  /// **'Unstar'**
  String get unstar;

  /// No description provided for @pin.
  ///
  /// In en, this message translates to:
  /// **'Pin'**
  String get pin;

  /// No description provided for @unpin.
  ///
  /// In en, this message translates to:
  /// **'Unpin'**
  String get unpin;

  /// No description provided for @info.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get info;

  /// No description provided for @select.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get select;

  /// No description provided for @savedToGallery.
  ///
  /// In en, this message translates to:
  /// **'Saved to your gallery'**
  String get savedToGallery;

  /// No description provided for @noAppToOpen.
  ///
  /// In en, this message translates to:
  /// **'No app installed that can open this file type.'**
  String get noAppToOpen;

  /// No description provided for @photo.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get photo;

  /// No description provided for @videoFile.
  ///
  /// In en, this message translates to:
  /// **'🎥 Video'**
  String get videoFile;

  /// No description provided for @attachment.
  ///
  /// In en, this message translates to:
  /// **'📎 Attachment'**
  String get attachment;

  /// No description provided for @forwardedLower.
  ///
  /// In en, this message translates to:
  /// **'forwarded'**
  String get forwardedLower;

  /// No description provided for @video.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get video;

  /// No description provided for @couldNotOpenFile.
  ///
  /// In en, this message translates to:
  /// **'Could not open this file.'**
  String get couldNotOpenFile;

  /// No description provided for @allowGalleryAccess.
  ///
  /// In en, this message translates to:
  /// **'Allow gallery access to save this file.'**
  String get allowGalleryAccess;

  /// No description provided for @galleryPluginMissing.
  ///
  /// In en, this message translates to:
  /// **'Gallery plugin not installed in this build. Opening share sheet instead.'**
  String get galleryPluginMissing;

  /// No description provided for @couldNotSaveToGallery.
  ///
  /// In en, this message translates to:
  /// **'Could not save to the gallery.'**
  String get couldNotSaveToGallery;

  /// No description provided for @couldNotPlayVideo.
  ///
  /// In en, this message translates to:
  /// **'Could not play this video.'**
  String get couldNotPlayVideo;

  /// No description provided for @saveToGallery.
  ///
  /// In en, this message translates to:
  /// **'Save to gallery'**
  String get saveToGallery;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @messageDeleted.
  ///
  /// In en, this message translates to:
  /// **'Message deleted'**
  String get messageDeleted;

  /// No description provided for @notSentTapToRetry.
  ///
  /// In en, this message translates to:
  /// **'Not sent · Tap to retry'**
  String get notSentTapToRetry;

  /// No description provided for @errorTapToRetry.
  ///
  /// In en, this message translates to:
  /// **'{error} · Tap to retry'**
  String errorTapToRetry(String error);

  /// No description provided for @saveShare.
  ///
  /// In en, this message translates to:
  /// **'Save / share'**
  String get saveShare;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @forwardMessageTo.
  ///
  /// In en, this message translates to:
  /// **'Forward message to…'**
  String get forwardMessageTo;

  /// No description provided for @forwardMessagesTo.
  ///
  /// In en, this message translates to:
  /// **'Forward {count} messages to…'**
  String forwardMessagesTo(int count);

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @noChatsToForwardTo.
  ///
  /// In en, this message translates to:
  /// **'No chats to forward to'**
  String get noChatsToForwardTo;

  /// No description provided for @sendingShort.
  ///
  /// In en, this message translates to:
  /// **'Sending…'**
  String get sendingShort;

  /// No description provided for @messageInfo.
  ///
  /// In en, this message translates to:
  /// **'Message info'**
  String get messageInfo;

  /// No description provided for @couldNotLoadInfo.
  ///
  /// In en, this message translates to:
  /// **'Could not load info'**
  String get couldNotLoadInfo;

  /// No description provided for @read.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get read;

  /// No description provided for @delivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get delivered;

  /// No description provided for @sent.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get sent;

  /// No description provided for @reactionsCount.
  ///
  /// In en, this message translates to:
  /// **'Reactions · {count}'**
  String reactionsCount(int count);

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

  /// No description provided for @lastSeen.
  ///
  /// In en, this message translates to:
  /// **'Last seen recently'**
  String get lastSeen;

  /// No description provided for @fundiDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get fundiDashboard;

  /// No description provided for @welcomeFundi.
  ///
  /// In en, this message translates to:
  /// **'Welcome Fundi'**
  String get welcomeFundi;

  /// No description provided for @manageServicesPosts.
  ///
  /// In en, this message translates to:
  /// **'Manage your services, posts and all your requests in one place.'**
  String get manageServicesPosts;

  /// No description provided for @stayConnected.
  ///
  /// In en, this message translates to:
  /// **'Stay Connected'**
  String get stayConnected;

  /// No description provided for @getNotifications.
  ///
  /// In en, this message translates to:
  /// **'Get instant notifications for new requests and updates.'**
  String get getNotifications;

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

  /// No description provided for @totalRequests.
  ///
  /// In en, this message translates to:
  /// **'Total Requests'**
  String get totalRequests;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @myPosts.
  ///
  /// In en, this message translates to:
  /// **' Posts'**
  String get myPosts;

  /// No description provided for @noPosts.
  ///
  /// In en, this message translates to:
  /// **'No posts yet.'**
  String get noPosts;

  /// No description provided for @createPost.
  ///
  /// In en, this message translates to:
  /// **'Create your first post'**
  String get createPost;

  /// No description provided for @createPostTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Post'**
  String get createPostTitle;

  /// No description provided for @editPostTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Post'**
  String get editPostTitle;

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

  /// No description provided for @postDeleted.
  ///
  /// In en, this message translates to:
  /// **'Post deleted'**
  String get postDeleted;

  /// No description provided for @deletePost.
  ///
  /// In en, this message translates to:
  /// **'Delete Post'**
  String get deletePost;

  /// No description provided for @filterByTitleContent.
  ///
  /// In en, this message translates to:
  /// **'Filter by title or content...'**
  String get filterByTitleContent;

  /// No description provided for @portfolio.
  ///
  /// In en, this message translates to:
  /// **'Portfolio'**
  String get portfolio;

  /// No description provided for @noPortfolio.
  ///
  /// In en, this message translates to:
  /// **'No portfolio items.'**
  String get noPortfolio;

  /// No description provided for @addPortfolio.
  ///
  /// In en, this message translates to:
  /// **'Add your first item'**
  String get addPortfolio;

  /// No description provided for @addPortfolioItem.
  ///
  /// In en, this message translates to:
  /// **'Add Portfolio Item'**
  String get addPortfolioItem;

  /// No description provided for @editPortfolioItem.
  ///
  /// In en, this message translates to:
  /// **'Edit Portfolio Item'**
  String get editPortfolioItem;

  /// No description provided for @itemAdded.
  ///
  /// In en, this message translates to:
  /// **'Item added'**
  String get itemAdded;

  /// No description provided for @itemUpdated.
  ///
  /// In en, this message translates to:
  /// **'Item updated'**
  String get itemUpdated;

  /// No description provided for @itemDeleted.
  ///
  /// In en, this message translates to:
  /// **'Item deleted'**
  String get itemDeleted;

  /// No description provided for @deletePortfolioItem.
  ///
  /// In en, this message translates to:
  /// **'Delete Portfolio Item'**
  String get deletePortfolioItem;

  /// No description provided for @filterByDescription.
  ///
  /// In en, this message translates to:
  /// **'Filter by description...'**
  String get filterByDescription;

  /// No description provided for @customer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get customer;

  /// No description provided for @service.
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get service;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @aboutUs.
  ///
  /// In en, this message translates to:
  /// **'About Us'**
  String get aboutUs;

  /// No description provided for @aboutFundiApp.
  ///
  /// In en, this message translates to:
  /// **'About NETSAF FUNDI APP'**
  String get aboutFundiApp;

  /// No description provided for @terms.
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get terms;

  /// No description provided for @faq.
  ///
  /// In en, this message translates to:
  /// **'FAQ'**
  String get faq;

  /// No description provided for @contactUs.
  ///
  /// In en, this message translates to:
  /// **'Contact Us'**
  String get contactUs;

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

  /// No description provided for @settingsPreferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get settingsPreferences;

  /// No description provided for @settingsInformation.
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get settingsInformation;

  /// No description provided for @settingsAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsAccount;

  /// No description provided for @settingsDarkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get settingsDarkMode;

  /// No description provided for @settingsDarkOn.
  ///
  /// In en, this message translates to:
  /// **'Dark theme enabled'**
  String get settingsDarkOn;

  /// No description provided for @settingsLightOn.
  ///
  /// In en, this message translates to:
  /// **'Light theme enabled'**
  String get settingsLightOn;

  /// No description provided for @pushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Push Notifications'**
  String get pushNotifications;

  /// No description provided for @receiveAlerts.
  ///
  /// In en, this message translates to:
  /// **'Receive alerts about requests'**
  String get receiveAlerts;

  /// No description provided for @viewNotifications.
  ///
  /// In en, this message translates to:
  /// **'View Notifications'**
  String get viewNotifications;

  /// No description provided for @seeAllNotifications.
  ///
  /// In en, this message translates to:
  /// **'See all your incoming notifications'**
  String get seeAllNotifications;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageSwahili.
  ///
  /// In en, this message translates to:
  /// **'Kiswahili'**
  String get languageSwahili;

  /// No description provided for @logoutConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get logoutConfirmation;

  /// No description provided for @logoutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Log out?'**
  String get logoutConfirmTitle;

  /// No description provided for @logoutConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'You’ll need to sign in again to access your account.'**
  String get logoutConfirmMessage;

  /// No description provided for @logoutFailed.
  ///
  /// In en, this message translates to:
  /// **'Logout failed: {error}'**
  String logoutFailed(Object error);

  /// No description provided for @loggingOut.
  ///
  /// In en, this message translates to:
  /// **'Logging out…'**
  String get loggingOut;

  /// No description provided for @deleteAccountConfirmation.
  ///
  /// In en, this message translates to:
  /// **'This action is permanent. All your data will be lost. Are you sure?'**
  String get deleteAccountConfirmation;

  /// No description provided for @couldNotDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Could not delete account'**
  String get couldNotDeleteAccount;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get profileUpdated;

  /// No description provided for @tapToChangePhoto.
  ///
  /// In en, this message translates to:
  /// **'Tap camera to change photo'**
  String get tapToChangePhoto;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name required'**
  String get nameRequired;

  /// No description provided for @nidaNumber.
  ///
  /// In en, this message translates to:
  /// **'NIDA Number'**
  String get nidaNumber;

  /// No description provided for @nidaHelperText.
  ///
  /// In en, this message translates to:
  /// **'Set during registration. Contact support to change.'**
  String get nidaHelperText;

  /// No description provided for @verifiedLabel.
  ///
  /// In en, this message translates to:
  /// **'✓ VERIFIED'**
  String get verifiedLabel;

  /// No description provided for @selectAtLeastOneService.
  ///
  /// In en, this message translates to:
  /// **'Select at least one service'**
  String get selectAtLeastOneService;

  /// No description provided for @editServices.
  ///
  /// In en, this message translates to:
  /// **'Edit services'**
  String get editServices;

  /// No description provided for @noServicesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No services available.'**
  String get noServicesAvailable;

  /// No description provided for @servicesUpdated.
  ///
  /// In en, this message translates to:
  /// **'Services updated'**
  String get servicesUpdated;

  /// No description provided for @typeAreaOrPickOnMap.
  ///
  /// In en, this message translates to:
  /// **'Type area or pick on map'**
  String get typeAreaOrPickOnMap;

  /// No description provided for @pickOnMap.
  ///
  /// In en, this message translates to:
  /// **'Pick on map'**
  String get pickOnMap;

  /// No description provided for @locationSetOnMap.
  ///
  /// In en, this message translates to:
  /// **'Location set on map'**
  String get locationSetOnMap;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @pickLocationOnMap.
  ///
  /// In en, this message translates to:
  /// **'Pick location on map'**
  String get pickLocationOnMap;

  /// No description provided for @searchAreaHint.
  ///
  /// In en, this message translates to:
  /// **'Search area, street, or landmark…'**
  String get searchAreaHint;

  /// No description provided for @gettingAddress.
  ///
  /// In en, this message translates to:
  /// **'Getting address…'**
  String get gettingAddress;

  /// No description provided for @tapMapToSelectLocation.
  ///
  /// In en, this message translates to:
  /// **'Tap on the map to select a location'**
  String get tapMapToSelectLocation;

  /// No description provided for @useThisLocation.
  ///
  /// In en, this message translates to:
  /// **'Use this location'**
  String get useThisLocation;

  /// No description provided for @selectedLocation.
  ///
  /// In en, this message translates to:
  /// **'Selected location'**
  String get selectedLocation;

  /// No description provided for @zoomIn.
  ///
  /// In en, this message translates to:
  /// **'Zoom in'**
  String get zoomIn;

  /// No description provided for @zoomOut.
  ///
  /// In en, this message translates to:
  /// **'Zoom out'**
  String get zoomOut;

  /// No description provided for @noNotificationsYet.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get noNotificationsYet;

  /// No description provided for @unreadNotifications.
  ///
  /// In en, this message translates to:
  /// **'unread notifications'**
  String get unreadNotifications;

  /// No description provided for @noNewNotifications.
  ///
  /// In en, this message translates to:
  /// **'No new notifications'**
  String get noNewNotifications;

  /// No description provided for @notification.
  ///
  /// In en, this message translates to:
  /// **'Notification'**
  String get notification;

  /// No description provided for @markAllAsRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get markAllAsRead;

  /// No description provided for @noMessagesYet.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get noMessagesYet;

  /// No description provided for @typeAMessage.
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get typeAMessage;

  /// No description provided for @messageCopied.
  ///
  /// In en, this message translates to:
  /// **'Message copied'**
  String get messageCopied;

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

  /// No description provided for @deleteMessageConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Delete this message?'**
  String get deleteMessageConfirmation;

  /// No description provided for @selectImage.
  ///
  /// In en, this message translates to:
  /// **'Select an image'**
  String get selectImage;

  /// No description provided for @image.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get image;

  /// No description provided for @voiceMessage.
  ///
  /// In en, this message translates to:
  /// **'Voice message'**
  String get voiceMessage;

  /// No description provided for @startChattingWithFundis.
  ///
  /// In en, this message translates to:
  /// **'Start chatting with customers near you'**
  String get startChattingWithFundis;

  /// No description provided for @viewProfile.
  ///
  /// In en, this message translates to:
  /// **'View Profile'**
  String get viewProfile;

  /// No description provided for @clearChat.
  ///
  /// In en, this message translates to:
  /// **'Clear Chat'**
  String get clearChat;

  /// No description provided for @blockUser.
  ///
  /// In en, this message translates to:
  /// **'Block User'**
  String get blockUser;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @document.
  ///
  /// In en, this message translates to:
  /// **'Document'**
  String get document;

  /// No description provided for @recordVoice.
  ///
  /// In en, this message translates to:
  /// **'Record voice'**
  String get recordVoice;

  /// No description provided for @stopRecording.
  ///
  /// In en, this message translates to:
  /// **'Stop recording'**
  String get stopRecording;

  /// No description provided for @downloadFile.
  ///
  /// In en, this message translates to:
  /// **'Download File'**
  String get downloadFile;

  /// No description provided for @deleteFile.
  ///
  /// In en, this message translates to:
  /// **'Delete File'**
  String get deleteFile;

  /// No description provided for @deleteConversation.
  ///
  /// In en, this message translates to:
  /// **'Delete Conversation'**
  String get deleteConversation;

  /// No description provided for @deleteConversationConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this entire conversation? This action cannot be undone.'**
  String get deleteConversationConfirmation;

  /// No description provided for @conversationDeleted.
  ///
  /// In en, this message translates to:
  /// **'Conversation deleted'**
  String get conversationDeleted;

  /// No description provided for @fileDownloaded.
  ///
  /// In en, this message translates to:
  /// **'File downloaded successfully'**
  String get fileDownloaded;

  /// No description provided for @fileDeleted.
  ///
  /// In en, this message translates to:
  /// **'File deleted successfully'**
  String get fileDeleted;

  /// No description provided for @downloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to download file'**
  String get downloadFailed;

  /// No description provided for @permissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Permission denied'**
  String get permissionDenied;

  /// No description provided for @storagePermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Storage permission denied'**
  String get storagePermissionDenied;

  /// No description provided for @photosPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Photos permission denied'**
  String get photosPermissionDenied;

  /// No description provided for @filterTiles.
  ///
  /// In en, this message translates to:
  /// **'Filter tiles...'**
  String get filterTiles;

  /// No description provided for @noMatchingTiles.
  ///
  /// In en, this message translates to:
  /// **'No matching tiles'**
  String get noMatchingTiles;

  /// No description provided for @noMatchingItems.
  ///
  /// In en, this message translates to:
  /// **'No matching items'**
  String get noMatchingItems;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @call.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get call;

  /// No description provided for @areYouSure.
  ///
  /// In en, this message translates to:
  /// **'Are you sure?'**
  String get areYouSure;

  /// No description provided for @selectServicesDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Services'**
  String get selectServicesDialogTitle;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @openFile.
  ///
  /// In en, this message translates to:
  /// **'Open File'**
  String get openFile;

  /// No description provided for @inProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get inProgress;

  /// No description provided for @markComplete.
  ///
  /// In en, this message translates to:
  /// **'Mark as Complete'**
  String get markComplete;

  /// No description provided for @requestCompleted.
  ///
  /// In en, this message translates to:
  /// **'Request completed'**
  String get requestCompleted;

  /// No description provided for @completeRequest.
  ///
  /// In en, this message translates to:
  /// **'Complete Request'**
  String get completeRequest;

  /// No description provided for @completeConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to mark this request as completed?'**
  String get completeConfirmation;

  /// No description provided for @completedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Request completed successfully!'**
  String get completedSuccess;

  /// No description provided for @failedToComplete.
  ///
  /// In en, this message translates to:
  /// **'Failed to complete request'**
  String get failedToComplete;

  /// No description provided for @startWork.
  ///
  /// In en, this message translates to:
  /// **'Start Work'**
  String get startWork;

  /// No description provided for @requestInProgress.
  ///
  /// In en, this message translates to:
  /// **'Request in progress'**
  String get requestInProgress;

  /// No description provided for @accepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get accepted;

  /// No description provided for @rejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get rejected;

  /// No description provided for @cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelled;

  /// No description provided for @filterByStatus.
  ///
  /// In en, this message translates to:
  /// **'Filter by status'**
  String get filterByStatus;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @noRequestsMatchFilter.
  ///
  /// In en, this message translates to:
  /// **'No requests match the selected filter'**
  String get noRequestsMatchFilter;

  /// No description provided for @subscriptions.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions'**
  String get subscriptions;

  /// No description provided for @mySubscriptions.
  ///
  /// In en, this message translates to:
  /// **'My Subscriptions'**
  String get mySubscriptions;

  /// No description provided for @subscriptionStatus.
  ///
  /// In en, this message translates to:
  /// **'Subscription Status'**
  String get subscriptionStatus;

  /// No description provided for @choosePlan.
  ///
  /// In en, this message translates to:
  /// **'Choose Your Plan'**
  String get choosePlan;

  /// No description provided for @selectPlan.
  ///
  /// In en, this message translates to:
  /// **'Select the subscription plan that suits you'**
  String get selectPlan;

  /// No description provided for @continueToPayment.
  ///
  /// In en, this message translates to:
  /// **'Continue to Payment'**
  String get continueToPayment;

  /// No description provided for @paymentMethods.
  ///
  /// In en, this message translates to:
  /// **'Payment Methods'**
  String get paymentMethods;

  /// No description provided for @choosePaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Choose Payment Method'**
  String get choosePaymentMethod;

  /// No description provided for @selectedPlan.
  ///
  /// In en, this message translates to:
  /// **'Selected Plan'**
  String get selectedPlan;

  /// No description provided for @paymentReference.
  ///
  /// In en, this message translates to:
  /// **'Payment Reference'**
  String get paymentReference;

  /// No description provided for @paymentReferenceHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., MPESA-123456'**
  String get paymentReferenceHint;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @notesHint.
  ///
  /// In en, this message translates to:
  /// **'Any additional information...'**
  String get notesHint;

  /// No description provided for @uploadPaymentProof.
  ///
  /// In en, this message translates to:
  /// **'Upload Payment Proof'**
  String get uploadPaymentProof;

  /// No description provided for @tapToUpload.
  ///
  /// In en, this message translates to:
  /// **'Tap to upload payment proof'**
  String get tapToUpload;

  /// No description provided for @paymentProofFormats.
  ///
  /// In en, this message translates to:
  /// **'JPG, PNG, or PDF'**
  String get paymentProofFormats;

  /// No description provided for @paymentInstructions.
  ///
  /// In en, this message translates to:
  /// **'Payment Instructions'**
  String get paymentInstructions;

  /// No description provided for @sendAmountTo.
  ///
  /// In en, this message translates to:
  /// **'Send {amount} to:'**
  String sendAmountTo(String amount);

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @submitSubscription.
  ///
  /// In en, this message translates to:
  /// **'Submit Subscription'**
  String get submitSubscription;

  /// No description provided for @subscriptionCreated.
  ///
  /// In en, this message translates to:
  /// **'Subscription Created!'**
  String get subscriptionCreated;

  /// No description provided for @subscriptionCreatedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your subscription request was created successfully.'**
  String get subscriptionCreatedMessage;

  /// No description provided for @waitForApproval.
  ///
  /// In en, this message translates to:
  /// **'Please wait for admin approval. You will be notified once your subscription is approved.'**
  String get waitForApproval;

  /// No description provided for @goToDashboard.
  ///
  /// In en, this message translates to:
  /// **'Go to Dashboard'**
  String get goToDashboard;

  /// No description provided for @renewNow.
  ///
  /// In en, this message translates to:
  /// **'Renew Now'**
  String get renewNow;

  /// No description provided for @subscribeNow.
  ///
  /// In en, this message translates to:
  /// **'Subscribe Now'**
  String get subscribeNow;

  /// No description provided for @subscriptionExpired.
  ///
  /// In en, this message translates to:
  /// **'Subscription Expired'**
  String get subscriptionExpired;

  /// No description provided for @subscriptionPending.
  ///
  /// In en, this message translates to:
  /// **'Pending Approval'**
  String get subscriptionPending;

  /// No description provided for @subscriptionActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get subscriptionActive;

  /// No description provided for @subscriptionInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get subscriptionInactive;

  /// No description provided for @daysRemaining.
  ///
  /// In en, this message translates to:
  /// **'{days} days remaining'**
  String daysRemaining(int days);

  /// No description provided for @expiresOn.
  ///
  /// In en, this message translates to:
  /// **'Expires: {date}'**
  String expiresOn(String date);

  /// No description provided for @validUntil.
  ///
  /// In en, this message translates to:
  /// **'Valid until: {date}'**
  String validUntil(String date);

  /// No description provided for @noSubscriptions.
  ///
  /// In en, this message translates to:
  /// **'No subscriptions yet'**
  String get noSubscriptions;

  /// No description provided for @noInvoices.
  ///
  /// In en, this message translates to:
  /// **'No invoices available'**
  String get noInvoices;

  /// No description provided for @invoiceNumber.
  ///
  /// In en, this message translates to:
  /// **'Invoice #{number}'**
  String invoiceNumber(String number);

  /// No description provided for @invoiceStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get invoiceStatus;

  /// No description provided for @viewInvoice.
  ///
  /// In en, this message translates to:
  /// **'View Invoice'**
  String get viewInvoice;

  /// No description provided for @downloadPdf.
  ///
  /// In en, this message translates to:
  /// **'Download PDF'**
  String get downloadPdf;

  /// No description provided for @subscriptionHistory.
  ///
  /// In en, this message translates to:
  /// **'Subscription History'**
  String get subscriptionHistory;

  /// No description provided for @paid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paid;

  /// No description provided for @unpaid.
  ///
  /// In en, this message translates to:
  /// **'Unpaid'**
  String get unpaid;

  /// No description provided for @yourSubscriptionHasExpired.
  ///
  /// In en, this message translates to:
  /// **'Your subscription has expired. Please renew to continue.'**
  String get yourSubscriptionHasExpired;

  /// No description provided for @subscriptionPendingApproval.
  ///
  /// In en, this message translates to:
  /// **'Your subscription is pending approval. Please wait.'**
  String get subscriptionPendingApproval;

  /// No description provided for @subscribeToUnlock.
  ///
  /// In en, this message translates to:
  /// **'Subscribe to unlock all Fundi features.'**
  String get subscribeToUnlock;

  /// No description provided for @rateCards.
  ///
  /// In en, this message translates to:
  /// **'Rate Cards'**
  String get rateCards;

  /// No description provided for @subscriptionDetails.
  ///
  /// In en, this message translates to:
  /// **'Subscription Details'**
  String get subscriptionDetails;

  /// No description provided for @invoiceDetails.
  ///
  /// In en, this message translates to:
  /// **'Invoice Details'**
  String get invoiceDetails;

  /// No description provided for @activePlan.
  ///
  /// In en, this message translates to:
  /// **'Active Plan'**
  String get activePlan;

  /// No description provided for @amountPaid.
  ///
  /// In en, this message translates to:
  /// **'Amount Paid'**
  String get amountPaid;

  /// No description provided for @paymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get paymentMethod;

  /// No description provided for @paymentReferenceLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment Reference'**
  String get paymentReferenceLabel;

  /// No description provided for @approvedAt.
  ///
  /// In en, this message translates to:
  /// **'Approved At'**
  String get approvedAt;

  /// No description provided for @approvedBy.
  ///
  /// In en, this message translates to:
  /// **'Approved By'**
  String get approvedBy;

  /// No description provided for @adminNotes.
  ///
  /// In en, this message translates to:
  /// **'Admin Notes'**
  String get adminNotes;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No Notifications'**
  String get noNotifications;

  /// No description provided for @allCaughtUp.
  ///
  /// In en, this message translates to:
  /// **'You\'re all caught up!'**
  String get allCaughtUp;

  /// No description provided for @markAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark All Read'**
  String get markAllRead;

  /// No description provided for @loadingNotifications.
  ///
  /// In en, this message translates to:
  /// **'Loading notifications...'**
  String get loadingNotifications;

  /// No description provided for @viewAllNotifications.
  ///
  /// In en, this message translates to:
  /// **'View All Notifications'**
  String get viewAllNotifications;

  /// No description provided for @notificationSettings.
  ///
  /// In en, this message translates to:
  /// **'Notification Settings'**
  String get notificationSettings;

  /// No description provided for @invoices.
  ///
  /// In en, this message translates to:
  /// **'Invoices'**
  String get invoices;

  /// No description provided for @certificate.
  ///
  /// In en, this message translates to:
  /// **'Certificate'**
  String get certificate;

  /// No description provided for @approvedOn.
  ///
  /// In en, this message translates to:
  /// **'Approved on {date}'**
  String approvedOn(String date);

  /// No description provided for @startedOn.
  ///
  /// In en, this message translates to:
  /// **'Started: {date}'**
  String startedOn(String date);

  /// No description provided for @createdOn.
  ///
  /// In en, this message translates to:
  /// **'Created: {date}'**
  String createdOn(String date);

  /// No description provided for @paidOn.
  ///
  /// In en, this message translates to:
  /// **'Paid: {date}'**
  String paidOn(String date);

  /// No description provided for @dueOn.
  ///
  /// In en, this message translates to:
  /// **'Due: {date}'**
  String dueOn(String date);

  /// No description provided for @subscriptionReference.
  ///
  /// In en, this message translates to:
  /// **'Subscription #{id}'**
  String subscriptionReference(String id);

  /// No description provided for @plan.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get plan;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// No description provided for @openPdf.
  ///
  /// In en, this message translates to:
  /// **'Open PDF'**
  String get openPdf;

  /// No description provided for @typeArea.
  ///
  /// In en, this message translates to:
  /// **'Type area'**
  String get typeArea;

  /// No description provided for @oops.
  ///
  /// In en, this message translates to:
  /// **'Oops!'**
  String get oops;

  /// No description provided for @themeLabel.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeLabel;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @backToApp.
  ///
  /// In en, this message translates to:
  /// **'Back to app'**
  String get backToApp;

  /// No description provided for @regBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get regBack;

  /// No description provided for @regContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get regContinue;

  /// No description provided for @regStepOf.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String regStepOf(int current, int total);

  /// No description provided for @regCreateAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get regCreateAccountTitle;

  /// No description provided for @regCreateAccountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'ll send a code to your phone to verify it.'**
  String get regCreateAccountSubtitle;

  /// No description provided for @regFullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get regFullName;

  /// No description provided for @regPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get regPhoneHint;

  /// No description provided for @regEmailOptional.
  ///
  /// In en, this message translates to:
  /// **'Email (optional)'**
  String get regEmailOptional;

  /// No description provided for @regPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Password (min 8 characters)'**
  String get regPasswordHint;

  /// No description provided for @regConfirmPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get regConfirmPasswordHint;

  /// No description provided for @regPhotoOptional.
  ///
  /// In en, this message translates to:
  /// **'Photo (optional)'**
  String get regPhotoOptional;

  /// No description provided for @regChooseGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get regChooseGallery;

  /// No description provided for @regTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get regTakePhoto;

  /// No description provided for @regRemovePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get regRemovePhoto;

  /// No description provided for @regSearchCountry.
  ///
  /// In en, this message translates to:
  /// **'Search country...'**
  String get regSearchCountry;

  /// No description provided for @regNoCountryFound.
  ///
  /// In en, this message translates to:
  /// **'No country found'**
  String get regNoCountryFound;

  /// No description provided for @regNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get regNameRequired;

  /// No description provided for @regPhoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Phone is required'**
  String get regPhoneRequired;

  /// No description provided for @regPhoneInvalidTz.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid Tanzanian number (e.g. 0682 131 178)'**
  String get regPhoneInvalidTz;

  /// No description provided for @regPhoneInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid phone number'**
  String get regPhoneInvalid;

  /// No description provided for @regEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get regEmailInvalid;

  /// No description provided for @regPasswordMin.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters'**
  String get regPasswordMin;

  /// No description provided for @regPasswordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get regPasswordMismatch;

  /// No description provided for @regIdentityTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify your identity'**
  String get regIdentityTitle;

  /// No description provided for @regIdentitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Used only by our team to approve your account.'**
  String get regIdentitySubtitle;

  /// No description provided for @regIdNida.
  ///
  /// In en, this message translates to:
  /// **'NIDA'**
  String get regIdNida;

  /// No description provided for @regIdLicense.
  ///
  /// In en, this message translates to:
  /// **'Driver\'s license'**
  String get regIdLicense;

  /// No description provided for @regIdVoter.
  ///
  /// In en, this message translates to:
  /// **'Voter\'s ID (KURA)'**
  String get regIdVoter;

  /// No description provided for @regNidaHint.
  ///
  /// In en, this message translates to:
  /// **'NIDA number (20 digits)'**
  String get regNidaHint;

  /// No description provided for @regVoterHint.
  ///
  /// In en, this message translates to:
  /// **'Voter ID (12 digits)'**
  String get regVoterHint;

  /// No description provided for @regLicenseHint.
  ///
  /// In en, this message translates to:
  /// **'License number (min 10 digits)'**
  String get regLicenseHint;

  /// No description provided for @regEnterId.
  ///
  /// In en, this message translates to:
  /// **'Enter the ID number'**
  String get regEnterId;

  /// No description provided for @regNidaLen.
  ///
  /// In en, this message translates to:
  /// **'NIDA must be exactly 20 digits'**
  String get regNidaLen;

  /// No description provided for @regVoterLen.
  ///
  /// In en, this message translates to:
  /// **'Voter ID must be exactly 12 digits'**
  String get regVoterLen;

  /// No description provided for @regLicenseLen.
  ///
  /// In en, this message translates to:
  /// **'License must be at least 10 digits'**
  String get regLicenseLen;

  /// No description provided for @regAddIdPhoto.
  ///
  /// In en, this message translates to:
  /// **'Tap to add a photo of your ID (optional)'**
  String get regAddIdPhoto;

  /// No description provided for @regFingerprintTitle.
  ///
  /// In en, this message translates to:
  /// **'Ink fingerprint'**
  String get regFingerprintTitle;

  /// No description provided for @regFingerprintHeadIdle.
  ///
  /// In en, this message translates to:
  /// **'Place your finger'**
  String get regFingerprintHeadIdle;

  /// No description provided for @regFingerprintHeadDone.
  ///
  /// In en, this message translates to:
  /// **'Fingerprint captured'**
  String get regFingerprintHeadDone;

  /// No description provided for @regFingerprintDescIdle.
  ///
  /// In en, this message translates to:
  /// **'Touch and press the area below to stamp your ink print.'**
  String get regFingerprintDescIdle;

  /// No description provided for @regFingerprintDescDone.
  ///
  /// In en, this message translates to:
  /// **'Your ink print was captured. Tap the button below to continue.'**
  String get regFingerprintDescDone;

  /// No description provided for @regFingerprintChipIdle.
  ///
  /// In en, this message translates to:
  /// **'Tap here'**
  String get regFingerprintChipIdle;

  /// No description provided for @regFingerprintChipDone.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get regFingerprintChipDone;

  /// No description provided for @regFingerprintStamp.
  ///
  /// In en, this message translates to:
  /// **'Tap to stamp'**
  String get regFingerprintStamp;

  /// No description provided for @regFingerprintScanning.
  ///
  /// In en, this message translates to:
  /// **'Capturing…'**
  String get regFingerprintScanning;

  /// No description provided for @regFingerprintSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit & continue'**
  String get regFingerprintSubmit;

  /// No description provided for @regFingerprintRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get regFingerprintRetry;

  /// No description provided for @regFingerprintSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save the fingerprint.'**
  String get regFingerprintSaveFailed;

  /// No description provided for @regFaceTitle.
  ///
  /// In en, this message translates to:
  /// **'Face capture'**
  String get regFaceTitle;

  /// No description provided for @regFaceOpening.
  ///
  /// In en, this message translates to:
  /// **'Opening camera…'**
  String get regFaceOpening;

  /// No description provided for @regFacePosition.
  ///
  /// In en, this message translates to:
  /// **'Position your face in the frame'**
  String get regFacePosition;

  /// No description provided for @regFaceNone.
  ///
  /// In en, this message translates to:
  /// **'No face detected'**
  String get regFaceNone;

  /// No description provided for @regFaceCloser.
  ///
  /// In en, this message translates to:
  /// **'Move closer'**
  String get regFaceCloser;

  /// No description provided for @regFaceFarther.
  ///
  /// In en, this message translates to:
  /// **'Move back a little'**
  String get regFaceFarther;

  /// No description provided for @regFaceHold.
  ///
  /// In en, this message translates to:
  /// **'Hold still…'**
  String get regFaceHold;

  /// No description provided for @regFaceConfirmPhoto.
  ///
  /// In en, this message translates to:
  /// **'Confirm your photo'**
  String get regFaceConfirmPhoto;

  /// No description provided for @regFaceSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get regFaceSaving;

  /// No description provided for @regFaceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Camera unavailable'**
  String get regFaceUnavailable;

  /// No description provided for @regFaceNoCamera.
  ///
  /// In en, this message translates to:
  /// **'No camera available on this device.'**
  String get regFaceNoCamera;

  /// No description provided for @regFaceOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open the camera: {error}'**
  String regFaceOpenFailed(String error);

  /// No description provided for @regFaceCaptureFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not capture the photo: {error}'**
  String regFaceCaptureFailed(String error);

  /// No description provided for @regFaceSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save the face capture.'**
  String get regFaceSaveFailed;

  /// No description provided for @regFaceSubmitFailed.
  ///
  /// In en, this message translates to:
  /// **'Submission failed: {error}'**
  String regFaceSubmitFailed(String error);

  /// No description provided for @regFaceFallbackFailed.
  ///
  /// In en, this message translates to:
  /// **'Camera fallback failed: {error}'**
  String regFaceFallbackFailed(String error);

  /// No description provided for @regFaceCapturing.
  ///
  /// In en, this message translates to:
  /// **'Capturing…'**
  String get regFaceCapturing;

  /// No description provided for @regFaceCaptureNow.
  ///
  /// In en, this message translates to:
  /// **'Capture now'**
  String get regFaceCaptureNow;

  /// No description provided for @regFaceRetake.
  ///
  /// In en, this message translates to:
  /// **'Retake'**
  String get regFaceRetake;

  /// No description provided for @regFaceConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get regFaceConfirm;

  /// No description provided for @regFaceSystemCamera.
  ///
  /// In en, this message translates to:
  /// **'Use system camera'**
  String get regFaceSystemCamera;

  /// No description provided for @regKinTitle.
  ///
  /// In en, this message translates to:
  /// **'Emergency contact'**
  String get regKinTitle;

  /// No description provided for @regKinSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Who should we contact in an emergency?'**
  String get regKinSubtitle;

  /// No description provided for @regKinRelationship.
  ///
  /// In en, this message translates to:
  /// **'Relationship (e.g. Spouse, Parent, Sibling)'**
  String get regKinRelationship;

  /// No description provided for @regKinRelationRequired.
  ///
  /// In en, this message translates to:
  /// **'Relationship is required'**
  String get regKinRelationRequired;

  /// No description provided for @regReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review & Submit'**
  String get regReviewTitle;

  /// No description provided for @regReviewHeading.
  ///
  /// In en, this message translates to:
  /// **'Please review your registration details'**
  String get regReviewHeading;

  /// No description provided for @regCompletedSteps.
  ///
  /// In en, this message translates to:
  /// **'Completed steps'**
  String get regCompletedSteps;

  /// No description provided for @regAccountCreated.
  ///
  /// In en, this message translates to:
  /// **'Account created'**
  String get regAccountCreated;

  /// No description provided for @regIdentityVerified.
  ///
  /// In en, this message translates to:
  /// **'Identity saved'**
  String get regIdentityVerified;

  /// No description provided for @regFingerprintEnrolled.
  ///
  /// In en, this message translates to:
  /// **'Fingerprint captured'**
  String get regFingerprintEnrolled;

  /// No description provided for @regFaceEnrolled.
  ///
  /// In en, this message translates to:
  /// **'Face captured'**
  String get regFaceEnrolled;

  /// No description provided for @regKinSaved.
  ///
  /// In en, this message translates to:
  /// **'Emergency contact saved'**
  String get regKinSaved;

  /// No description provided for @regRelationship.
  ///
  /// In en, this message translates to:
  /// **'Relationship'**
  String get regRelationship;

  /// No description provided for @regSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit registration'**
  String get regSubmit;

  /// No description provided for @regBackToStep5.
  ///
  /// In en, this message translates to:
  /// **'Back to step 5'**
  String get regBackToStep5;

  /// No description provided for @regSubmittedTitle.
  ///
  /// In en, this message translates to:
  /// **'Registration submitted!'**
  String get regSubmittedTitle;

  /// No description provided for @regSubmittedBody.
  ///
  /// In en, this message translates to:
  /// **'Your account is pending admin verification. You\'ll receive an SMS once approved.'**
  String get regSubmittedBody;

  /// No description provided for @regSubmitFailed.
  ///
  /// In en, this message translates to:
  /// **'Submission failed. Please try again.'**
  String get regSubmitFailed;

  /// No description provided for @regSessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Registration session expired. Please start over.'**
  String get regSessionExpired;

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

  /// No description provided for @downloads.
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get downloads;

  /// No description provided for @subscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get subscription;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @viewAllShort.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get viewAllShort;

  /// No description provided for @latestRequests.
  ///
  /// In en, this message translates to:
  /// **'Latest Requests'**
  String get latestRequests;

  /// No description provided for @activeJobs.
  ///
  /// In en, this message translates to:
  /// **'Active Jobs'**
  String get activeJobs;

  /// No description provided for @openTickets.
  ///
  /// In en, this message translates to:
  /// **'Open Tickets'**
  String get openTickets;

  /// No description provided for @noActiveJobs.
  ///
  /// In en, this message translates to:
  /// **'No active jobs'**
  String get noActiveJobs;

  /// No description provided for @noOpenTickets.
  ///
  /// In en, this message translates to:
  /// **'No open tickets'**
  String get noOpenTickets;

  /// No description provided for @noJobsFound.
  ///
  /// In en, this message translates to:
  /// **'No jobs found'**
  String get noJobsFound;

  /// No description provided for @noTicketsFound.
  ///
  /// In en, this message translates to:
  /// **'No tickets found'**
  String get noTicketsFound;

  /// No description provided for @searchJobsHint.
  ///
  /// In en, this message translates to:
  /// **'Search job number, customer, service...'**
  String get searchJobsHint;

  /// No description provided for @searchTicketsHint.
  ///
  /// In en, this message translates to:
  /// **'Search ticket, job, customer, service...'**
  String get searchTicketsHint;

  /// No description provided for @subscriptionComingSoonTitle.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get subscriptionComingSoonTitle;

  /// No description provided for @subscriptionComingSoonBody.
  ///
  /// In en, this message translates to:
  /// **'Premium version — Coming soon 🚀\nUnlock more features and grow your business.'**
  String get subscriptionComingSoonBody;

  /// No description provided for @pendingStatus.
  ///
  /// In en, this message translates to:
  /// **'PENDING'**
  String get pendingStatus;

  /// No description provided for @onProgressStatus.
  ///
  /// In en, this message translates to:
  /// **'ON PROGRESS'**
  String get onProgressStatus;

  /// No description provided for @completedStatus.
  ///
  /// In en, this message translates to:
  /// **'COMPLETED'**
  String get completedStatus;

  /// No description provided for @jobDetails.
  ///
  /// In en, this message translates to:
  /// **'Job Details'**
  String get jobDetails;

  /// No description provided for @ticketDetails.
  ///
  /// In en, this message translates to:
  /// **'Ticket Details'**
  String get ticketDetails;

  /// No description provided for @noTicket.
  ///
  /// In en, this message translates to:
  /// **'No ticket'**
  String get noTicket;

  /// No description provided for @ticketsCount.
  ///
  /// In en, this message translates to:
  /// **'Tickets ({count})'**
  String ticketsCount(int count);

  /// No description provided for @noTicketsForJob.
  ///
  /// In en, this message translates to:
  /// **'No tickets for this job'**
  String get noTicketsForJob;

  /// No description provided for @downloadTicket.
  ///
  /// In en, this message translates to:
  /// **'Download Ticket'**
  String get downloadTicket;

  /// No description provided for @downloadingTicket.
  ///
  /// In en, this message translates to:
  /// **'Downloading ticket {number}...'**
  String downloadingTicket(String number);

  /// No description provided for @jobNumber.
  ///
  /// In en, this message translates to:
  /// **'Job number'**
  String get jobNumber;

  /// No description provided for @ticketNumber.
  ///
  /// In en, this message translates to:
  /// **'Ticket number'**
  String get ticketNumber;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @requestDescription.
  ///
  /// In en, this message translates to:
  /// **'Request description'**
  String get requestDescription;

  /// No description provided for @started.
  ///
  /// In en, this message translates to:
  /// **'Started'**
  String get started;

  /// No description provided for @completedLabel.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completedLabel;

  /// No description provided for @jobStatus.
  ///
  /// In en, this message translates to:
  /// **'Job status'**
  String get jobStatus;

  /// No description provided for @ticketStatus.
  ///
  /// In en, this message translates to:
  /// **'Ticket status'**
  String get ticketStatus;

  /// No description provided for @created.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get created;

  /// No description provided for @areYouSureDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this message?'**
  String get areYouSureDeleteMessage;

  /// No description provided for @filterOnProgress.
  ///
  /// In en, this message translates to:
  /// **'On progress'**
  String get filterOnProgress;

  /// No description provided for @filterCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get filterCompleted;

  /// No description provided for @payments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get payments;

  /// No description provided for @myPortfolio.
  ///
  /// In en, this message translates to:
  /// **'My Portfolio'**
  String get myPortfolio;

  /// No description provided for @noPostsYet.
  ///
  /// In en, this message translates to:
  /// **'No Posts Yet'**
  String get noPostsYet;

  /// No description provided for @uploadPhotosToShowcase.
  ///
  /// In en, this message translates to:
  /// **'Upload photos of your work to showcase your skills.'**
  String get uploadPhotosToShowcase;

  /// No description provided for @newPortfolioPost.
  ///
  /// In en, this message translates to:
  /// **'New Portfolio Post'**
  String get newPortfolioPost;

  /// No description provided for @tapToSelectImages.
  ///
  /// In en, this message translates to:
  /// **'Tap to select images'**
  String get tapToSelectImages;

  /// No description provided for @addMoreImages.
  ///
  /// In en, this message translates to:
  /// **'Add more images'**
  String get addMoreImages;

  /// No description provided for @post.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get post;

  /// No description provided for @deletePostTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Post?'**
  String get deletePostTitle;

  /// No description provided for @deletePostConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove this entire post?'**
  String get deletePostConfirmation;

  /// No description provided for @editImages.
  ///
  /// In en, this message translates to:
  /// **'Edit Images'**
  String get editImages;

  /// No description provided for @myBalance.
  ///
  /// In en, this message translates to:
  /// **'My Balance'**
  String get myBalance;

  /// No description provided for @earnings.
  ///
  /// In en, this message translates to:
  /// **'Earnings'**
  String get earnings;

  /// No description provided for @reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// No description provided for @recentJobs.
  ///
  /// In en, this message translates to:
  /// **'Recent Jobs'**
  String get recentJobs;

  /// No description provided for @recentTickets.
  ///
  /// In en, this message translates to:
  /// **'Recent Tickets'**
  String get recentTickets;

  /// No description provided for @noJobsYet.
  ///
  /// In en, this message translates to:
  /// **'No jobs yet'**
  String get noJobsYet;

  /// No description provided for @noTicketsYet.
  ///
  /// In en, this message translates to:
  /// **'No tickets yet'**
  String get noTicketsYet;

  /// No description provided for @comingSoonTitle.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get comingSoonTitle;

  /// No description provided for @comingSoonBody.
  ///
  /// In en, this message translates to:
  /// **'This feature is coming soon 🚀\nStay tuned for updates.'**
  String get comingSoonBody;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get goodMorning;

  /// No description provided for @goodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get goodEvening;

  /// No description provided for @pendingCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Pending'**
  String pendingCount(int count);

  /// No description provided for @acceptedStatus.
  ///
  /// In en, this message translates to:
  /// **'ACCEPTED'**
  String get acceptedStatus;

  /// No description provided for @rejectedStatus.
  ///
  /// In en, this message translates to:
  /// **'REJECTED'**
  String get rejectedStatus;

  /// No description provided for @cancelledStatus.
  ///
  /// In en, this message translates to:
  /// **'CANCELLED'**
  String get cancelledStatus;
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
