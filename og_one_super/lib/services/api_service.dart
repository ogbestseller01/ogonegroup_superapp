// lib/services/api_service.dart
//
// Static-pages API only (About, Terms, Privacy, FAQs, Contact).
// All of these endpoints are public, so no auth token is needed.

import 'package:dio/dio.dart';

import '../config/app_config.dart';

/// Standard API response wrapper.
class ApiResponse {
  final bool success;
  final String message;
  final dynamic data;
  final Map<String, dynamic>? errors;

  const ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.errors,
  });

  factory ApiResponse.fromJson(dynamic json) {
    if (json is! Map) {
      return const ApiResponse(
        success: false,
        message: 'Unexpected response from server.',
      );
    }
    final map = Map<String, dynamic>.from(json);
    return ApiResponse(
      success: map['success'] ?? (map['status'] == 'success'),
      message: (map['message'] ?? 'No message from server').toString(),
      data: map['data'],
      errors: map['errors'] is Map
          ? Map<String, dynamic>.from(map['errors'] as Map)
          : null,
    );
  }
}

class ApiService {
  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        headers: const {'Accept': 'application/json'},
      ),
    );
  }

  /// Shared instance used by the static pages.
  static final ApiService instance = ApiService();

  late final Dio _dio;

  // ============================================================
  // STATIC PAGES
  // ============================================================

  Future<ApiResponse> getAbout() => _get('/v1/about');

  Future<ApiResponse> getFaqs() => _get('/v1/faqs');

  Future<ApiResponse> getTerms() => _get('/v1/terms');

  Future<ApiResponse> getPrivacyPolicy() => _get('/v18/privacy-policy');

  // ============================================================
  // CONTACT
  // ============================================================

  Future<ApiResponse> sendContactMessage(Map<String, dynamic> data) =>
      _post('/v1/contact', data: data);

  // ============================================================
  // FEEDBACK (send only)
  // ============================================================

  /// POST /v23/feedback – public endpoint, token is optional.
  /// Fields: name, email, type (suggestion|bug|compliment|other),
  /// rating (1-5, optional), message.
  Future<ApiResponse> sendFeedback(Map<String, dynamic> data) =>
      _post('/v23/feedback', data: data);

  // ============================================================
  // PRIVATE HELPERS
  // ============================================================

  Future<ApiResponse> _get(String path, {Map<String, dynamic>? query}) async {
    try {
      final res = await _dio.get(path, queryParameters: query);
      return ApiResponse.fromJson(res.data);
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse> _post(String path, {dynamic data}) async {
    try {
      final res = await _dio.post(path, data: data);
      return ApiResponse.fromJson(res.data);
    } catch (e) {
      return _handleError(e);
    }
  }

  ApiResponse _handleError(dynamic error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (error.response?.statusCode == 422 && data is Map) {
        return ApiResponse(
          success: false,
          message: (data['message'] ?? 'Validation failed').toString(),
          errors: data['errors'] is Map
              ? Map<String, dynamic>.from(data['errors'] as Map)
              : null,
        );
      }
      if (data is Map) {
        return ApiResponse(
          success: false,
          message: (data['message'] ?? 'Something went wrong').toString(),
        );
      }
    }
    return const ApiResponse(
      success: false,
      message: 'Network error. Please check your connection.',
    );
  }
}