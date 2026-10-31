// lib/main.dart
// ============================================================
//  FundiApp SDK — root entry point.
// ============================================================

import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

// ── Local: core ──────────────────────────────────────────────
import 'app_navigator.dart';
import 'config/app_routes.dart';
import 'config/app_theme.dart';
import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'models/chat_conversation.dart';

// ── Local: providers ─────────────────────────────────────────
import 'providers/auth_provider.dart';
import 'providers/chat_provider.dart';
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

// ── Local: services ──────────────────────────────────────────
import 'services/fcm_service.dart';
import 'services/security_service.dart';

// ── Local: screens ───────────────────────────────────────────
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
import 'screens/chat/chat_list_screen.dart';
import 'screens/chat/chat_screen.dart';
import 'screens/chat/video_call_screen.dart';
import 'screens/chat/voice_call_screen.dart';
import 'screens/fundi/fundi_home_screen.dart';
import 'screens/fundi/fundi_portfolio_screen.dart';
import 'screens/fundi/fundi_posts_screen.dart';
import 'screens/fundi/fundi_requests_screen.dart';
import 'screens/fundi/profile/edit_profile_screen.dart';
import 'screens/fundi/profile/fundi_profile_screen.dart';
import 'screens/fundi/profile/fundi_settings_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/static/about_screen.dart';
import 'screens/static/contact_us_screen.dart';
import 'screens/static/faq_screen.dart';
import 'screens/static/privacy_policy_screen.dart';
import 'screens/static/terms_screen.dart';
import 'screens/subscription/downloads_screen.dart';
import 'screens/subscription/my_subscriptions_screen.dart';
import 'screens/subscription/payment_methods_screen.dart';
import 'screens/subscription/rate_cards_screen.dart';

// ============================================================
//  FCM BACKGROUND HANDLER  (must be top-level + vm:entry-point)
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

  // ── Global error hooks ────────────────────────────────────
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    return true;
  };

  // ── 1/5  Firebase ─────────────────────────────────────────
  if (Firebase.apps.isEmpty) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (_) {}
  }

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // ── 2/5  Secure screen ────────────────────────────────────
  try {
    await SecurityService.enableSecureScreen();
  } catch (_) {}

  // ── 3/5  System UI ────────────────────────────────────────
  try {
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  } catch (_) {}

  // ── 4/5  AuthProvider (eager — mini-app + FCM need it) ────
  final authProvider = AuthProvider(navigatorKey: navigatorKey);
  ProviderRegistry.registerAuthProvider(authProvider);

  // ── 5/5  runApp ───────────────────────────────────────────
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
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
      ],
      child: const MyApp(),
    ),
  );

  // ── FCM (background, so the splash shows immediately) ─────
  unawaited(() async {
    try {
      await FcmService.init();
    } catch (_) {}
  }());
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
          builder: (context, child) {
            return AnnotatedRegion<SystemUiOverlayStyle>(
              value: const SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.dark,
                systemNavigationBarColor: Colors.transparent,
                systemNavigationBarIconBrightness: Brightness.light,
              ),
              child: child ?? const SizedBox.shrink(),
            );
          },
        );
      },
    );
  }
}

// ============================================================
//  ROUTING  (exported for use by FundiAppMiniApp)
// ============================================================

