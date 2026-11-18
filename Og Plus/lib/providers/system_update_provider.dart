// lib/providers/system_update_provider.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/system_update.dart';
import '../services/api_service.dart';

class SystemUpdateProvider extends ChangeNotifier {
  static const _kDismissed = 'dismissedSystemUpdates';

  final List<SystemUpdate> _all = [];
  final Set<int> _dismissed = {};

  bool _loading = false;
  String? _error;
  bool _disposed = false;

  bool get loading => _loading;
  String? get error => _error;

  List<SystemUpdate> get all => List.unmodifiable(_all);

  List<SystemUpdate> get visible =>
      _all.where((u) => !_dismissed.contains(u.id)).toList();

  SystemUpdate? get top => visible.isEmpty ? null : visible.first;

  int get unreadCount => visible.length;

  // -----------------------------------------------------------------
  // HOME CARD — latest active update (published today)
  // -----------------------------------------------------------------
  Future<void> load() async {
    _loading = true;
    _error = null;
    _safeNotify();

    try {
      await _restoreDismissed();

      final res = await ApiService.instance.getActiveSystemUpdates();

      if (res.success) {
        final raw = _extractList(res.data);
        _all
          ..clear()
          ..addAll(raw.map(
                  (e) => SystemUpdate.fromJson(Map<String, dynamic>.from(e))));
      } else if (res.statusCode == 404) {
        // /v26/system-updates missing on backend — fall back to /all.
        await loadAll();
        return;
      } else {
        _error = res.message;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      _safeNotify();
    }
  }

  // -----------------------------------------------------------------
  // LIST SCREEN — all published updates (any date)
  // -----------------------------------------------------------------
  Future<void> loadAll({int limit = 200}) async {
    _loading = true;
    _error = null;
    _safeNotify();

    try {
      await _restoreDismissed();

      final res = await ApiService.instance.getAllSystemUpdates(limit: limit);

      if (res.success) {
        final raw = _extractList(res.data);
        _all
          ..clear()
          ..addAll(raw.map(
                  (e) => SystemUpdate.fromJson(Map<String, dynamic>.from(e))));
      } else {
        _error = res.message;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      _safeNotify();
    }
  }

  /// Called by SystemUpdatePush when a new update is detected.
  Future<void> refresh() => load();

  Future<void> dismiss(int id) async {
    _dismissed.add(id);
    _safeNotify();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _kDismissed,
      _dismissed.map((e) => '$e').toList(),
    );

    try {
      await ApiService.instance.dismissSystemUpdate(id);
    } catch (_) {}
  }

  Future<void> markViewed(int id) async {
    try {
      await ApiService.instance.markSystemUpdateViewed(id);
    } catch (_) {}
  }

  SystemUpdate? findById(int id) {
    for (final u in _all) {
      if (u.id == id) return u;
    }
    return null;
  }

  // -----------------------------------------------------------------
  // internals
  // -----------------------------------------------------------------

  List<Map> _extractList(dynamic payload) {
    if (payload is List) {
      return payload.whereType<Map>().toList();
    }
    if (payload is Map && payload['data'] is List) {
      return (payload['data'] as List).whereType<Map>().toList();
    }
    return const [];
  }

  Future<void> _restoreDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    _dismissed
      ..clear()
      ..addAll(
        (prefs.getStringList(_kDismissed) ?? [])
            .map(int.tryParse)
            .whereType<int>(),
      );
  }

  void _safeNotify() {
    if (_disposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}