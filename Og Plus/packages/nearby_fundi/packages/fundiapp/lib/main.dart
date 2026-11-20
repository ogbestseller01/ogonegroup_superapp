import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:fundiapp_sdk/payments/chanel/mock_channel.dart';
import 'package:fundiapp_sdk/screens/chat/chat_list_screen.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

// ── Core ─────────────────────────────────────────────────────
import 'app_navigator.dart';
import 'config/app_routes.dart';
import 'config/app_theme.dart';
import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'models/chat_conversation.dart';

// ── Providers ────────────────────────────────────────────────
import 'providers/auth_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/job_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/portfolio_provider.dart';
import 'providers/post_provider.dart';
import 'providers/request_provider.dart';
import 'providers/service_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/static_page_provider.dart';
import 'providers/subscription_provider.dart';
import 'providers/technician_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/ticket_provider.dart';

// ── Payments ─────────────────────────────────────────────────
import 'payments/provider/payment_provider.dart';
import 'payments/screens/payment_screen.dart';

// ── Services ─────────────────────────────────────────────────
import 'services/app_security_middleware.dart';
import 'services/fcm_service.dart';
import 'services/security_service.dart';

// ── Screens ──────────────────────────────────────────────────
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/otp_verification_screen.dart';
import 'screens/auth/register_flow/register_location_screen.dart';
import 'screens/auth/register_flow/register_review_screen.dart';
import 'screens/auth/register_flow/register_services_screen.dart';
import 'screens/auth/register_flow/register_step1_screen.dart';
import 'screens/auth/register_flow/register_step2_screen.dart';
import 'screens/auth/register_flow/register_step3_screen.dart';
import 'screens/auth/register_flow/register_step4_screen.dart';
import 'screens/auth/register_flow/register_step5_screen.dart';
import 'screens/auth/reset_password_screen.dart';
import 'screens/chat/fundi_chat_screen.dart';
import 'screens/fundi/fundi_home_screen.dart';
import 'screens/fundi/fundi_portfolio_screen.dart';
import 'screens/fundi/fundi_posts_screen.dart';
import 'screens/fundi/fundi_requests_screen.dart';
import 'screens/fundi/profile/edit_profile_screen.dart';
import 'screens/fundi/profile/fundi_profile_screen.dart';
import 'screens/fundi/profile/fundi_settings_screen.dart';
import 'screens/jobs/jobs_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/static/about_screen.dart';
import 'screens/static/contact_us_screen.dart';
import 'screens/static/faq_screen.dart';
import 'screens/static/privacy_policy_screen.dart';
import 'screens/static/terms_screen.dart';
import 'screens/tickets/tickets_screen.dart';

const SystemUiOverlayStyle _kSystemUiOverlayStyle = SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarIconBrightness: Brightness.dark,
  systemNavigationBarColor: Colors.transparent,
  systemNavigationBarIconBrightness: Brightness.light,
);

// ============================================================
//  FCM BACKGROUND HANDLER (must be top-level + vm:entry-point)
// ============================================================

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
}

// ============================================================
//  MAIN
// ============================================================

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = FlutterError.presentError;
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) => true;

  // 0/5 Security middleware
  try {
    await AppSecurityMiddleware.initialize();
  } catch (_) {
    try {
      await SystemChannels.platform.invokeMethod('SystemNavigator.pop');
    } catch (_) {}
    return;
  }

  // 1/5 Firebase
  if (Firebase.apps.isEmpty) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (_) {}
  }
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // 2/5 Secure screen
  try {
    await SecurityService.enableSecureScreen();
  } catch (_) {}

  // 3/5 System UI
  try {
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setSystemUIOverlayStyle(_kSystemUiOverlayStyle);
  } catch (_) {}

  // 4/5 Eager AuthProvider for mini-app & FCM hooks
  final authProvider = AuthProvider(navigatorKey: navigatorKey);
  ProviderRegistry.registerAuthProvider(authProvider);

  // 5/5 Run app
  runApp(
    MultiProvider(
      providers: fundiAppProviders(authProvider: authProvider),
      child: const MyApp(),
    ),
  );

  // Background FCM setup after first frame
  unawaited(FcmService.init().catchError((_) {}));
}

