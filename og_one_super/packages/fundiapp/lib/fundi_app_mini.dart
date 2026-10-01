// packages/fundiapp/lib/fundi_app_mini.dart
//
// Public entry point for embedding the FundiApp SDK inside a host app.
// Host should import ONLY this file.
//
// Design:
//  * Nested MaterialApp so the SDK has its own localizations, theme, and routes.
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
import 'providers/notification_provider.dart';
import 'providers/portfolio_provider.dart';
import 'providers/post_provider.dart';
import 'providers/request_provider.dart';
import 'providers/service_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/static_page_provider.dart';
import 'providers/subscription_provider.dart';
import 'providers/technician_provider.dart';
import 'providers/theme_provider.dart';

import 'main.dart' show generateFundiAppRoute;

/// Host-facing widget.
///
/// ```dart
/// import 'package:fundiapp_sdk/fundi_app_mini.dart';
///
/// Navigator.of(context).push(
///   MaterialPageRoute(builder: (_) => const FundiAppMiniApp()),
/// );
/// ```
class FundiAppMiniApp extends StatelessWidget {
  const FundiAppMiniApp({super.key, this.initialRoute});

  /// Defaults to splash. Pass [AppRoutes.home] to skip splash when already logged in.
  final String? initialRoute;

  @override
  Widget build(BuildContext context) {
    // Prefer host locale if available, else English.
    final hostLocale = Localizations.maybeLocaleOf(context);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(navigatorKey: navigatorKey),
        ),
        ChangeNotifierProvider(create: (_) => PostProvider()),
        ChangeNotifierProvider(create: (_) => RequestProvider()),
        ChangeNotifierProvider(create: (_) => PortfolioProvider()),
        ChangeNotifierProvider(create: (_) => TechnicianProvider()),
        ChangeNotifierProvider(create: (_) => ServiceProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => StaticPageProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
      ],
      child: Consumer2<ThemeProvider, SettingsProvider>(
        builder: (context, themeProvider, settings, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            // SDK locale (SettingsProvider) wins; fall back to host, then en.
            locale: settings.currentLocale ?? hostLocale ?? const Locale('en'),
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
            navigatorKey: navigatorKey,
            initialRoute: initialRoute ?? AppRoutes.splash,
            onGenerateRoute: generateFundiAppRoute,
          );
        },
      ),
    );
  }
}