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
import 'services/security_service.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SecurityService.instance.init();

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
        // This gate completely blocks the app when debug mode is ON
        return _SecurityGate(child: child ?? const SizedBox.shrink());
      },
      onGenerateRoute: (route) {
        switch (route.name) {
          case AppRoutes.splash:
            return MaterialPageRoute(
              settings: route,
              builder: (_) => const SplashScreen(),
            );
          case AppRoutes.dashboard:
            return MaterialPageRoute(
              settings: route,
              builder: (_) => const SuperAppDashboard(),
            );
          case AppRoutes.settings:
            return MaterialPageRoute(
              settings: route,
              builder: (_) => const SettingsScreen(),
            );
          default:
            return MaterialPageRoute(
              settings: route,
              builder: (_) => _UnknownRoutePage(route.name),
            );
        }
      },
    );
  }
}

/// Full-screen permanent blocker.
/// When debug mode is ON the real app is never shown.
class _SecurityGate extends StatefulWidget {
  final Widget child;
  const _SecurityGate({required this.child});

  @override
  State<_SecurityGate> createState() => _SecurityGateState();
}

class _SecurityGateState extends State<_SecurityGate> with WidgetsBindingObserver {
  bool? _blocked; // null = still checking

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _check();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Re-check when user returns from Settings (after turning debug off)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _check();
    }
  }

  Future<void> _check() async {
    final isDebugOn = await SecurityService.instance.isDebugModeEnabled();
    if (!mounted) return;
    setState(() => _blocked = isDebugOn);
  }

  @override
  Widget build(BuildContext context) {
    // Still checking → show nothing (or a black screen)
    if (_blocked == null) {
      return const ColoredBox(color: Colors.black);
    }

    // Debug mode ON → permanent full-screen alert (no navigation possible)
    if (_blocked == true) {
      return const _DebugBlockerScreen();
    }

    // Debug mode OFF → normal app
    return widget.child;
  }
}

/// Full screen that never goes away until debug mode is turned off
class _DebugBlockerScreen extends StatelessWidget {
  const _DebugBlockerScreen();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF0F1A2E),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.security_rounded,
                size: 72,
                color: Color(0xFFE5484D),
              ),
              const SizedBox(height: 24),
              const Text(
                'Security Alert',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Please turn off your phone debug mode.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFE5484D),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => SystemNavigator.pop(),
                  child: const Text(
                    'Close App',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Turn off Developer Options / USB Debugging\nthen reopen the app.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white38, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
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
        child: Text('Page not found: ${name ?? '(unknown)'}'),
      ),
    );
  }
}