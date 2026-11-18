// lib/providers/static_page_provider.dart

import 'package:flutter/material.dart';

import '../models/about.dart';
import '../models/contact.dart';
import '../models/faq.dart';
import '../models/privacy_policy.dart';
import '../models/terms.dart';
import '../services/api_service.dart';

class StaticPageProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  // ── Cached data ─────────────────────────────────────────
  About? _about;
  Term? _terms;
  List<Faq> _faqs = [];
  PrivacyPolicy? _privacyPolicy;

  // ── Read state (about / terms / faqs) ───────────────────
  bool _isLoading = false;
  String? _error;

  // ── Separate state for privacy policy ───────────────────
  bool _privacyLoading = false;
  String? _privacyError;

  // ── Getters ─────────────────────────────────────────────
  About? get about => _about;
  Term? get terms => _terms;
  List<Faq> get faqs => List.unmodifiable(_faqs);
  PrivacyPolicy? get privacyPolicy => _privacyPolicy;

  bool get isLoading => _isLoading;
  String? get error => _error;

  bool get privacyLoading => _privacyLoading;
  String? get privacyError => _privacyError;

  // ════════════════════════════════════════════════════════
  // ABOUT / TERMS / FAQS
  // ════════════════════════════════════════════════════════

  Future<void> loadAbout() async {
    _setLoading(true);
    final res = await _api.getAbout();
    if (res.success && res.data is Map) {
      _about = About.fromJson(
        Map<String, dynamic>.from(res.data as Map),
      );
    } else {
      _error = res.message;
    }
    _setLoading(false);
  }

  Future<void> loadTerms() async {
    _setLoading(true);
    final res = await _api.getTerms();
    if (res.success && res.data is Map) {
      _terms = Term.fromJson(
        Map<String, dynamic>.from(res.data as Map),
      );
    } else {
      _error = res.message;
    }
    _setLoading(false);
  }

  Future<void> loadFaqs() async {
    _setLoading(true);
    final res = await _api.getFaqs();

    // Backend returns either a List directly, or { data: [...] }.
    final raw = res.data;
    List<dynamic>? list;
    if (raw is List) {
      list = raw;
    } else if (raw is Map && raw['data'] is List) {
      list = raw['data'] as List;
    }

    if (res.success && list != null) {
      _faqs = list
          .whereType<Map>()
          .map((e) => Faq.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } else {
      _error = res.message;
    }
    _setLoading(false);
  }

  // ════════════════════════════════════════════════════════
  // CONTACT FORM
  //
  // The /v1/contact route does not exist. The correct endpoint
  // is POST /v23/feedback (FeedbackController@store), throttled
  // at 5 requests/minute.
  // ════════════════════════════════════════════════════════

  Future<bool> sendContactMessage(ContactMessage message) async {
    _setLoading(true);
    final res = await _api.sendFeedback(message.toJson());
    _isLoading = false;

    if (res.success) {
      _error = null;
      notifyListeners();
      return true;
    }

    _error = res.message;
    notifyListeners();
    return false;
  }

  // ════════════════════════════════════════════════════════
  // PRIVACY POLICY
  //
  // GET /v18/privacy-policy       → public read
  // PUT /v18/privacy-policy       → admin only (permission:privacy.edit)
  // ════════════════════════════════════════════════════════

  Future<void> loadPrivacyPolicy() async {
    _privacyLoading = true;
    _privacyError = null;
    notifyListeners();

    final res = await _api.getPrivacyPolicy();
    _privacyLoading = false;

    if (res.success && res.data is Map) {
      _privacyPolicy = PrivacyPolicy.fromJson(
        Map<String, dynamic>.from(res.data as Map),
      );
    } else {
      _privacyError = res.message;
    }
    notifyListeners();
  }

  Future<bool> updatePrivacyPolicy(String content) async {
    _privacyLoading = true;
    _privacyError = null;
    notifyListeners();

    final res = await _api.updatePrivacyPolicy({'content': content});
    _privacyLoading = false;

    if (res.success && res.data is Map) {
      _privacyPolicy = PrivacyPolicy.fromJson(
        Map<String, dynamic>.from(res.data as Map),
      );
      notifyListeners();
      return true;
    }

    _privacyError = res.message;
    notifyListeners();
    return false;
  }

  // ════════════════════════════════════════════════════════
  // HELPERS
  // ════════════════════════════════════════════════════════

  void clearError() {
    _error = null;
    _privacyError = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    if (value) _error = null;
    notifyListeners();
  }
}