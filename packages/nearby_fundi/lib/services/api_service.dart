// lib/services/api_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:path/path.dart' as path;
import '../config/app_config.dart';
import 'storage_service.dart';

/// Standard API response wrapper
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

/// Main API service – handles all HTTP requests to the backend.
class ApiService {
  late final Dio _dio;
  void Function()? onSessionExpired;

  Dio get dio => _dio;

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

  // ═══════════════════════════════════════════════════════════════════════
  //  AUTH ENDPOINTS
  // ═══════════════════════════════════════════════════════════════════════

  Future<ApiResponse> register(Map<String, dynamic> data) =>
      _post('/v1/auth/register', data: data);

  Future<ApiResponse> registerFundi(Map<String, dynamic> data) async {
    if (data.containsKey('profile_photo') && data['profile_photo'] is String) {
      final file = File(data['profile_photo']);
      if (await file.exists()) {
        final formData = FormData();
        data.forEach((key, value) {
          if (key == 'profile_photo') return;
          if (key == 'service_ids' && value is List) {
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
    }
    return _post('/v1/auth/register-fundi', data: data);
  }

  Future<ApiResponse> login(String identifier, String password) =>
      _post('/v1/auth/login', data: {'email': identifier, 'password': password});

  Future<ApiResponse> loginWithGoogle(String idToken, {String? fcmToken}) async {
    final body = <String, dynamic>{
      'id_token': idToken,
      if (fcmToken != null && fcmToken.isNotEmpty) 'fcm_token': fcmToken,
    };
    return _post('/v1/auth/google', data: body);
  }

  Future<ApiResponse> verifyOtp(String email, String otp, {String? fcmToken}) =>
      _post('/v1/auth/verify-otp', data: {
        'email': email,
        'otp': otp,
        if (fcmToken != null) 'fcm_token': fcmToken,
      });

  Future<ApiResponse> resendOtp(String email) =>
      _post('/v1/auth/resend-otp', data: {'email': email});

  Future<ApiResponse> forgotPassword(String email) =>
      _post('/v1/auth/forgot-password', data: {'email': email});

  Future<ApiResponse> resetPassword({
    required String email,
    required String otp,
    required String password,
  }) => _post('/v1/auth/reset-password', data: {
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
  }) => _post('/v1/auth/change-password', data: {
    'current_password': currentPassword,
    'password': newPassword,
    'password_confirmation': newPassword,
  });

  Future<ApiResponse> updateLocale(String locale) =>
      _post('/v1/auth/locale', data: {'locale': locale});

  Future<ApiResponse> updateDeviceToken(String token) =>
      _post('/v1/device-token', data: {'token': token});

  Future<ApiResponse> deleteAccount() => _delete('/v1/auth/account');

  // ═══════════════════════════════════════════════════════════════════════
  //  SERVICES WITH CATEGORIES (V11)
  // ═══════════════════════════════════════════════════════════════════════

  Future<ApiResponse> getServicesWithCategories({String locale = 'en'}) =>
      _get('/v11/services', query: {'locale': locale});

  Future<ApiResponse> getServicesGroupedByCategory({String locale = 'en'}) =>
      _get('/v11/services/grouped-by-category', query: {'locale': locale});

  Future<ApiResponse> getServicesByCategory(int categoryId, {String locale = 'en'}) =>
      _get('/v11/services/by-category/$categoryId', query: {'locale': locale});

  Future<ApiResponse> getCategoriesWithServiceCount({String locale = 'en'}) =>
      _get('/v11/categories/with-service-count', query: {'locale': locale});

  Future<ApiResponse> getServicesDropdown({String locale = 'en'}) =>
      _get('/v11/services/dropdown', query: {'locale': locale});

  Future<ApiResponse> getServicesByCategorySlug(String slug, {String locale = 'en'}) =>
      _get('/v11/services/by-category-slug/$slug', query: {'locale': locale});

  // ═══════════════════════════════════════════════════════════════════════
  //  TECHNICIANS BY SERVICE AND CATEGORY (V4)
  // ═══════════════════════════════════════════════════════════════════════

  Future<ApiResponse> getTechniciansByServiceCategory({
    required int serviceId,
    int? categoryId,
    String locale = 'en',
  }) => _get('/v4/technicians/by-service-category', query: {
    'service_id': serviceId,
    if (categoryId != null) 'category_id': categoryId,
    'locale': locale,
  });

  Future<ApiResponse> getRequestServices({String locale = 'en'}) =>
      _get('/v4/request-services', query: {'locale': locale});

  // ═══════════════════════════════════════════════════════════════════════
  //  TECHNICIANS (Customer side) - V1
  // ═══════════════════════════════════════════════════════════════════════

  Future<ApiResponse> getNearbyTechnicians({
    required double lat,
    required double lng,
    int radius = 10,
    int? serviceId,
    int? categoryId,
    String locale = 'en',
    String? search,
  }) => _get('/v1/technicians/nearby', query: {
    'lat': lat,
    'lng': lng,
    'radius': radius,
    if (serviceId != null) 'service_id': serviceId,
    if (categoryId != null) 'category_id': categoryId,
    'locale': locale,
    if (search != null && search.isNotEmpty) 'search': search,
  });

  Future<ApiResponse> searchTechniciansByPlace({
    required String place,
    int? serviceId,
    int? categoryId,
    int radius = 10,
    String locale = 'en',
    String? search,
  }) => _get('/v1/technicians/nearby-by-place', query: {
    'place': place,
    if (serviceId != null) 'service_id': serviceId,
    if (categoryId != null) 'category_id': categoryId,
    'radius': radius,
    'locale': locale,
    if (search != null && search.isNotEmpty) 'search': search,
  });

  Future<ApiResponse> getTechnicianDetail(int id, {String locale = 'en'}) =>
      _get('/v1/technicians/$id', query: {'locale': locale});

  // ═══════════════════════════════════════════════════════════════════════
  //  TECHNICIAN PROFILE (Fundi side) - V2
  // ═══════════════════════════════════════════════════════════════════════

  Future<ApiResponse> getTechnicianProfile() =>
      _get('/v2/technicians/profile');

  Future<ApiResponse> updateTechnicianServices(List<int> serviceIds) =>
      _put('/v2/technicians/services', data: {'service_ids': serviceIds});

  Future<ApiResponse> toggleTechnicianOnline(bool isOnline) =>
      _patch('/v2/technicians/online-status', data: {'is_online': isOnline});

  Future<ApiResponse> updateTechnicianLocation(double latitude, double longitude) =>
      _post('/v2/technicians/location', data: {
        'latitude': latitude,
        'longitude': longitude,
      });

  Future<ApiResponse> sendTechnicianHeartbeat({
    double? latitude,
    double? longitude,
  }) => _post('/v2/technicians/heartbeat', data: {
    if (latitude != null) 'latitude': latitude,
    if (longitude != null) 'longitude': longitude,
  });

  Future<ApiResponse> uploadTechnicianPhoto(File imageFile) async {
    final formData = FormData.fromMap({
      'profile_photo': await MultipartFile.fromFile(
        imageFile.path,
        filename: path.basename(imageFile.path),
      ),
    });
    return _post('/v2/technicians/profile/photo', data: formData);
  }

  Future<ApiResponse> updateServicePrices(Map<String, dynamic> pricesData) =>
      _put('/v2/technicians/service-prices', data: pricesData);

  // ═══════════════════════════════════════════════════════════════════════
  //  PORTFOLIOS (V3)
  // ═══════════════════════════════════════════════════════════════════════

  Future<ApiResponse> getTechnicianPortfolio(int technicianId) =>
      _get('/v3/portfolios/technician/$technicianId');

  Future<ApiResponse> getMyPortfolios() =>
      _get('/v3/portfolios/my');

  Future<ApiResponse> createPortfolio({
    required File imageFile,
    String? description,
    String? instagram,
    String? facebook,
    String? tiktok,
    String? twitter,
    String? telegram,
  }) async {
    final formData = FormData();
    formData.files.add(
      MapEntry('image', await MultipartFile.fromFile(imageFile.path)),
    );
    if (description != null) formData.fields.add(MapEntry('description', description));
    if (instagram != null) formData.fields.add(MapEntry('instagram', instagram));
    if (facebook != null) formData.fields.add(MapEntry('facebook', facebook));
    if (tiktok != null) formData.fields.add(MapEntry('tiktok', tiktok));
    if (twitter != null) formData.fields.add(MapEntry('twitter', twitter));
    if (telegram != null) formData.fields.add(MapEntry('telegram', telegram));
    return _post('/v3/portfolios', data: formData);
  }

  Future<ApiResponse> updatePortfolio(
      int id, {
        File? imageFile,
        String? description,
        String? instagram,
        String? facebook,
        String? tiktok,
        String? twitter,
        String? telegram,
      }) async {
    if (imageFile != null) {
      final formData = FormData();
      formData.fields.add(MapEntry('_method', 'PUT'));
      if (description != null) formData.fields.add(MapEntry('description', description));
      if (instagram != null) formData.fields.add(MapEntry('instagram', instagram));
      if (facebook != null) formData.fields.add(MapEntry('facebook', facebook));
      if (tiktok != null) formData.fields.add(MapEntry('tiktok', tiktok));
      if (twitter != null) formData.fields.add(MapEntry('twitter', twitter));
      if (telegram != null) formData.fields.add(MapEntry('telegram', telegram));
      formData.files.add(
        MapEntry('image', await MultipartFile.fromFile(imageFile.path)),
      );
      return _post('/v3/portfolios/$id', data: formData);
    }
    return _put('/v3/portfolios/$id', data: {
      if (description != null) 'description': description,
      if (instagram != null) 'instagram': instagram,
      if (facebook != null) 'facebook': facebook,
      if (tiktok != null) 'tiktok': tiktok,
      if (twitter != null) 'twitter': twitter,
      if (telegram != null) 'telegram': telegram,
    });
  }

  Future<ApiResponse> deletePortfolio(int id) =>
      _delete('/v3/portfolios/$id');

  Future<ApiResponse> updatePortfolioSocialLinks(int id, Map<String, dynamic> socialLinks) =>
      _put('/v3/portfolios/$id/social-links', data: socialLinks);

  // ═══════════════════════════════════════════════════════════════════════
  //  REQUESTS (Booking) - V4
  // ═══════════════════════════════════════════════════════════════════════

  Future<ApiResponse> createRequest({
    required int technicianId,
    required int serviceId,
    int? categoryId,
    required String description,
    double? latitude,
    double? longitude,
  }) => _post('/v4/requests', data: {
    'technician_id': technicianId,
    'service_id': serviceId,
    if (categoryId != null) 'category_id': categoryId,
    'description': description,
    if (latitude != null) 'latitude': latitude,
    if (longitude != null) 'longitude': longitude,
  });

  Future<ApiResponse> getMyRequests() => _get('/v4/my-requests');

  Future<ApiResponse> updateRequestStatus(int id, String status) =>
      _patch('/v4/requests/$id/status', data: {'status': status});

  Future<ApiResponse> cancelRequest(int id) =>
      _delete('/v4/requests/$id/cancel');

  Future<ApiResponse> markOnTheWay(int requestId) =>
      _patch('/v4/requests/$requestId/on-the-way');

  Future<ApiResponse> markArrived(int requestId) =>
      _patch('/v4/requests/$requestId/arrive');

  Future<ApiResponse> getTrackingData(int requestId) =>
      _get('/tracking/$requestId');

  // ═══════════════════════════════════════════════════════════════════════
  //  BLOG (Posts, Comments, Likes) - V1 & V5
  // ═══════════════════════════════════════════════════════════════════════

  Future<ApiResponse> getPosts({int page = 1, int? technicianId}) =>
      _get('/v1/posts', query: {
        'page': page,
        if (technicianId != null) 'technician_id': technicianId,
      });

  Future<ApiResponse> getPostDetail(int id) => _get('/v1/posts/$id');

  Future<ApiResponse> likePost(int postId) =>
      _post('/v5/posts/$postId/like');

  Future<ApiResponse> commentOnPost(int postId, String comment) =>
      _post('/v5/posts/$postId/comments', data: {'comment': comment});

  Future<ApiResponse> deleteComment(int id) => _delete('/v5/comments/$id');

  Future<ApiResponse> createPost({
    required String title,
    required String content,
    File? imageFile,
    String? youtubeUrl,
  }) async {
    if (imageFile != null && await imageFile.exists()) {
      final formData = FormData.fromMap({
        'title': title,
        'content': content,
        'image': await MultipartFile.fromFile(imageFile.path),
      });
      if (youtubeUrl != null && youtubeUrl.isNotEmpty) {
        formData.fields.add(MapEntry('youtube_url', youtubeUrl));
      }
      return _post('/v5/posts', data: formData);
    }

    final Map<String, dynamic> data = {
      'title': title,
      'content': content,
    };
    if (youtubeUrl != null && youtubeUrl.isNotEmpty) {
      data['youtube_url'] = youtubeUrl;
    }
    return _post('/v5/posts', data: data);
  }

  Future<ApiResponse> updatePost(
      int id, {
        String? title,
        String? content,
        File? imageFile,
        String? youtubeUrl,
      }) async {
    if (imageFile != null && await imageFile.exists()) {
      final formData = FormData.fromMap({
        '_method': 'PUT',
        if (title != null) 'title': title,
        if (content != null) 'content': content,
        'image': await MultipartFile.fromFile(imageFile.path),
      });
      if (youtubeUrl != null) {
        formData.fields.add(MapEntry('youtube_url', youtubeUrl));
      } else {
        formData.fields.add(MapEntry('youtube_url', ''));
      }
      return _post('/v5/posts/$id', data: formData);
    }

    final Map<String, dynamic> data = {
      '_method': 'PUT',
      if (title != null) 'title': title,
      if (content != null) 'content': content,
    };
    if (youtubeUrl != null) {
      data['youtube_url'] = youtubeUrl;
    } else {
      data['youtube_url'] = '';
    }
    return _post('/v5/posts/$id', data: data);
  }

  Future<ApiResponse> deletePost(int id) => _delete('/v5/posts/$id');

  // ═══════════════════════════════════════════════════════════════════════
  //  STATIC PAGES - V1 & V6
  // ═══════════════════════════════════════════════════════════════════════

  Future<ApiResponse> getAbout() => _get('/v1/about');
  Future<ApiResponse> getFaqs() => _get('/v1/faqs');
  Future<ApiResponse> getTerms() => _get('/v1/terms');

  // ═══════════════════════════════════════════════════════════════════════
  //  CONTACT
  // ═══════════════════════════════════════════════════════════════════════

  Future<ApiResponse> sendContactMessage(Map<String, dynamic> data) =>
      _post('/v1/contact', data: data);

  // ═══════════════════════════════════════════════════════════════════════
  //  CHAT ENDPOINTS (V14)
  // ═══════════════════════════════════════════════════════════════════════

  Future<ApiResponse> getOrCreateConversation({
    required int customerId,
    required int fundiId,
  }) => _post('/v14/chat/conversation', data: {
    'customer_id': customerId,
    'fundi_id': fundiId,
  });

  Future<ApiResponse> getConversations() => _get('/v14/chat/conversations');

  Future<ApiResponse> getMessages({
    required int conversationId,
    int limit = 50,
    int offset = 0,
  }) => _get('/v14/chat/conversations/$conversationId/messages', query: {
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

  Future<ApiResponse> uploadChatFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('File does not exist: $filePath');
    }
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path),
    });
    return _post('/v14/chat/upload', data: formData);
  }

  Future<ApiResponse> sendTypingStatus({
    required int conversationId,
    required bool isTyping,
  }) => _post('/v14/chat/typing', data: {
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

  Future<ApiResponse> deleteChatFile(int messageId) =>
      _delete('/v14/chat/files/$messageId');

  Future<ApiResponse> deleteConversation(int conversationId) =>
      _delete('/v14/chat/conversations/$conversationId');

// ═══════════════════════════════════════════════════════════════════════
//  NOTIFICATION ENDPOINTS (V15) - FIXED QUERY PARAMS
// ═══════════════════════════════════════════════════════════════════════

  Future<ApiResponse> getNotifications({String? excludeType, String? type}) =>
      _get('/v15/notifications', query: {
        if (excludeType != null && excludeType.isNotEmpty) 'exclude_type': excludeType,
        if (type != null && type.isNotEmpty) 'type': type,
      });

  Future<ApiResponse> getUnreadNotificationCount({String? excludeType}) =>
      _get('/v15/notifications/unread-count', query: {
        if (excludeType != null && excludeType.isNotEmpty) 'exclude_type': excludeType,
      });

  Future<ApiResponse> markNotificationAsRead(String notificationId) =>
      _put('/v15/notifications/$notificationId/read');

  Future<ApiResponse> markAllNotificationsAsRead({String? excludeType}) =>
      _put('/v15/notifications/read-all', query: {
        if (excludeType != null && excludeType.isNotEmpty) 'exclude_type': excludeType,
      });

  Future<ApiResponse> deleteNotification(String notificationId) =>
      _delete('/v15/notifications/$notificationId');

  Future<ApiResponse> clearNotifications({String? excludeType}) =>
      _delete('/v15/notifications/clear', query: {
        if (excludeType != null && excludeType.isNotEmpty) 'exclude_type': excludeType,
      });

  // ═══════════════════════════════════════════════════════════════════════
  //  SUBSCRIPTION ENDPOINTS (V16)
  // ═══════════════════════════════════════════════════════════════════════

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
        if (paymentReference != null) MapEntry('payment_reference', paymentReference),
        if (notes != null) MapEntry('notes', notes),
      ]);
      formData.files.add(
        MapEntry('payment_proof', await MultipartFile.fromFile(paymentProof.path)),
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

  // ═══════════════════════════════════════════════════════════════════════
  //  SERVICE CATEGORIES (V17)
  // ═══════════════════════════════════════════════════════════════════════

  Future<ApiResponse> getServiceCategories({String locale = 'en'}) =>
      _get('/v17/service-categories', query: {'locale': locale});

  Future<ApiResponse> getServiceCategory(int id, {String locale = 'en'}) =>
      _get('/v17/service-categories/$id', query: {'locale': locale});

  Future<ApiResponse> getServiceCategoryBySlug(String slug, {String locale = 'en'}) =>
      _get('/v17/service-categories/slug/$slug', query: {'locale': locale});

  Future<ApiResponse> getCategoriesDropdown({String locale = 'en'}) =>
      _get('/v17/service-categories/dropdown/by-id', query: {'locale': locale});

  Future<ApiResponse> getActiveCategoriesDropdown({String locale = 'en'}) =>
      _get('/v17/service-categories/dropdown/active', query: {'locale': locale});

  // ═══════════════════════════════════════════════════════════════════════
  //  REVIEWS & PRIVACY POLICY (V18)
  // ═══════════════════════════════════════════════════════════════════════

  Future<ApiResponse> getTechnicianReviews(int technicianId) =>
      _get('/v18/technicians/$technicianId/reviews');

  Future<ApiResponse> submitReview({
    required int requestId,
    required int rating,
    String? comment,
  }) => _post('/v18/reviews', data: {
    'request_id': requestId,
    'rating': rating,
    if (comment != null) 'comment': comment,
  });

  Future<ApiResponse> getPrivacyPolicy() =>
      _get('/v18/privacy-policy');


  // ═══════════════════════════════════════════════════════════════════════
  //  PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════════════

  void _logRequest(String method, String path, {Map<String, dynamic>? query}) {
    if (kDebugMode) {
      debugPrint('➡️  $method $path${query != null ? ' query=$query' : ''}');
    }
  }

  void _logSuccess(String method, String path, Response res) {
    if (kDebugMode) {
      debugPrint('✅ $method $path -> ${res.statusCode}');
    }
  }

  void _logFailure(String method, String path, dynamic error) {
    if (!kDebugMode) return;
    debugPrint('❌ $method $path failed: $error');
    if (error is DioException) {
      debugPrint('   type: ${error.type}');
      debugPrint('   status: ${error.response?.statusCode}');
      final data = error.response?.data;
      if (data is Map) {
        debugPrint('   body(json): $data');
      } else if (data is String) {
        final preview = data.length > 500 ? '${data.substring(0, 500)}…' : data;
        debugPrint('   body(non-json, first 500 chars): $preview');
      } else if (data != null) {
        debugPrint('   body(unexpected type ${data.runtimeType}): $data');
      } else {
        debugPrint('   body: null');
      }
    }
  }

  ApiResponse _parseResponse(String method, String path, Response res) {
    final data = res.data;

    if (data is Map<String, dynamic>) {
      return ApiResponse.fromJson(data);
    }

    if (data is String) {
      if (kDebugMode) {
        final preview = data.length > 800 ? '${data.substring(0, 800)}…' : data;
        debugPrint('⚠️  $method $path returned 200 but body was a String');
        debugPrint('   raw body (first 800 chars): $preview');
      }
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map<String, dynamic>) {
          if (kDebugMode) {
            debugPrint('   ↳ recovered: body WAS valid JSON');
          }
          return ApiResponse.fromJson(decoded);
        }
      } catch (_) {}
    }

    return ApiResponse(
      success: false,
      message: 'Server returned an unexpected (non-JSON) response.',
    );
  }

