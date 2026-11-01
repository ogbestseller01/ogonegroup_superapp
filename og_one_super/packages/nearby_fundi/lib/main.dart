// lib/main.dart
import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'app_navigator.dart' show navigatorKey;

import 'config/app_routes.dart';
import 'config/app_theme.dart';
import 'l10n/app_localizations.dart';
import 'models/chat_conversation.dart';

import 'providers/auth_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/job_provider.dart';
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

import 'screens/jobs/job_detail_screen.dart';
import 'screens/jobs/jobs_screen.dart';
import 'screens/notifications/notifications_screen.dart';
import 'screens/onboarding_screen.dart';

import 'screens/profile/edit_profile_screen.dart';
import 'screens/profile/settings_screen.dart';

import 'screens/requests/my_requests_screen.dart';

import 'screens/static/about_screen.dart';
import 'screens/static/contact_us_screen.dart';
import 'screens/static/faq_screen.dart';
import 'screens/static/privacy_policy_screen.dart';
import 'screens/static/terms_screen.dart';

import 'screens/splash_screen.dart';
import 'screens/technicians/technician_detail_screen.dart';
import 'screens/tickets/tickets_screen.dart';

import 'services/api_service.dart';
import 'services/fcm_service.dart';
import 'services/security_service.dart';

// ============================================================
// ERROR LOGGING
// ============================================================

void _logError(String label, Object error, [StackTrace? stack]) {
  if (!kDebugMode) return;
  debugPrint('[$label] $error');
  if (stack != null) debugPrint('$stack');
}

// ============================================================
// BACKGROUND FIREBASE MESSAGING
// ============================================================

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
  }
}

// ============================================================
// MAIN
// ============================================================

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    _logError('FlutterError', details.exceptionAsString(), details.stack);
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    _logError('Uncaught', error, stack);
    return true;
  };

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
  } catch (error, stack) {
    _logError('Firebase init', error, stack);
  }

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  try {
    await SecurityService.enableSecureScreen();
  } catch (error, stack) {
    _logError('Secure screen', error, stack);
  }

  try {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  } catch (error, stack) {
    _logError('System UI', error, stack);
  }

  runApp(const MyApp());

  // Initialize FCM without delaying the first frame.
  unawaited(_initializeFcm());
}

Future<void> _initializeFcm() async {
  try {
    await FcmService.initialize();
  } catch (error, stack) {
    _logError('FCM init', error, stack);
  }
}

// ============================================================
// APPLICATION
// ============================================================

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PostProvider()),
        ChangeNotifierProvider(create: (_) => RequestProvider()),
        ChangeNotifierProvider(create: (_) => JobProvider()),
        ChangeNotifierProvider(create: (_) => TechnicianProvider()),
        ChangeNotifierProvider(create: (_) => ServiceProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => StaticPageProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: Consumer2<ThemeProvider, SettingsProvider>(
        builder: (context, themeProvider, settings, child) {
          return MaterialApp(
            title: 'NearbyFundi',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            locale: Locale(settings.locale),
            supportedLocales: const [Locale('en'), Locale('sw')],
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
// ROUTING
// ============================================================

Route<dynamic> generateNearbyFundiRoute(RouteSettings routeSettings) {
  final Object? args = routeSettings.arguments;

  MaterialPageRoute<dynamic> route(Widget page) {
    return MaterialPageRoute<dynamic>(
      builder: (_) => page,
      settings: routeSettings,
    );
  }

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

    case AppRoutes.myRequests:
      return route(const MyRequestsScreen());

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
      // Screens pass the fundi's users.id (an int): resolve the conversation first.
      final fundiUserId = _intArg(args);
      if (fundiUserId > 0) {
        return route(_ChatLauncher(fundiUserId: fundiUserId));
      }
      return route(const ChatListScreen());

    case AppRoutes.jobs:
      return route(const JobsScreen());

    case AppRoutes.jobDetail:
      return route(JobDetailScreen(jobId: _intArg(args)));

    case AppRoutes.tickets:
      return route(const TicketsScreen());

    case AppRoutes.notifications:
      return route(const NotificationsScreen());

    case AppRoutes.privacyPolicy:
      return route(const PrivacyPolicyScreen());

    default:
      return route(const SplashScreen());
  }
}

// ============================================================
// CHAT LAUNCHER  (fundi users.id -> conversation -> ChatScreen)
// ============================================================

class _ChatLauncher extends StatefulWidget {
  const _ChatLauncher({required this.fundiUserId});

  final int fundiUserId;

  @override
  State<_ChatLauncher> createState() => _ChatLauncherState();
}

class _ChatLauncherState extends State<_ChatLauncher> {
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _open());
  }

  Future<void> _open() async {
    if (mounted) setState(() => _error = null);

    try {
      // ASSUMPTION: AuthProvider exposes the signed-in user as `user?.id`.
      final myId = int.tryParse('${context.read<AuthProvider>().user?.id}') ?? 0;
      if (myId == 0) {
        throw Exception('Please sign in again.');
      }

      final res = await ApiService().getOrCreateConversation(
        customerId: myId,
        fundiId: widget.fundiUserId,
      );

      if (!res.success || res.data is! Map) {
        throw Exception(res.message);
      }

      // ASSUMPTION: ChatConversation.fromJson(Map<String, dynamic>) exists.
      final raw = Map<String, dynamic>.from(res.data as Map);
      final data = raw['conversation'] is Map
          ? Map<String, dynamic>.from(raw['conversation'] as Map)
          : raw;
      final conversation = ChatConversation.fromJson(data);

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => ChatScreen(conversation: conversation),
        ),
      );
    } catch (e) {
      _logError('ChatLauncher', e);
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        title: Text(AppLocalizations.of(context)!.chat),
      ),
      body: Center(
        child: _error == null
            ? const CircularProgressIndicator(color: AppTheme.primary)
            : Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: _open, child: const Text('Retry')),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// ROUTE ARGUMENT HELPERS
// ============================================================

int _intArg(Object? args) {
  if (args is int) return args;
  if (args is String) return int.tryParse(args) ?? 0;

  if (args is Map) {
    final value = args['id'] ??
        args['jobId'] ??
        args['technicianId'] ??
        args['postId'] ??
        args['requestId'] ??
        args['userId'];

    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
  }

  return 0;
}

String _stringArg(Object? args) {
  if (args is String) return args;
  if (args is Map) return args['email']?.toString() ?? '';
  return '';
}