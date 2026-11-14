// lib/providers/system_update_provider.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/system_update.dart';
import '../services/api_service.dart';

class SystemUpdateProvider extends ChangeNotifier {
  static const _kDismissed = 'dismissedSystemUpdates';

  final List<SystemUpdate> _all = [];
  final Set<int> _dismissed = {};
  final Set<int> _viewedThisSession = {};

  bool _loading = false;
  String? _error;

  bool get loading => _loading;
  String? get error => _error;
  int get unreadCount => visible.length;

  /// ALL updates fetched from the backend (regardless of dismissal).
  List<SystemUpdate> get all => List.unmodifiable(_all);

  /// Updates the user has NOT dismissed (newest first).
  List<SystemUpdate> get visible =>
      _all.where((u) => !_dismissed.contains(u.id)).toList();

  /// Latest visible update, or null.
  SystemUpdate? get top => visible.isEmpty ? null : visible.first;

  // -----------------------------------------------------------------
  // HOME CARD — today's latest only
  // -----------------------------------------------------------------
  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await _restoreDismissed();

      // Since you removed the specific "today" route, we just fetch
      // all updates and the card will naturally show the newest one.
      final res = await ApiService.instance.getAllSystemUpdates(limit: 10);

      if (res.success && res.data is List) {
        _all
          ..clear()
          ..addAll((res.data as List)
              .whereType<Map>()
              .map((e) => SystemUpdate.fromJson(Map<String, dynamic>.from(e))));
      } else {
        _error = res.message;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // -----------------------------------------------------------------
  // LIST SCREEN — ALL published updates (any date)
  // -----------------------------------------------------------------
  Future<void> loadAll({int limit = 200}) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await _restoreDismissed();

      final res = await ApiService.instance.getAllSystemUpdates(limit: limit);

      if (res.success) {
        final List<Map> raw;
        if (res.data is List) {
          raw = (res.data as List).whereType<Map>().toList();
        } else if (res.data is Map && res.data['data'] is List) {
          // Fallback: paginated shape { data: [...] }
          raw = (res.data['data'] as List).whereType<Map>().toList();
        } else {
          raw = const [];
        }

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
      notifyListeners();
    }
  }

  // -----------------------------------------------------------------
  // LOCAL ACTIONS (No backend route needed)
  // -----------------------------------------------------------------
  Future<void> dismiss(int id) async {
    _dismissed.add(id);
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        _kDismissed, _dismissed.map((e) => '$e').toList());
  }

  void markViewed(int id) {
    _viewedThisSession.add(id);
  }

  Future<SystemUpdate?> findById(int id) async {
    for (final u in _all) {
      if (u.id == id) return u;
    }
    return null; // No backend fetch since the route doesn't exist
  }

  Future<void> _restoreDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    _dismissed
      ..clear()
      ..addAll((prefs.getStringList(_kDismissed) ?? [])
          .map(int.tryParse)
          .whereType<int>());
  }
}