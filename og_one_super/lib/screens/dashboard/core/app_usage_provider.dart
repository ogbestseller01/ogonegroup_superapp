import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Keeps the user's favorite and recently opened mini apps (by slug),
/// saved on the device.
class AppUsageProvider extends ChangeNotifier {
  static const _favKey = 'dash_favorite_apps';
  static const _recentKey = 'dash_recent_apps';
  static const _maxRecent = 8;

  List<String> _favorites = [];
  List<String> _recent = [];
  bool _disposed = false;

  List<String> get favorites => List.unmodifiable(_favorites);
  List<String> get recent => List.unmodifiable(_recent);

  bool isFavorite(String slug) => _favorites.contains(slug);

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _favorites = prefs.getStringList(_favKey) ?? [];
      _recent = prefs.getStringList(_recentKey) ?? [];
      _notify();
    } catch (_) {
      // Storage problems should never break the dashboard.
    }
  }

  /// Returns true when the app is now a favorite.
  Future<bool> toggleFavorite(String slug) async {
    final nowFav = !_favorites.contains(slug);
    if (nowFav) {
      _favorites = [slug, ..._favorites];
    } else {
      _favorites = _favorites.where((s) => s != slug).toList();
    }
    _notify();
    await _save();
    return nowFav;
  }

  Future<void> markOpened(String slug) async {
    _recent =
        [slug, ..._recent.where((s) => s != slug)].take(_maxRecent).toList();
    _notify();
    await _save();
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_favKey, _favorites);
      await prefs.setStringList(_recentKey, _recent);
    } catch (_) {}
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
