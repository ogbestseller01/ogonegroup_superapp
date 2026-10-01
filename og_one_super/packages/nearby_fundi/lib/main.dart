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

import 'config/app_routes.dart';
import 'config/app_theme.dart';
import 'l10n/app_localizations.dart';
import 'models/chat_conversation.dart';

import 'providers/auth_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/location_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/post_provider.dart';
import 'providers/request_provider.dart';
import 'providers/service_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/static_page_provider.dart';
import 'providers/technician_provider.dart';
import 'providers/theme_provider.dart';

import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/otp_verification_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/reset_password_screen.dart';
import 'screens/chat/chat_list_screen.dart';
import 'screens/chat/chat_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/home/post_detail_screen.dart';
import 'screens/notifications/notifications_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/static/about_screen.dart';
import 'screens/static/contact_us_screen.dart';
import 'screens/profile/edit_profile_screen.dart';
import 'screens/static/faq_screen.dart';
import 'screens/profile/settings_screen.dart';
import 'screens/static/terms_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/static/privacy_policy_screen.dart';
import 'screens/technicians/technician_detail_screen.dart';
import 'screens/tracking/tracking_screen.dart';

import 'services/fcm_service.dart';
import 'services/security_service.dart';

// Use the shared key from app_navigator.dart so both standalone + mini-app share it
import 'app_navigator.dart' show navigatorKey;

// ============================================================
// BOOT DEBUG HELPERS
// ============================================================

final Stopwatch _bootClock = Stopwatch();

void _log(String message) {
  debugPrint('[BOOT +${_bootClock.elapsedMilliseconds}ms] $message');
}

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
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('📩 Background message received: ${message.messageId}');
}

Future<void> main() async {
  _bootClock.start();
  _log('🚀 main() started');

  WidgetsFlutterBinding.ensureInitialized();
  _log('✅ WidgetsFlutterBinding initialized');
  _log('ℹ️ Platform: $defaultTargetPlatform | '
      'debug=$kDebugMode profile=$kProfileMode release=$kReleaseMode');

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

  // 1. Firebase – only initialize if the host has not already done it
  try {
    _log('⏳ [1/3] Firebase.initializeApp starting');
    _log('ℹ️ Firebase apps already registered (native): '
        '${Firebase.apps.map((a) => a.name).toList()}');
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
    final opts = Firebase.app().options;
    _log('✅ Firebase initialized | appId=${opts.appId} | '
        'project=${opts.projectId} | bundle=${opts.iosBundleId}');
  } catch (e, stackTrace) {
    debugPrint('❌ Firebase initialization failed: $e');
    debugPrint('$stackTrace');
  }

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  _log('✅ Background handler registered');

  // 2. Secure screen
  try {
    _log('⏳ [2/3] SecurityService.enableSecureScreen starting');
    await SecurityService.enableSecureScreen();
    _log('✅ [2/3] SecurityService.enableSecureScreen finished');
  } catch (e, stackTrace) {
    debugPrint('❌ Secure screen initialization failed: $e');
    debugPrint('$stackTrace');
  }

  // 3. System UI
  try {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ));
    _log('✅ [3/3] System UI overlay style set');
  } catch (e, stackTrace) {
    debugPrint('⚠️ System UI configuration failed: $e');
    debugPrint('$stackTrace');
  }

  _log('⏳ Calling runApp()');
  runApp(const MyApp());
  _log('✅ runApp() returned');

  WidgetsBinding.instance.addPostFrameCallback((_) {
    _log('🎉 First Flutter frame rendered');
  });

  unawaited(() async {
    try {
      _log('⏳ FcmService.initialize starting (background)');
      await FcmService.initialize();
      _log('✅ FcmService.initialize finished');
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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
            create: (_) => _timed('AuthProvider', () => AuthProvider())),
        ChangeNotifierProvider(
            create: (_) => _timed('PostProvider', () => PostProvider())),
        ChangeNotifierProvider(
            create: (_) => _timed('RequestProvider', () => RequestProvider())),
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
                _timed('LocationProvider', () => LocationProvider())),
        ChangeNotifierProvider(
            create: (_) =>
                _timed('StaticPageProvider', () => StaticPageProvider())),
        ChangeNotifierProvider(
            create: (_) => _timed('ThemeProvider', () => ThemeProvider())),
        ChangeNotifierProvider(
            create: (_) => _timed('ChatProvider', () => ChatProvider())),
      ],
      child: Consumer2<ThemeProvider, SettingsProvider>(
        builder: (context, themeProvider, settings, _) {
          return MaterialApp(
            title: 'NearbyFundi',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            locale: Locale(settings.locale),
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
            navigatorKey: navigatorKey,
            initialRoute: AppRoutes.splash,
            onGenerateRoute: generateNearbyFundiRoute,
          );
        },
      ),
    );
  }
}

