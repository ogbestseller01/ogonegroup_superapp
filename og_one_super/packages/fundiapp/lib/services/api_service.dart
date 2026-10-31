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

/// Main API service — handles all HTTP requests across the application.
///
/// Full method index (use these numbers for reference):
///   #1   register                        #52  getPortfoliosByTechnician
///   #2   registerFundi                   #53  createRequest
///   #3   login                           #54  getMyRequests
///   #4   verifyOtp                       #55  updateRequestStatus
///   #5   resendOtp                       #56  cancelRequest
///   #6   forgotPassword                  #57  markOnTheWay
///   #7   resetPassword                   #58  markArrived
///   #8   logout                          #59  getTrackingData
///   #9   getProfile                      #60  getPosts
///   #10  updateProfile                   #61  getPostDetail
///   #11  changePassword                  #62  likePost
///   #12  updateLocale                    #63  commentOnPost
///   #13  updateDeviceToken               #64  deleteComment
///   #14  updateFcmDeviceToken            #65  getAbout
///   #15  deleteAccount                   #66  getFaqs
///   #16  getServices                     #67  getTerms
///   #17  getMyTechnicianProfile          #68  sendFeedback
///   #18  updateTechnicianProfile         #69  getOrCreateConversation
///   #19  uploadProfilePhoto              #70  getConversations
///   #20  updateTechnicianServices        #71  getMessages
///   #21  sendTechnicianHeartbeat         #72  sendMessage
///   #22  updateLocation                  #73  markMessageAsRead
///   #23  registerTechnicianStep1         #74  markConversationAsRead
///   #24  verifyDraftOtp                  #75  deleteMessage
///   #25  resendDraftOtp                  #76  addReaction
///   #26  registerTechnicianStep2         #77  removeReaction
///   #27  registerTechnicianStep3         #78  getUnreadCount
///   #28  registerTechnicianStep4         #79  uploadChatFile
///   #29  registerTechnicianStep5         #80  sendTypingStatus
///   #30  submitTechnicianRegistration    #81  downloadChatFile
///   #31  getRegistrationStatus           #82  downloadChatFileToPath
///   #32  getMyRegistrationStatus         #83  getFileInfo
///   #33  getPublicTechnicians            #84  deleteFile
///   #34  getTechnicianDetail             #85  deleteConversation
///   #35  getPublicPortfoliosByTechnician #86  getNotifications
///   #36  getAdminTechnicians             #87  getUnreadNotificationCount
///   #37  getPendingTechnicians           #88  markNotificationAsRead
///   #38  getApprovedTechnicians          #89  markAllNotificationsAsRead
///   #39  getTechnicianBiometrics         #90  deleteNotification
///   #40  approveTechnicianByAdmin        #91  clearNotifications
///   #41  verifyTechnician                #92  getRateCards
///   #42  getMyPosts                      #93  getPaymentMethods
///   #43  createPost                      #94  createSubscription
///   #44  updatePost                      #95  getMySubscriptions
///   #45  deletePost                      #96  getMyInvoices
///   #46  getMyPortfolios                 #97  checkSubscriptionStatus
///   #47  createPortfolio                 #98  downloadInvoice
///   #48  updatePortfolio                 #99  getPrivacyPolicy
///   #49  deletePortfolio                 #100 updatePrivacyPolicy
///   #50  updatePortfolioSocialLinks      #101 searchNearbyFundis
///   #51  getPortfolios                   #102 searchNearbyByPlace
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
        if (!options.headers.containsKey('Authorization')) {
          final token = await StorageService.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        }
        options.headers['Accept'] = 'application/json';
        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        final path = e.requestOptions.path;
        final isRegistrationCall = path.contains('/technicians/register/');

        if (e.response?.statusCode == 401 && !isRegistrationCall) {
          await StorageService.clearAuth();
          onSessionExpired?.call();
        }
        return handler.next(e);
      },
    ));
  }

  // ============================================================
  // SECTION 1: AUTHENTICATION
  // ============================================================

  Future<ApiResponse> register(Map<String, dynamic> data) =>
      _post('/v1/auth/register', data: data);

  Future<ApiResponse> registerFundi(Map<String, dynamic> data) async {
    if (data.containsKey('profile_photo') && data['profile_photo'] is String) {
      final file = File(data['profile_photo']);
      final formData = FormData();
      data.forEach((key, value) {
        if (key != 'profile_photo') {
          if (key == 'service_ids' && value is List) {
            for (var id in value) {
              formData.fields.add(MapEntry('service_ids[]', id.toString()));
            }
          } else if (value != null) {
            formData.fields.add(MapEntry(key, value.toString()));
          }
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

  Future<ApiResponse> verifyOtp(String identifier, String otp, {String? fcmToken}) =>
      _post('/v1/auth/verify-otp', data: {
        'identifier': identifier,
        'otp': otp,
        if (fcmToken != null) 'fcm_token': fcmToken,
      });

  Future<ApiResponse> resendOtp(String identifier) =>
      _post('/v1/auth/resend-otp', data: {'identifier': identifier});

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

  Future<ApiResponse> updateFcmDeviceToken(String fcmDeviceToken) =>
      _post('/v1/device/fcm-token', data: {'fcm_device_token': fcmDeviceToken});

  Future<ApiResponse> deleteAccount() => _delete('/v1/auth/account');

  // ============================================================
  // SECTION 2: SERVICES CATALOG
  // ============================================================

  Future<ApiResponse> getServices({String locale = 'en'}) async {
    try {
      final res = await _dio.get(
        '/v1/services',
        options: Options(headers: {'Accept-Language': locale}),
      );
      return ApiResponse.fromJson(res.data);
    } catch (e) {
      return _handleError(e);
    }
  }

  // ============================================================
  // SECTION 3: TECHNICIAN PROFILE & SERVICES
  // ============================================================

  Future<ApiResponse> getMyTechnicianProfile() => _get('/v19/technicians/profile');

  Future<ApiResponse> updateTechnicianProfile(Map<String, dynamic> data) =>
      _put('/v19/technicians/profile', data: data);

  Future<ApiResponse> uploadProfilePhoto(File imageFile) async {
    final formData = FormData.fromMap({
      'profile_photo': await MultipartFile.fromFile(imageFile.path),
    });
    return _post('/v19/technicians/profile/photo', data: formData);
  }

  Future<ApiResponse> updateTechnicianServices(List<int> serviceIds) =>
      _post('/v19/technicians/services', data: {'services': serviceIds});

  // ============================================================
  // SECTION 4: LOCATION & HEARTBEAT
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

  // ============================================================
  // SECTION 5: 6-STEP TECHNICIAN REGISTRATION
  // ============================================================

  Future<ApiResponse> registerTechnicianStep1(
      Map<String, dynamic> data, {
        String? fcmDeviceToken,
      }) async {
    final payload = Map<String, dynamic>.from(data);
    if (fcmDeviceToken != null && fcmDeviceToken.isNotEmpty) {
      payload['fcm_device_token'] = fcmDeviceToken;
    }

    final hasPhoto = payload['profile_photo'] is String &&
        (payload['profile_photo'] as String).isNotEmpty;

    if (hasPhoto) {
      final file = File(payload['profile_photo'] as String);
      final formData = FormData();

      payload.forEach((key, value) {
        if (key == 'profile_photo' || value == null) return;

        if (value is List) {
          for (final item in value) {
            formData.fields.add(MapEntry('$key[]', item.toString()));
          }
        } else {
          formData.fields.add(MapEntry(key, value.toString()));
        }
      });

      formData.files.add(
        MapEntry('profile_photo', await MultipartFile.fromFile(file.path)),
      );
      return _post('/v19/technicians/register/step1', data: formData);
    }

    return _post('/v19/technicians/register/step1', data: payload);
  }

  Future<ApiResponse> verifyDraftOtp({
    required String identifier,
    required String otp,
    int? draftId,
  }) =>
      _post('/v19/technicians/register/verify-otp', data: {
        'identifier': identifier,
        'otp': otp,
        if (draftId != null) 'draft_id': draftId,
      });

  Future<ApiResponse> resendDraftOtp({
    required String identifier,
    int? draftId,
  }) =>
      _post('/v19/technicians/register/resend-otp', data: {
        'identifier': identifier,
        if (draftId != null) 'draft_id': draftId,
      });

  Future<ApiResponse> registerTechnicianStep2({
    required String registrationToken,
    required String nida,
    required String idDocumentType,
    File? idDocumentImage,
  }) async {
    final formData = FormData();
    formData.fields.add(MapEntry('nida', nida));
    formData.fields.add(MapEntry('id_document_type', idDocumentType));
    if (idDocumentImage != null) {
      formData.files.add(MapEntry(
        'id_document_image',
        await MultipartFile.fromFile(idDocumentImage.path),
      ));
    }
    return _post(
      '/v19/technicians/register/step2',
      data: formData,
      headers: {'Authorization': 'Bearer $registrationToken'},
    );
  }

  Future<ApiResponse> registerTechnicianStep3({
    required String registrationToken,
    required String fingerprintData,
  }) =>
      _post(
        '/v19/technicians/register/step3',
        data: {'fingerprint_data': fingerprintData},
        headers: {'Authorization': 'Bearer $registrationToken'},
      );

  Future<ApiResponse> registerTechnicianStep4({
    required String registrationToken,
    required String faceData,
  }) =>
      _post(
        '/v19/technicians/register/step4',
        data: {'face_data': faceData},
        headers: {'Authorization': 'Bearer $registrationToken'},
      );

  Future<ApiResponse> registerTechnicianStep5({
    required String registrationToken,
    required String nextOfKinName,
    required String nextOfKinPhone,
    required String nextOfKinRelationship,
  }) =>
      _post(
        '/v19/technicians/register/step5',
        data: {
          'next_of_kin_name': nextOfKinName,
          'next_of_kin_phone': nextOfKinPhone,
          'next_of_kin_relationship': nextOfKinRelationship,
        },
        headers: {'Authorization': 'Bearer $registrationToken'},
      );

  Future<ApiResponse> submitTechnicianRegistration({
    required String registrationToken,
    String? fcmDeviceToken,
  }) =>
      _post(
        '/v19/technicians/register/step6',
        data: {
          if (fcmDeviceToken != null && fcmDeviceToken.isNotEmpty)
            'fcm_device_token': fcmDeviceToken,
        },
        headers: {'Authorization': 'Bearer $registrationToken'},
      );

  Future<ApiResponse> getRegistrationStatus(int id) =>
      _get('/v19/technicians/register/status/$id');

  Future<ApiResponse> getMyRegistrationStatus() =>
      _get('/v19/technicians/my-registration-status');

  // ============================================================
  // SECTION 6: TECHNICIAN DIRECTORY & ADMIN
  // ============================================================

  Future<ApiResponse> getPublicTechnicians({
    int page = 1,
    int perPage = 15,
    int? serviceId,
    String? search,
  }) =>
      _get('/v1/technicians', query: {
        'page': page,
        'per_page': perPage,
        if (serviceId != null) 'service_id': serviceId,
        if (search != null && search.isNotEmpty) 'search': search,
      });

  Future<ApiResponse> getTechnicianDetail(int id) => _get('/v1/technicians/$id');

  Future<ApiResponse> getPublicPortfoliosByTechnician(int technicianId) =>
      _get('/v1/portfolios/$technicianId');

  Future<ApiResponse> getAdminTechnicians({
    int page = 1,
    int perPage = 15,
    String? search,
  }) =>
      _get('/v20/admin/technicians', query: {
        'page': page,
        'per_page': perPage,
        if (search != null && search.isNotEmpty) 'search': search,
      });

  Future<ApiResponse> getPendingTechnicians({
    int page = 1,
    int perPage = 15,
    String? search,
  }) =>
      _get('/v20/admin/technicians/pending', query: {
        'page': page,
        'per_page': perPage,
        if (search != null && search.isNotEmpty) 'search': search,
      });

  Future<ApiResponse> getApprovedTechnicians({
    int page = 1,
    int perPage = 15,
    String? search,
  }) =>
      _get('/v20/admin/technicians/approved', query: {
        'page': page,
        'per_page': perPage,
        if (search != null && search.isNotEmpty) 'search': search,
      });

  Future<ApiResponse> getTechnicianBiometrics(int technicianId) =>
      _get('/v20/admin/technicians/$technicianId/biometrics');

  Future<ApiResponse> approveTechnicianByAdmin(int technicianId) =>
      _post('/v19/admin/technicians/$technicianId/approve');

  Future<ApiResponse> verifyTechnician(int technicianId) =>
      _patch('/v2/technicians/$technicianId/verify');

  // ============================================================
  // SECTION 7: POSTS & FEED
  // ============================================================

  // [API #42] GET /v5/my-posts
  Future<ApiResponse> getMyPosts() => _get('/v5/my-posts');

  // [API #43] POST /v5/posts
  Future<ApiResponse> createPost(Map<String, dynamic> data) async {
    final formData = FormData();

    // Add Video
    if (data['video'] != null && data['video'] is String && data['video'].isNotEmpty) {
      final file = File(data['video']);
      if (await file.exists()) {
        formData.files.add(MapEntry(
          'video',
          await MultipartFile.fromFile(file.path, filename: file.path.split('/').last),
        ));
      }
    }

    // Add Images
    if (data['images'] != null && data['images'] is List) {
      for (final path in data['images']) {
        if (path is String && path.isNotEmpty) {
          final file = File(path);
          if (await file.exists()) {
            formData.files.add(MapEntry(
              'images[]',
              await MultipartFile.fromFile(file.path, filename: file.path.split('/').last),
            ));
          }
        }
      }
    }

    return _post('/v5/posts', data: formData);
  }

  // [API #44] POST /v5/posts/{id} (with _method=PUT)
  Future<ApiResponse> updatePost(int id, Map<String, dynamic> data) async {
    final formData = FormData();
    formData.fields.add(const MapEntry('_method', 'PUT'));

    // Add Video
    if (data['video'] != null && data['video'] is String && data['video'].isNotEmpty) {
      final file = File(data['video']);
      if (await file.exists()) {
        formData.files.add(MapEntry(
          'video',
          await MultipartFile.fromFile(file.path, filename: file.path.split('/').last),
        ));
      }
    }

    // Remove Video
    if (data['remove_video'] == true) {
      formData.fields.add(const MapEntry('remove_video', '1'));
    }

    // Add Images
    if (data['images'] != null && data['images'] is List) {
      for (final path in data['images']) {
        if (path is String && path.isNotEmpty) {
          final file = File(path);
          if (await file.exists()) {
            formData.files.add(MapEntry(
              'images[]',
              await MultipartFile.fromFile(file.path, filename: file.path.split('/').last),
            ));
          }
        }
      }
    }

    // Keep Images
    if (data['keep_images'] != null && data['keep_images'] is List) {
      for (final path in data['keep_images']) {
        formData.fields.add(MapEntry('keep_images[]', path.toString()));
      }
      formData.fields.add(const MapEntry('images_managed', '1'));
    }

    return _post('/v5/posts/$id', data: formData);
  }

  // [API #45] DELETE /v5/posts/{id}
  Future<ApiResponse> deletePost(int id) => _delete('/v5/posts/$id');

  // ============================================================
  // SECTION 8: PORTFOLIO
  // ============================================================

  Future<ApiResponse> getMyPortfolios() => _get('/v3/portfolios/my');

  Future<ApiResponse> createPortfolio(List<String> imagePaths) async {
    final formData = FormData();
    for (final path in imagePaths) {
      final file = File(path);
      if (await file.exists()) {
        formData.files.add(MapEntry(
          'images[]',
          await MultipartFile.fromFile(file.path, filename: file.path.split('/').last),
        ));
      }
    }
    return _post('/v3/portfolios', data: formData);
  }

  Future<ApiResponse> updatePortfolio(
      int id, {
        List<String>? newImagePaths,
        List<int>? deleteImageIds,
      }) async {
    final formData = FormData();
    formData.fields.add(const MapEntry('_method', 'PUT'));

    if (newImagePaths != null && newImagePaths.isNotEmpty) {
      for (final path in newImagePaths) {
        final file = File(path);
        if (await file.exists()) {
          formData.files.add(MapEntry(
            'images[]',
            await MultipartFile.fromFile(file.path, filename: file.path.split('/').last),
          ));
        }
      }
    }

    if (deleteImageIds != null && deleteImageIds.isNotEmpty) {
      for (final imgId in deleteImageIds) {
        formData.fields.add(MapEntry('delete_image_ids[]', imgId.toString()));
      }
    }

    return _post('/v3/portfolios/$id', data: formData);
  }

  Future<ApiResponse> deletePortfolio(int id) => _delete('/v3/portfolios/$id');

  Future<ApiResponse> updatePortfolioSocialLinks(int id, Map<String, dynamic> socialLinks) =>
      _put('/v3/portfolios/$id/social-links', data: socialLinks);

  Future<ApiResponse> getPortfolios({int? technicianId, int page = 1}) =>
      _get('/v3/portfolios', query: {
        'page': page,
        if (technicianId != null) 'technician_id': technicianId,
      });

  Future<ApiResponse> getPortfoliosByTechnician(int technicianId) =>
      _get('/v3/portfolios/technician/$technicianId');

  // ============================================================
  // SECTION 9: SERVICE REQUESTS & TRACKING
  // ============================================================

  Future<ApiResponse> createRequest(Map<String, dynamic> data) =>
      _post('/v4/requests', data: data);

  Future<ApiResponse> getMyRequests() => _get('/v4/my-requests');

  Future<ApiResponse> updateRequestStatus(int id, String status) =>
      _patch('/v4/requests/$id/status', data: {'status': status});

  Future<ApiResponse> cancelRequest(int id) => _delete('/v4/requests/$id/cancel');

  Future<ApiResponse> markOnTheWay(int requestId) =>
      _patch('/v4/requests/$requestId/on-the-way');

  Future<ApiResponse> markArrived(int requestId) =>
      _patch('/v4/requests/$requestId/arrive');

  Future<ApiResponse> getTrackingData(int requestId) =>
      _get('/v4/requests/$requestId/tracking');

  // ============================================================
  // SECTION 10: PUBLIC BLOG & SOCIAL
  // ============================================================

  Future<ApiResponse> getPosts({int page = 1, int? technicianId}) =>
      _get('/v1/posts', query: {
        'page': page,
        if (technicianId != null) 'technician_id': technicianId,
      });

  Future<ApiResponse> getPostDetail(int id) => _get('/v1/posts/$id');

  Future<ApiResponse> likePost(int postId) => _post('/v5/posts/$postId/like');

  Future<ApiResponse> commentOnPost(int postId, String comment) =>
      _post('/v5/posts/$postId/comments', data: {'content': comment});

  Future<ApiResponse> deleteComment(int id) => _delete('/v5/comments/$id');

  // ============================================================
  // SECTION 11: STATIC PAGES
  // ============================================================

  Future<ApiResponse> getAbout() => _get('/v1/about');
  Future<ApiResponse> getFaqs() => _get('/v1/faqs');
  Future<ApiResponse> getTerms() => _get('/v1/terms');

  Future<ApiResponse> sendFeedback(Map<String, dynamic> data) =>
      _post('/v23/feedback', data: data);

  // ============================================================
  // SECTION 12: CHAT & MESSAGING
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
      _post('/v14/chat/messages/$messageId/reaction', data: {'reaction': reaction});

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
      _get('/v14/chat/files/$messageId/download', query: {'download': 'true'});

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
  // SECTION 13: NOTIFICATIONS
  // ============================================================

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

  // ============================================================
  // SECTION 14: SUBSCRIPTIONS & INVOICING
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
  Future<ApiResponse> checkSubscriptionStatus() => _get('/v16/check-subscription');

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
  // SECTION 15: PRIVACY POLICY
  // ============================================================

  Future<ApiResponse> getPrivacyPolicy() => _get('/v18/privacy-policy');

  Future<ApiResponse> updatePrivacyPolicy(Map<String, dynamic> data) =>
      _put('/v18/privacy-policy', data: data);

  // ============================================================
  // SECTION 16: NEARBY SEARCH
  // ============================================================

  Future<ApiResponse> searchNearbyFundis({
    required double lat,
    required double lng,
    int radius = 12,
    int? serviceId,
    int? categoryId,
    String? search,
    int perPage = 15,
  }) =>
      _get('/fundis/nearby', query: {
        'lat': lat,
        'lng': lng,
        'radius': radius,
        if (serviceId != null) 'service_id': serviceId,
        if (categoryId != null) 'category_id': categoryId,
        if (search != null && search.isNotEmpty) 'search': search,
        'per_page': perPage,
      });

  Future<ApiResponse> searchNearbyByPlace({
    required String place,
    int radius = 20,
    int? serviceId,
    int? categoryId,
    String? search,
    int perPage = 15,
  }) =>
      _get('/fundis/nearby-by-place', query: {
        'place': place,
        'radius': radius,
        if (serviceId != null) 'service_id': serviceId,
        if (categoryId != null) 'category_id': categoryId,
        if (search != null && search.isNotEmpty) 'search': search,
        'per_page': perPage,
      });

  // ============================================================
  // PRIVATE HTTP HELPERS
  // ============================================================

  Future<ApiResponse> _get(
      String path, {
        Map<String, dynamic>? query,
        Map<String, String>? headers,
      }) async {
    try {
      final res = await _dio.get(
        path,
        queryParameters: query,
        options: (headers != null && headers.isNotEmpty) ? Options(headers: headers) : null,
      );
      return ApiResponse.fromJson(res.data);
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse> _post(
      String path, {
        dynamic data,
        Map<String, String>? headers,
      }) async {
    try {
      final res = await _dio.post(
        path,
        data: data,
        options: (headers != null && headers.isNotEmpty) ? Options(headers: headers) : null,
      );
      return ApiResponse.fromJson(res.data);
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse> _put(
      String path, {
        dynamic data,
        Map<String, dynamic>? query,
        Map<String, String>? headers,
      }) async {
    try {
      final res = await _dio.put(
        path,
        data: data,
        queryParameters: query,
        options: (headers != null && headers.isNotEmpty) ? Options(headers: headers) : null,
      );
      return ApiResponse.fromJson(res.data);
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse> _patch(
      String path, {
        dynamic data,
        Map<String, String>? headers,
      }) async {
    try {
      final res = await _dio.patch(
        path,
        data: data,
        options: (headers != null && headers.isNotEmpty) ? Options(headers: headers) : null,
      );
      return ApiResponse.fromJson(res.data);
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse> _delete(
      String path, {
        Map<String, dynamic>? query,
        Map<String, String>? headers,
      }) async {
    try {
      final res = await _dio.delete(
        path,
        queryParameters: query,
        options: (headers != null && headers.isNotEmpty) ? Options(headers: headers) : null,
      );
      return ApiResponse.fromJson(res.data);
    } catch (e) {
      return _handleError(e);
    }
  }

  ApiResponse _handleError(dynamic error) {
    if (error is DioException) {
      final path = error.requestOptions.path;
      final isRegistrationCall = path.contains('/technicians/register/');

      if (error.response?.statusCode == 401) {
        return ApiResponse(
          success: false,
          message: isRegistrationCall
              ? 'Registration session expired. Please start over.'
              : 'Session expired. Please log in again.',
          sessionExpired: !isRegistrationCall,
        );
      }

      if (error.response?.statusCode == 422 && error.response?.data is Map) {
        final data = error.response!.data as Map;
        return ApiResponse(
          success: false,
          message: data['message'] ?? 'Validation failed',
          errors: data['errors'] as Map<String, dynamic>?,
        );
      }

      if (error.response?.data is Map) {
        final data = error.response!.data as Map;
        return ApiResponse(
          success: false,
          message: data['message'] ?? 'Something went wrong',
        );
      }
    }

    return ApiResponse(
      success: false,
      message: 'Network error. Please check your connection.',
    );
  }
}