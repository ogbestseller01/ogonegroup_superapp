// config/app_routes.dart

class AppRoutes {
  AppRoutes._();

  // Auth / onboarding
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String otp = '/otp';
  static const String forgot = '/forgot-password';
  static const String reset = '/reset-password';

  // Main
  static const String home = '/home';
  static const String technicianDetail = '/technician-detail';
  static const String postDetail = '/post-detail';
  static const String myRequests = '/my-requests';
  static const String tracking = '/tracking';

  // Jobs & tickets
  static const String jobs = '/jobs';
  static const String tickets = '/tickets';
  static const String jobDetail = '/job-detail';       // NEW
  static const String ticketDetail = '/ticket-detail'; // NEW

  // Chat.
  static const String chatList = '/chat-list';
  static const String chatScreen = '/chat-screen';
  static const String chat = chatScreen;

  // Notifications
  static const String notifications = '/notifications';

  // Profile & settings
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';
  static const String settings = '/settings';

  // Static pages
  static const String about = '/about';
  static const String terms = '/terms';
  static const String faq = '/faq';
  static const String contactUs = '/contact-us';
  static const String privacyPolicy = '/privacy-policy';
}