// lib/main.dart
// ============================================================
//  FundiApp SDK — root entry point.
//
//  Runs two ways:
//    1. Standalone  — this main() boots the whole app.
//    2. Embedded    — host super-app owns Firebase/root MaterialApp,
//                     and mounts `FundiAppMiniApp` instead of this.
// ============================================================

import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kDebugMode, kProfileMode, kReleaseMode;
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
import 'screens/auth/register_flow/register_review_screen.dart';
import 'screens/auth/register_flow/register_step1_screen.dart';
import 'screens/auth/register_flow/register_step2_screen.dart';
import 'screens/auth/register_flow/register_step3_screen.dart';
import 'screens/auth/register_flow/register_step4_screen.dart';
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
import 'screens/splash_screen.dart'; // ← the ONLY splash. Delete splash_screen_fixed.dart.
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
//  BOOT DEBUG HELPERS
// ============================================================

final Stopwatch _bootClock = Stopwatch();

/// Prints a boot step with elapsed ms since main() started.
/// Filter your console with "[BOOT]" to follow the startup sequence.
void _log(String message) {
  debugPrint('[BOOT +${_bootClock.elapsedMilliseconds}ms] $message');
}

/// Wraps a provider constructor so a crash is easy to locate.
/// Providers are lazy, so these logs appear on first read.
T _timed<T>(String name, T Function() build) {
  _log('⏳ Creating $name');
  try {
    final value = build();
    _log('✅ Created $name');
    return value;
  } catch (e, stackTrace) {
    debugPrint('❌ [BOOT] $name constructor FAILED: $e');
    debugPrint('$stackTrace');
    rethrow;
  }
}

// ============================================================
//  FCM BACKGROUND HANDLER  (must be top-level + vm:entry-point)
// ============================================================

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('📩 BG handler start: ${message.messageId}');

  // Host super-app may have already initialized Firebase; only init
  // here if this isolate is completely cold.
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  debugPrint('📩 BG message handled: ${message.messageId}');
}

// ============================================================
//  MAIN
// ============================================================

Future<void> main() async {
  _bootClock.start();
  _log('🚀 main() started');

  WidgetsFlutterBinding.ensureInitialized();
  _log('✅ WidgetsFlutterBinding initialized');
  _log('ℹ️ Platform: $defaultTargetPlatform | '
      'debug=$kDebugMode profile=$kProfileMode release=$kReleaseMode');

  // ── Global error hooks ────────────────────────────────────
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('🔥 [FlutterError] ${details.exceptionAsString()}');
    debugPrint('${details.stack}');
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    debugPrint('🔥 [PlatformDispatcher] Uncaught async error: $error');
    debugPrint('$stack');
    return true;
  };
  _log('✅ Global error handlers installed');

  // ── 1/5  Firebase ─────────────────────────────────────────
  if (Firebase.apps.isEmpty) {
    try {
      _log('⏳ [1/5] Firebase.initializeApp starting');
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      final opts = Firebase.app().options;
      _log('✅ [1/5] Firebase ready | app=${Firebase.app().name} '
          '| project=${opts.projectId} | appId=${opts.appId}');
    } catch (e, stackTrace) {
      debugPrint('❌ Firebase initialization failed: $e');
      debugPrint('$stackTrace');
    }
  } else {
    _log('ℹ️ [1/5] Firebase already initialized by host — skipping');
  }

  _log('⏳ Registering FirebaseMessaging background handler');
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  _log('✅ Background handler registered');

  // ── 2/5  Secure screen ────────────────────────────────────
  try {
    _log('⏳ [2/5] SecurityService.enableSecureScreen starting');
    await SecurityService.enableSecureScreen();
    _log('✅ [2/5] Secure screen enabled');
  } catch (e, stackTrace) {
    debugPrint('❌ Secure screen initialization failed: $e');
    debugPrint('$stackTrace');
  }

  // ── 3/5  System UI ────────────────────────────────────────
  try {
    _log('⏳ [3/5] System UI configuration starting');
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
    _log('✅ [3/5] System UI configured');
  } catch (e, stackTrace) {
    debugPrint('⚠️ System UI configuration failed: $e');
    debugPrint('$stackTrace');
  }

  // ── 4/5  AuthProvider (eager — mini-app + FCM need it) ────
  _log('⏳ [4/5] Creating AuthProvider');
  final authProvider = AuthProvider(navigatorKey: navigatorKey);
  ProviderRegistry.registerAuthProvider(authProvider);
  _log('✅ [4/5] AuthProvider ready & registered');

  // ── 5/5  runApp ───────────────────────────────────────────
  _log('⏳ [5/5] Calling runApp()');
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider(
            create: (_) => _timed('PostProvider', () => PostProvider())),
        ChangeNotifierProvider(
            create: (_) =>
                _timed('RequestProvider', () => RequestProvider())),
        ChangeNotifierProvider(
            create: (_) =>
                _timed('PortfolioProvider', () => PortfolioProvider())),
        ChangeNotifierProvider(
            create: (_) =>
                _timed('TechnicianProvider', () => TechnicianProvider())),
        ChangeNotifierProvider(
            create: (_) => _timed('ServiceProvider', () => ServiceProvider())),
        ChangeNotifierProvider(
            create: (_) =>
                _timed('NotificationProvider', () => NotificationProvider())),
        ChangeNotifierProvider(
            create: (_) =>
                _timed('SettingsProvider', () => SettingsProvider())),
        ChangeNotifierProvider(
            create: (_) =>
                _timed('StaticPageProvider', () => StaticPageProvider())),
        ChangeNotifierProvider(
            create: (_) => _timed('ThemeProvider', () => ThemeProvider())),
        ChangeNotifierProvider(
            create: (_) => _timed('ChatProvider', () => ChatProvider())),
        ChangeNotifierProvider(
            create: (_) =>
                _timed('SubscriptionProvider', () => SubscriptionProvider())),
      ],
      child: const MyApp(),
    ),
  );
  _log('✅ runApp() returned');

  WidgetsBinding.instance.addPostFrameCallback((_) {
    _log('🎉 First Flutter frame rendered');
  });

  // ── FCM (background, so the splash shows immediately) ─────
  unawaited(() async {
    try {
      _log('⏳ FcmService.init starting (background)');
      await FcmService.init();
      _log('✅ FcmService.init finished');
    } catch (e, stackTrace) {
      debugPrint('❌ FCM initialization failed: $e');
      debugPrint('$stackTrace');
    }
  }());
}

