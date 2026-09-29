import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kDebugMode, kProfileMode, kReleaseMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';

import 'app_navigator.dart';
import 'config/app_routes.dart';
import 'config/app_theme.dart';
import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'models/chat_conversation.dart';

import 'providers/auth_provider.dart';
import 'providers/post_provider.dart';
import 'providers/request_provider.dart';
import 'providers/portfolio_provider.dart';
import 'providers/technician_provider.dart';
import 'providers/service_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/static_page_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/subscription_provider.dart';

import 'services/fcm_service.dart';
import 'services/security_service.dart';

import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/otp_verification_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/reset_password_screen.dart';

import 'screens/auth/register_flow/register_step1_screen.dart';
import 'screens/auth/register_flow/register_step2_screen.dart';
import 'screens/auth/register_flow/register_step3_screen.dart';
import 'screens/auth/register_flow/register_step4_screen.dart';
import 'screens/auth/register_flow/register_review_screen.dart';

import 'screens/fundi/fundi_home_screen.dart';
import 'screens/fundi/fundi_posts_screen.dart';
import 'screens/fundi/fundi_portfolio_screen.dart';
import 'screens/fundi/fundi_requests_screen.dart';
import 'screens/fundi/profile/edit_profile_screen.dart';
import 'screens/fundi/profile/fundi_profile_screen.dart';
import 'screens/fundi/profile/fundi_settings_screen.dart';

import 'screens/static/about_screen.dart';
import 'screens/static/terms_screen.dart';
import 'screens/static/faq_screen.dart';
import 'screens/static/contact_us_screen.dart';
import 'screens/static/privacy_policy_screen.dart';

import 'screens/chat/chat_list_screen.dart';
import 'screens/chat/chat_screen.dart';
import 'screens/chat/voice_call_screen.dart';
import 'screens/chat/video_call_screen.dart';

import 'screens/subscription/rate_cards_screen.dart';
import 'screens/subscription/payment_methods_screen.dart';
import 'screens/subscription/my_subscriptions_screen.dart';
import 'screens/subscription/downloads_screen.dart';

// ============================================================
// BOOT DEBUG HELPERS
// ============================================================

final Stopwatch _bootClock = Stopwatch();

/// Prints a boot step with elapsed milliseconds since main() started.
/// Filter your console with "[BOOT]" to follow the startup sequence.
void _log(String message) {
  debugPrint('[BOOT +${_bootClock.elapsedMilliseconds}ms] $message');
}

/// Logs before/after creating a provider so a crashing constructor is easy to find.
/// Note: providers are lazy, so these logs appear the first time each is read.
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

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('📩 BG handler start: ${message.messageId}');
  // Only initialize if this isolate hasn't already done so.
  // When embedded in the super-app, the host app owns Firebase init.
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  debugPrint('📩 BG message: ${message.messageId}');
}

