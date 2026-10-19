// lib/config/app_prefs.dart

import 'package:shared_preferences/shared_preferences.dart';

class AppPrefs {
  AppPrefs._();

  static const String _onboardingDoneKey = 'onboarding_completed';

  /// True once the user has finished (or skipped) onboarding.
  static Future<bool> isOnboardingDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingDoneKey) ?? false;
  }

  /// Call when onboarding is finished or skipped.
  static Future<void> setOnboardingDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingDoneKey, true);
  }
}