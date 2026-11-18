// packages/nearby_fundi/packages/fundiapp/lib/fundi_mini.dart
//
// Public entry point for embedding FundiApp inside NearbyFundi (or any host).
// Hosts import ONLY this file.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'app_navigator.dart' show navigatorKey; // fundiapp's OWN key
import 'config/app_routes.dart';
import 'config/app_theme.dart';
import 'fundi_routes.dart' show generateFundiRoute;
import 'l10n/app_localizations.dart';
import 'providers/auth_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/theme_provider.dart';
// TODO: import every other provider that fundiapp's main.dart registers.

class FundiMiniApp extends StatelessWidget {
  const FundiMiniApp({super.key, this.initialRoute});

  /// Public constant so NearbyFundi never imports fundiapp's AppRoutes.
  static const String loginRoute = AppRoutes.login;

  /// Defaults to splash. Pass [loginRoute] to open the login screen directly.
  final String? initialRoute;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(navigatorKey: navigatorKey),
        ),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        // TODO: copy the remaining providers from fundiapp's main.dart.
      ],
      child: Consumer2<ThemeProvider, SettingsProvider>(
        builder: (context, themeProvider, settings, _) {
          return MaterialApp(
            title: 'Fundi App',
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
            initialRoute: initialRoute ?? AppRoutes.splash,
            onGenerateRoute: generateFundiRoute,
          );
        },
      ),
    );
  }
}