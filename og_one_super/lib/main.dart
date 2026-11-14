// lib/main.dart
import 'dart:async';
import 'dart:developer' as dev;
import 'dart:ui' show PlatformDispatcher;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'config/app_routes.dart';
import 'config/app_theme.dart';
import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'providers/banner_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/system_update_provider.dart';
import 'screens/dashboard/super_app_dashboard.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/splash_screen.dart';
import 'services/app_security_middleware.dart';
import 'services/fcm_token_service.dart';
import 'services/internet_checker.dart';
import 'services/security_service.dart';
import 'services/system_update_push.dart';
import 'widgets/app_gates.dart';
import 'widgets/developer_mode_gate.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

const bool _kEnforceSecurityGate = true;
const String _kApiHealthUrl = String.fromEnvironment('API_HEALTH_URL');

void main() {
  runZonedGuarded(_bootstrap, _reportError);
}

Future<void> _bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1) Security middleware
  try {
    await AppSecurityMiddleware.initialize();
  } catch (e, st) {
    _reportError(e, st, context: 'Security middleware violation');
    try {
      SystemChannels.platform.invokeMethod('SystemNavigator.pop');
    } catch (_) {}
    return;
  }

  GoogleFonts.config.allowRuntimeFetching = false;

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    _reportError(details.exception, details.stack);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    _reportError(error, stack);
    return true;
  };

  await _safeInit('SecurityService', () => SecurityService.instance.init());

  // 2) Firebase (single default app, safe against duplicate-app)
  await _safeInit('Firebase', _initFirebase);

  // 3) FCM background handler (MUST be before runApp)
  await _safeInit('FCM background', () async {
    FirebaseMessaging.onBackgroundMessage(systemUpdateBackgroundHandler);
  });

  // 4) Android notification channel
  await _safeInit('NotificationChannel', _createAndroidChannel);

  // 5) Register FCM token (best-effort; safe if auth not yet set)
  unawaited(FcmTokenService.register());

  // 6) System chrome
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => BannerProvider()..fetchBanners()),
        // Global provider so Settings/Updates screens can access it
        ChangeNotifierProvider(create: (_) => SystemUpdateProvider()..load()),
      ],
      child: const OgOneSuperApp(),
    ),
  );
}

Future<void> _initFirebase() async {
  if (Firebase.apps.isNotEmpty) return;
  try {
    // Explicitly use the options we defined in firebase_options.dart
    // This works for both Android and iOS and avoids native file mismatches.
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on FirebaseException catch (e) {
    // Native side or a mini app already created [DEFAULT]; that's fine.
    if (e.code != 'duplicate-app') rethrow;
  }
}

Future<void> _createAndroidChannel() async {
  const channel = AndroidNotificationChannel(
    'fundi_channel',
    'Fundi Notifications',
    description: 'System updates and announcements',
    importance: Importance.high,
  );
  final plugin = FlutterLocalNotificationsPlugin();
  await plugin
      .resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
}

Future<void> _safeInit(String name, Future<void> Function() init) async {
  try {
    await init();
  } catch (e, st) {
    _reportError(e, st, context: 'Init failed: $name');
  }
}

void _reportError(Object error, StackTrace? stack, {String? context}) {
  dev.log(
    context ?? 'Uncaught error',
    name: 'OgOneSuper',
    error: error,
    stackTrace: stack,
  );
}

class OgOneSuperApp extends StatelessWidget {
  const OgOneSuperApp({super.key});

  static const InternetChecker _checker =
  InternetChecker(apiHealthUrl: _kApiHealthUrl);

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return MaterialApp(
      navigatorKey: rootNavigatorKey,
      title: 'OG ONE GROUP',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settings.themeMode,
      locale: settings.locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      initialRoute: AppRoutes.splash,
      builder: (context, child) {
        return MediaQuery.withClampedTextScaling(
          minScaleFactor: 0.85,
          maxScaleFactor: 1.3,
          child: SecurityGate(
            enforce: _kEnforceSecurityGate,
            checker: _checker,
            child: DeveloperModeGate(
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        );
      },
      onGenerateRoute: _onGenerateRoute,
    );
  }

  static Route<dynamic> _onGenerateRoute(RouteSettings route) {
    final Widget page = switch (route.name) {
      AppRoutes.splash => const SplashScreen(),
      AppRoutes.dashboard => const SuperAppDashboard(),
      AppRoutes.settings => const SettingsScreen(),
      _ => _UnknownRoutePage(route.name),
    };

    return MaterialPageRoute(settings: route, builder: (_) => page);
  }
}

class _UnknownRoutePage extends StatelessWidget {
  const _UnknownRoutePage(this.name);

  final String? name;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(child: Text('Page not found: ${name ?? '(unknown)'}')),
    );
  }
}