/// Shared provider list so both standalone [MyApp] and host mini-apps
/// mount every required provider above Fundi routes.
List<SingleChildWidget> fundiAppProviders({AuthProvider? authProvider}) {
  final resolvedAuth = authProvider ?? AuthProvider(navigatorKey: navigatorKey);
  return [
    ChangeNotifierProvider<AuthProvider>.value(value: resolvedAuth),
    ChangeNotifierProvider(create: (_) => PostProvider()),
    ChangeNotifierProvider(create: (_) => RequestProvider()),
    ChangeNotifierProvider(create: (_) => PortfolioProvider()),
    ChangeNotifierProvider(create: (_) => TechnicianProvider()),
    ChangeNotifierProvider(create: (_) => ServiceProvider()),
    ChangeNotifierProvider(create: (_) => NotificationProvider()),
    ChangeNotifierProvider(create: (_) => SettingsProvider()),
    ChangeNotifierProvider(create: (_) => StaticPageProvider()),
    ChangeNotifierProvider(create: (_) => ThemeProvider()),
    ChangeNotifierProvider(create: (_) => ChatProvider()),
    ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
    ChangeNotifierProvider(create: (_) => TicketProvider()),
    ChangeNotifierProvider(create: (_) => JobProvider()),
    ChangeNotifierProvider(
      create: (_) => PaymentProvider(channel: MockPaymentChannel()),
    ),
  ];
}

