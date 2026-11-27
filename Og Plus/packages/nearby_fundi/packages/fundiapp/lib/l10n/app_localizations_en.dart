// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'NETSAF FUNDI APP';

  @override
  String get fundiAppTitle => 'NETSAF FUNDI APP';

  @override
  String get hello => 'Hello';

  @override
  String get home => 'Home';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get logout => 'Log out';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String get profile => 'Profile';

  @override
  String get notifications => 'Notifications';

  @override
  String get aiAssistant => 'AI Assistant';

  @override
  String get chat => 'Chat';

  @override
  String get blog => 'Blog';

  @override
  String get more => 'More';

  @override
  String get comingSoon => 'Coming soon!';

  @override
  String get quickActions => 'Quick Actions';

  @override
  String get registrationSessionLost => 'Registration session lost. Please start again.';

  @override
  String otpResentTo(String identifier) {
    return 'OTP resent to $identifier';
  }

  @override
  String get failedToResendOtp => 'Failed to resend OTP.';

  @override
  String resendAvailableIn(int seconds) {
    return 'Resend available in ${seconds}s';
  }

  @override
  String get didntReceiveCode => 'Didn\'t receive the code?';

  @override
  String sending(String percent) {
    return 'Sending…';
  }

  @override
  String get wait => 'Wait';

  @override
  String get resend => 'Resend';

  @override
  String get enter6DigitOtp => 'Enter 6-digit OTP';

  @override
  String get passwordMinLength => 'Password must be at least 8 characters';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get enterValidEmail => 'Enter a valid email';

  @override
  String get regStep1Failed => 'Could not create your account. Please check your details and try again.';

  @override
  String get regOtpDeliveryFailed => 'Account created, but we could not send the code right now. Tap Resend on the next screen.';

  @override
  String regOtpSentSms(String recipient) {
    return 'We sent a 6-digit verification code via SMS to $recipient';
  }

  @override
  String regOtpSentEmail(String recipient) {
    return 'We sent a 6-digit verification code to your email $recipient';
  }

  @override
  String get welcomeBack => 'Welcome Back';

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
  String get becomeFundi => 'Become a Fundi';

  @override
  String get joinProvider => 'Join as a service provider';

  @override
  String get fundiRegistration => 'Fundi Registration';

  @override
  String get fillDetails => 'Fill in your details to start serving customers';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get serviceArea => 'Service Area';

  @override
  String get selectServices => 'Select Services';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get registerAsFundi => 'Register as Fundi';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get verificationCode => 'Verification Code';

  @override
  String get enterCodeSent => 'Enter the code sent to';

  @override
  String get enterOtp => 'Enter the 6-digit OTP';

  @override
  String get otpSent => 'A 6-digit code has been sent to your email';

  @override
  String get verifyOtp => 'Verify';

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
  String get loginBack => 'Back';

  @override
  String get loginTheme => 'Theme';

  @override
  String get loginThemeLight => 'Light';

  @override
  String get loginThemeDark => 'Dark';

  @override
  String get loginEmail => 'Email';

  @override
  String get loginPhone => 'Phone';

  @override
  String get loginEmailHint => 'you@example.com';

  @override
  String get loginPhoneHint => '712345678';

  @override
  String get loginEnterValidEmail => 'Enter a valid email';

  @override
  String get loginEnterPhone => 'Enter phone number';

  @override
  String get loginPhoneDigits => '7–15 digits required';

  @override
  String get loginPasswordMin => 'Min 6 characters';

  @override
  String get loginSearchCountry => 'Search country...';

  @override
  String get loginNoCountry => 'No country found';

  @override
  String get loginIAgree => 'I agree to the';

  @override
  String get loginTerms => 'Terms & Conditions';

  @override
  String get loginAnd => 'and';

  @override
  String get loginPrivacy => 'Privacy Policy';

  @override
  String get loginAcceptTerms => 'Please accept the Terms & Conditions to continue';

  @override
  String get loginBrandTagline => 'Hire. Manage. Get it done.';

  @override
  String get loginHome => 'Home';

  @override
  String get loginRememberMe => 'Remember me';

  @override
  String loginContinueAs(String name) {
    return 'Continue as $name';
  }

  @override
  String get loginUseAnother => 'Use another account';

  @override
  String get loginFailed => 'Login failed. Please try again.';

  @override
  String get loginNetworkError => 'Network error. Check your connection and try again.';

  @override
  String get loginNotFundiAccount => 'This account is not a Fundi account. Please use the NearbyFundi customer app.';

  @override
  String get loginSavedLoginInvalid => 'Saved login is no longer valid. Please sign in again.';

  @override
  String get loginSessionExpired => 'Session expired. Please sign in again.';

  @override
  String get loginRegistrationExpired => 'Registration session expired. Please start over.';

  @override
  String get loginPhoneTaken => 'This phone number is already registered. Please log in or use a different number.';

  @override
  String get loginPhoneDeleted => 'This phone number belongs to a deleted account. Contact support to restore it, or use a different number.';

  @override
  String get loginEmailTaken => 'This email is already registered. Please log in or use a different email.';

  @override
  String get loginIdTaken => 'This ID number has already been registered. Contact support if you believe this is a mistake.';

  @override
  String get loginStepsIncomplete => 'Some registration steps are incomplete. Please go back and complete them before submitting.';

  @override
  String get loginSubmitFailed => 'Registration submission failed. Please try again.';

  @override
  String get myProfile => ' Profile';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get profileDetails => 'Profile Details';

  @override
  String get updateInfo => 'Update Your Info';

  @override
  String get name => 'Name';

  @override
  String get phone => 'Phone';

  @override
  String get bio => 'Bio';

  @override
  String get hourlyRate => 'Hourly Rate (TZS)';

  @override
  String get area => 'Area';

  @override
  String get experience => 'Experience';

  @override
  String get years => 'years';

  @override
  String get tzs => 'TZS';

  @override
  String get accountStatus => 'Account Status';

  @override
  String get active => 'Active';

  @override
  String get onlineStatus => 'Online Status';

  @override
  String get servicesIOffer => 'Services I offer';

  @override
  String get noServicesSelected => 'No services selected';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get updateFailed => 'Update failed. Please try again.';

  @override
  String get retry => 'Retry';

  @override
  String get back => 'Back';

  @override
  String get refresh => 'Refresh';

  @override
  String get newPost => 'New Post';

  @override
  String get photos => 'Photos';

  @override
  String get addAtLeastOnePhoto => 'Add at least one photo.';

  @override
  String get failedToSavePost => 'Failed to save post';

  @override
  String get deleteFailed => 'Failed to delete file';

  @override
  String get imageNotAvailable => 'Image not available';

  @override
  String get portfolioEmptySubtitle => 'Share your work with photos to build your portfolio.';

  @override
  String get justNow => 'Just now';

  @override
  String minutesAgo(int minutes) {
    return '${minutes}m ago';
  }

  @override
  String hoursAgo(int hours) {
    return '${hours}h ago';
  }

  @override
  String daysAgo(int days) {
    return '${days}d ago';
  }

  @override
  String get editPost => 'Edit Post';

  @override
  String get deletePostAction => 'Delete Post';

  @override
  String get addPost => 'Add Post';

  @override
  String get portfolioFailedToLoad => 'Failed to load portfolio';

  @override
  String get portfolioUpdateFailed => 'Failed to update portfolio';

  @override
  String get portfolioDeleteFailed => 'Failed to delete post';

  @override
  String get requests => 'Requests';

  @override
  String get filterByCustomerService => 'Filter by customer or service...';

  @override
  String get noRequests => 'No requests yet.';

  @override
  String get noMatchingRequests => 'No matching requests';

  @override
  String get accept => 'Accept';

  @override
  String get reject => 'Reject';

  @override
  String get requestAccepted => 'Request accepted';

  @override
  String get requestRejected => 'Request rejected';

  @override
  String get failedToAccept => 'Failed to accept';

  @override
  String get failedToReject => 'Failed to reject';

  @override
  String get viewJob => 'View Job';

  @override
  String get chatWithCustomer => 'Chat with Customer';

  @override
  String jobLabel(String number) {
    return 'Job $number';
  }

  @override
  String jobWithStatus(String number, String status) {
    return 'Job $number • $status';
  }

  @override
  String get requestRejectedBanner => 'Request Rejected';

  @override
  String get requestCancelledBanner => 'Request Cancelled';

  @override
  String failedToStartChat(String error) {
    return 'Failed to start chat: $error';
  }

  @override
  String get statusPending => 'Pending';

  @override
  String get statusAccepted => 'Accepted';

  @override
  String get statusRejected => 'Rejected';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String get filterAll => 'All';

  @override
  String get statTotal => 'Total';

  @override
  String get statPending => 'Pending';

  @override
  String get statAccepted => 'Accepted';

  @override
  String get typing => 'Typing...';

  @override
  String get sayHelloToStart => 'Say hello to start chatting!';

  @override
  String get replyEllipsis => 'Reply…';

  @override
  String get message => 'Message';

  @override
  String get attach => 'Attach';

  @override
  String get send => 'Send';

  @override
  String get copy => 'Copy';

  @override
  String get copied => 'Copied';

  @override
  String get delete => 'Delete';

  @override
  String get cancel => 'Cancel';

  @override
  String get forwarded => 'Forwarded';

  @override
  String get deleted => 'Deleted';

  @override
  String get starred => 'Starred';

  @override
  String get removedFromStarred => 'Removed from starred';

  @override
  String get messagePinned => 'Message pinned';

  @override
  String get messageUnpinned => 'Message unpinned';

  @override
  String get deleteMessage => 'Delete message?';

  @override
  String deleteMessages(int count) {
    return 'Delete $count messages?';
  }

  @override
  String get deleteForEveryone => 'Delete for everyone';

  @override
  String get deleteForEveryoneSubtitle => 'Removed for both of you';

  @override
  String get deleteForMe => 'Delete for me';

  @override
  String get deleteForMeSubtitle => 'Only removed on this phone';

  @override
  String deleteEveryoneFailed(int count) {
    return '$count message(s) could not be deleted for everyone.';
  }

  @override
  String get originalMessageUnavailable => 'The original message is no longer available.';

  @override
  String get fileTypeNotAllowed => 'This file type is not allowed.';

  @override
  String fileTooLarge(int limit) {
    return 'File too large. Max $limit MB for this type.';
  }

  @override
  String get attachCamera => 'Camera';

  @override
  String get attachPhotos => 'Photos';

  @override
  String get attachVideo => 'Video';

  @override
  String get attachDocument => 'Document';

  @override
  String get attachSizeHint => 'Photos 5 MB · Videos 20 MB · Files 15 MB';

  @override
  String get pinnedMessage => 'Pinned message';

  @override
  String pinnedXofY(int i, int n) {
    return 'Pinned $i of $n';
  }

  @override
  String get you => 'You';

  @override
  String get mediaLinksDocs => 'Media, links & docs';

  @override
  String get starredMessages => 'Starred messages';

  @override
  String get mediaTab => 'Media';

  @override
  String get docsTab => 'Docs';

  @override
  String get linksTab => 'Links';

  @override
  String get noMedia => 'No media';

  @override
  String get noDocuments => 'No documents';

  @override
  String get noLinks => 'No links';

  @override
  String get noStarredMessages => 'No starred messages';

  @override
  String get file => 'File';

  @override
  String get customers => 'Customers';

  @override
  String get archivedChats => 'Archived Chats';

  @override
  String get viewActiveChats => 'View Active Chats';

  @override
  String get viewArchivedChats => 'View Archived Chats';

  @override
  String get searchCustomers => 'Search customers';

  @override
  String get filterUnread => 'Unread';

  @override
  String filterUnreadCount(int count) {
    return 'Unread $count';
  }

  @override
  String get filterPinned => 'Pinned';

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
  String deleteChatWith(String name) {
    return 'Delete chat with $name?';
  }

  @override
  String get deleteChatWarning => 'All messages and files will be removed for both of you.';

  @override
  String get noMatchingConversations => 'No matching conversations';

  @override
  String get noArchivedChats => 'No archived chats';

  @override
  String get reply => 'Reply';

  @override
  String get noConversationsYet => 'No conversations yet';

  @override
  String get customersWillAppearHere => 'Customers will appear here when they message you';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get photoEmoji => '📷 Photo';

  @override
  String get fileEmoji => '📁 File';

  @override
  String replyChip(String sender, String text) {
    return '↩ $sender: $text';
  }

  @override
  String get backTooltip => 'Back';

  @override
  String get refreshTooltip => 'Refresh';

  @override
  String get noCustomersYet => 'No customers yet';

  @override
  String get customersWillAppear => 'Customers will appear here when they message you';

  @override
  String get deleteChatConfirmation => 'All messages and files will be removed for both of you.';

  @override
  String get chatDeleted => 'Chat deleted';

  @override
  String get failedToDeleteChat => 'Could not delete the chat';

  @override
  String get chatArchived => 'Chat archived';

  @override
  String get chatUnarchived => 'Chat unarchived';

  @override
  String get forward => 'Forward';

  @override
  String get star => 'Star';

  @override
  String get unstar => 'Unstar';

  @override
  String get pin => 'Pin';

  @override
  String get unpin => 'Unpin';

  @override
  String get info => 'Info';

  @override
  String get select => 'Select';

  @override
  String get savedToGallery => 'Saved to your gallery';

  @override
  String get noAppToOpen => 'No app installed that can open this file type.';

  @override
  String get photo => 'Photo';

  @override
  String get videoFile => '🎥 Video';

  @override
  String get attachment => '📎 Attachment';

  @override
  String get forwardedLower => 'forwarded';

  @override
  String get video => 'Video';

  @override
  String get couldNotOpenFile => 'Could not open this file.';

  @override
  String get allowGalleryAccess => 'Allow gallery access to save this file.';

  @override
  String get galleryPluginMissing => 'Gallery plugin not installed in this build. Opening share sheet instead.';

  @override
  String get couldNotSaveToGallery => 'Could not save to the gallery.';

  @override
  String get couldNotPlayVideo => 'Could not play this video.';

  @override
  String get saveToGallery => 'Save to gallery';

  @override
  String get share => 'Share';

  @override
  String get messageDeleted => 'Message deleted';

  @override
  String get notSentTapToRetry => 'Not sent · Tap to retry';

  @override
  String errorTapToRetry(String error) {
    return '$error · Tap to retry';
  }

  @override
  String get saveShare => 'Save / share';

  @override
  String get save => 'Save';

  @override
  String get forwardMessageTo => 'Forward message to…';

  @override
  String forwardMessagesTo(int count) {
    return 'Forward $count messages to…';
  }

  @override
  String get search => 'Search';

  @override
  String get noChatsToForwardTo => 'No chats to forward to';

  @override
  String get sendingShort => 'Sending…';

  @override
  String get messageInfo => 'Message info';

  @override
  String get couldNotLoadInfo => 'Could not load info';

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
  String get online => 'Online';

  @override
  String get offline => 'Offline';

  @override
  String get youAreOnline => 'You are online';

  @override
  String get youAreOffline => 'You are offline';

  @override
  String get lastSeen => 'Last seen recently';

  @override
  String get fundiDashboard => 'Dashboard';

  @override
  String get welcomeFundi => 'Welcome Fundi';

  @override
  String get manageServicesPosts => 'Manage your services, posts and all your requests in one place.';

  @override
  String get stayConnected => 'Stay Connected';

  @override
  String get getNotifications => 'Get instant notifications for new requests and updates.';

  @override
  String get getStarted => 'Get Started';

  @override
  String get next => 'Next';

  @override
  String get skip => 'Skip';

  @override
  String get totalRequests => 'Total Requests';

  @override
  String get pending => 'Pending';

  @override
  String get completed => 'Completed';

  @override
  String get myPosts => ' Posts';

  @override
  String get noPosts => 'No posts yet.';

  @override
  String get createPost => 'Create your first post';

  @override
  String get createPostTitle => 'Create Post';

  @override
  String get editPostTitle => 'Edit Post';

  @override
  String get postCreated => 'Post created';

  @override
  String get postUpdated => 'Post updated';

  @override
  String get postDeleted => 'Post deleted';

  @override
  String get deletePost => 'Delete Post';

  @override
  String get filterByTitleContent => 'Filter by title or content...';

  @override
  String get portfolio => 'Portfolio';

  @override
  String get noPortfolio => 'No portfolio items.';

  @override
  String get addPortfolio => 'Add your first item';

  @override
  String get addPortfolioItem => 'Add Portfolio Item';

  @override
  String get editPortfolioItem => 'Edit Portfolio Item';

  @override
  String get itemAdded => 'Item added';

  @override
  String get itemUpdated => 'Item updated';

  @override
  String get itemDeleted => 'Item deleted';

  @override
  String get deletePortfolioItem => 'Delete Portfolio Item';

  @override
  String get filterByDescription => 'Filter by description...';

  @override
  String get customer => 'Customer';

  @override
  String get service => 'Service';

  @override
  String get description => 'Description';

  @override
  String get aboutUs => 'About Us';

  @override
  String get aboutFundiApp => 'About NETSAF FUNDI APP';

  @override
  String get terms => 'Terms & Conditions';

  @override
  String get faq => 'FAQ';

  @override
  String get contactUs => 'Contact Us';

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
  String get settingsPreferences => 'Preferences';

  @override
  String get settingsInformation => 'Information';

  @override
  String get settingsAccount => 'Account';

  @override
  String get settingsDarkMode => 'Dark Mode';

  @override
  String get settingsDarkOn => 'Dark theme enabled';

  @override
  String get settingsLightOn => 'Light theme enabled';

  @override
  String get pushNotifications => 'Push Notifications';

  @override
  String get receiveAlerts => 'Receive alerts about requests';

  @override
  String get viewNotifications => 'View Notifications';

  @override
  String get seeAllNotifications => 'See all your incoming notifications';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSwahili => 'Kiswahili';

  @override
  String get logoutConfirmation => 'Are you sure you want to logout?';

  @override
  String get logoutConfirmTitle => 'Log out?';

  @override
  String get logoutConfirmMessage => 'You’ll need to sign in again to access your account.';

  @override
  String logoutFailed(Object error) {
    return 'Logout failed: $error';
  }

  @override
  String get loggingOut => 'Logging out…';

  @override
  String get deleteAccountConfirmation => 'This action is permanent. All your data will be lost. Are you sure?';

  @override
  String get couldNotDeleteAccount => 'Could not delete account';

  @override
  String get profileUpdated => 'Profile updated successfully';

  @override
  String get tapToChangePhoto => 'Tap camera to change photo';

  @override
  String get nameRequired => 'Name required';

  @override
  String get nidaNumber => 'NIDA Number';

  @override
  String get nidaHelperText => 'Set during registration. Contact support to change.';

  @override
  String get verifiedLabel => '✓ VERIFIED';

  @override
  String get selectAtLeastOneService => 'Select at least one service';

  @override
  String get editServices => 'Edit services';

  @override
  String get noServicesAvailable => 'No services available.';

  @override
  String get servicesUpdated => 'Services updated';

  @override
  String get typeAreaOrPickOnMap => 'Type area or pick on map';

  @override
  String get pickOnMap => 'Pick on map';

  @override
  String get locationSetOnMap => 'Location set on map';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get ok => 'OK';

  @override
  String get pickLocationOnMap => 'Pick location on map';

  @override
  String get searchAreaHint => 'Search area, street, or landmark…';

  @override
  String get gettingAddress => 'Getting address…';

  @override
  String get tapMapToSelectLocation => 'Tap on the map to select a location';

  @override
  String get useThisLocation => 'Use this location';

  @override
  String get selectedLocation => 'Selected location';

  @override
  String get zoomIn => 'Zoom in';

  @override
  String get zoomOut => 'Zoom out';

  @override
  String get noNotificationsYet => 'No notifications yet';

  @override
  String get unreadNotifications => 'unread notifications';

  @override
  String get noNewNotifications => 'No new notifications';

  @override
  String get notification => 'Notification';

  @override
  String get markAllAsRead => 'Mark all as read';

  @override
  String get noMessagesYet => 'No messages yet';

  @override
  String get typeAMessage => 'Type a message...';

  @override
  String get messageCopied => 'Message copied';

  @override
  String get failedToSend => 'Failed to send message';

  @override
  String get failedToSendImage => 'Failed to send image';

  @override
  String get failedToSendFile => 'Failed to send file';

  @override
  String get deleteMessageConfirmation => 'Delete this message?';

  @override
  String get selectImage => 'Select an image';

  @override
  String get image => 'Image';

  @override
  String get voiceMessage => 'Voice message';

  @override
  String get startChattingWithFundis => 'Start chatting with customers near you';

  @override
  String get viewProfile => 'View Profile';

  @override
  String get clearChat => 'Clear Chat';

  @override
  String get blockUser => 'Block User';

  @override
  String get camera => 'Camera';

  @override
  String get gallery => 'Gallery';

  @override
  String get document => 'Document';

  @override
  String get recordVoice => 'Record voice';

  @override
  String get stopRecording => 'Stop recording';

  @override
  String get downloadFile => 'Download File';

  @override
  String get deleteFile => 'Delete File';

  @override
  String get deleteConversation => 'Delete Conversation';

  @override
  String get deleteConversationConfirmation => 'Are you sure you want to delete this entire conversation? This action cannot be undone.';

  @override
  String get conversationDeleted => 'Conversation deleted';

  @override
  String get fileDownloaded => 'File downloaded successfully';

  @override
  String get fileDeleted => 'File deleted successfully';

  @override
  String get downloadFailed => 'Failed to download file';

  @override
  String get permissionDenied => 'Permission denied';

  @override
  String get storagePermissionDenied => 'Storage permission denied';

  @override
  String get photosPermissionDenied => 'Photos permission denied';

  @override
  String get filterTiles => 'Filter tiles...';

  @override
  String get noMatchingTiles => 'No matching tiles';

  @override
  String get noMatchingItems => 'No matching items';

  @override
  String get add => 'Add';

  @override
  String get update => 'Update';

  @override
  String get create => 'Create';

  @override
  String get call => 'Call';

  @override
  String get areYouSure => 'Are you sure?';

  @override
  String get selectServicesDialogTitle => 'Select Services';

  @override
  String get open => 'Open';

  @override
  String get openFile => 'Open File';

  @override
  String get inProgress => 'In Progress';

  @override
  String get markComplete => 'Mark as Complete';

  @override
  String get requestCompleted => 'Request completed';

  @override
  String get completeRequest => 'Complete Request';

  @override
  String get completeConfirmation => 'Are you sure you want to mark this request as completed?';

  @override
  String get completedSuccess => 'Request completed successfully!';

  @override
  String get failedToComplete => 'Failed to complete request';

  @override
  String get startWork => 'Start Work';

  @override
  String get requestInProgress => 'Request in progress';

  @override
  String get accepted => 'Accepted';

  @override
  String get rejected => 'Rejected';

  @override
  String get cancelled => 'Cancelled';

  @override
  String get filterByStatus => 'Filter by status';

  @override
  String get all => 'All';

  @override
  String get noRequestsMatchFilter => 'No requests match the selected filter';

  @override
  String get subscriptions => 'Subscriptions';

  @override
  String get mySubscriptions => 'My Subscriptions';

  @override
  String get subscriptionStatus => 'Subscription Status';

  @override
  String get choosePlan => 'Choose Your Plan';

  @override
  String get selectPlan => 'Select the subscription plan that suits you';

  @override
  String get continueToPayment => 'Continue to Payment';

  @override
  String get paymentMethods => 'Payment Methods';

  @override
  String get choosePaymentMethod => 'Choose Payment Method';

  @override
  String get selectedPlan => 'Selected Plan';

  @override
  String get paymentReference => 'Payment Reference';

  @override
  String get paymentReferenceHint => 'e.g., MPESA-123456';

  @override
  String get notes => 'Notes';

  @override
  String get notesHint => 'Any additional information...';

  @override
  String get uploadPaymentProof => 'Upload Payment Proof';

  @override
  String get tapToUpload => 'Tap to upload payment proof';

  @override
  String get paymentProofFormats => 'JPG, PNG, or PDF';

  @override
  String get paymentInstructions => 'Payment Instructions';

  @override
  String sendAmountTo(String amount) {
    return 'Send $amount to:';
  }

  @override
  String get account => 'Account';

  @override
  String get submitSubscription => 'Submit Subscription';

  @override
  String get subscriptionCreated => 'Subscription Created!';

  @override
  String get subscriptionCreatedMessage => 'Your subscription request was created successfully.';

  @override
  String get waitForApproval => 'Please wait for admin approval. You will be notified once your subscription is approved.';

  @override
  String get goToDashboard => 'Go to Dashboard';

  @override
  String get renewNow => 'Renew Now';

  @override
  String get subscribeNow => 'Subscribe Now';

  @override
  String get subscriptionExpired => 'Subscription Expired';

  @override
  String get subscriptionPending => 'Pending Approval';

  @override
  String get subscriptionActive => 'Active';

  @override
  String get subscriptionInactive => 'Inactive';

  @override
  String daysRemaining(int days) {
    return '$days days remaining';
  }

  @override
  String expiresOn(String date) {
    return 'Expires: $date';
  }

  @override
  String validUntil(String date) {
    return 'Valid until: $date';
  }

  @override
  String get noSubscriptions => 'No subscriptions yet';

  @override
  String get noInvoices => 'No invoices available';

  @override
  String invoiceNumber(String number) {
    return 'Invoice #$number';
  }

  @override
  String get invoiceStatus => 'Status';

  @override
  String get viewInvoice => 'View Invoice';

  @override
  String get downloadPdf => 'Download PDF';

  @override
  String get subscriptionHistory => 'Subscription History';

  @override
  String get paid => 'Paid';

  @override
  String get unpaid => 'Unpaid';

  @override
  String get yourSubscriptionHasExpired => 'Your subscription has expired. Please renew to continue.';

  @override
  String get subscriptionPendingApproval => 'Your subscription is pending approval. Please wait.';

  @override
  String get subscribeToUnlock => 'Subscribe to unlock all Fundi features.';

  @override
  String get rateCards => 'Rate Cards';

  @override
  String get subscriptionDetails => 'Subscription Details';

  @override
  String get invoiceDetails => 'Invoice Details';

  @override
  String get activePlan => 'Active Plan';

  @override
  String get amountPaid => 'Amount Paid';

  @override
  String get paymentMethod => 'Payment Method';

  @override
  String get paymentReferenceLabel => 'Payment Reference';

  @override
  String get approvedAt => 'Approved At';

  @override
  String get approvedBy => 'Approved By';

  @override
  String get adminNotes => 'Admin Notes';

  @override
  String get noNotifications => 'No Notifications';

  @override
  String get allCaughtUp => 'You\'re all caught up!';

  @override
  String get markAllRead => 'Mark All Read';

  @override
  String get loadingNotifications => 'Loading notifications...';

  @override
  String get viewAllNotifications => 'View All Notifications';

  @override
  String get notificationSettings => 'Notification Settings';

  @override
  String get invoices => 'Invoices';

  @override
  String get certificate => 'Certificate';

  @override
  String approvedOn(String date) {
    return 'Approved on $date';
  }

  @override
  String startedOn(String date) {
    return 'Started: $date';
  }

  @override
  String createdOn(String date) {
    return 'Created: $date';
  }

  @override
  String paidOn(String date) {
    return 'Paid: $date';
  }

  @override
  String dueOn(String date) {
    return 'Due: $date';
  }

  @override
  String subscriptionReference(String id) {
    return 'Subscription #$id';
  }

  @override
  String get plan => 'Plan';

  @override
  String get status => 'Status';

  @override
  String get download => 'Download';

  @override
  String get openPdf => 'Open PDF';

  @override
  String get typeArea => 'Type area';

  @override
  String get oops => 'Oops!';

  @override
  String get themeLabel => 'Theme';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get backToApp => 'Back to app';

  @override
  String get regBack => 'Back';

  @override
  String get regContinue => 'Continue';

  @override
  String regStepOf(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get regCreateAccountTitle => 'Create your account';

  @override
  String get regCreateAccountSubtitle => 'We\'ll send a code to your phone to verify it.';

  @override
  String get regFullName => 'Full name';

  @override
  String get regPhoneHint => 'Phone number';

  @override
  String get regEmailOptional => 'Email (optional)';

  @override
  String get regPasswordHint => 'Password (min 8 characters)';

  @override
  String get regConfirmPasswordHint => 'Confirm password';

  @override
  String get regPhotoOptional => 'Photo (optional)';

  @override
  String get regChooseGallery => 'Choose from gallery';

  @override
  String get regTakePhoto => 'Take a photo';

  @override
  String get regRemovePhoto => 'Remove photo';

  @override
  String get regSearchCountry => 'Search country...';

  @override
  String get regNoCountryFound => 'No country found';

  @override
  String get regNameRequired => 'Name is required';

  @override
  String get regPhoneRequired => 'Phone is required';

  @override
  String get regPhoneInvalidTz => 'Enter a valid Tanzanian number (e.g. 0682 131 178)';

  @override
  String get regPhoneInvalid => 'Enter a valid phone number';

  @override
  String get regEmailInvalid => 'Enter a valid email';

  @override
  String get regPasswordMin => 'At least 8 characters';

  @override
  String get regPasswordMismatch => 'Passwords do not match';

  @override
  String get regIdentityTitle => 'Verify your identity';

  @override
  String get regIdentitySubtitle => 'Used only by our team to approve your account.';

  @override
  String get regIdNida => 'NIDA';

  @override
  String get regIdLicense => 'Driver\'s license';

  @override
  String get regIdVoter => 'Voter\'s ID (KURA)';

  @override
  String get regNidaHint => 'NIDA number (20 digits)';

  @override
  String get regVoterHint => 'Voter ID (12 digits)';

  @override
  String get regLicenseHint => 'License number (min 10 digits)';

  @override
  String get regEnterId => 'Enter the ID number';

  @override
  String get regNidaLen => 'NIDA must be exactly 20 digits';

  @override
  String get regVoterLen => 'Voter ID must be exactly 12 digits';

  @override
  String get regLicenseLen => 'License must be at least 10 digits';

  @override
  String get regAddIdPhoto => 'Tap to add a photo of your ID (optional)';

  @override
  String get regFingerprintTitle => 'Ink fingerprint';

  @override
  String get regFingerprintHeadIdle => 'Place your finger';

  @override
  String get regFingerprintHeadDone => 'Fingerprint captured';

  @override
  String get regFingerprintDescIdle => 'Touch and press the area below to stamp your ink print.';

  @override
  String get regFingerprintDescDone => 'Your ink print was captured. Tap the button below to continue.';

  @override
  String get regFingerprintChipIdle => 'Tap here';

  @override
  String get regFingerprintChipDone => 'Ready';

  @override
  String get regFingerprintStamp => 'Tap to stamp';

  @override
  String get regFingerprintScanning => 'Capturing…';

  @override
  String get regFingerprintSubmit => 'Submit & continue';

  @override
  String get regFingerprintRetry => 'Try again';

  @override
  String get regFingerprintSaveFailed => 'Could not save the fingerprint.';

  @override
  String get regFaceTitle => 'Face capture';

  @override
  String get regFaceOpening => 'Opening camera…';

  @override
  String get regFacePosition => 'Position your face in the frame';

  @override
  String get regFaceNone => 'No face detected';

  @override
  String get regFaceCloser => 'Move closer';

  @override
  String get regFaceFarther => 'Move back a little';

  @override
  String get regFaceHold => 'Hold still…';

  @override
  String get regFaceConfirmPhoto => 'Confirm your photo';

  @override
  String get regFaceSaving => 'Saving…';

  @override
  String get regFaceUnavailable => 'Camera unavailable';

  @override
  String get regFaceNoCamera => 'No camera available on this device.';

  @override
  String regFaceOpenFailed(String error) {
    return 'Could not open the camera: $error';
  }

  @override
  String regFaceCaptureFailed(String error) {
    return 'Could not capture the photo: $error';
  }

  @override
  String get regFaceSaveFailed => 'Could not save the face capture.';

  @override
  String regFaceSubmitFailed(String error) {
    return 'Submission failed: $error';
  }

  @override
  String regFaceFallbackFailed(String error) {
    return 'Camera fallback failed: $error';
  }

  @override
  String get regFaceCapturing => 'Capturing…';

  @override
  String get regFaceCaptureNow => 'Capture now';

  @override
  String get regFaceRetake => 'Retake';

  @override
  String get regFaceConfirm => 'Confirm';

  @override
  String get regFaceSystemCamera => 'Use system camera';

  @override
  String get regKinTitle => 'Emergency contact';

  @override
  String get regKinSubtitle => 'Who should we contact in an emergency?';

  @override
  String get regKinRelationship => 'Relationship (e.g. Spouse, Parent, Sibling)';

  @override
  String get regKinRelationRequired => 'Relationship is required';

  @override
  String get regReviewTitle => 'Review & Submit';

  @override
  String get regReviewHeading => 'Please review your registration details';

  @override
  String get regCompletedSteps => 'Completed steps';

  @override
  String get regAccountCreated => 'Account created';

  @override
  String get regIdentityVerified => 'Identity saved';

  @override
  String get regFingerprintEnrolled => 'Fingerprint captured';

  @override
  String get regFaceEnrolled => 'Face captured';

  @override
  String get regKinSaved => 'Emergency contact saved';

  @override
  String get regRelationship => 'Relationship';

  @override
  String get regSubmit => 'Submit registration';

  @override
  String get regBackToStep5 => 'Back to step 5';

  @override
  String get regSubmittedTitle => 'Registration submitted!';

  @override
  String get regSubmittedBody => 'Your account is pending admin verification. You\'ll receive an SMS once approved.';

  @override
  String get regSubmitFailed => 'Submission failed. Please try again.';

  @override
  String get regSessionExpired => 'Registration session expired. Please start over.';

  @override
  String get jobs => 'Jobs';

  @override
  String get tickets => 'Tickets';

  @override
  String get downloads => 'Downloads';

  @override
  String get subscription => 'Subscription';

  @override
  String get viewAll => 'View All';

  @override
  String get viewAllShort => 'View all';

  @override
  String get latestRequests => 'Latest Requests';

  @override
  String get activeJobs => 'Active Jobs';

  @override
  String get openTickets => 'Open Tickets';

  @override
  String get noActiveJobs => 'No active jobs';

  @override
  String get noOpenTickets => 'No open tickets';

  @override
  String get noJobsFound => 'No jobs found';

  @override
  String get noTicketsFound => 'No tickets found';

  @override
  String get searchJobsHint => 'Search job number, customer, service...';

  @override
  String get searchTicketsHint => 'Search ticket, job, customer, service...';

  @override
  String get subscriptionComingSoonTitle => 'Subscription';

  @override
  String get subscriptionComingSoonBody => 'Premium version — Coming soon 🚀\nUnlock more features and grow your business.';

  @override
  String get pendingStatus => 'PENDING';

  @override
  String get onProgressStatus => 'ON PROGRESS';

  @override
  String get completedStatus => 'COMPLETED';

  @override
  String get jobDetails => 'Job Details';

  @override
  String get ticketDetails => 'Ticket Details';

  @override
  String get noTicket => 'No ticket';

  @override
  String ticketsCount(int count) {
    return 'Tickets ($count)';
  }

  @override
  String get noTicketsForJob => 'No tickets for this job';

  @override
  String get downloadTicket => 'Download Ticket';

  @override
  String downloadingTicket(String number) {
    return 'Downloading ticket $number...';
  }

  @override
  String get jobNumber => 'Job number';

  @override
  String get ticketNumber => 'Ticket number';

  @override
  String get title => 'Title';

  @override
  String get category => 'Category';

  @override
  String get requestDescription => 'Request description';

  @override
  String get started => 'Started';

  @override
  String get completedLabel => 'Completed';

  @override
  String get jobStatus => 'Job status';

  @override
  String get ticketStatus => 'Ticket status';

  @override
  String get created => 'Created';

  @override
  String get areYouSureDeleteMessage => 'Are you sure you want to delete this message?';

  @override
  String get filterOnProgress => 'On progress';

  @override
  String get filterCompleted => 'Completed';

  @override
  String get payments => 'Payments';

  @override
  String get myPortfolio => 'My Portfolio';

  @override
  String get noPostsYet => 'No Posts Yet';

  @override
  String get uploadPhotosToShowcase => 'Upload photos of your work to showcase your skills.';

  @override
  String get newPortfolioPost => 'New Portfolio Post';

  @override
  String get tapToSelectImages => 'Tap to select images';

  @override
  String get addMoreImages => 'Add more images';

  @override
  String get post => 'Post';

  @override
  String get deletePostTitle => 'Delete Post?';

  @override
  String get deletePostConfirmation => 'Are you sure you want to remove this entire post?';

  @override
  String get editImages => 'Edit Images';

  @override
  String get myBalance => 'My Balance';

  @override
  String get earnings => 'Earnings';

  @override
  String get reports => 'Reports';

  @override
  String get recentJobs => 'Recent Jobs';

  @override
  String get recentTickets => 'Recent Tickets';

  @override
  String get noJobsYet => 'No jobs yet';

  @override
  String get noTicketsYet => 'No tickets yet';

  @override
  String get comingSoonTitle => 'Coming Soon';

  @override
  String get comingSoonBody => 'This feature is coming soon 🚀\nStay tuned for updates.';

  @override
  String get goodMorning => 'Good morning';

  @override
  String get goodAfternoon => 'Good afternoon';

  @override
  String get goodEvening => 'Good evening';

  @override
  String pendingCount(int count) {
    return '$count Pending';
  }

  @override
  String get acceptedStatus => 'ACCEPTED';

  @override
  String get rejectedStatus => 'REJECTED';

  @override
  String get cancelledStatus => 'CANCELLED';
}