  Future<ApiResponse> _get(String path, {Map<String, dynamic>? query}) async {
    _logRequest('GET', path, query: query);
    try {
      final res = await _dio.get(path, queryParameters: query);
      _logSuccess('GET', path, res);
      return _parseResponse('GET', path, res);
    } catch (e) {
      _logFailure('GET', path, e);
      return _handleError(e);
    }
  }

  Future<ApiResponse> _post(String path, {dynamic data, Map<String, dynamic>? query}) async {
    _logRequest('POST', path, query: query);
    try {
      final res = await _dio.post(path, data: data, queryParameters: query);
      _logSuccess('POST', path, res);
      return _parseResponse('POST', path, res);
    } catch (e) {
      _logFailure('POST', path, e);
      return _handleError(e);
    }
  }

  Future<ApiResponse> _put(String path, {dynamic data, Map<String, dynamic>? query}) async {
    _logRequest('PUT', path, query: query);
    try {
      final res = await _dio.put(path, data: data, queryParameters: query);
      _logSuccess('PUT', path, res);
      return _parseResponse('PUT', path, res);
    } catch (e) {
      _logFailure('PUT', path, e);
      return _handleError(e);
    }
  }

  Future<ApiResponse> _patch(String path, {dynamic data, Map<String, dynamic>? query}) async {
    _logRequest('PATCH', path, query: query);
    try {
      final res = await _dio.patch(path, data: data, queryParameters: query);
      _logSuccess('PATCH', path, res);
      return _parseResponse('PATCH', path, res);
    } catch (e) {
      _logFailure('PATCH', path, e);
      return _handleError(e);
    }
  }

  Future<ApiResponse> _delete(String path, {Map<String, dynamic>? query}) async {
    _logRequest('DELETE', path, query: query);
    try {
      final res = await _dio.delete(path, queryParameters: query);
      _logSuccess('DELETE', path, res);
      return _parseResponse('DELETE', path, res);
    } catch (e) {
      _logFailure('DELETE', path, e);
      return _handleError(e);
    }
  }

  ApiResponse _handleError(dynamic error) {
    if (error is DioException) {
      if (error.response?.statusCode == 401) {
        return ApiResponse(
          success: false,
          message: 'Invalid Credentials.',
          sessionExpired: true,
        );
      }

      if (error.response?.statusCode == 422 && error.response?.data is Map) {
        final data = error.response!.data as Map<String, dynamic>;
        String errorMessage = data['message'] ?? 'Validation failed';

        if (data.containsKey('errors') && data['errors'] is Map) {
          final errors = data['errors'] as Map<String, dynamic>;
          final firstError = errors.values.first;
          if (firstError is List && firstError.isNotEmpty) {
            errorMessage = firstError.first.toString();
          }
        }
        return ApiResponse(
          success: false,
          message: errorMessage,
          errors: data['errors'] as Map<String, dynamic>?,
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