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
import 'payments/chanel/mock_channel.dart';
import 'payments/provider/payment_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/job_provider.dart';
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
import 'providers/ticket_provider.dart';

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
        ChangeNotifierProvider(create: (_) => ServiceProvider()),
        ChangeNotifierProvider(create: (_) => TechnicianProvider()),
        ChangeNotifierProvider(create: (_) => RequestProvider()),
        ChangeNotifierProvider(create: (_) => JobProvider()),
        ChangeNotifierProvider(create: (_) => PortfolioProvider()),
        ChangeNotifierProvider(create: (_) => PostProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
        ChangeNotifierProvider(create: (_) => TicketProvider()),
        ChangeNotifierProvider(create: (_) => StaticPageProvider()),
        ChangeNotifierProvider(
          create: (_) => PaymentProvider(channel: MockPaymentChannel()),
        ),
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