// ============================================================
//  ROOT WIDGET
// ============================================================

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    _log('🧱 MyApp.build()');
    return Consumer2<ThemeProvider, SettingsProvider>(
      builder: (context, themeProvider, settings, _) {
        debugPrint('🧱 MaterialApp rebuild | '
            'themeMode=${themeProvider.themeMode} '
            '| locale=${settings.currentLocale}');
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
  debugPrint('🧭 Route requested: ${settings.name} | '
      'args type: ${args?.runtimeType}');

  MaterialPageRoute<dynamic> route(Widget page) => MaterialPageRoute(
    builder: (_) => page,
    settings: settings,
  );

  switch (settings.name) {
    case AppRoutes.splash:
      return route(const SplashScreen());
    case AppRoutes.onboarding:
      return route(const OnboardingScreen());
    case AppRoutes.login:
      return route(const LoginScreen());
    case AppRoutes.registerStep1:
      return route(const RegisterStep1Screen());
    case AppRoutes.registerStep2:
      return route(RegisterStep2Screen(technicianId: _getIntArgument(args)));
    case AppRoutes.registerStep3:
      return route(RegisterStep3Screen(technicianId: _getIntArgument(args)));
    case AppRoutes.registerStep4:
      return route(RegisterStep4Screen(technicianId: _getIntArgument(args)));
    case AppRoutes.registerReview:
      if (args is Map<String, dynamic>) {
        return route(RegisterReviewScreen(registrationData: args));
      }
      debugPrint('⚠️ registerReview called without Map args → RegisterStep1');
      return route(const RegisterStep1Screen());
    case AppRoutes.otp:
      if (args is Map<String, dynamic>) {
        return route(OtpVerificationScreen(
          email: args['email']?.toString() ?? '',
          redirectToStep2: args['redirectToStep2'] == true,
          technicianId: _nullableInt(args['technicianId']),
        ));
      }
      return route(OtpVerificationScreen(email: args?.toString() ?? ''));
    case AppRoutes.forgot:
      return route(const ForgotPasswordScreen());
    case AppRoutes.reset:
      return route(ResetPasswordScreen(email: args?.toString() ?? ''));
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
    // TODO: swap to a dedicated NotificationsScreen when available.
      return route(const FundiHomeScreen());
    case AppRoutes.profile:
      return route(const FundiProfileScreen());
    case AppRoutes.editProfile:
      return route(const EditProfileScreen());
    case AppRoutes.settings:
      return route(const FundiSettingsScreen());
    case AppRoutes.chatList:
      return route(const ChatListScreen());
    case AppRoutes.chat:
      if (args is ChatConversation) {
        return route(ChatScreen(conversation: args));
      }
      debugPrint('⚠️ chat route called without ChatConversation '
          '(got ${args?.runtimeType}) → ChatListScreen');
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
      debugPrint('⚠️ Unknown route: ${settings.name}');
      return route(const SplashScreen());
  }
}

// ============================================================
//  ROUTE ARG HELPERS
// ============================================================

int _getIntArgument(Object? args) {
  if (args is int) return args;
  if (args is String) return int.tryParse(args) ?? 0;
  if (args is Map<String, dynamic>) {
    final value = args['technicianId'] ?? args['id'];
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
  }
  return 0;
}

int? _nullableInt(Object? value) {
  if (value is int) return value;
  if (value is String) return int.tryParse(value);
  return null;
}

Map<String, dynamic>? _getMapArgument(Object? args) {
  if (args is Map<String, dynamic>) return args;
  return null;
}

// ============================================================
//  PROVIDER REGISTRY  (legacy access point)
//
//  Only useful for code that runs *outside* the widget tree — e.g.
//  a background isolate, FCM tap handler before runApp, or a native
//  MethodChannel callback. Inside widgets, prefer:
//
//      context.read<AuthProvider>()
//
//  If nothing in your codebase reads `ProviderRegistry.authProvider`,
//  delete this class entirely.
// ============================================================

class ProviderRegistry {
  ProviderRegistry._();

  static AuthProvider? _authProvider;

  static void registerAuthProvider(AuthProvider provider) {
    _authProvider = provider;
  }

  static AuthProvider? get authProvider => _authProvider;
}