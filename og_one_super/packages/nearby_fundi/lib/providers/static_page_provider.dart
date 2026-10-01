// providers/static_page_provider.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/about.dart';
import '../models/terms.dart';
import '../models/faq.dart';
import '../models/contact.dart';
import '../models/privacy_policy.dart';

class StaticPageProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  About? _about;
  Term? _terms;
  List<Faq> _faqs = [];
  PrivacyPolicy? _privacyPolicy;
  bool _isLoading = false;
  String? _error;

  About? get about => _about;
  Term? get terms => _terms;
  List<Faq> get faqs => _faqs;
  PrivacyPolicy? get privacyPolicy => _privacyPolicy;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load About
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

  // Load Terms
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

  // Load FAQs
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

  // Load Privacy Policy
  Future<void> loadPrivacyPolicy({required String locale}) async {
    _setLoading(true);
    final res = await _api.getPrivacyPolicy();
    if (res.success && res.data != null) {
      _privacyPolicy = PrivacyPolicy.fromJson(res.data);
    } else {
      _error = res.message;
    }
    _setLoading(false);
  }

  // Send contact message
  Future<bool> sendContactMessage(ContactMessage message) async {
    _setLoading(true);
    final res = await _api.sendContactMessage(message.toJson());
    _setLoading(false);
    if (res.success) return true;
    _error = res.message;
    notifyListeners();
    return false;
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