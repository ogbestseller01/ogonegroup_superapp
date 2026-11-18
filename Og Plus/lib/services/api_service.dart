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
  final int? statusCode;

  const ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.errors,
    this.statusCode,
  });

  factory ApiResponse.fromJson(dynamic json, {int? statusCode}) {
    if (json is! Map) {
      return ApiResponse(
        success: false,
        message: 'Unexpected response from server.',
        statusCode: statusCode,
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
      statusCode: statusCode,
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

  /// PUBLIC — latest active update (home card).
  /// Route: GET /api/v26/system-updates
  /// Returns { data: [ {id,title,description,published_at} ] } — empty if none.
  Future<ApiResponse> getActiveSystemUpdates() =>
      _get('/v26/system-updates');

  /// PUBLIC — ALL published, non-closed updates (any date), newest first.
  /// Route: GET /api/system-updates/all
  ///
  /// Pass `limit` for a flat array; omit it for a paginated payload.
  Future<ApiResponse> getAllSystemUpdates({
    int? limit,
    int? page,
    int? perPage,
  }) =>
      _get(
        '/system-updates/all',
        query: {
          if (limit != null) 'limit': limit,
          if (page != null) 'page': page,
          if (perPage != null) 'per_page': perPage,
        },
      );

  /// USER — mark an update viewed (auth optional).
  /// Route: POST /api/v26/system-updates/{id}/view
  Future<ApiResponse> markSystemUpdateViewed(int id) =>
      _post('/v26/system-updates/$id/view');

  /// USER — dismiss an update (auth optional).
  /// Route: POST /api/v26/system-updates/{id}/dismiss
  Future<ApiResponse> dismissSystemUpdate(int id) =>
      _post('/v26/system-updates/$id/dismiss');

  // ============================================================
  // DEVICE TOKEN (super app + mini apps)
  // ============================================================

  /// PUBLIC — register this device's FCM token.
  /// Route: POST /api/v1/device-token
  Future<ApiResponse> registerDeviceToken({
    required String token,
    required String platform,
    String app = 'og_one_super',
    String? deviceId,
  }) =>
      _post('/v1/device-token', data: {
        'fcm_device_token': token,
        'platform': platform,
        'app': app,
        if (deviceId != null) 'device_id': deviceId,
      });

  /// PUBLIC — unregister this device's FCM token (e.g. on logout).
  /// Route: DELETE /api/v1/device-token
  Future<ApiResponse> unregisterDeviceToken({
    required String token,
    required String platform,
    String app = 'og_one_super',
  }) async {
    try {
      final res = await _dio.delete('/v1/device-token', data: {
        'fcm_device_token': token,
        'platform': platform,
        'app': app,
      });
      return ApiResponse.fromJson(res.data, statusCode: res.statusCode);
    } catch (e) {
      return _handleError(e);
    }
  }

  /// AUTH — link this device_id to the currently logged-in user.
  /// Route: POST /api/v1/auth/device-token/link
  /// Called by mini apps right after login.
  Future<ApiResponse> linkDeviceToUser({required String deviceId}) =>
      _post('/v1/auth/device-token/link', data: {'device_id': deviceId});

  // ============================================================
  // PRIVATE HELPERS
  // ============================================================
  Future<ApiResponse> _get(String path, {Map<String, dynamic>? query}) async {
    try {
      final res = await _dio.get(path, queryParameters: query);
      return ApiResponse.fromJson(res.data, statusCode: res.statusCode);
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse> _post(String path, {dynamic data}) async {
    try {
      final res = await _dio.post(path, data: data);
      return ApiResponse.fromJson(res.data, statusCode: res.statusCode);
    } catch (e) {
      return _handleError(e);
    }
  }

  ApiResponse _handleError(dynamic error) {
    if (error is DioException) {
      final code = error.response?.statusCode;
      final data = error.response?.data;
      if (code == 422 && data is Map) {
        return ApiResponse(
          success: false,
          message: (data['message'] ?? 'Validation failed').toString(),
          errors: data['errors'] is Map
              ? Map<String, dynamic>.from(data['errors'] as Map)
              : null,
          statusCode: code,
        );
      }
      if (data is Map) {
        return ApiResponse(
          success: false,
          message: (data['message'] ?? 'Something went wrong').toString(),
          statusCode: code,
        );
      }
      return ApiResponse(
        success: false,
        message: 'Network error. Please check your connection.',
        statusCode: code,
      );
    }
    return const ApiResponse(
      success: false,
      message: 'Network error. Please check your connection.',
    );
  }
}