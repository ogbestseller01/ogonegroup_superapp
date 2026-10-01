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
    _locale = (await StorageService.getLocale()) ?? 'en';
    _notificationsEnabled =
        (await StorageService.getNotificationsEnabled()) ?? true;
    notifyListeners();
  }

  /// Update language locally first, then try to sync with backend
  Future<bool> updateLocale(String newLocale) async {
    if (_locale == newLocale) return true;

    // 1. Update UI immediately (this is the key fix)
    _locale = newLocale;
    await StorageService.saveLocale(newLocale);
    notifyListeners(); // ← UI changes right away

    // 2. Try to sync with backend (non-blocking for the UI)
    _setLoading(true);
    try {
      final res = await _api.updateLocale(newLocale);
      if (!res.success) {
        _error = res.message;
        // Optional: you can revert here if you want strict sync
        // _locale = previousLocale;
        // await StorageService.saveLocale(previousLocale);
        // notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      // Still keep the local change even if API fails
    } finally {
      _setLoading(false);
    }

    return true;
  }

  Future<bool> updateNotificationStatus(bool enabled) async {
    _notificationsEnabled = enabled;
    await StorageService.saveNotificationsEnabled(enabled);
    notifyListeners();
    return true;
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
}