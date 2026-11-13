// lib/providers/system_update_provider.dart
import 'dart:async'; // Proper import for unawaited()
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
  /// Used by the full System Updates List Screen.
  List<SystemUpdate> get all => List.unmodifiable(_all);

  /// Updates the user has NOT dismissed (newest first).
  /// Used by the Home Screen card.
  List<SystemUpdate> get visible =>
      _all.where((u) => !_dismissed.contains(u.id)).toList();

  /// Latest visible update, or null.
  SystemUpdate? get top => visible.isEmpty ? null : visible.first;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      _dismissed
        ..clear()
        ..addAll((prefs.getStringList(_kDismissed) ?? [])
            .map(int.tryParse)
            .whereType<int>());

      final res = await ApiService.instance.getSystemUpdates();
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

  Future<void> dismiss(int id) async {
    _dismissed.add(id);
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        _kDismissed, _dismissed.map((e) => '$e').toList());

    // Properly fire-and-forget the API call
    unawaited(ApiService.instance.dismissSystemUpdate(id));
  }

  void markViewed(int id) {
    if (!_viewedThisSession.add(id)) return;
    unawaited(ApiService.instance.markSystemUpdateViewed(id));
  }

  Future<SystemUpdate?> findById(int id) async {
    for (final u in _all) {
      if (u.id == id) return u;
    }
    final res = await ApiService.instance.getSystemUpdate(id);
    if (res.success && res.data is Map) {
      return SystemUpdate.fromJson(Map<String, dynamic>.from(res.data as Map));
    }
    return null;
  }
}