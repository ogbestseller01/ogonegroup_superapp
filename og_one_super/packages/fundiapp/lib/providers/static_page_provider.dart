import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/about.dart';
import '../models/terms.dart';
import '../models/faq.dart';
import '../models/contact.dart';
import '../models/privacy_policy.dart'; // <-- Added import

class StaticPageProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  About? _about;
  Term? _terms;
  List<Faq> _faqs = [];

  // ✨ NEW: Privacy Policy Variable
  PrivacyPolicy? _privacyPolicy;

  bool _isLoading = false;
  String? _error;

  // --- Getters ---
  About? get about => _about;
  Term? get terms => _terms;
  List<Faq> get faqs => _faqs;

  // ✨ NEW: Privacy Policy Getter
  PrivacyPolicy? get privacyPolicy => _privacyPolicy;

  bool get isLoading => _isLoading;
  String? get error => _error;

  // ============================================================
  // ✨ NEW: Privacy Policy Loading/Error Getters (Added for your screen)
  // ============================================================
  bool _privacyLoading = false;
  String? _privacyError;

  bool get privacyLoading => _privacyLoading;
  String? get privacyError => _privacyError;
  // ============================================================

  // --- Existing Load Methods ---
  Future<void> loadAbout() async {
    _setLoading(true);
    final res = await _api.getAbout();
    if (res.success && res.data != null) {
      _about = About.fromJson(res.data);
    } else {
      _error = res.message;
    }
    _setLoading(false);
  }

  Future<void> loadTerms() async {
    _setLoading(true);
    final res = await _api.getTerms();
    if (res.success && res.data != null) {
      _terms = Term.fromJson(res.data);
    } else {
      _error = res.message;
    }
    _setLoading(false);
  }

  Future<void> loadFaqs() async {
    _setLoading(true);
    final res = await _api.getFaqs();
    if (res.success && res.data != null) {
      _faqs = (res.data as List).map((e) => Faq.fromJson(e)).toList();
    } else {
      _error = res.message;
    }
    _setLoading(false);
  }

  Future<bool> sendContactMessage(ContactMessage message) async {
    _setLoading(true);
    final res = await _api.sendContactMessage(message.toJson());
    _setLoading(false);
    if (res.success) return true;
    _error = res.message;
    notifyListeners();
    return false;
  }

  // ============================================================
  // ✨ NEW: Privacy Policy Methods
  // ============================================================

  /// Fetch the public privacy policy from the API
  Future<void> loadPrivacyPolicy() async {
    _privacyLoading = true;
    _privacyError = null;
    notifyListeners(); // Using separate privacy loading state

    final res = await _api.getPrivacyPolicy();
    _privacyLoading = false;
    if (res.success && res.data != null) {
      _privacyPolicy = PrivacyPolicy.fromJson(res.data);
    } else {
      _privacyError = res.message;
    }
    notifyListeners();
  }

  /// Update the privacy policy (Admin only)
  Future<bool> updatePrivacyPolicy(String content) async {
    _privacyLoading = true;
    _privacyError = null;
    notifyListeners();

    final res = await _api.updatePrivacyPolicy({'content': content});
    _privacyLoading = false;

    if (res.success && res.data != null) {
      _privacyPolicy = PrivacyPolicy.fromJson(res.data);
      notifyListeners();
      return true;
    } else {
      _privacyError = res.message;
      notifyListeners();
      return false;
    }
  }

  // ============================================================
  // Helpers
  // ============================================================

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