Route<dynamic> generateFundiAppRoute(RouteSettings settings) {
  final Object? args = settings.arguments;

  MaterialPageRoute<dynamic> route(Widget page) => MaterialPageRoute(
    builder: (_) => page,
    settings: settings,
  );

  switch (settings.name) {
  // ── Entry screens ─────────────────────────────────────
    case AppRoutes.splash:
      return route(const SplashScreen());
    case AppRoutes.onboarding:
      return route(const OnboardingScreen());
    case AppRoutes.login:
      return route(const LoginScreen());

  // ── Registration flow ─────────────────────────────────

  // Account: photo + name + phone + email + password
    case AppRoutes.registerStep1:
      return route(RegisterStep1Screen(
        initialData:
        args is Map<String, dynamic> && args.isNotEmpty ? args : null,
      ));

  // Services: fundi picks what they offer
    case AppRoutes.registerServices:
      if (args is Map<String, dynamic> && args.isNotEmpty) {
        return route(RegisterServicesScreen(args: args));
      }
      return route(const RegisterStep1Screen());

  // Location: area + lat/lng → triggers POST /register/step1
    case AppRoutes.registerLocation:
      if (args is Map<String, dynamic> && args.isNotEmpty) {
        return route(RegisterLocationScreen(args: args));
      }
      return route(const RegisterStep1Screen());

  // Identity: NIDA + ID photo
    case AppRoutes.registerStep2:
      return route(RegisterStep2Screen(
        draftId: _getDraftArgument(args),
      ));

  // Fingerprint
    case AppRoutes.registerStep3:
      return route(RegisterStep3Screen(
        draftId: _getDraftArgument(args),
      ));

  // Face
    case AppRoutes.registerStep4:
      return route(RegisterStep4Screen(
        draftId: _getDraftArgument(args),
      ));

  // Emergency contact
    case AppRoutes.registerStep5:
      return route(RegisterStep5Screen(
        draftId: _getDraftArgument(args),
      ));

  // Review & submit
    case AppRoutes.registerReview:
      if (args is Map<String, dynamic>) {
        final id = _getDraftArgument(args);
        if (id <= 0) return route(const RegisterStep1Screen());
        return route(RegisterReviewScreen(draftId: id, extra: args));
      }
      if (args is int && args > 0) {
        return route(RegisterReviewScreen(draftId: args));
      }
      return route(const RegisterStep1Screen());

  // ── OTP ───────────────────────────────────────────────
    case AppRoutes.otp:
      if (args is Map<String, dynamic>) {
        final identifier = (args['identifier'] ??
            args['phone'] ??
            args['email'] ??
            '')
            .toString();
        return route(OtpVerificationScreen(
          identifier: identifier,
          email: args['email']?.toString(),
          phone: args['phone']?.toString(),
          redirectToStep2: args['redirectToStep2'] == true,
          // ✅ Fallback to technicianId in case Step 1 used the legacy key
          draftId: _nullableInt(args['draftId'] ?? args['technicianId']),
        ));
      }
      return route(OtpVerificationScreen(
        identifier: args?.toString() ?? '',
      ));

    case AppRoutes.forgot:
      return route(const ForgotPasswordScreen());
    case AppRoutes.reset:
      return route(ResetPasswordScreen(email: args?.toString() ?? ''));

  // ── Main fundi screens ────────────────────────────────
    case AppRoutes.home:
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
    case AppRoutes.notifications:
      return route(const FundiHomeScreen());
    case AppRoutes.profile:
      return route(const FundiProfileScreen());
    case AppRoutes.editProfile:
      return route(const EditProfileScreen());
    case AppRoutes.settings:
      return route(const FundiSettingsScreen());

  // ── Chat / calls ──────────────────────────────────────
    case AppRoutes.chatList:
      return route(const ChatListScreen());
    case AppRoutes.chat:
      if (args is ChatConversation) {
        return route(ChatScreen(conversation: args));
      }
      return route(const ChatListScreen());
    case AppRoutes.voiceCall:
      final a = _getMapArgument(args);
      return route(VoiceCallScreen(
        userName: a?['userName']?.toString() ?? 'Unknown',
        userId: a?['userId']?.toString() ?? '',
      ));
    case AppRoutes.videoCall:
      final a = _getMapArgument(args);
      return route(VideoCallScreen(
        userName: a?['userName']?.toString() ?? 'Unknown',
        userId: a?['userId']?.toString() ?? '',
      ));

  // ── Static pages ──────────────────────────────────────
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

  // ── Subscriptions ─────────────────────────────────────
    case AppRoutes.rateCards:
      return route(const RateCardsScreen());
    case AppRoutes.paymentMethods:
      return route(const PaymentMethodsScreen());
    case AppRoutes.subscriptions:
      return route(const MySubscriptionsScreen());
    case AppRoutes.createSubscription:
      return route(const RateCardsScreen());
    case AppRoutes.downloads:
      return route(const DownloadsScreen());

    default:
      return route(const SplashScreen());
  }
}

// ============================================================
//  ROUTE ARG HELPERS
// ============================================================

int _getDraftArgument(Object? args) {
  if (args is int) return args;
  if (args is String) return int.tryParse(args) ?? 0;
  if (args is Map<String, dynamic>) {
    final value = args['draftId'] ?? args['technicianId'] ?? args['id'];
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

Map<String, dynamic>? _getMapArgument(Object? args) {
  if (args is Map<String, dynamic>) return args;
  return null;
}

// ============================================================
//  PROVIDER REGISTRY  (legacy access point)
// ============================================================

class ProviderRegistry {
  ProviderRegistry._();

  static AuthProvider? _authProvider;

  static void registerAuthProvider(AuthProvider provider) {
    _authProvider = provider;
  }

  static AuthProvider? get authProvider => _authProvider;
}