// ============================================================
// ROUTING  (exported for the mini-app)
// ============================================================

Route<dynamic> generateNearbyFundiRoute(RouteSettings routeSettings) {
  final Object? args = routeSettings.arguments;
  debugPrint('🧭 Route requested: ${routeSettings.name} | '
      'args type: ${args?.runtimeType}');

  MaterialPageRoute<dynamic> route(Widget page) => MaterialPageRoute(
    builder: (_) => page,
    settings: routeSettings,
  );

  switch (routeSettings.name) {
    case AppRoutes.splash:
      return route(const SplashScreen());
    case AppRoutes.onboarding:
      return route(const OnboardingScreen());
    case AppRoutes.login:
      return route(const LoginScreen());
    case AppRoutes.register:
      return route(const RegisterScreen());
    case AppRoutes.otp:
      return route(OtpVerificationScreen(email: _stringArg(args)));
    case AppRoutes.forgot:
      return route(const ForgotPasswordScreen());
    case AppRoutes.reset:
      return route(ResetPasswordScreen(email: _stringArg(args)));
    case AppRoutes.home:
      return route(const HomeScreen());
    case AppRoutes.technicianDetail:
      return route(TechnicianDetailScreen(technicianId: _intArg(args)));
    case AppRoutes.postDetail:
      return route(PostDetailScreen(postId: _intArg(args)));
    case AppRoutes.editProfile:
      return route(const EditProfileScreen());
    case AppRoutes.settings:
      return route(const SettingsScreen());
    case AppRoutes.about:
      return route(const AboutScreen());
    case AppRoutes.terms:
      return route(const TermsScreen());
    case AppRoutes.faq:
      return route(const FaqScreen());
    case AppRoutes.contactUs:
      return route(const ContactUsScreen());
    case AppRoutes.chatList:
      return route(const ChatListScreen());
    case AppRoutes.chatScreen:
      if (args is ChatConversation) {
        return route(ChatScreen(conversation: args));
      }
      debugPrint('⚠️ chatScreen called without ChatConversation '
          '(got ${args?.runtimeType}) → ChatListScreen');
      return route(const ChatListScreen());
    case AppRoutes.notifications:
      return route(const NotificationsScreen());
    case AppRoutes.privacyPolicy:
      return route(const PrivacyPolicyScreen());
    case AppRoutes.tracking:
      return route(TrackingScreen(requestId: _intArg(args)));
    default:
      debugPrint('⚠️ Unknown route: ${routeSettings.name}');
      return route(const SplashScreen());
  }
}

int _intArg(Object? args) {
  if (args is int) return args;
  if (args is String) return int.tryParse(args) ?? 0;
  if (args is Map) {
    final value = args['id'] ??
        args['technicianId'] ??
        args['postId'] ??
        args['requestId'];
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
  }
  debugPrint('⚠️ Expected an int route argument, got ${args?.runtimeType}');
  return 0;
}

String _stringArg(Object? args) {
  if (args is String) return args;
  if (args is Map) return args['email']?.toString() ?? '';
  debugPrint('⚠️ Expected a String route argument, got ${args?.runtimeType}');
  return '';
}