Future<void> main() async {
  _bootClock.start();
  _log('🚀 main() started');

  WidgetsFlutterBinding.ensureInitialized();
  _log('✅ WidgetsFlutterBinding initialized');
  _log('ℹ️ Platform: $defaultTargetPlatform | '
      'debug=$kDebugMode profile=$kProfileMode release=$kReleaseMode');

  // ----------------------------------------------------------
  // Global error hooks: catch anything that would otherwise be silent
  // ----------------------------------------------------------
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

  // ----------------------------------------------------------
  // 1. Firebase
  //
  // Standalone (fundiapp as the root app): this initializes Firebase.
  // Embedded (super-app owns the root): Firebase.apps is non-empty,
  // so we skip re-init — the host already did it.
  // ----------------------------------------------------------
  if (Firebase.apps.isEmpty) {
    try {
      _log('⏳ [1/4] Firebase.initializeApp starting');
      _log('ℹ️ Firebase apps already registered (native): '
          '${Firebase.apps.map((a) => a.name).toList()}');
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint('✅ Firebase initialized successfully');
      final opts = Firebase.app().options;
      _log('ℹ️ Firebase app: ${Firebase.app().name} | appId=${opts.appId} | '
          'project=${opts.projectId} | bundle=${opts.iosBundleId}');
    } catch (e, stackTrace) {
      debugPrint('❌ Firebase initialization failed: $e');
      debugPrint('$stackTrace');
    }
  } else {
    _log('ℹ️ Firebase already initialized by host — skipping');
  }

  // Top-level background handler (required)
  _log('⏳ Registering FirebaseMessaging background handler');
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  _log('✅ Background handler registered');

  // ----------------------------------------------------------
  // 3. Secure screen
  // ----------------------------------------------------------
  try {
    _log('⏳ [2/4] SecurityService.enableSecureScreen starting');
    await SecurityService.enableSecureScreen();
    debugPrint('✅ Secure screen initialized successfully');
    _log('✅ [2/4] SecurityService.enableSecureScreen finished');
  } catch (e, stackTrace) {
    debugPrint('❌ Secure screen initialization failed: $e');
    debugPrint('$stackTrace');
  }

  // ----------------------------------------------------------
  // 4. System UI
  // ----------------------------------------------------------
  try {
    _log('⏳ [3/4] System UI configuration starting');
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    _log('✅ Preferred orientations set');
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
    _log('✅ [3/4] System UI overlay style set');
  } catch (e, stackTrace) {
    debugPrint('⚠️ System UI configuration failed: $e');
    debugPrint('$stackTrace');
  }

  // ----------------------------------------------------------
  // 5. AuthProvider + runApp
  // ----------------------------------------------------------
  _log('⏳ [4/4] Creating AuthProvider');
  final authProvider = AuthProvider(navigatorKey: navigatorKey);
  _log('✅ AuthProvider created');
  ProviderRegistry.registerAuthProvider(authProvider);
  _log('✅ AuthProvider registered in ProviderRegistry');

  _log('⏳ Calling runApp()');
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider(
            create: (_) => _timed('PostProvider', () => PostProvider())),
        ChangeNotifierProvider(
            create: (_) => _timed('RequestProvider', () => RequestProvider())),
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

  // ----------------------------------------------------------
  // FCM: runs in the background so the splash shows immediately.
  // On iOS it waits for the notification permission dialog.
  // ----------------------------------------------------------
  unawaited(() async {
    try {
      _log('⏳ FcmService.init starting (background)');
      await FcmService.init();
      debugPrint('✅ FCM initialized successfully');
      _log('✅ FcmService.init finished');
    } catch (e, stackTrace) {
      debugPrint('❌ FCM initialization failed: $e');
      debugPrint('$stackTrace');
    }
  }());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    _log('🧱 MyApp.build()');
    return Consumer2<ThemeProvider, SettingsProvider>(
      builder: (context, themeProvider, settings, _) {
        debugPrint('🧱 MaterialApp rebuild | themeMode=${themeProvider.themeMode} '
            '| locale=${settings.currentLocale}');
        return MaterialApp(
          title: 'NETSAF FUNDI APP',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          navigatorKey: navigatorKey,
          locale: settings.currentLocale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'),
            Locale('sw'),
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

Route<dynamic> generateFundiAppRoute(RouteSettings settings) {
  final Object? args = settings.arguments;
  debugPrint('🧭 Route requested: ${settings.name} | '
      'args type: ${args?.runtimeType}');

  switch (settings.name) {
    case AppRoutes.splash:
      return MaterialPageRoute(
        builder: (_) => const SplashScreen(),
        settings: settings,
      );
    case AppRoutes.onboarding:
      return MaterialPageRoute(
        builder: (_) => const OnboardingScreen(),
        settings: settings,
      );
    case AppRoutes.login:
      return MaterialPageRoute(
        builder: (_) => const LoginScreen(),
        settings: settings,
      );
    case AppRoutes.registerStep1:
      return MaterialPageRoute(
        builder: (_) => const RegisterStep1Screen(),
        settings: settings,
      );
    case AppRoutes.registerStep2:
      return MaterialPageRoute(
        builder: (_) => RegisterStep2Screen(
          technicianId: _getIntArgument(args),
        ),
        settings: settings,
      );
    case AppRoutes.registerStep3:
      return MaterialPageRoute(
        builder: (_) => RegisterStep3Screen(
          technicianId: _getIntArgument(args),
        ),
        settings: settings,
      );
    case AppRoutes.registerStep4:
      return MaterialPageRoute(
        builder: (_) => RegisterStep4Screen(
          technicianId: _getIntArgument(args),
        ),
        settings: settings,
      );
    case AppRoutes.registerReview:
      if (args is Map<String, dynamic>) {
        return MaterialPageRoute(
          builder: (_) => RegisterReviewScreen(registrationData: args),
          settings: settings,
        );
      }
      debugPrint('⚠️ registerReview called without Map args → RegisterStep1');
      return MaterialPageRoute(
        builder: (_) => const RegisterStep1Screen(),
        settings: settings,
      );
    case AppRoutes.otp:
      if (args is Map<String, dynamic>) {
        return MaterialPageRoute(
          builder: (_) => OtpVerificationScreen(
            email: args['email']?.toString() ?? '',
            redirectToStep2: args['redirectToStep2'] == true,
            technicianId: _nullableInt(args['technicianId']),
          ),
          settings: settings,
        );
      }
      return MaterialPageRoute(
        builder: (_) => OtpVerificationScreen(
          email: args?.toString() ?? '',
        ),
        settings: settings,
      );
    case AppRoutes.forgot:
      return MaterialPageRoute(
        builder: (_) => const ForgotPasswordScreen(),
        settings: settings,
      );
    case AppRoutes.reset:
      return MaterialPageRoute(
        builder: (_) => ResetPasswordScreen(
          email: args?.toString() ?? '',
        ),
        settings: settings,
      );
    case AppRoutes.home:
      return MaterialPageRoute(
        builder: (_) => const FundiHomeScreen(),
        settings: settings,
      );
    case AppRoutes.posts:
    case AppRoutes.blog:
    case AppRoutes.createPost:
    case AppRoutes.editPost:
      return MaterialPageRoute(
        builder: (_) => const FundiPostsScreen(),
        settings: settings,
      );
    case AppRoutes.portfolio:
    case AppRoutes.addPortfolio:
    case AppRoutes.editPortfolio:
      return MaterialPageRoute(
        builder: (_) => const FundiPortfolioScreen(),
        settings: settings,
      );
    case AppRoutes.requests:
      return MaterialPageRoute(
        builder: (_) => const FundiRequestsScreen(),
        settings: settings,
      );
    case AppRoutes.notifications:
    // TODO: use NotificationsScreen when available
      return MaterialPageRoute(
        builder: (_) => const FundiHomeScreen(),
        settings: settings,
      );
    case AppRoutes.profile:
      return MaterialPageRoute(
        builder: (_) => const FundiProfileScreen(),
        settings: settings,
      );
    case AppRoutes.editProfile:
      return MaterialPageRoute(
        builder: (_) => const EditProfileScreen(),
        settings: settings,
      );
    case AppRoutes.settings:
      return MaterialPageRoute(
        builder: (_) => const FundiSettingsScreen(),
        settings: settings,
      );
    case AppRoutes.chatList:
      return MaterialPageRoute(
        builder: (_) => const ChatListScreen(),
        settings: settings,
      );
    case AppRoutes.chat:
      if (args is ChatConversation) {
        return MaterialPageRoute(
          builder: (_) => ChatScreen(conversation: args),
          settings: settings,
        );
      }
      debugPrint('⚠️ chat route called without ChatConversation '
          '(got ${args?.runtimeType}) → ChatListScreen');
      return MaterialPageRoute(
        builder: (_) => const ChatListScreen(),
        settings: settings,
      );
    case AppRoutes.voiceCall:
      final voiceArgs = _getMapArgument(args);
      return MaterialPageRoute(
        builder: (_) => VoiceCallScreen(
          userName: voiceArgs?['userName']?.toString() ?? 'Unknown',
          userId: voiceArgs?['userId']?.toString() ?? '',
        ),
        settings: settings,
      );
    case AppRoutes.videoCall:
      final videoArgs = _getMapArgument(args);
      return MaterialPageRoute(
        builder: (_) => VideoCallScreen(
          userName: videoArgs?['userName']?.toString() ?? 'Unknown',
          userId: videoArgs?['userId']?.toString() ?? '',
        ),
        settings: settings,
      );
    case AppRoutes.about:
      return MaterialPageRoute(
        builder: (_) => const AboutScreen(),
        settings: settings,
      );
    case AppRoutes.terms:
      return MaterialPageRoute(
        builder: (_) => const TermsScreen(),
        settings: settings,
      );
    case AppRoutes.faq:
      return MaterialPageRoute(
        builder: (_) => const FaqScreen(),
        settings: settings,
      );
    case AppRoutes.contactUs:
      return MaterialPageRoute(
        builder: (_) => const ContactUsScreen(),
        settings: settings,
      );
    case AppRoutes.privacy:
      return MaterialPageRoute(
        builder: (_) => const PrivacyPolicyScreen(),
        settings: settings,
      );
    case AppRoutes.rateCards:
      return MaterialPageRoute(
        builder: (_) => const RateCardsScreen(),
        settings: settings,
      );
    case AppRoutes.paymentMethods:
      return MaterialPageRoute(
        builder: (_) => const PaymentMethodsScreen(),
        settings: settings,
      );
    case AppRoutes.subscriptions:
      return MaterialPageRoute(
        builder: (_) => const MySubscriptionsScreen(),
        settings: settings,
      );
    case AppRoutes.createSubscription:
      return MaterialPageRoute(
        builder: (_) => const RateCardsScreen(),
        settings: settings,
      );
    case AppRoutes.downloads:
      return MaterialPageRoute(
        builder: (_) => const DownloadsScreen(),
        settings: settings,
      );
    default:
      debugPrint('⚠️ Unknown route: ${settings.name}');
      return MaterialPageRoute(
        builder: (_) => const SplashScreen(),
        settings: settings,
      );
  }
}

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

class ProviderRegistry {
  static AuthProvider? _authProvider;

  static void registerAuthProvider(AuthProvider provider) {
    _authProvider = provider;
  }

  static AuthProvider? get authProvider => _authProvider;
}