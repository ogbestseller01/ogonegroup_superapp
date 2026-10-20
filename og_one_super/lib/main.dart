// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'config/app_routes.dart';
import 'config/app_theme.dart';
import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'providers/settings_provider.dart';
import 'screens/dashboard/super_app_dashboard.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase ONCE for the whole super-app.
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  await SystemChrome.setPreferredOrientations([
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
    ChangeNotifierProvider(
      create: (_) => SettingsProvider(),
      child: const OgOneSuperApp(),
    ),
  );
}

class OgOneSuperApp extends StatelessWidget {
  const OgOneSuperApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return MaterialApp(
      title: 'OG ONE GROUP',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settings.themeMode,
      locale: settings.locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      initialRoute: AppRoutes.splash,
      onGenerateRoute: (route) {
        switch (route.name) {
          case AppRoutes.splash:
            return MaterialPageRoute(
                settings: route, builder: (_) => const SplashScreen());
          case AppRoutes.dashboard:
            return MaterialPageRoute(
                settings: route, builder: (_) => const SuperAppDashboard());
          case AppRoutes.settings:
            return MaterialPageRoute(
                settings: route, builder: (_) => const SettingsScreen());
          default:
            debugPrint('⚠️ Host app: unknown route "${route.name}"');
            return MaterialPageRoute(
                settings: route, builder: (_) => _UnknownRoutePage(route.name));
        }
      },
    );
  }
}

class _UnknownRoutePage extends StatelessWidget {
  final String? name;
  const _UnknownRoutePage(this.name);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.explore_off_rounded, size: 56),
              const SizedBox(height: 16),
              Text('Page not found: ${name ?? '(unknown)'}',
                  textAlign: TextAlign.center),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
                    AppRoutes.dashboard, (r) => false),
                child: const Text('Go to dashboard'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}