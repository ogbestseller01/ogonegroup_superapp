// lib/services/api_service.dart

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import 'storage_service.dart';

/// Standard API response wrapper.
class ApiResponse {
  final bool success;
  final String message;
  final dynamic data;
  final Map<String, dynamic>? errors;
  final bool sessionExpired;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.errors,
    this.sessionExpired = false,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json) => ApiResponse(
    success: json['success'] ?? (json['status'] == 'success'),
    message: json['message'] ?? 'No message from server',
    data: json['data'],
    errors: json['errors'] as Map<String, dynamic>?,
  );
}

/// Main API service – handles all HTTP requests.
class ApiService {
  late final Dio _dio;
  void Function()? onSessionExpired;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await StorageService.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        options.headers['Accept'] = 'application/json';
        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        if (e.response?.statusCode == 401) {
          await StorageService.clearAll();
          onSessionExpired?.call();
        }
        return handler.next(e);
      },
    ));
  }

  // ============================================================
  // AUTH ENDPOINTS
  // ============================================================

  Future<ApiResponse> register(Map<String, dynamic> data) =>
      _post('/v1/auth/register', data: data);

  Future<ApiResponse> registerFundi(Map<String, dynamic> data) async {
    if (data.containsKey('profile_photo') && data['profile_photo'] is String) {
      final file = File(data['profile_photo']);
      final formData = FormData();

      data.forEach((key, value) {
        if (key == 'profile_photo') {
          // skip
        } else if (key == 'service_ids' && value is List) {
          for (var id in value) {
            formData.fields.add(MapEntry('service_ids[]', id.toString()));
          }
        } else if (value != null) {
          formData.fields.add(MapEntry(key, value.toString()));
        }
      });

      formData.files.add(
        MapEntry('profile_photo', await MultipartFile.fromFile(file.path)),
      );

      return _post('/v1/auth/register-fundi', data: formData);
    }
    return _post('/v1/auth/register-fundi', data: data);
  }

  Future<ApiResponse> login(String identifier, String password) =>
      _post('/v1/auth/login', data: {
        'email': identifier,
        'password': password,
      });

  Future<ApiResponse> verifyOtp(String email, String otp, {String? fcmToken}) =>
      _post('/v1/auth/verify-otp', data: {
        'email': email,
        'otp': otp,
        if (fcmToken != null) 'fcm_token': fcmToken,
      });

  Future<ApiResponse> forgotPassword(String email) =>
      _post('/v1/auth/forgot-password', data: {'email': email});

  Future<ApiResponse> resetPassword({
    required String email,
    required String otp,
    required String password,
  }) =>
      _post('/v1/auth/reset-password', data: {
        'email': email,
        'otp': otp,
        'password': password,
        'password_confirmation': password,
      });

  Future<ApiResponse> logout() => _post('/v1/auth/logout');

  Future<ApiResponse> getProfile() => _get('/v1/auth/me');

  Future<ApiResponse> updateProfile(Map<String, dynamic> data) =>
      _put('/v1/auth/profile', data: data);

  Future<ApiResponse> changePassword({
    required String currentPassword,
    required String newPassword,
  }) =>
      _post('/v1/auth/change-password', data: {
        'current_password': currentPassword,
        'password': newPassword,
        'password_confirmation': newPassword,
      });

  Future<ApiResponse> updateLocale(String locale) =>
      _post('/v1/auth/locale', data: {'locale': locale});

  Future<ApiResponse> updateDeviceToken(String token) =>
      _post('/v1/device-token', data: {'token': token});

  Future<ApiResponse> deleteAccount() => _delete('/v1/auth/account');

  Future<ApiResponse> resendOtp(String email) =>
      _post('/v1/auth/resend-otp', data: {'email': email});

  // ============================================================
  // SERVICES
  // ============================================================

  Future<ApiResponse> getServices() => _get('/v1/services');

  // ============================================================
  // FUNDI – PROFILE & SERVICES (V19)
  // ============================================================

  Future<ApiResponse> getMyTechnicianProfile() =>
      _get('/v19/technicians/profile');

  Future<ApiResponse> updateTechnicianProfile(Map<String, dynamic> data) =>
      _put('/v19/technicians/profile', data: data);

  Future<ApiResponse> updateServicePrices(List<Map<String, dynamic>> prices) =>
      _put('/v19/technicians/service-prices', data: {'prices': prices});

  Future<ApiResponse> uploadProfilePhoto(File imageFile) async {
    final formData = FormData.fromMap({
      'profile_photo': await MultipartFile.fromFile(imageFile.path),
    });
    return _post('/v19/technicians/profile/photo', data: formData);
  }

  Future<ApiResponse> updateTechnicianServices(List<int> serviceIds) =>
      _post('/v2/technicians/services', data: {'service_ids': serviceIds});

  // ============================================================
  // FUNDI – HEARTBEAT, LOCATION & ONLINE STATUS (V19)
  // ============================================================

  Future<ApiResponse> sendTechnicianHeartbeat({
    required double latitude,
    required double longitude,
  }) =>
      _post('/v19/technicians/heartbeat', data: {
        'latitude': latitude,
        'longitude': longitude,
      });

  Future<ApiResponse> updateLocation({
    required double latitude,
    required double longitude,
  }) =>
      _post('/v19/technicians/location', data: {
        'latitude': latitude,
        'longitude': longitude,
      });

  Future<ApiResponse> toggleOnlineStatus(bool online) =>
      _patch('/v19/technicians/online-status', data: {'is_online': online});

  // ============================================================
  // V19 – 4-STEP TECHNICIAN REGISTRATION
  // ============================================================

  Future<ApiResponse> registerTechnicianStep1(Map<String, dynamic> data) async {
    if (data.containsKey('profile_photo') && data['profile_photo'] is String) {
      final file = File(data['profile_photo']);
      final formData = FormData();

      data.forEach((key, value) {
        if (key == 'profile_photo') {
          // skip
        } else if (value != null) {
          formData.fields.add(MapEntry(key, value.toString()));
        }
      });

      formData.files.add(
        MapEntry('profile_photo', await MultipartFile.fromFile(file.path)),
      );

      return _post('/v19/technicians/register/step1', data: formData);
    }
    return _post('/v19/technicians/register/step1', data: data);
  }

  Future<ApiResponse> registerTechnicianStep2({
    required int technicianId,
    required String nida,
    required String idDocumentType,
    required File idDocumentImage,
  }) async {
    final formData = FormData.fromMap({
      'technician_id': technicianId,
      'nida': nida,
      'id_document_type': idDocumentType,
      'id_document_image': await MultipartFile.fromFile(idDocumentImage.path),
    });
    return _post('/v19/technicians/register/step2', data: formData);
  }

  Future<ApiResponse> registerTechnicianStep3({
    required int technicianId,
    required String area,
    double? latitude,
    double? longitude,
  }) =>
      _post('/v19/technicians/register/step3', data: {
        'technician_id': technicianId,
        'area': area,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      });

  Future<ApiResponse> registerTechnicianStep4({
    required int technicianId,
    required List<Map<String, dynamic>> services,
  }) =>
      _post('/v19/technicians/register/step4', data: {
        'technician_id': technicianId,
        'services': services,
      });

  Future<ApiResponse> submitTechnicianRegistration(int technicianId) =>
      _post('/v19/technicians/register/submit', data: {
        'technician_id': technicianId,
      });

  Future<ApiResponse> approveTechnicianByAdmin(int technicianId) =>
      _post('/v19/admin/technicians/$technicianId/approve');

  // ============================================================
  // Registration Status (public, no auth)
  // ============================================================

  Future<ApiResponse> getRegistrationStatus(int technicianId) =>
      _get('/technicians/registration-status/$technicianId');

  // ============================================================
  // FUNDI – POSTS (WITH YOUTUBE SUPPORT)
  // ============================================================

  Future<ApiResponse> getMyPosts() => _get('/v5/my-posts');

  Future<ApiResponse> createPost(Map<String, dynamic> data) async {
    final hasImage = data.containsKey('image') &&
        data['image'] is String &&
        data['image'].isNotEmpty;

    if (hasImage) {
      final file = File(data['image']);
      if (await file.exists()) {
        final formData = FormData();
        formData.fields.add(MapEntry('title', data['title'] ?? ''));
        formData.fields.add(MapEntry('content', data['content'] ?? ''));

        if (data.containsKey('youtube_url') &&
            data['youtube_url'] != null &&
            data['youtube_url'].isNotEmpty) {
          formData.fields.add(MapEntry('youtube_url', data['youtube_url']));
        }

        formData.files.add(
          MapEntry('image', await MultipartFile.fromFile(file.path)),
        );

        return _post('/v5/posts', data: formData);
      }
    }

    final Map<String, dynamic> jsonData = {
      'title': data['title'] ?? '',
      'content': data['content'] ?? '',
    };

    if (data.containsKey('youtube_url') &&
        data['youtube_url'] != null &&
        data['youtube_url'].isNotEmpty) {
      jsonData['youtube_url'] = data['youtube_url'];
    }

    return _post('/v5/posts', data: jsonData);
  }

  Future<ApiResponse> updatePost(int id, Map<String, dynamic> data) async {
    final hasImage = data.containsKey('image') &&
        data['image'] is String &&
        data['image'].isNotEmpty;

    if (hasImage) {
      final file = File(data['image']);
      if (await file.exists()) {
        final formData = FormData();
        formData.fields.add(MapEntry('_method', 'PUT'));

        if (data.containsKey('title')) {
          formData.fields.add(MapEntry('title', data['title'] ?? ''));
        }
        if (data.containsKey('content')) {
          formData.fields.add(MapEntry('content', data['content'] ?? ''));
        }

        if (data.containsKey('youtube_url')) {
          formData.fields.add(MapEntry(
            'youtube_url',
            data['youtube_url']?.toString() ?? '',
          ));
        }

        formData.files.add(
          MapEntry('image', await MultipartFile.fromFile(file.path)),
        );

        return _post('/v5/posts/$id', data: formData);
      }
    }

    final Map<String, dynamic> jsonData = {};
    if (data.containsKey('title')) jsonData['title'] = data['title'] ?? '';
    if (data.containsKey('content')) {
      jsonData['content'] = data['content'] ?? '';
    }
    if (data.containsKey('youtube_url')) {
      jsonData['youtube_url'] = data['youtube_url']?.toString() ?? '';
    }

    return _put('/v5/posts/$id', data: jsonData);
  }

  Future<ApiResponse> deletePost(int id) => _delete('/v5/posts/$id');

  // ============================================================
  // FUNDI – PORTFOLIO
  // ============================================================

  Future<ApiResponse> getMyPortfolios() => _get('/v3/portfolios/my');

  Future<ApiResponse> createPortfolio(Map<String, dynamic> data) async {
    if (data.containsKey('image') &&
        data['image'] is String &&
        data['image'].isNotEmpty) {
      final file = File(data['image']);
      if (await file.exists()) {
        final formData = FormData();
        data.forEach((key, value) {
          if (key != 'image') {
            formData.fields.add(MapEntry(key, value?.toString() ?? ''));
          }
        });
        formData.files.add(
          MapEntry('image', await MultipartFile.fromFile(file.path)),
        );
        return _post('/v3/portfolios', data: formData);
      }
    }
    return _post('/v3/portfolios', data: data);
  }

  Future<ApiResponse> updatePortfolio(int id, Map<String, dynamic> data) async {
    if (data.containsKey('image') &&
        data['image'] is String &&
        data['image'].isNotEmpty) {
      final file = File(data['image']);
      if (await file.exists()) {
        final formData = FormData();
        data.forEach((key, value) {
          if (key != 'image') {
            formData.fields.add(MapEntry(key, value?.toString() ?? ''));
          }
        });
        formData.files.add(
          MapEntry('image', await MultipartFile.fromFile(file.path)),
        );
        formData.fields.add(MapEntry('_method', 'PUT'));
        return _post('/v3/portfolios/$id', data: formData);
      }
    }
    return _put('/v3/portfolios/$id', data: data);
  }

  Future<ApiResponse> deletePortfolio(int id) =>
      _delete('/v3/portfolios/$id');

  Future<ApiResponse> updatePortfolioSocialLinks(
      int id,
      Map<String, dynamic> socialLinks,
      ) =>
      _put('/v3/portfolios/$id/social-links', data: socialLinks);

  Future<ApiResponse> getPortfolios({int? technicianId, int page = 1}) =>
      _get('/v3/portfolios', query: {
        'page': page,
        if (technicianId != null) 'technician_id': technicianId,
      });

  Future<ApiResponse> getPortfoliosByTechnician(int technicianId) =>
      _get('/v3/portfolios/technician/$technicianId');

  // ============================================================
  // REQUESTS
  // ============================================================

  Future<ApiResponse> createRequest(Map<String, dynamic> data) =>
      _post('/v4/requests', data: data);

  Future<ApiResponse> getMyRequests() => _get('/v4/my-requests');

  Future<ApiResponse> updateRequestStatus(int id, String status) =>
      _patch('/v4/requests/$id/status', data: {'status': status});

  Future<ApiResponse> cancelRequest(int id) =>
      _delete('/v4/requests/$id/cancel');

  // ============================================================
  // REQUEST TRACKING (Fundi side)
  // ============================================================

  Future<ApiResponse> markOnTheWay(int requestId) =>
      _patch('/v4/requests/$requestId/on-the-way');

  Future<ApiResponse> markArrived(int requestId) =>
      _patch('/v4/requests/$requestId/arrive');

  Future<ApiResponse> getTrackingData(int requestId) =>
      _get('/v4/requests/$requestId/tracking');

  // ============================================================
  // BLOG
  // ============================================================

  Future<ApiResponse> getPosts({int page = 1, int? technicianId}) =>
      _get('/v1/posts', query: {
        'page': page,
        if (technicianId != null) 'technician_id': technicianId,
      });

  Future<ApiResponse> getPostDetail(int id) => _get('/v1/posts/$id');

  Future<ApiResponse> likePost(int postId) =>
      _post('/v5/posts/$postId/like');

  Future<ApiResponse> commentOnPost(int postId, String comment) =>
      _post('/v5/posts/$postId/comments', data: {'content': comment});

  Future<ApiResponse> deleteComment(int id) => _delete('/v5/comments/$id');

  // ============================================================
  // STATIC PAGES
  // ============================================================

  Future<ApiResponse> getAbout() => _get('/v1/about');

  Future<ApiResponse> getFaqs() => _get('/v1/faqs');

  Future<ApiResponse> getTerms() => _get('/v1/terms');

  // ============================================================
  // CONTACT
  // ============================================================

  Future<ApiResponse> sendContactMessage(Map<String, dynamic> data) =>
      _post('/v1/contact', data: data);

  // ============================================================
  // CHAT ENDPOINTS (V14)
  // ============================================================

  Future<ApiResponse> getOrCreateConversation({
    required int customerId,
    required int fundiId,
  }) =>
      _post('/v14/chat/conversation', data: {
        'customer_id': customerId,
        'fundi_id': fundiId,
      });

  Future<ApiResponse> getConversations() => _get('/v14/chat/conversations');

  Future<ApiResponse> getMessages({
    required int conversationId,
    int limit = 50,
    int offset = 0,
  }) =>
      _get('/v14/chat/conversations/$conversationId/messages', query: {
        'limit': limit,
        'offset': offset,
      });

  Future<ApiResponse> sendMessage({
    required int conversationId,
    String? content,
    String? filePath,
    String messageType = 'text',
    int? voiceDuration,
  }) async {
    if (filePath != null && filePath.isNotEmpty) {
      final file = File(filePath);
      if (await file.exists()) {
        final formData = FormData.fromMap({
          'conversation_id': conversationId,
          'content': content ?? '',
          'message_type': messageType,
          if (voiceDuration != null) 'voice_duration': voiceDuration,
          'file': await MultipartFile.fromFile(file.path),
        });
        return _post('/v14/chat/send', data: formData);
      }
    }

    return _post('/v14/chat/send', data: {
      'conversation_id': conversationId,
      'content': content ?? '',
      'message_type': messageType,
      if (voiceDuration != null) 'voice_duration': voiceDuration,
    });
  }

  Future<ApiResponse> markMessageAsRead(int messageId) =>
      _put('/v14/chat/messages/$messageId/read');

  Future<ApiResponse> markConversationAsRead(int conversationId) =>
      _post('/v14/chat/conversations/$conversationId/read');

  Future<ApiResponse> deleteMessage(int messageId) =>
      _delete('/v14/chat/messages/$messageId');

  Future<ApiResponse> addReaction(int messageId, String reaction) =>
      _post('/v14/chat/messages/$messageId/reaction', data: {
        'reaction': reaction,
      });

  Future<ApiResponse> removeReaction(int messageId) =>
      _delete('/v14/chat/messages/$messageId/reaction');

  Future<ApiResponse> getUnreadCount() => _get('/v14/chat/unread');

  Future<ApiResponse> uploadChatFile(File file) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path),
    });
    return _post('/v14/chat/upload', data: formData);
  }

  Future<ApiResponse> sendTypingStatus({
    required int conversationId,
    required bool isTyping,
  }) =>
      _post('/v14/chat/typing', data: {
        'conversation_id': conversationId,
        'is_typing': isTyping,
      });

  Future<ApiResponse> downloadChatFile(int messageId) =>
      _get('/v14/chat/files/$messageId/download', query: {
        'download': 'true',
      });

  Future<String?> downloadChatFileToPath(int messageId, String savePath) async {
    try {
      final token = await StorageService.getToken();
      await _dio.download(
        '/v14/chat/files/$messageId/download?download=true',
        savePath,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          responseType: ResponseType.bytes,
        ),
      );
      return savePath;
    } catch (e) {
      debugPrint('❌ Download file error: $e');
      return null;
    }
  }

  Future<ApiResponse> getFileInfo(int messageId) =>
      _get('/v14/chat/files/$messageId/info');

  Future<ApiResponse> deleteFile(int messageId) =>
      _delete('/v14/chat/files/$messageId');

  Future<ApiResponse> deleteConversation(int conversationId) =>
      _delete('/v14/chat/conversations/$conversationId');

  // ============================================================
  // NOTIFICATION ENDPOINTS (V15) - FIXED QUERY PARAMS
  // ============================================================

  Future<ApiResponse> getNotifications({
    String? excludeType,
    String? type,
  }) =>
      _get('/v15/notifications', query: {
        if (excludeType != null && excludeType.isNotEmpty)
          'exclude_type': excludeType,
        if (type != null && type.isNotEmpty) 'type': type,
      });

  Future<ApiResponse> getUnreadNotificationCount({String? excludeType}) =>
      _get('/v15/notifications/unread-count', query: {
        if (excludeType != null && excludeType.isNotEmpty)
          'exclude_type': excludeType,
      });

  Future<ApiResponse> markNotificationAsRead(String notificationId) =>
      _put('/v15/notifications/$notificationId/read');

  Future<ApiResponse> markAllNotificationsAsRead({String? excludeType}) =>
      _put(
        '/v15/notifications/read-all',
        query: {
          if (excludeType != null && excludeType.isNotEmpty)
            'exclude_type': excludeType,
        },
      );

  Future<ApiResponse> deleteNotification(String notificationId) =>
      _delete('/v15/notifications/$notificationId');

  Future<ApiResponse> clearNotifications({String? excludeType}) =>
      _delete(
        '/v15/notifications/clear',
        query: {
          if (excludeType != null && excludeType.isNotEmpty)
            'exclude_type': excludeType,
        },
      );

  // ============================================================
  // SUBSCRIPTION ENDPOINTS (V16)
  // ============================================================

  Future<ApiResponse> getRateCards() => _get('/v16/rate-cards');

  Future<ApiResponse> getPaymentMethods() => _get('/v16/payment-methods');

  Future<ApiResponse> createSubscription({
    required int rateCardId,
    required int paymentMethodId,
    File? paymentProof,
    String? paymentReference,
    String? notes,
  }) async {
    if (paymentProof != null && await paymentProof.exists()) {
      final formData = FormData();
      formData.fields.addAll([
        MapEntry('rate_card_id', rateCardId.toString()),
        MapEntry('payment_method_id', paymentMethodId.toString()),
        if (paymentReference != null)
          MapEntry('payment_reference', paymentReference),
        if (notes != null) MapEntry('notes', notes),
      ]);
      formData.files.add(
        MapEntry(
          'payment_proof',
          await MultipartFile.fromFile(paymentProof.path),
        ),
      );
      return _post('/v16/subscriptions', data: formData);
    }

    return _post('/v16/subscriptions', data: {
      'rate_card_id': rateCardId,
      'payment_method_id': paymentMethodId,
      if (paymentReference != null) 'payment_reference': paymentReference,
      if (notes != null) 'notes': notes,
    });
  }

  Future<ApiResponse> getMySubscriptions() => _get('/v16/my-subscriptions');

  Future<ApiResponse> getMyInvoices() => _get('/v16/my-invoices');

  Future<ApiResponse> checkSubscriptionStatus() =>
      _get('/v16/check-subscription');

  Future<String?> downloadInvoice(int invoiceId) async {
    try {
      final token = await StorageService.getToken();
      final response = await _dio.download(
        '/v16/invoices/$invoiceId/download',
        '${Directory.systemTemp.path}/invoice_$invoiceId.pdf',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          responseType: ResponseType.bytes,
        ),
      );
      return response.realUri.path;
    } catch (e) {
      debugPrint('❌ Download invoice error: $e');
      return null;
    }
  }

  // ============================================================
  // PRIVACY POLICY (V18)
  // ============================================================

  Future<ApiResponse> getPrivacyPolicy() => _get('/v18/privacy-policy');

  Future<ApiResponse> updatePrivacyPolicy(Map<String, dynamic> data) =>
      _put('/v18/privacy-policy', data: data);

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

  Future<ApiResponse> _put(
      String path, {
        dynamic data,
        Map<String, dynamic>? query,
      }) async {
    try {
      final res = await _dio.put(
        path,
        data: data,
        queryParameters: query,
      );
      return ApiResponse.fromJson(res.data);
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse> _patch(String path, {dynamic data}) async {
    try {
      final res = await _dio.patch(path, data: data);
      return ApiResponse.fromJson(res.data);
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse> _delete(
      String path, {
        Map<String, dynamic>? query,
      }) async {
    try {
      final res = await _dio.delete(
        path,
        queryParameters: query,
      );
      return ApiResponse.fromJson(res.data);
    } catch (e) {
      return _handleError(e);
    }
  }

  ApiResponse _handleError(dynamic error) {
    if (error is DioException) {
      if (error.response?.statusCode == 401) {
        return ApiResponse(
          success: false,
          message: 'Invalid credentials.',
          sessionExpired: true,
        );
      }
      if (error.response?.statusCode == 422 && error.response?.data is Map) {
        return ApiResponse(
          success: false,
          message: error.response!.data['message'] ?? 'Validation failed',
          errors: error.response!.data['errors'],
        );
      }
      if (error.response?.data is Map) {
        return ApiResponse(
          success: false,
          message: error.response!.data['message'] ?? 'Something went wrong',
        );
      }
    }
    return ApiResponse(
      success: false,
      message: 'Network error. Please check your connection.',
    );
  }
}