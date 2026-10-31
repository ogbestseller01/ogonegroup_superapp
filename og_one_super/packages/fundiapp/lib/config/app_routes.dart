// lib/config/app_routes.dart

class AppRoutes {
  AppRoutes._();

  // ===== AUTH ROUTES =====
  static const String splash    = '/';
  static const String onboarding = '/onboarding';
  static const String login     = '/login';
  static const String register  = '/register';
  static const String otp       = '/otp';
  static const String forgot    = '/forgot-password';
  static const String reset     = '/reset-password';

  // ===== FUNDI MAIN SCREENS =====
  static const String home          = '/home';
  static const String posts         = '/posts';
  static const String createPost    = '/create-post';
  static const String editPost      = '/edit-post';
  static const String portfolio     = '/portfolio';
  static const String addPortfolio  = '/add-portfolio';
  static const String editPortfolio = '/edit-portfolio';
  static const String requests      = '/requests';
  static const String profile       = '/profile';
  static const String editProfile   = '/edit-profile';
  static const String settings      = '/settings';
  static const String notifications = '/notifications';
  static const String registerServices = '/register-services';
  static const String registerLocation = '/register-location';

  // ===== CHAT ROUTES =====
  static const String chatList  = '/chat-list';
  static const String chat      = '/chat';
  static const String voiceCall = '/voice-call';
  static const String videoCall = '/video-call';

  // ===== BLOG/POSTS (alias) =====
  static const String blog = '/posts';

  // ===== STATIC PAGES =====
  static const String about     = '/about';
  static const String terms     = '/terms';
  static const String faq       = '/faq';
  static const String contactUs = '/contact-us';
  static const String privacy   = '/privacy';

  // ===== SUBSCRIPTION ROUTES =====
  static const String subscriptions       = '/subscriptions';
  static const String rateCards           = '/rate-cards';
  static const String createSubscription  = '/create-subscription';
  static const String subscriptionDetails = '/subscription-details';
  static const String invoiceDetails      = '/invoice-details';
  static const String paymentMethods      = '/payment-methods';

  // ===== DOWNLOADS =====
  static const String downloads = '/downloads';

  // ===== 6-STEP FUNDI REGISTRATION =====
  static const String registerStep1  = '/register-step1';
  static const String registerStep2  = '/register-step2';
  static const String registerStep3  = '/register-step3';
  static const String registerStep4  = '/register-step4';
  static const String registerStep5  = '/register-step5';
  static const String registerReview = '/register-review';

  // ===== NAVIGATION HELPERS =====
  static String getChatRoute(int conversationId) => '/chat/$conversationId';
  static String getEditPostRoute(int postId) => '/edit-post/$postId';
  static String getEditPortfolioRoute(int itemId) => '/edit-portfolio/$itemId';
  static String getOtpRoute(String email) => '/otp?email=$email';
  static String getResetRoute(String email) => '/reset-password?email=$email';

  /// Maps the last completed step to the next screen.
  ///
  ///  step  0 / null  →  registerStep1  (nothing started)
  ///        1         →  registerStep2  (account created + OTP verified)
  ///        2         →  registerStep3  (identity verified)
  ///        3         →  registerStep4  (fingerprint enrolled)
  ///        4         →  registerStep5  (face enrolled)
  ///        5+        →  registerReview (emergency contact saved)
  static String registrationRouteForStep(int step) {
    if (step < 1) return registerStep1;
    if (step < 2) return registerStep2;
    if (step < 3) return registerStep3;
    if (step < 4) return registerStep4;
    if (step < 5) return registerStep5;
    return registerReview;
  }

  // ===== ROUTE MAP FOR REFERENCE =====
  static const Map<String, String> routeNames = {
    splash: 'Splash Screen',
    onboarding: 'Onboarding',
    login: 'Login',
    register: 'Register',
    otp: 'OTP Verification',
    forgot: 'Forgot Password',
    reset: 'Reset Password',

    home: 'Home Dashboard',
    posts: 'My Posts',
    createPost: 'Create Post',
    editPost: 'Edit Post',
    portfolio: 'Portfolio',
    addPortfolio: 'Add Portfolio Item',
    editPortfolio: 'Edit Portfolio Item',
    requests: 'Requests',
    profile: 'Profile',
    editProfile: 'Edit Profile',
    settings: 'Settings',
    notifications: 'Notifications',

    chatList: 'Chat List',
    chat: 'Chat',
    voiceCall: 'Voice Call',
    videoCall: 'Video Call',

    about: 'About Us',
    terms: 'Terms & Conditions',
    faq: 'FAQ',
    contactUs: 'Contact Us',
    privacy: 'Privacy Policy',

    subscriptions: 'My Subscriptions',
    rateCards: 'Rate Cards',
    createSubscription: 'Create Subscription',
    subscriptionDetails: 'Subscription Details',
    invoiceDetails: 'Invoice Details',
    paymentMethods: 'Payment Methods',
    downloads: 'Downloads',

    registerStep1: 'Register – Step 1 (Account)',
    registerStep2: 'Register – Step 2 (Identity)',
    registerStep3: 'Register – Step 3 (Fingerprint)',
    registerStep4: 'Register – Step 4 (Face)',
    registerStep5: 'Register – Step 5 (Emergency Contact)',
    registerReview: 'Register – Review & Submit',
  };
}