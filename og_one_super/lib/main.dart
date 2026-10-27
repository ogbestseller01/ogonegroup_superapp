import 'dart:async';
import 'dart:developer' as dev;
import 'dart:ui' show PlatformDispatcher;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'config/app_routes.dart';
import 'config/app_theme.dart';
import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'providers/banner_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/dashboard/super_app_dashboard.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/splash_screen.dart';
import 'services/internet_checker.dart';
import 'services/security_service.dart';
import 'widgets/app_gates.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

/// Block the app while USB / developer debugging is ON.
/// Use `kReleaseMode` (from foundation.dart) to enforce only in release.
const bool _kEnforceSecurityGate = true;

/// Backend health endpoint, injected at build time so each environment
/// (dev / staging / prod) can use its own URL:
///
///   flutter run   --dart-define=API_HEALTH_URL=http://10.0.2.2:8000/health
///   flutter build apk --dart-define=API_HEALTH_URL=https://api.yourdomain.com/health
///
/// Empty → the connection check uses public probes only.
const String _kApiHealthUrl = String.fromEnvironment('API_HEALTH_URL');

void main() {
  // One safety net for every kind of uncaught error.
  runZonedGuarded(_bootstrap, _reportError);
}

Future<void> _bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Disable runtime font downloading – use only the fonts declared in assets
  GoogleFonts.config.allowRuntimeFetching = false;

  // Flutter framework errors (build / layout / paint).
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    _reportError(details.exception, details.stack);
  };

  // Errors outside the Flutter framework (platform channels, isolates).
  PlatformDispatcher.instance.onError = (error, stack) {
    _reportError(error, stack);
    return true;
  };

  await _safeInit('SecurityService', () => SecurityService.instance.init());

  await _safeInit('Firebase', () async {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  });

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
      ],
      child: const OgOneSuperApp(),
    ),
  );
}

/// Runs a startup step without letting one failure kill the whole launch.
Future<void> _safeInit(String name, Future<void> Function() init) async {
  try {
    await init();
  } catch (e, st) {
    _reportError(e, st, context: 'Init failed: $name');
  }
}

/// Central error sink.
/// TODO(production): forward to Crashlytics / Sentry here, e.g.
///   FirebaseCrashlytics.instance.recordError(error, stack, reason: context);
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
        // Keep layouts intact when users set extreme system font sizes.
        return MediaQuery.withClampedTextScaling(
          minScaleFactor: 0.85,
          maxScaleFactor: 1.3,
          child: SecurityGate(
            enforce: _kEnforceSecurityGate,
            checker: _checker,
            child: child ?? const SizedBox.shrink(),
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
      body: Center(
        child: Text('Page not found: ${name ?? '(unknown)'}'),
      ),
    );
  }
}