// lib/config/app_routes.dart

class AppRoutes {
  AppRoutes._();

  // ===== AUTH ROUTES =====
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String otp = '/otp';
  static const String forgot = '/forgot-password';
  static const String reset = '/reset-password';

  // ===== REGISTRATION FLOW =====
  static const String registerStep1 = '/register-step1';
  static const String registerOtp = '/register/otp';
  static const String registerServices = '/register-services';
  static const String registerLocation = '/register-location';
  static const String registerStep2 = '/register-step2';
  static const String registerStep3 = '/register-step3';
  static const String registerStep4 = '/register-step4';
  static const String registerStep5 = '/register-step5';
  static const String registerReview = '/register-review';

  // ===== FUNDI MAIN SCREENS =====
  static const String home = '/home';
  static const String posts = '/posts';
  static const String blog = posts;
  static const String createPost = '/create-post';
  static const String editPost = '/edit-post';
  static const String portfolio = '/portfolio';
  static const String addPortfolio = '/add-portfolio';
  static const String editPortfolio = '/edit-portfolio';
  static const String requests = '/requests';
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';
  static const String manageServices = '/manage-services';
  static const String settings = '/settings';
  static const String notifications = '/notifications';

  // ===== TICKETS & JOBS =====
  static const String tickets = '/tickets';
  static const String jobs = '/jobs';

  // ===== EARNINGS & REPORTS =====
  static const String earnings = '/earnings';
  static const String reports = '/reports';

  // ===== CHAT ROUTES =====
  static const String chatList = '/chat-list';
  static const String chat = '/chat';
  static const String voiceCall = '/voice-call';
  static const String videoCall = '/video-call';

  // ===== STATIC PAGES =====
  static const String about = '/about';
  static const String terms = '/terms';
  static const String faq = '/faq';
  static const String contactUs = '/contact-us';
  static const String privacy = '/privacy';

  // ===== SUBSCRIPTION ROUTES =====
  static const String subscriptions = '/subscriptions';
  static const String rateCards = '/rate-cards';
  static const String createSubscription = '/create-subscription';
  static const String subscriptionDetails = '/subscription-details';
  static const String invoiceDetails = '/invoice-details';
  static const String paymentMethods = '/payment-methods';

  // ===== PAYMENTS & DOWNLOADS =====
  static const String payment = '/payment';
  static const String downloads = '/downloads';

  // ===== NAVIGATION HELPERS =====
  static String getChatRoute(int conversationId) => '/chat/$conversationId';
  static String getEditPostRoute(int postId) => '/edit-post/$postId';
  static String getEditPortfolioRoute(int itemId) => '/edit-portfolio/$itemId';
  static String getOtpRoute(String email) => '/otp?email=$email';
  static String getResetRoute(String email) => '/reset-password?email=$email';

  static String registrationRouteForStep(int step) => switch (step) {
    1 => registerStep1,
    2 => registerStep2,
    3 => registerStep3,
    4 => registerStep4,
    5 => registerStep5,
    _ => registerReview,
  };

  // ===== ROUTE DISPLAY NAMES =====
  static const Map<String, String> routeNames = {
    splash: 'Splash Screen',
    onboarding: 'Onboarding',
    login: 'Login',
    register: 'Register',
    otp: 'OTP Verification',
    forgot: 'Forgot Password',
    reset: 'Reset Password',
    registerStep1: 'Register – Step 1 (Account)',
    registerServices: 'Register – Services',
    registerLocation: 'Register – Location',
    registerStep2: 'Register – Step 2 (Identity)',
    registerStep3: 'Register – Step 3 (Fingerprint)',
    registerStep4: 'Register – Step 4 (Face)',
    registerStep5: 'Register – Step 5 (Emergency Contact)',
    registerReview: 'Register – Review & Submit',
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
    manageServices: 'Manage Services',
    settings: 'Settings',
    notifications: 'Notifications',
    tickets: 'Tickets',
    jobs: 'Jobs',
    earnings: 'Earnings',
    reports: 'Reports',
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
    payment: 'Payment',
    downloads: 'Downloads',
  };
}