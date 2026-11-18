// lib/config/app_routes.dart
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String dashboard = '/dashboard';
  static const String home = '/home'; // 👈 Added back to resolve errors
  static const String settings = '/settings';

  // 👇 SYSTEM UPDATES
  static const String systemUpdates = '/settings/system-updates';
}