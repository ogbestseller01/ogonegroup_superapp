// lib/main.dart
import 'dart:async';
import 'dart:developer' as dev;
import 'dart:ui' show PlatformDispatcher;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fundiapp_sdk/firebase_options.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'config/app_routes.dart';
import 'config/app_theme.dart';
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
import 'widgets/app_gates.dart';
import 'widgets/developer_mode_gate.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

const bool _kEnforceSecurityGate = true;
const String _kApiHealthUrl = String.fromEnvironment('API_HEALTH_URL');

/// FCM background handler — MUST be a top-level function with
/// @pragma('vm:entry-point'). The OS displays the notification automatically.
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // No manual UI needed — the OS renders the visible notification.
}

void main() {
  runZonedGuarded(_bootstrap, _reportError);
}

Future<void> _bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  GoogleFonts.config.allowRuntimeFetching = false;

  try {
    await AppSecurityMiddleware.initialize();
  } catch (e, st) {
    _reportError(e, st, context: 'Security middleware violation');
    try {
      await SystemChannels.platform.invokeMethod('SystemNavigator.pop');
    } catch (_) {}
    return;
  }

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    _reportError(details.exception, details.stack);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    _reportError(error, stack);
    return true;
  };

  await _safeInit('SecurityService', () => SecurityService.instance.init());
  await _safeInit('Firebase', _initFirebase);

  if (Firebase.apps.isNotEmpty) {
    await _safeInit('FCM background', () async {
      FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
    });

    // Register the token (public — no auth required)
    unawaited(
      FcmTokenService.register().catchError((e, st) {
        _reportError(e, st, context: 'FcmTokenService.register');
      }),
    );
  }

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
        ChangeNotifierProvider(create: (_) => SystemUpdateProvider()..load()),
      ],
      child: const OgOneSuperApp(),
    ),
  );
}

Future<void> _initFirebase() async {
  if (Firebase.apps.isNotEmpty) return;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on FirebaseException catch (e) {
    if (e.code != 'duplicate-app') rethrow;
  }
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
      title: 'OG ONE-GROUP',
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