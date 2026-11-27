// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'NearbyFundi';

  @override
  String get nearby => 'Home';

  @override
  String get nearbyMap => 'Nearby Map';

  @override
  String get near => 'Near';

  @override
  String get blog => 'Blog';

  @override
  String get requests => 'Requests';

  @override
  String get myRequests => 'My Requests';

  @override
  String get profile => 'Profile';

  @override
  String get settings => 'Settings';

  @override
  String get chat => 'Chat';

  @override
  String get payments => 'Payments';

  @override
  String get jobs => 'Jobs';

  @override
  String get tickets => 'Tickets';

  @override
  String get soon => 'Soon';

  @override
  String get becomeFundi => 'Become a Fundi';

  @override
  String get otpDigitRequired => 'Enter 6-digit OTP';

  @override
  String get passwordMinLength => 'Password must be at least 6 characters';

  @override
  String get repeatPassword => 'Repeat your password';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get languageEnglish => 'English 🇬🇧';

  @override
  String get languageSwahili => 'Kiswahili 🇹🇿';

  @override
  String get themeLight => 'Light ☀️';

  @override
  String get themeDark => 'Dark 🌙';

  @override
  String get themeSystem => 'System ⚙️';

  @override
  String get accountVerified => 'Account verified!';

  @override
  String get welcomeToApp => 'Welcome to NearbyFundi';

  @override
  String welcomeToAppName(String name) {
    return 'Welcome to NearbyFundi, $name';
  }

  @override
  String get takingYouToDashboard => 'Taking you to your dashboard…';

  @override
  String get continueButton => 'Continue';

  @override
  String get invalidOrExpiredCode => 'Invalid or expired code. Please try again.';

  @override
  String get couldNotSendCodeAuto => 'We could not send your code automatically. Tap \"Resend code\" below.';

  @override
  String codeSentBySms(String target) {
    return 'We sent a 6-digit code by SMS to\n$target';
  }

  @override
  String codeSentByEmail(String target) {
    return 'We sent a 6-digit code to your email\n$target';
  }

  @override
  String get newCodeSent => 'A new code has been sent.';

  @override
  String get couldNotResendCode => 'Could not resend the code. Try again.';

  @override
  String resendCodeIn(String time) {
    return 'Resend code in $time';
  }

  @override
  String get resendCode => 'Resend code';

  @override
  String get changeMyDetails => 'Change my details';

  @override
  String get passwordResetSuccess => 'Password reset successfully';

  @override
  String get emailHint => 'you@example.com';

  @override
  String get registerPhoneHint => '712345678';

  @override
  String get splashTagline => 'Find trusted help, right where you need it.';

  @override
  String get onboardFindFundisTitle => 'Find Fundis';

  @override
  String get onboardFindFundisDesc => 'Discover trusted and verified technicians offering quality services near you.';

  @override
  String get onboardConnectFastTitle => 'Connect Fast';

  @override
  String get onboardConnectFastDesc => 'Browse technician profiles, check ratings and connect with the right professional.';

  @override
  String get onboardGetItDoneTitle => 'Get It Done';

  @override
  String get onboardGetItDoneDesc => 'Send your request, get accepted and follow your service from start to finish.';

  @override
  String get benefitVerified => 'Verified';

  @override
  String get benefitTrusted => 'Trusted';

  @override
  String get benefitFast => 'Fast';

  @override
  String get rememberMe => 'Remember me';

  @override
  String get orContinueWith => 'or continue with';

  @override
  String get phoneHint => '679117291';

  @override
  String get pleaseEnterPhone => 'Please enter phone number';

  @override
  String get enterValidPhoneDigits => 'Enter a valid 9-digit number';

  @override
  String get back => 'Back';

  @override
  String get trustedTechniciansNearYou => 'Trusted technicians near you';

  @override
  String get nearbyFundiTagline => 'NearbyFundi • trusted technicians near you';

  @override
  String get registerNameTooShort => 'Name is too short';

  @override
  String get registerEmailRequired => 'Email is required';

  @override
  String get registerPhoneRequired => 'Phone number is required';

  @override
  String get registerValidTanzaniaPhone => 'Enter a valid Tanzanian number, e.g. 0712 345 678';

  @override
  String get registerValidPhone => 'Enter a valid phone number';

  @override
  String get registerPasswordRequired => 'Password is required';

  @override
  String get registerPasswordMinLength => 'Password must be at least 8 characters';

  @override
  String get registerPasswordStrength => 'Use uppercase, lowercase and a number';

  @override
  String get registerConfirmPasswordRequired => 'Please confirm your password';

  @override
  String get registerPasswordsMismatch => 'Passwords do not match';

  @override
  String get registerFailedRetry => 'Registration failed. Please try again.';

  @override
  String get registerOtpSendFailed => 'Account created, but we could not send the code. Please try again.';

  @override
  String get registerPasswordHint => 'Min 8 chars, upper + lower + number';

  @override
  String get registerRepeatPassword => 'Repeat your password';

  @override
  String get registerRuleLength => '8+ characters';

  @override
  String get registerRuleUppercase => 'Uppercase';

  @override
  String get registerRuleLowercase => 'Lowercase';

  @override
  String get registerRuleNumber => 'Number';

  @override
  String get registerAlreadyHaveAccount => 'Already have an account?';

  @override
  String get registerSearchCountry => 'Search country...';

  @override
  String get registerNoCountryFound => 'No country found';

  @override
  String get refresh => 'Refresh';

  @override
  String get blogSearchHint => 'Search by fundi name...';

  @override
  String get blogEmptySubtitle => 'Check back later for updates from our technicians.';

  @override
  String get retry => 'Retry';

  @override
  String blogNoResults(String query) {
    return 'No posts match \"$query\"';
  }

  @override
  String get loadMorePosts => 'Load more posts';

  @override
  String get imageNotAvailable => 'Image not available';

  @override
  String get viewProfile => 'View Profile';

  @override
  String get timeJustNow => 'Just now';

  @override
  String timeMinutesAgo(int count) {
    return '${count}m ago';
  }

  @override
  String timeHoursAgo(int count) {
    return '${count}h ago';
  }

  @override
  String timeDaysAgo(int count) {
    return '${count}d ago';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get sendSmsCode => 'Send SMS Code';

  @override
  String get confirmCompletionBody => 'Would you like to send the 6-digit verification code via SMS to complete this job?';

  @override
  String get comingSoon => 'coming soon!';

  @override
  String get yourReview => 'Your review';

  @override
  String howWasTheJob(String name) {
    return 'How was the job? Rate $name and leave a remark.';
  }

  @override
  String rateJobTitle(String name) {
    return 'Rate $name';
  }

  @override
  String get tapStarToRate => 'Tap a star to rate';

  @override
  String get ratingPoor => 'Poor';

  @override
  String get ratingFair => 'Fair';

  @override
  String get ratingGood => 'Good';

  @override
  String get ratingVeryGood => 'Very good';

  @override
  String get ratingExcellent => 'Excellent';

  @override
  String get selectStarRating => 'Please select a star rating.';

  @override
  String get reviewSubmitted => 'Thank you for your review!';

  @override
  String get failedSubmitReview => 'Failed to submit review.';

  @override
  String get remarkOptional => 'Remark (optional)';

  @override
  String get tellUsHowJobWent => 'Tell us how the job went…';

  @override
  String get submitReview => 'Submit review';

  @override
  String get maybeLater => 'Maybe later';

  @override
  String get rateThisJob => 'Rate this job';

  @override
  String get chatToGetContact => 'Chat to get contact';

  @override
  String get findFundi => 'Find Fundi';

  @override
  String get searchLocation => '📍 Search location...';

  @override
  String get search => 'Search';

  @override
  String get filterByService => '🔧 Filter by service...';

  @override
  String get all => 'All';

  @override
  String get allServices => 'All Services';

  @override
  String get category => 'Category';

  @override
  String get noServicesFound => 'No services found';

  @override
  String get noServicesMatch => 'No services match your filter';

  @override
  String get clearAllFilters => 'Clear All Filters';

  @override
  String get clearFilters => 'Clear filters';

  @override
  String get filtered => 'Filtered';

  @override
  String get onlineOnly => 'Online only';

  @override
  String get viewOnMap => 'View on map';

  @override
  String get editProfileSubtitle => 'Keep your personal information up to date.';

  @override
  String get personalInformation => 'Personal information';

  @override
  String get editNameAndContact => 'Edit your name and contact details.';

  @override
  String get enterFullName => 'Enter your full name';

  @override
  String get enterPhoneNumber => 'Enter your phone number';

  @override
  String get nameRequiredError => 'Name is required';

  @override
  String get validNameError => 'Enter a valid name';

  @override
  String get name => 'Full Name';

  @override
  String get phone => 'Phone';

  @override
  String get noFundisFound => 'No Fundis Found';

  @override
  String get tryAdjustingSearch => 'Try adjusting your search or location';

  @override
  String get fundisFound => 'Fundis found';

  @override
  String get searchingForFundis => 'Searching for fundis...';

  @override
  String get oopsSomethingWentWrong => 'Oops! Something went wrong';

  @override
  String get pleaseTryAgain => 'Please try again';

  @override
  String noResultsFor(String service) {
    return 'No Fundis for $service';
  }

  @override
  String noResultsForServiceCategory(String service, String category) {
    return 'No Fundis for $service ($category)';
  }

  @override
  String get tryDifferentCategoryOrService => 'Try a different category or service';

  @override
  String get tryDifferentService => 'Try selecting a different service';

  @override
  String get tryAdjustingLocation => 'Try adjusting your search or location';

  @override
  String get suggestionClearFilters => 'Try clearing your filters';

  @override
  String get suggestionDifferentLocation => 'Try a different location';

  @override
  String get suggestionDifferentService => 'Try a different service';

  @override
  String get suggestionRemoveFilters => 'Try removing service/category filters';

  @override
  String get suggestionIncreaseRadius => 'Try increasing the search radius';

  @override
  String get suggestionAllCategories => 'Try selecting \'All Categories\'';

  @override
  String get suggestionAllServices => 'Try selecting \'All Services\'';

  @override
  String get kmAway => 'km away';

  @override
  String get directions => 'Directions';

  @override
  String get online => 'Online';

  @override
  String get offline => 'Offline';

  @override
  String get request => 'Request';

  @override
  String get requestThisFundi => 'Request This Fundi';

  @override
  String get requestAlreadySent => 'Request Already Sent';

  @override
  String get hourlyRate => 'Hourly Rate';

  @override
  String get tzs => 'TZS';

  @override
  String get socialMedia => 'Social Media';

  @override
  String get contact => 'Contact';

  @override
  String get call => 'Call';

  @override
  String get items => 'items';

  @override
  String get sendingToTechnician => 'Sending to technician...';

  @override
  String get awaitingResponse => 'Awaiting response...';

  @override
  String get noServicesSelected => 'No services selected';

  @override
  String get selectService => 'Select a service';

  @override
  String get welcomeBack => 'Welcome Back';

  @override
  String get signInToContinue => 'Please sign in or create an account to continue.';

  @override
  String get signInManage => 'Sign in to manage your services';

  @override
  String get emailAddress => 'Email Address';

  @override
  String get password => 'Password';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get signIn => 'Sign In';

  @override
  String get dontHaveAccount => 'Don\'t have an account?';

  @override
  String get signUp => 'Sign Up';

  @override
  String get createAccount => 'Create Account';

  @override
  String get joinCommunity => 'Join the community of smart users';

  @override
  String get fullName => 'Full Name';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get verificationCode => 'Verification Code';

  @override
  String get enterCodeSent => 'Enter the code sent to';

  @override
  String get enterOtp => 'Enter OTP';

  @override
  String get otpSent => 'A 6-digit code has been sent to your email';

  @override
  String get verifyOtp => 'Verify OTP';

  @override
  String get backToSignIn => 'Back to Sign In';

  @override
  String get noWorries => 'No worries — we\'ll send you a reset code';

  @override
  String get resetPassword => 'Reset Password';

  @override
  String get enterEmailReset => 'Enter your email to receive a verification code';

  @override
  String get sendResetCode => 'Send Reset Code';

  @override
  String get setNewPassword => 'Set New Password';

  @override
  String get otpSentTo => 'OTP sent to';

  @override
  String get otpCode => 'OTP Code';

  @override
  String get newPassword => 'New Password';

  @override
  String get resetPasswordButton => 'Reset Password';

  @override
  String get logout => 'Logout';

  @override
  String get logoutConfirmation => 'Are you sure you want to logout?';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String get deleteAccountConfirmation => 'This action is permanent. All your data will be lost. Are you sure?';

  @override
  String get areYouSure => 'Are you sure?';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get delete => 'Delete';

  @override
  String get enterEmail => 'Enter your email address';

  @override
  String get enterValidEmail => 'Enter a valid email address';

  @override
  String get enterPassword => 'Enter your password';

  @override
  String get pleaseAcceptTerms => 'Please accept the Terms & Conditions';

  @override
  String get iAgreeToThe => 'I agree to the';

  @override
  String get termsAndConditions => 'Terms & Conditions';

  @override
  String get and => 'and';

  @override
  String get or => 'OR';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get yourAccount => 'Your Account';

  @override
  String get managePersonalAccount => 'Manage your personal account';

  @override
  String get updatePersonalInfo => 'Update your personal information';

  @override
  String get manageAppPreferences => 'Manage your app preferences';

  @override
  String get yourNearbyFundiAccount => 'Your NearbyFundi account';

  @override
  String get accountActive => 'Account active';

  @override
  String get accountReadyToUse => 'Your account is ready to use.';

  @override
  String get dangerZone => 'Danger Zone';

  @override
  String get irreversibleActions => 'Irreversible account actions';

  @override
  String get deleteAccountSubtitle => 'Permanently remove your account and data';

  @override
  String get deleteAccountTitle => 'Delete account?';

  @override
  String get deleteAccountWarning => 'You will be signed out of this app immediately. You can sign in again at any time.';

  @override
  String get manageSettings => 'Manage your settings';

  @override
  String get personalizeExperience => 'Personalize your NearbyFundi experience.';

  @override
  String get lightAppearance => 'Light appearance';

  @override
  String get darkAppearance => 'Dark appearance';

  @override
  String get followDeviceSettings => 'Follow device settings';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get system => 'System';

  @override
  String get preferences => 'Preferences';

  @override
  String get information => 'Information';

  @override
  String get appearance => 'Appearance';

  @override
  String get manageYourAccount => 'Manage your account';

  @override
  String get refreshProfile => 'Refresh profile';

  @override
  String get trustedConnection => 'Your trusted connection to local technicians.';

  @override
  String get findTrustedNearby => 'Find trusted technicians near you.';

  @override
  String get nameRequired => 'Name is required';

  @override
  String get enterValidName => 'Enter a valid name';

  @override
  String get keepInfoUpdated => 'Keep your personal information up to date.';

  @override
  String get profileHeaderSubtitle => 'Manage your account details';

  @override
  String get cancelActionLabel => 'Cancel';

  @override
  String get activeStatus => 'Active';

  @override
  String get menu => 'Menu';

  @override
  String get justNow => 'Just now';

  @override
  String minAgo(int count) {
    return '$count min ago';
  }

  @override
  String hrAgo(int count) {
    return '$count hr ago';
  }

  @override
  String daysAgo(int count) {
    return '$count days ago';
  }

  @override
  String get nearbyRefresh => 'Refresh';

  @override
  String get nearbyFitAll => 'Fit all';

  @override
  String get nearbyNoTechniciansFound => 'No technicians found';

  @override
  String get nearbyTryAnotherLocation => 'Try another location or a different service';

  @override
  String get nearbyNearYou => 'Near you';

  @override
  String nearbyApproxMinShort(String value) {
    return '~${value}m';
  }

  @override
  String nearbyMapSummary(int count, int radius) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count technicians',
      one: '1 technician',
    );
    return '$_temp0 • within $radius km';
  }

  @override
  String get techMapLocationUnavailable => 'Location not available for this technician.';

  @override
  String get techMapRefreshRoute => 'Refresh route';

  @override
  String get techMapCalculatingRoute => 'Calculating route…';

  @override
  String get techMapRecenter => 'Recenter';

  @override
  String get techMapMaps => 'Maps';

  @override
  String get techMapOnline => 'Online';

  @override
  String get techMapOffline => 'Offline';

  @override
  String get pickerTitle => 'Pick location';

  @override
  String get pickerOk => 'OK';

  @override
  String get pickerSettings => 'Settings';

  @override
  String get pickerEnableLocation => 'Please enable location services.';

  @override
  String get pickerPermissionDenied => 'Location permission denied.';

  @override
  String get pickerPermissionDeniedForever => 'Location permission permanently denied.';

  @override
  String get pickerOutsideTanzania => 'Your location is outside Tanzania.';

  @override
  String get pickerLocationFailed => 'Could not get your location. Please try again.';

  @override
  String get pickerPickInsideTanzania => 'Please pick a location inside Tanzania.';

  @override
  String get pickerMyLocation => 'My current location';

  @override
  String get pickerSearchHint => 'Search a place in Tanzania…';

  @override
  String get pickerRecent => 'Recent';

  @override
  String get pickerClearAll => 'Clear all';

  @override
  String get pickerRemove => 'Remove';

  @override
  String get pickerGettingAddress => 'Getting address…';

  @override
  String get pickerTapMapHint => 'Tap the map or search for a place';

  @override
  String get pickerUseLocation => 'Use this location';

  @override
  String get nearbyFindFundiTitle => 'Find a fundi near you';

  @override
  String get nearbySearch => 'Search';

  @override
  String get nearbyShowSearch => 'Show search';

  @override
  String get nearbyHideSearch => 'Hide search';

  @override
  String get nearbyClearSearch => 'Clear search';

  @override
  String get nearbyFilterByService => 'Filter by service...';

  @override
  String get nearbyChooseOnMap => 'Choose location on map';

  @override
  String get nearbyRecommendedReason => 'Top ranked near you: rating, jobs and requests';

  @override
  String get nearbyRecentSearches => 'Recent searches';

  @override
  String get nearbyClear => 'Clear';

  @override
  String get nearbyClearFilters => 'Clear filters';

  @override
  String get nearbyFindingRoutes => 'Finding best routes...';

  @override
  String get nearbySearchForTechnicians => 'Search for technicians';

  @override
  String get nearbyNoTechniciansNearby => 'No technicians found nearby';

  @override
  String get nearbyYou => 'You';

  @override
  String get nearbyZoomIn => 'Zoom in';

  @override
  String get nearbyZoomOut => 'Zoom out';

  @override
  String get nearbyFitTechnicians => 'Fit technicians';

  @override
  String get nearbyShowList => 'Show technician list';

  @override
  String get nearbyShowFullMap => 'Show full-screen map';

  @override
  String get nearbyViewProfile => 'View Profile';

  @override
  String get nearbyDirections => 'Get directions';

  @override
  String get nearbyCouldNotOpenMaps => 'Could not open maps app.';

  @override
  String get nearbyTopPick => 'Top pick';

  @override
  String get nearbyAll => 'All';

  @override
  String get nearbySearchFailed => 'Search failed. Please check your connection and try again.';

  @override
  String get nearbyInvalidLocation => 'Invalid location selected. Please try again.';

  @override
  String get nearbySearchLoginMessage => 'Sign in or create an account to search for fundis near you.';

  @override
  String get nearbyFilterLoginMessage => 'Sign in or create an account to filter fundis by service.';

  @override
  String get nearbySearchHint => 'Search a place or pick one on the map.';

  @override
  String get nearbyStatDistance => 'Distance';

  @override
  String get nearbyStatDriveTime => 'Drive time';

  @override
  String get nearbyStatRating => 'Rating';

  @override
  String get nearbyStatJobsDone => 'Jobs done';

  @override
  String get nearbyStatRequests => 'Requests';

  @override
  String get nearbyStatReviews => 'Reviews';

  @override
  String nearbyKm(String value) {
    return '$value km';
  }

  @override
  String nearbyApproxMin(String value) {
    return '~$value min';
  }

  @override
  String nearbyFoundWithRadius(int count, int radius) {
    return '$count found • $radius km';
  }

  @override
  String nearbyExpandedNotice(int radius) {
    return 'No fundis very close, so we searched up to $radius km.';
  }

  @override
  String nearbyNoneWithinMax(int radius) {
    return 'No fundis within $radius km of this location. Try another place or service.';
  }

  @override
  String nearbyNoneWithin(int radius) {
    return 'No fundis within $radius km of this location.';
  }

  @override
  String nearbySearchWiderUpTo(int radius) {
    return 'Search wider (up to $radius km)';
  }

  @override
  String nearbyJobsCount(int count) {
    return '$count jobs';
  }

  @override
  String nearbyRequestsCount(int count) {
    return '$count requests';
  }

  @override
  String nearbyJobsDone(int count) {
    return '$count jobs done';
  }

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get deleteMessageForEveryone => 'Delete for everyone';

  @override
  String get deleteMessageForMe => 'Delete for me';

  @override
  String get removedForBoth => 'Removed for both of you';

  @override
  String get removedOnPhone => 'Only removed on this phone';

  @override
  String get deleted => 'Deleted';

  @override
  String get forwarded => 'Forwarded';

  @override
  String get copied => 'Copied';

  @override
  String get typingEllipsis => 'typing…';

  @override
  String get pinnedMessage => 'Pinned message';

  @override
  String pinnedCount(int count, int total) {
    return 'Pinned $count of $total';
  }

  @override
  String get msgDeleted => 'This message was deleted';

  @override
  String get tapToRetry => 'Tap to retry';

  @override
  String get notSent => 'Not sent';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get editProfileTitle => 'Edit Profile';

  @override
  String get updateInfo => 'Update Your Info';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get profileUpdated => 'Profile updated';

  @override
  String get updateFailed => 'Update failed';

  @override
  String get guest => 'Guest';

  @override
  String get technician => 'Technician';

  @override
  String get technicianNotFound => 'Technician not found';

  @override
  String get about => 'About';

  @override
  String get bio => 'Bio';

  @override
  String get experience => 'Experience';

  @override
  String get years => 'years';

  @override
  String get area => 'Area';

  @override
  String get accountStatus => 'Account Status';

  @override
  String get active => 'Active';

  @override
  String get onlineStatus => 'Online Status';

  @override
  String get youAreOnline => 'You are online';

  @override
  String get youAreOffline => 'You are offline';

  @override
  String get servicesIOffer => 'Services I Offer';

  @override
  String get selectServicesDialogTitle => 'Select Services';

  @override
  String get selectAtLeastOneService => 'Please select at least one service';

  @override
  String get servicesUpdated => 'Services updated';

  @override
  String get pushNotifications => 'Push Notifications';

  @override
  String get receiveAlerts => 'Receive alerts about requests and updates';

  @override
  String get language => 'Language';

  @override
  String get theme => 'Theme';

  @override
  String get aboutUs => 'About Us';

  @override
  String get faq => 'FAQ';

  @override
  String get terms => 'Terms & Conditions';

  @override
  String get contactUs => 'Contact Us';

  @override
  String get version => 'Version';

  @override
  String get noRequestsYet => 'You have no requests yet';

  @override
  String get requestsWillAppear => 'Your service requests will appear here.';

  @override
  String get cancelRequest => 'Cancel Request';

  @override
  String get areYouSureCancel => 'Are you sure you want to cancel this request?';

  @override
  String get requestSent => 'Request sent successfully!';

  @override
  String get preparingRequest => 'Preparing your request...';

  @override
  String get validatingDetails => 'Validating details...';

  @override
  String get creatingRequest => 'Creating service request...';

  @override
  String get failedToSubmit => 'Failed to submit request.';

  @override
  String get describeIssue => 'Describe your issue';

  @override
  String get describeHint => 'e.g. My AC is not cooling...';

  @override
  String get submitRequest => 'Submit Request';

  @override
  String get done => 'Done';

  @override
  String get pleaseSelectService => 'Please select a service';

  @override
  String get newRequest => 'New Request';

  @override
  String get requestAccepted => 'Request Accepted';

  @override
  String get requestRejected => 'Request Rejected';

  @override
  String get requestInProgress => 'Request In Progress';

  @override
  String get requestCompleted => 'Request Completed';

  @override
  String get noBlogPosts => 'No blog posts yet.';

  @override
  String get noCommentsYet => 'No comments yet. Be the first!';

  @override
  String get writeComment => 'Write a comment...';

  @override
  String get comments => 'Comments';

  @override
  String get postedOn => 'Posted on';

  @override
  String get likes => 'Likes';

  @override
  String get like => 'Like';

  @override
  String get unlike => 'Unlike';

  @override
  String get share => 'Share';

  @override
  String get edit => 'Edit';

  @override
  String get deletePost => 'Delete Post';

  @override
  String get areYouSureDeletePost => 'Are you sure you want to delete this post?';

  @override
  String get postDeleted => 'Post deleted';

  @override
  String get postCreated => 'Post created';

  @override
  String get postUpdated => 'Post updated';

  @override
  String get title => 'Title';

  @override
  String get content => 'Content';

  @override
  String get image => 'Image';

  @override
  String get createPost => 'Create Post';

  @override
  String get updatePost => 'Update Post';

  @override
  String get myPosts => 'My Posts';

  @override
  String get portfolio => 'Portfolio';

  @override
  String get noPortfolioItems => 'No portfolio items available.';

  @override
  String get notifications => 'Notifications';

  @override
  String get markAllAsRead => 'Mark all as read';

  @override
  String get noNotificationsYet => 'No notifications yet';

  @override
  String get notification => 'Notification';

  @override
  String get noConversationsYet => 'No conversations yet';

  @override
  String get startChattingWithFundis => 'Start chatting with technicians near you';

  @override
  String get noMessagesYet => 'No messages yet';

  @override
  String get sayHelloToStart => 'Say hello to start chatting';

  @override
  String get typeAMessage => 'Type a message...';

  @override
  String get copy => 'Copy';

  @override
  String get messageCopied => 'Message copied';

  @override
  String get messageDeleted => 'Message deleted';

  @override
  String get deleteMessage => 'Delete message?';

  @override
  String get areYouSureDeleteMessage => 'Are you sure you want to delete this message?';

  @override
  String get failedToSend => 'Failed to send message';

  @override
  String get failedToSendImage => 'Failed to send image';

  @override
  String get failedToSendFile => 'Failed to send file';

  @override
  String get voiceRecordingComingSoon => 'Voice recording coming soon!';

  @override
  String get messageReactionAdded => 'Reaction added';

  @override
  String get messageReactionRemoved => 'Reaction removed';

  @override
  String get typing => 'typing…';

  @override
  String get download => 'Download';

  @override
  String get fileDownloaded => 'File downloaded';

  @override
  String get fileDownloadFailed => 'Failed to download file';

  @override
  String get conversationDeleted => 'Conversation deleted';

  @override
  String get areYouSureDeleteConversation => 'Are you sure you want to delete this conversation?';

  @override
  String get noInternetConnection => 'No internet connection';

  @override
  String get connecting => 'Connecting...';

  @override
  String get disconnected => 'Disconnected';

  @override
  String get reconnecting => 'Reconnecting...';

  @override
  String get noContent => 'No content available.';

  @override
  String get getInTouch => 'Get in Touch';

  @override
  String get email => 'Email';

  @override
  String get website => 'Website';

  @override
  String get phoneNumbers => 'Phone Numbers';

  @override
  String get noFaqs => 'No FAQs available.';

  @override
  String get welcomeFundi => 'Find Trusted Fundis';

  @override
  String get findTrustedDesc => 'Connect with verified, experienced fundis near you. Request services like AC repair, plumbing, and more.';

  @override
  String get requestTrack => 'Request & Track';

  @override
  String get requestTrackDesc => 'Post a service request, get accepted by a fundi, and track the status in real time. Simple, fast, and reliable.';

  @override
  String get getStarted => 'Get Started';

  @override
  String get next => 'Next';

  @override
  String get skip => 'Skip';

  @override
  String get failed => 'Failed';

  @override
  String get services => 'Services';

  @override
  String get generalServices => 'General Services';

  @override
  String get fundi => 'Fundi';

  @override
  String get rate => 'Rate';

  @override
  String get aboutFundi => 'About';

  @override
  String get servicesAndRate => 'Services & Rate';

  @override
  String get searchPlaceFirst => 'Search a place first to see it on the map.';

  @override
  String get searchPlaceHint => 'Go back and search for a location to see technicians nearby.';

  @override
  String get aiAssistant => 'AI Assistant';

  @override
  String get pleaseEnterLocation => 'Please enter a location';

  @override
  String get searchServiceHint => 'Search for services (e.g. plumbing, electrician...)';

  @override
  String noFundisForService(String service) {
    return 'No fundis for $service';
  }

  @override
  String get refreshed => 'Refreshed successfully';

  @override
  String get refreshFailed => 'Failed to refresh data';

  @override
  String get pullToRefresh => 'Pull to refresh';

  @override
  String get loading => 'Loading...';

  @override
  String get showList => 'Show List';

  @override
  String get viewAll => 'View All';

  @override
  String get jobsCompleted => 'jobs completed';

  @override
  String get rating => 'Rating';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get send => 'Send';

  @override
  String get noJobsYet => 'No jobs yet';

  @override
  String get noJobsHint => 'Accepted requests you mark as a job appear here.';

  @override
  String get activeJobs => 'Active Jobs';

  @override
  String get completedJobs => 'Completed Jobs';

  @override
  String get markComplete => 'Mark Complete';

  @override
  String get jobCompletedMsg => 'Job completed. Ticket closed.';

  @override
  String get couldNotStartCompletion => 'Could not start completion.';

  @override
  String get viewDetails => 'View Details';

  @override
  String get statusInProgress => 'In progress';

  @override
  String get statusCompleted => 'Completed';

  @override
  String get noJobsMatchFilter => 'No jobs match your filters';

  @override
  String get noContactDetails => 'No contact details available for this fundi.';

  @override
  String get contactFundi => 'Contact Fundi';

  @override
  String get chats => 'Chats';

  @override
  String get archives => 'Archives';

  @override
  String get updates => 'Updates';

  @override
  String get message => 'Message';

  @override
  String get reply => 'Reply';

  @override
  String get sayHello => 'Say hello to start the conversation';

  @override
  String get noArchivedChats => 'No archived chats';

  @override
  String get nothingHere => 'Nothing here';

  @override
  String get findTechnicians => 'Find technicians';

  @override
  String get unread => 'Unread';

  @override
  String unreadCount(int count) {
    return 'Unread $count';
  }

  @override
  String get pinned => 'Pinned';

  @override
  String get pinChat => 'Pin chat';

  @override
  String get unpinChat => 'Unpin chat';

  @override
  String get archiveChat => 'Archive chat';

  @override
  String get unarchiveChat => 'Unarchive chat';

  @override
  String get deleteChat => 'Delete chat';

  @override
  String deleteChatConfirm(String name) {
    return 'Delete chat with $name?';
  }

  @override
  String get deleteChatWarning => 'All messages and files in this chat will be removed for both of you.';

  @override
  String get chatArchived => 'Chat archived';

  @override
  String get chatUnarchived => 'Chat unarchived';

  @override
  String get chatDeleted => 'Chat deleted';

  @override
  String get chatDeleteFailed => 'Could not delete the chat';

  @override
  String get noRecentUpdates => 'No recent updates';

  @override
  String get postsFromFundis => 'Posts from fundis you chat with show up here';

  @override
  String get newUpdates => 'New';

  @override
  String get viewedUpdates => 'Viewed';

  @override
  String newPosts(int count) {
    return '$count new post';
  }

  @override
  String newPostsPlural(int count) {
    return '$count new posts';
  }

  @override
  String hAgo(int count) {
    return '$count h ago';
  }

  @override
  String get mediaLinksDocs => 'Media, links & docs';

  @override
  String get starredMessages => 'Starred messages';

  @override
  String pinnedXOfY(int current, int total) {
    return 'Pinned $current of $total';
  }

  @override
  String get originalMsgNotAvailable => 'The original message is no longer available.';

  @override
  String get fileNotAllowed => 'This file type is not allowed.';

  @override
  String fileTooLarge(int max) {
    return 'File too large. Max $max MB for this type.';
  }

  @override
  String get camera => 'Camera';

  @override
  String get photos => 'Photos';

  @override
  String get video => 'Video';

  @override
  String get document => 'Document';

  @override
  String get fileSizeHint => 'Photos 5 MB · Videos 20 MB · Files 15 MB';

  @override
  String get messagePinned => 'Message pinned';

  @override
  String get messageUnpinned => 'Message unpinned';

  @override
  String get starred => 'Starred';

  @override
  String get removedFromStarred => 'Removed from starred';

  @override
  String deleteMessages(int count) {
    return 'Delete $count messages?';
  }

  @override
  String get deleteForEveryone => 'Delete for everyone';

  @override
  String get deleteForMe => 'Delete for me';

  @override
  String get onlyRemovedThisPhone => 'Only removed on this phone';

  @override
  String msgCouldNotBeDeleted(int count) {
    return '$count message(s) could not be deleted for everyone.';
  }

  @override
  String get you => 'You';

  @override
  String get thisMessageWasDeleted => 'This message was deleted';

  @override
  String get messageInfo => 'Message info';

  @override
  String get read => 'Read';

  @override
  String get delivered => 'Delivered';

  @override
  String get sent => 'Sent';

  @override
  String reactionsCount(int count) {
    return 'Reactions · $count';
  }

  @override
  String get couldNotLoadInfo => 'Could not load info';

  @override
  String get noMedia => 'No media';

  @override
  String get noDocs => 'No documents';

  @override
  String get noLinks => 'No links';

  @override
  String get media => 'Media';

  @override
  String get docs => 'Docs';

  @override
  String get links => 'Links';

  @override
  String get saveShare => 'Save / share';

  @override
  String get noChatsToForward => 'No chats to forward to';

  @override
  String get forwardMsgTo => 'Forward message to…';

  @override
  String forwardMsgsTo(int count) {
    return 'Forward $count messages to…';
  }

  @override
  String get sending => 'Sending…';

  @override
  String get more => 'More';

  @override
  String get info => 'Info';

  @override
  String get select => 'Select';

  @override
  String get forward => 'Forward';

  @override
  String get pin => 'Pin';

  @override
  String get unpin => 'Unpin';

  @override
  String get star => 'Star';

  @override
  String get unstar => 'Unstar';

  @override
  String get save => 'Save';

  @override
  String get noStarredMessages => 'No starred messages';

  @override
  String get file => 'File';

  @override
  String get showInChat => 'Show in chat';

  @override
  String newPostsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count new posts',
      one: '1 new post',
    );
    return '$_temp0';
  }

  @override
  String get noTicketsYet => 'No tickets yet';

  @override
  String get noTicketsHint => 'A ticket is created when you mark a request as a job.';

  @override
  String get fundiLabel => 'Fundi';

  @override
  String get createdOn => 'Created';

  @override
  String get completedOn => 'Completed';

  @override
  String get searchByFundiName => 'Search by fundi name...';

  @override
  String get checkBackLater => 'Check back later for updates from our technicians.';

  @override
  String get noPostsMatch => 'No posts match';

  @override
  String get tapToPlayVideo => 'Tap to play video';

  @override
  String get tapToPayForJob => 'Tap to Pay for Job';

  @override
  String get payForJobConfirm => 'Do you want to pay for a job?';

  @override
  String get confirm => 'Go to Pay';

  @override
  String get startedOn => 'Started';

  @override
  String get completedOnLabel => 'Completed';

  @override
  String get descriptionLabel => 'Description';

  @override
  String get ticketLabel => 'Ticket';

  @override
  String get payForJob => 'Pay for Job';

  @override
  String get confirmCompletion => 'Confirm Completion';

  @override
  String get sendingSmsCode => 'Sending SMS Code…';

  @override
  String get jobCompletedSuccess => 'Job completed successfully!';

  @override
  String get jobNotFound => 'Job not found';

  @override
  String get couldNotSendSms => 'Could not send verification code via SMS.';

  @override
  String get enterSixDigitCode => 'Enter the 6-digit code received via SMS.';

  @override
  String get invalidCodeTryAgain => 'Invalid code. Check SMS and try again.';

  @override
  String get couldNotResendSms => 'Could not resend SMS code.';

  @override
  String get enterSmsCodeHint => 'Enter the 6-digit code sent by SMS to your phone to confirm completion.';

  @override
  String get verifyAndComplete => 'Verify & Complete';

  @override
  String resendIn(int seconds) {
    return 'Resend in ${seconds}s';
  }

  @override
  String get confirmCompletionTitle => 'Confirm Completion';

  @override
  String get completionCodeHint => '------';

  @override
  String get filterByFundiOrService => 'Filter by fundi or service...';

  @override
  String get allLabel => 'All';

  @override
  String get statusPending => 'Pending';

  @override
  String get statusAccepted => 'Accepted';

  @override
  String get statusRejected => 'Rejected';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String get statTotal => 'Total';

  @override
  String get statClosed => 'Closed';

  @override
  String get noRequestsMatchFilter => 'No requests match your filter';

  @override
  String get sectionActiveRequests => 'Active Requests';

  @override
  String get sectionClosedRequests => 'Closed Requests';

  @override
  String get cancelAction => 'Cancel';

  @override
  String get viewJob => 'View Job';

  @override
  String get chatAction => 'Chat';

  @override
  String get detailsAction => 'Details';

  @override
  String get couldNotCancelRequest => 'Could not cancel request.';

  @override
  String get markAsJob => 'Mark as job';

  @override
  String markAsJobConfirm(String name) {
    return 'Start this job with $name? A ticket will be created.';
  }

  @override
  String get couldNotCreateJob => 'Could not create the job.';

  @override
  String get timeAgoJustNow => 'Just now';

  @override
  String timeAgoMinutes(int count) {
    return '${count}m ago';
  }

  @override
  String timeAgoHours(int count) {
    return '${count}h ago';
  }

  @override
  String timeAgoDays(int count) {
    return '${count}d ago';
  }

  @override
  String get requestDetailsTitle => 'Request Details';

  @override
  String get fieldService => 'Service';

  @override
  String get fieldCategory => 'Category';

  @override
  String get fieldDescription => 'Description';

  @override
  String get fieldFundi => 'Fundi';

  @override
  String get fieldArea => 'Area';

  @override
  String get fieldRequestedOn => 'Requested On';

  @override
  String get fieldStatus => 'Status';

  @override
  String get closeAction => 'Close';

  @override
  String get signInToReadBlog => 'Sign in or create an account to read our blog and tips.';

  @override
  String get signInToRequests => 'Sign in or create an account to send and track your service requests.';

  @override
  String get signInToJobs => 'Sign in or create an account to view and manage your jobs.';

  @override
  String get signInToProfile => 'Sign in or create an account to see and edit your profile.';

  @override
  String get signInToTickets => 'Sign in or create an account to view your tickets.';

  @override
  String get signInToChat => 'Sign in or create an account to chat with fundis.';

  @override
  String get signInToNotifications => 'Sign in or create an account to see your notifications.';

  @override
  String get signInToRefresh => 'Sign in or create an account to refresh your data.';

  @override
  String get guestUser => 'Guest User';

  @override
  String get notLoggedIn => 'Not logged in';

  @override
  String get caughtUp => 'You are all caught up';

  @override
  String get notifyWhenNew => 'We will notify you when there is something new.';

  @override
  String get chatLabel => 'Chat';

  @override
  String get newRequestLabel => 'New Request';

  @override
  String get requestAcceptedLabel => 'Request Accepted';

  @override
  String get requestRejectedLabel => 'Request Rejected';

  @override
  String get notificationLabel => 'Notification';

  @override
  String get unreadNotifications => 'unread notifications';
}
