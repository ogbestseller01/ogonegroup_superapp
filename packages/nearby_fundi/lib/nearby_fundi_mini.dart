// packages/nearby_fundi/lib/nearby_fundi_mini.dart
//
// Public entry point for embedding NearbyFundi inside a host app.
// Host should import ONLY this file.
//
// Design:
//  * Nested MaterialApp → own localizations, theme, routes, providers.
//  * Host still owns Firebase init (main.dart skips if already initialized).
//  * Providers are scoped to this subtree.
//  * Shared navigatorKey keeps AuthProvider redirects working.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'app_navigator.dart' show navigatorKey;
import 'config/app_routes.dart';
import 'config/app_theme.dart';
import 'l10n/app_localizations.dart';

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

import 'main.dart' show generateNearbyFundiRoute;

/// Host-facing widget.
///
/// ```dart
/// import 'package:nearbyfundi_sdk/nearby_fundi_mini.dart';
///
/// Navigator.of(context).push(
///   MaterialPageRoute(builder: (_) => const NearbyFundiMiniApp()),
/// );
/// ```
class NearbyFundiMiniApp extends StatelessWidget {
  const NearbyFundiMiniApp({super.key, this.initialRoute});

  /// Defaults to splash. Pass a route to skip splash when already logged in.
  final String? initialRoute;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PostProvider()),
        ChangeNotifierProvider(create: (_) => RequestProvider()),
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
            initialRoute: initialRoute ?? AppRoutes.splash,
            onGenerateRoute: generateNearbyFundiRoute,
          );
        },
      ),
    );
  }
}