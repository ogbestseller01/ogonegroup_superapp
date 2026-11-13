// lib/services/api_service.dart
//
// Public API client for the super app.
// Auth token is optional — when set (after login), it enables per-user
// tracking (viewed / dismissed / device-token registration).

import 'package:dio/dio.dart';

import '../config/app_config.dart';

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
      success: map['success'] == true || map['status'] == 'success',
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

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final t = ApiService.authToken;
          if (t != null && t.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $t';
          }
          handler.next(options);
        },
      ),
    );
  }

  static final ApiService instance = ApiService();

  /// Set after login (leave null for guests).
  static String? authToken;

  late final Dio _dio;

  // ============================================================
  // STATIC PAGES
  // ============================================================
  Future<ApiResponse> getAbout() => _get('/v1/about');
  Future<ApiResponse> getFaqs() => _get('/v1/faqs');
  Future<ApiResponse> getTerms() => _get('/v1/terms');
  Future<ApiResponse> getPrivacyPolicy() => _get('/v18/privacy-policy');

  // ============================================================
  // MINI APPS
  // ============================================================
  Future<ApiResponse> getMiniApps() => _get('/v24/mini-apps');
  Future<ApiResponse> verifyQr(String token) =>
      _post('/v24/mini-apps/qr/verify', data: {'token': token});

  // ============================================================
  // CONTACT
  // ============================================================
  Future<ApiResponse> sendContactMessage(Map<String, dynamic> data) =>
      _post('/v1/contact', data: data);

  // ============================================================
  // FEEDBACK
  // ============================================================
  Future<ApiResponse> sendFeedback(Map<String, dynamic> data) =>
      _post('/v23/feedback', data: data);

  // ============================================================
  // BANNERS
  // ============================================================
  Future<ApiResponse> getBanners({String? type}) =>
      _get('/v25/banners', query: type != null ? {'type': type} : null);

  // ============================================================
  // SYSTEM UPDATES
  // ============================================================
  Future<ApiResponse> getSystemUpdates({int? limit}) => _get(
    '/v26/system-updates',
    query: limit != null ? {'limit': limit} : null,
  );

  Future<ApiResponse> getSystemUpdate(int id) =>
      _get('/v26/system-updates/$id');

  Future<ApiResponse> markSystemUpdateViewed(int id) =>
      _post('/v26/system-updates/$id/view');

  Future<ApiResponse> dismissSystemUpdate(int id) =>
      _post('/v26/system-updates/$id/dismiss');

  // ============================================================
  // DEVICE TOKEN (FCM push registration)
  // ============================================================
  /// POST /v1/device-token – saves this device's FCM token for the user.
  /// Requires a valid auth token.
  Future<ApiResponse> registerDeviceToken({
    required String token,
    required String platform,
  }) =>
      _post('/v1/device-token', data: {
        'fcm_device_token': token,
        'platform': platform,
      });

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