// ============================================================
//  ROOT WIDGET
// ============================================================

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, SettingsProvider>(
      builder: (context, themeProvider, settings, _) {
        return MaterialApp(
          title: 'NETSAF FUNDI APP',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          navigatorKey: navigatorKey,
          locale: settings.currentLocale,
          supportedLocales: const [
            Locale('en'),
            Locale('sw'),
          ],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          initialRoute: AppRoutes.splash,
          onGenerateRoute: generateFundiAppRoute,
          builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
            value: _kSystemUiOverlayStyle,
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}

// ============================================================
//  ROUTING (exported for use by FundiAppMiniApp)
// ============================================================

Route<dynamic> generateFundiAppRoute(RouteSettings settings) {
  final Object? args = settings.arguments;

  MaterialPageRoute<dynamic> route(Widget page) => MaterialPageRoute(
    builder: (_) => page,
    settings: settings,
  );

  switch (settings.name) {
  // Entry
    case AppRoutes.splash:
      return route(const SplashScreen());
    case AppRoutes.onboarding:
      return route(const OnboardingScreen());
    case AppRoutes.login:
      return route(const LoginScreen());

  // Registration flow
    case AppRoutes.registerStep1:
      return route(RegisterStep1Screen(initialData: _mapOrNull(args)));
    case AppRoutes.registerServices:
      final mapArgs = _mapOrNull(args);
      return mapArgs != null
          ? route(RegisterServicesScreen(args: mapArgs))
          : route(const RegisterStep1Screen());
    case AppRoutes.registerLocation:
      final mapArgs = _mapOrNull(args);
      return mapArgs != null
          ? route(RegisterLocationScreen(args: mapArgs))
          : route(const RegisterStep1Screen());
    case AppRoutes.registerStep2:
      return route(RegisterStep2Screen(draftId: _getDraftArgument(args)));
    case AppRoutes.registerStep3:
      return route(RegisterStep3Screen(draftId: _getDraftArgument(args)));
    case AppRoutes.registerStep4:
      return route(RegisterStep4Screen(draftId: _getDraftArgument(args)));
    case AppRoutes.registerStep5:
      return route(RegisterStep5Screen(draftId: _getDraftArgument(args)));
    case AppRoutes.registerReview:
      final mapArgs = _mapOrNull(args);
      if (mapArgs != null) {
        final id = _getDraftArgument(mapArgs);
        return id > 0
            ? route(RegisterReviewScreen(draftId: id, extra: mapArgs))
            : route(const RegisterStep1Screen());
      }
      if (args is int && args > 0) {
        return route(RegisterReviewScreen(draftId: args));
      }
      return route(const RegisterStep1Screen());

  // Auth & OTP
    case AppRoutes.otp:
      final mapArgs = _mapOrNull(args);
      if (mapArgs != null) {
        final identifier = (mapArgs['identifier'] ??
            mapArgs['phone'] ??
            mapArgs['email'] ??
            '')
            .toString();
        return route(
          OtpVerificationScreen(
            identifier: identifier,
            email: mapArgs['email']?.toString(),
            phone: mapArgs['phone']?.toString(),
            redirectToStep2: mapArgs['redirectToStep2'] == true,
            draftId: _nullableInt(mapArgs['draftId'] ?? mapArgs['technicianId']),
          ),
        );
      }
      return route(OtpVerificationScreen(identifier: args?.toString() ?? ''));
    case AppRoutes.forgot:
      return route(const ForgotPasswordScreen());
    case AppRoutes.reset:
      return route(ResetPasswordScreen(email: args?.toString() ?? ''));

  // Main Fundi screens
    case AppRoutes.home:
    case AppRoutes.notifications:
      return route(const FundiHomeScreen());
    case AppRoutes.posts:
    case AppRoutes.blog:
    case AppRoutes.createPost:
    case AppRoutes.editPost:
      return route(const FundiPostsScreen());
    case AppRoutes.portfolio:
    case AppRoutes.addPortfolio:
    case AppRoutes.editPortfolio:
      return route(const FundiPortfolioScreen());
    case AppRoutes.requests:
      return route(const FundiRequestsScreen());
    case AppRoutes.profile:
      return route(const FundiProfileScreen());
    case AppRoutes.editProfile:
      return route(const EditProfileScreen());
    case AppRoutes.settings:
      return route(const FundiSettingsScreen());

  // Tickets & Jobs
    case AppRoutes.tickets:
      return route(const TicketsScreen());
    case AppRoutes.jobs:
      return route(const JobsScreen());

  // Chat
    case AppRoutes.chatList:
      return route(const FundiChatListScreen());
    case AppRoutes.chat:
      return args is ChatConversation
          ? route(FundiChatScreen(conversation: args))
          : route(const FundiChatListScreen());

  // Payment
    case AppRoutes.payment:
      final mapArgs = _mapOrNull(args);
      if (mapArgs != null) {
        return route(
          PaymentScreen(
            reference: mapArgs['reference']?.toString() ?? 'UNKNOWN',
            requestsCount: _nullableInt(mapArgs['requestsCount']),
            customerPhone: mapArgs['customerPhone']?.toString(),
          ),
        );
      }
      return route(const SplashScreen());

  // Static pages
    case AppRoutes.about:
      return route(const AboutScreen());
    case AppRoutes.terms:
      return route(const TermsScreen());
    case AppRoutes.faq:
      return route(const FaqScreen());
    case AppRoutes.contactUs:
      return route(const ContactUsScreen());
    case AppRoutes.privacy:
      return route(const PrivacyPolicyScreen());

    default:
      return route(const SplashScreen());
  }
}

// ============================================================
//  ROUTE ARG HELPERS
// ============================================================

Map<String, dynamic>? _mapOrNull(Object? args) {
  if (args is Map<String, dynamic> && args.isNotEmpty) return args;
  return null;
}

int _getDraftArgument(Object? args) {
  if (args is int) return args;
  if (args is String) return int.tryParse(args) ?? 0;
  if (args is num) return args.toInt();
  final mapArgs = _mapOrNull(args);
  if (mapArgs != null) {
    final value = mapArgs['draftId'] ?? mapArgs['technicianId'] ?? mapArgs['id'];
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is num) return value.toInt();
  }
  return 0;
}

int? _nullableInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

// ============================================================
//  PROVIDER REGISTRY (legacy access point)
// ============================================================

class ProviderRegistry {
  ProviderRegistry._();

  static AuthProvider? _authProvider;

  static void registerAuthProvider(AuthProvider provider) {
    _authProvider = provider;
  }

  static AuthProvider? get authProvider => _authProvider;
}