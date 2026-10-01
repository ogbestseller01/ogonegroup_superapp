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
  String get myRequests => 'Requests';

  @override
  String get profile => 'Profile';

  @override
  String get settings => 'Settings';

  @override
  String get chat => 'Chat';

  @override
  String get payments => 'Payments';

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
  String get refresh => 'Refresh';

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
  String get retry => 'Retry';

  @override
  String noResultsFor(Object service) {
    return 'No Fundis for $service';
  }

  @override
  String noResultsForServiceCategory(Object category, Object service) {
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
  String get viewProfile => 'View Profile';

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
  String get signInToContinue => 'Sign in to continue';

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
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get enterEmail => 'Enter your email address';

  @override
  String get enterValidEmail => 'Enter a valid email address';

  @override
  String get enterPassword => 'Enter your password';

  @override
  String get passwordMinLength => 'Password must be at least 6 characters';

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
  String get editProfile => 'Edit Profile';

  @override
  String get editProfileTitle => 'Edit Profile';

  @override
  String get updateInfo => 'Update Your Info';

  @override
  String get name => 'Full Name';

  @override
  String get phone => 'Phone';

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
  String get noRequestsYet => 'No requests yet';

  @override
  String get requestsWillAppear => 'Your requests will appear here';

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
  String get justNow => 'Just now';

  @override
  String get copy => 'Copy';

  @override
  String get messageCopied => 'Message copied';

  @override
  String get messageDeleted => 'Message deleted';

  @override
  String get deleteMessage => 'Delete Message';

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
  String get typing => 'Typing...';

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
  String get comingSoon => 'coming soon!';

  @override
  String get pleaseEnterLocation => 'Please enter a location';

  @override
  String get searchServiceHint => 'Search for services (e.g. plumbing, electrician...)';

  @override
  String noFundisForService(Object service) {
    return 'No fundis for $service';
  }

  @override
  String get refreshed => 'Refreshed';

  @override
  String get refreshFailed => 'Refresh failed';

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
}
