import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class SettingsProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  bool _isLoading = false;
  String? _error;
  bool _notificationsEnabled = true;
  String _locale = 'en';

  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get notificationsEnabled => _notificationsEnabled;
  String get locale => _locale;
  Locale get currentLocale => Locale(_locale);

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final String? savedLocale = await StorageService.getLocale();
      final bool? savedNotifications =
      await StorageService.getNotificationsEnabled();

      _locale = _normalizeLocale(savedLocale);
      _notificationsEnabled = savedNotifications ?? true;
    } catch (e, stackTrace) {
      debugPrint('⚠️ SettingsProvider load error: $e');
      debugPrint('$stackTrace');
      _locale = 'en';
      _notificationsEnabled = true;
    }

    notifyListeners();
  }

  /// Update language immediately (local first), then try to sync with backend
  Future<bool> updateLocale(String newLocale) async {
    final String locale = _normalizeLocale(newLocale);

    if (_locale == locale) return true;

    // 1. Update UI immediately
    _locale = locale;
    await StorageService.saveLocale(locale);
    notifyListeners(); // ← This makes Swahili appear right away

    // 2. Try to sync with backend (non-blocking)
    _setLoading(true);
    try {
      final response = await _api.updateLocale(locale);

      if (!response.success) {
        _error = response.message;
        // We keep the local change even if API fails
      }
    } catch (e, stackTrace) {
      _error = e.toString();
      debugPrint('❌ updateLocale error: $e');
      debugPrint('$stackTrace');
    } finally {
      _setLoading(false);
    }

    return true;
  }

  Future<bool> updateNotificationStatus(bool enabled) async {
    try {
      _notificationsEnabled = enabled;
      await StorageService.saveNotificationsEnabled(enabled);
      notifyListeners();
      return true;
    } catch (e, stackTrace) {
      debugPrint('❌ updateNotificationStatus error: $e');
      debugPrint('$stackTrace');
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    if (value) _error = null;
    notifyListeners();
  }

  String _normalizeLocale(String? value) {
    if (value == 'sw') return 'sw';
    return 'en';
  }
}