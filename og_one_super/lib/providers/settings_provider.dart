// lib/providers/settings_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  Locale _locale = const Locale('en');

  // Notification preferences
  bool _pushEnabled = true;
  bool _orderNotifications = true;
  bool _promoNotifications = true;
  bool _systemNotifications = true;

  // Getters
  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;

  bool get pushEnabled => _pushEnabled;
  bool get orderNotifications => _orderNotifications;
  bool get promoNotifications => _promoNotifications;
  bool get systemNotifications => _systemNotifications;

  SettingsProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();

    // Theme
    final theme = prefs.getString('themeMode') ?? 'system';
    _themeMode = switch (theme) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };

    // Language
    final lang = prefs.getString('locale') ?? 'en';
    _locale = Locale(lang);

    // Notifications
    _pushEnabled = prefs.getBool('pushEnabled') ?? true;
    _promoNotifications = prefs.getBool('promoNotifications') ?? true;
    _systemNotifications = prefs.getBool('systemNotifications') ?? true;

    notifyListeners();
  }

  // ── Theme ───────────────────────────────────────────────
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'themeMode',
      switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        _ => 'system',
      },
    );
  }

  // ── Language ────────────────────────────────────────────
  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', locale.languageCode);
  }

  // ── Notifications ───────────────────────────────────────
  Future<void> setPushEnabled(bool value) async {
    _pushEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('pushEnabled', value);
  }


  Future<void> setPromoNotifications(bool value) async {
    _promoNotifications = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('promoNotifications', value);
  }

  Future<void> setSystemNotifications(bool value) async {
    _systemNotifications = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('systemNotifications', value);
  }

  // Optional helper
  Future<void> clearCache() async {
    // You can clear image cache, temporary files, etc. here
    // For now just a placeholder
    await Future.delayed(const Duration(milliseconds: 300));
  }
}