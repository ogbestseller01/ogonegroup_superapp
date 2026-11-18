// lib/providers/ticket_provider.dart

import 'package:flutter/material.dart';
import '../models/job.dart';
import '../services/api_service.dart';

class TicketProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<WorkTicket> _tickets = [];
  bool _isLoading = false;
  String? _error;

  List<WorkTicket> get tickets => List.unmodifiable(_tickets);
  bool get isLoading => _isLoading;
  String? get error => _error;

  int countByStatus(String status) =>
      _tickets.where((t) => t.status == status).length;

  Future<void> loadTickets() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _api.getMyTickets();
      if (res.success) {
        _tickets = extractList(res.data)
            .whereType<Map>()
            .map((e) => WorkTicket.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      } else {
        _error = res.message;
        _tickets = [];
      }
    } catch (e) {
      _error = 'Failed to load tickets: $e';
      _tickets = [];
      debugPrint('❌ loadTickets error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}