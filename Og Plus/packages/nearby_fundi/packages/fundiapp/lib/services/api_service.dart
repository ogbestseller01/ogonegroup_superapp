// lib/services/api_service.dart
import 'dart:convert';
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

  /// HTTP status. `null` means no HTTP answer at all (timeout, offline,
  /// unexpected exception). The auth provider uses this to show the
  /// localized "network error" text.
  final int? statusCode;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.errors,
    this.sessionExpired = false,
    this.statusCode,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json, {int? statusCode}) {
    final s = json['success'];
    return ApiResponse(
      success: s is bool
          ? s
          : (s == 1 || s == '1' || json['status'] == 'success'),
      message: json['message']?.toString() ?? 'No message from server',
      data: json['data'],
      errors: json['errors'] is Map
          ? Map<String, dynamic>.from(json['errors'] as Map)
          : null,
      statusCode: statusCode,
    );
  }
}

/// Main API service: handles all HTTP requests across the application.
class ApiService {
  late final Dio _dio;

  /// Fired when a 401 hits a request that belonged to the LIVE session
  /// (set by the AuthProvider that owns this instance).
  void Function()? onSessionExpired;

  /// Fired for any other ApiService instance (providers create their own),
  /// so a dead session redirects to login no matter who made the call.
  /// Set once in AuthProvider: `ApiService.onGlobalSessionExpired = ...`.
  static void Function()? onGlobalSessionExpired;

  /// Endpoints used while logged out. A 401 here means "wrong credentials"
  /// or "saved login invalid", NOT "session expired", and the stored session
  /// token must not be attached.
  /// '/v1/auth/quick-login' also matches '/v1/auth/quick-login/forget'.
  static const List<String> _publicAuthPaths = [
    '/v1/auth/login',
    '/v1/auth/register',
    '/v1/auth/register-fundi',
    '/v1/auth/verify-otp',
    '/v1/auth/resend-otp',
    '/v1/auth/forgot-password',
    '/v1/auth/reset-password',
    '/v1/auth/quick-login',
  ];

  bool _isPublicAuthPath(String p) => _publicAuthPaths.any(p.contains);

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(minutes: 2), // video uploads up to 20 MB
      headers: {
        // "FundiApp" makes the backend label this session "Fundi App"
        // (see getDeviceName patch); the OS shows up in the login email.
        'User-Agent': 'FundiApp Flutter (${Platform.operatingSystem})',
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Never overwrite an explicit Authorization header (registration
        // token, quick-login, logoutWithToken) and never attach the session
        // token to public auth endpoints.
        if (!_isPublicAuthPath(options.path) &&
            !options.headers.containsKey('Authorization')) {
          final token = await StorageService.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        }
        options.headers['Accept'] = 'application/json';
        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        final req = e.requestOptions;
        final isRegistrationCall = req.path.contains('/technicians/register/');

        if (e.response?.statusCode == 401 &&
            !isRegistrationCall &&
            !_isPublicAuthPath(req.path)) {
          final sent = req.headers['Authorization']
              ?.toString()
              .replaceFirst('Bearer ', '');
          final current = await StorageService.getToken();
          // Only the LIVE session may end itself. A late 401 from an old
          // token (e.g. logoutWithToken after local logout) must not.
          if (sent != null && sent.isNotEmpty && sent == current) {
            await StorageService.clearAuth();
            (onSessionExpired ?? onGlobalSessionExpired)?.call();
          }
        }
        return handler.next(e);
      },
    ));
  }

  /// Used by chat_service.dart to build absolute media URLs.
  String get baseUrl => _dio.options.baseUrl;

  // ============================================================
  // SECTION 1: AUTHENTICATION
  // ============================================================

  Future<ApiResponse> register(Map<String, dynamic> data) =>
      _post('/v1/auth/register', data: data);

  Future<ApiResponse> registerFundi(Map<String, dynamic> data) async {
    if (data['profile_photo'] is String) {
      final file = File(data['profile_photo']);
      final formData = FormData();
      data.forEach((key, value) {
        if (key == 'profile_photo') return;
        if (key == 'service_ids' && value is List) {
          for (final id in value) {
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

  /// Password login. [rememberMe] asks the server for a 30-day remember token.
  Future<ApiResponse> login(
      String identifier,
      String password, {
        bool rememberMe = false,
      }) =>
      _post('/v1/auth/login', data: {
        'email': identifier,
        'password': password,
        if (rememberMe) 'remember_me': true,
      });

  /// One-tap login. Bearer = the REMEMBER token (explicit header, so the
  /// interceptor never swaps it for a session token).
  Future<ApiResponse> quickLogin(String rememberToken, {String? fcmToken}) =>
      _post(
        '/v1/auth/quick-login',
        data: {
          if (fcmToken != null && fcmToken.isNotEmpty) 'fcm_token': fcmToken,
        },
        headers: {'Authorization': 'Bearer $rememberToken'},
      );

  /// "Use another account": revokes the remember token server-side.
  Future<ApiResponse> forgetRemembered(String rememberToken) => _post(
    '/v1/auth/quick-login/forget',
    headers: {'Authorization': 'Bearer $rememberToken'},
  );

  Future<ApiResponse> verifyOtp(
      String identifier,
      String otp, {
        String? fcmToken,
      }) =>
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

  /// Revokes a specific session token (used after local logout already ran).
  Future<ApiResponse> logoutWithToken(String token, {String? fcmToken}) =>
      _post(
        '/v1/auth/logout',
        data: {
          if (fcmToken != null && fcmToken.isNotEmpty) 'fcm_token': fcmToken,
        },
        headers: {'Authorization': 'Bearer $token'},
      );

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

  Future<ApiResponse> getServices({String locale = 'en'}) =>
      _get('/v1/services', headers: {'Accept-Language': locale});

  // ============================================================
  // SECTION 3: TECHNICIAN PROFILE & SERVICE CHANGES
  // ============================================================

  Future<ApiResponse> getMyTechnicianProfile() =>
      _get('/v19/technicians/profile');

  Future<ApiResponse> updateTechnicianProfile(Map<String, dynamic> data) =>
      _put('/v19/technicians/profile', data: data);

  Future<ApiResponse> uploadProfilePhoto(File imageFile) async {
    final formData = FormData.fromMap({
      'profile_photo': await MultipartFile.fromFile(imageFile.path),
    });
    return _post('/v19/technicians/profile/photo', data: formData);
  }

  // ── Service change requests (approval workflow) ───────────
  // Old instant-update endpoint (/v19/technicians/services) is closed.
  // All service changes now go through the approval flow.
  //
  // Backend bindings (routes/api.php, v19 group):
  //   POST /v19/technicians/services                   → store()
  //   POST /v19/technicians/service-changes            → store()  (alias)
  //   GET  /v19/technicians/service-changes            → options() (canonical)
  //   GET  /v19/technicians/service-changes/options    → options() (alias)
  //
  // store() validator expects:
  //   services: array<int>  (1..50, distinct, exists:services,id)
  //   reason:   string      (10..1000 chars)
  //
  // options() returns:
  //   services, current_service_ids, blocked_service_ids, latest_request

  /// Returns current services, full catalog (with categories), blocked IDs,
  /// and the latest request (if any).
  Future<ApiResponse> getServiceChangeOptions({String locale = 'en'}) =>
      _get(
        '/v19/technicians/service-changes',
        headers: {'Accept-Language': locale},
      );

  /// Submits a new change request. Only one pending request is allowed.
  /// Backend expects `services` (array of ints) and `reason` (string 10-1000).
  Future<ApiResponse> submitServiceChange({
    required List<int> serviceIds,
    required String reason,
    String locale = 'en',
  }) =>
      _post(
        '/v19/technicians/services',
        data: {
          'services': serviceIds,
          'reason': reason,
        },
        headers: {'Accept-Language': locale},
      );

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

  /// Step 1 needs: name, phone, password, password_confirmation,
  /// area, service_ids (List<int>). Optional: email, latitude, longitude,
  /// profile_photo (File or String path).
  Future<ApiResponse> registerTechnicianStep1(
      Map<String, dynamic> data, {
        String? fcmDeviceToken,
      }) async {
    final payload = Map<String, dynamic>.from(data);

    // UI-only keys, not needed by the backend
    payload.remove('phone_country_code');
    payload.remove('phone_local_raw');

    if (fcmDeviceToken != null && fcmDeviceToken.isNotEmpty) {
      payload['fcm_device_token'] = fcmDeviceToken;
    }

    // Accept the photo as File or String path
    final rawPhoto = payload['profile_photo'];
    final photoPath = rawPhoto is File
        ? rawPhoto.path
        : (rawPhoto is String ? rawPhoto : '');
    final hasPhoto = photoPath.isNotEmpty && File(photoPath).existsSync();

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

    if (hasPhoto) {
      formData.files.add(
        MapEntry('profile_photo', await MultipartFile.fromFile(photoPath)),
      );
    }

    return _post('/v19/technicians/register/step1', data: formData);
  }

  Future<ApiResponse> verifyDraftOtp({
    required String identifier,
    required String otp,
    int? draftId,
    String? fcmDeviceToken,
  }) =>
      _post('/v19/technicians/register/verify-otp', data: {
        'identifier': identifier,
        'otp': otp,
        if (draftId != null) 'draft_id': draftId,
        if (fcmDeviceToken != null && fcmDeviceToken.isNotEmpty)
          'fcm_device_token': fcmDeviceToken,
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

  Future<ApiResponse> getTechnicianDetail(int id) =>
      _get('/v1/technicians/$id');

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

  Future<ApiResponse> getMyPosts() => _get('/v5/my-posts');

  Future<ApiResponse> createPost(Map<String, dynamic> data) async {
    final formData = FormData();
    await _appendFile(formData, 'video', data['video']);
    await _appendFiles(formData, 'images[]', data['images']);
    return _post('/v5/posts', data: formData);
  }

  Future<ApiResponse> updatePost(int id, Map<String, dynamic> data) async {
    final formData = FormData();
    formData.fields.add(const MapEntry('_method', 'PUT'));

    await _appendFile(formData, 'video', data['video']);
    if (data['remove_video'] == true) {
      formData.fields.add(const MapEntry('remove_video', '1'));
    }
    await _appendFiles(formData, 'images[]', data['images']);

    if (data['keep_images'] is List) {
      for (final path in data['keep_images']) {
        formData.fields.add(MapEntry('keep_images[]', path.toString()));
      }
      formData.fields.add(const MapEntry('images_managed', '1'));
    }

    return _post('/v5/posts/$id', data: formData);
  }

  Future<ApiResponse> deletePost(int id) => _delete('/v5/posts/$id');

  // ============================================================
  // SECTION 8: PORTFOLIO
  // ============================================================

  Future<ApiResponse> getMyPortfolios() => _get('/v3/portfolios/my');

  Future<ApiResponse> createPortfolio(List<String> imagePaths) async {
    final formData = FormData();
    await _appendFiles(formData, 'images[]', imagePaths);
    return _post('/v3/portfolios', data: formData);
  }

  Future<ApiResponse> updatePortfolio(
      int id, {
        List<String>? newImagePaths,
        List<int>? deleteImageIds,
      }) async {
    final formData = FormData();
    formData.fields.add(const MapEntry('_method', 'PUT'));

    await _appendFiles(formData, 'images[]', newImagePaths);

    if (deleteImageIds != null) {
      for (final imgId in deleteImageIds) {
        formData.fields.add(MapEntry('delete_image_ids[]', imgId.toString()));
      }
    }

    return _post('/v3/portfolios/$id', data: formData);
  }

  Future<ApiResponse> deletePortfolio(int id) => _delete('/v3/portfolios/$id');

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
  // SECTION 9: SERVICE REQUESTS & TRACKING
  // ============================================================

  Future<ApiResponse> createRequest(Map<String, dynamic> data) =>
      _post('/v4/requests', data: data);

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
      _get('/v4/requests/$requestId/tracking');

  // ============================================================
  // SECTION 9B: JOBS & TICKETS
  // ============================================================

  Future<ApiResponse> getMyJobs({String? status}) => _get('/v4/jobs', query: {
    if (status != null && status.isNotEmpty) 'status': status,
  });

  Future<ApiResponse> getJobDetail(int id) => _get('/v4/jobs/$id');

  Future<ApiResponse> getMyTickets({String? status}) =>
      _get('/v4/tickets', query: {
        if (status != null && status.isNotEmpty) 'status': status,
      });

  Future<ApiResponse> getTicketDetail(int id) => _get('/v4/tickets/$id');

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
  // SECTION 12: CHAT & MESSAGING (V14)
  // ============================================================

  Future<ApiResponse> getConversations() => _get('/v14/chat/conversations');

  Future<ApiResponse> getOrCreateConversation({
    required int customerId,
    required int fundiId,
  }) =>
      _post('/v14/chat/conversation', data: {
        'customer_id': customerId,
        'fundi_id': fundiId,
      });

  Future<ApiResponse> getMessages({
    required int conversationId,
    int limit = 30,
    int? beforeId,
    int? afterId,
    int? untilId,
    String? since,
  }) {
    final q = <String, dynamic>{'limit': '$limit'};
    if (beforeId != null) q['before_id'] = '$beforeId';
    if (afterId != null) q['after_id'] = '$afterId';
    if (untilId != null) q['until_id'] = '$untilId';
    if (since != null) q['since'] = since;
    return _get('/v14/chat/conversations/$conversationId/messages', query: q);
  }

  Future<ApiResponse> sendMessage({
    required int conversationId,
    String? content,
    String? filePath,
    int? replyToId,
    void Function(int, int)? onSendProgress,
  }) async {
    final form = <String, dynamic>{'conversation_id': '$conversationId'};
    if (content != null && content.isNotEmpty) form['content'] = content;
    if (replyToId != null) form['reply_to_id'] = '$replyToId';
    if (filePath != null) {
      form['file'] = await MultipartFile.fromFile(
        filePath,
        filename: filePath.split(Platform.pathSeparator).last,
      );
    }
    return _postMultipart('/v14/chat/send', form,
        onSendProgress: onSendProgress);
  }

  Future<ApiResponse> markConversationAsRead(int conversationId) =>
      _post('/v14/chat/conversations/$conversationId/read');

  Future<ApiResponse> deleteConversation(int conversationId) =>
      _delete('/v14/chat/conversations/$conversationId');

  Future<ApiResponse> setConversationState(
      int id, {
        bool? pinned,
        bool? archived,
      }) {
    final body = <String, dynamic>{};
    if (pinned != null) body['pinned'] = pinned;
    if (archived != null) body['archived'] = archived;
    return _post('/v14/chat/conversations/$id/state', data: body);
  }

  Future<ApiResponse> deleteMessages(List<int> ids, {required String scope}) =>
      _post('/v14/chat/messages/delete', data: {
        'message_ids': ids,
        'scope': scope,
      });

  Future<ApiResponse> sendTyping(int conversationId) =>
      _post('/v14/chat/typing', data: {'conversation_id': '$conversationId'});

  Future<ApiResponse> react(int messageId, String? emoji) =>
      _post('/v14/chat/messages/$messageId/react',
          data: {'reaction': emoji ?? ''});

  Future<ApiResponse> toggleStar(int messageId) =>
      _post('/v14/chat/messages/$messageId/star');

  Future<ApiResponse> togglePin(int messageId) =>
      _post('/v14/chat/messages/$messageId/pin');

  Future<ApiResponse> forward({
    required List<int> messageIds,
    required List<int> conversationIds,
  }) =>
      _post('/v14/chat/forward', data: {
        'message_ids': messageIds,
        'conversation_ids': conversationIds,
      });

  Future<ApiResponse> fetchStarred(int conversationId) =>
      _get('/v14/chat/conversations/$conversationId/starred');

  Future<ApiResponse> fetchMedia(
      int conversationId,
      String tab, {
        int? beforeId,
      }) {
    final q = <String, dynamic>{'tab': tab, 'limit': '40'};
    if (beforeId != null) q['before_id'] = '$beforeId';
    return _get('/v14/chat/conversations/$conversationId/media', query: q);
  }

  Future<ApiResponse> fetchMessageInfo(int messageId) =>
      _get('/v14/chat/messages/$messageId/info');

  Future<ApiResponse> fetchChatUpdates() => _get('/v14/chat/updates');

  Future<ApiResponse> markStatusSeen(int technicianId) =>
      _post('/v14/chat/status/$technicianId/seen');

  Future<ApiResponse> getUnreadCount() => _get('/v14/chat/unread');

  // ============================================================
  // SECTION 13: NOTIFICATIONS
  // ============================================================

  Future<ApiResponse> getNotifications({String? excludeType, String? type}) =>
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
      _put('/v15/notifications/read-all', query: {
        if (excludeType != null && excludeType.isNotEmpty)
          'exclude_type': excludeType,
      });

  Future<ApiResponse> deleteNotification(String notificationId) =>
      _delete('/v15/notifications/$notificationId');

  Future<ApiResponse> clearNotifications({String? excludeType}) =>
      _delete('/v15/notifications/clear', query: {
        if (excludeType != null && excludeType.isNotEmpty)
          'exclude_type': excludeType,
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

  /// Turns a Dio response into an [ApiResponse]. Never throws: a non-JSON
  /// body becomes a failed response (with the HTTP status) instead of a crash.
  ApiResponse _parse(Response res) {
    final data = res.data;

    if (data is Map) {
      return ApiResponse.fromJson(
        Map<String, dynamic>.from(data),
        statusCode: res.statusCode,
      );
    }

    if (data is String) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map) {
          return ApiResponse.fromJson(
            Map<String, dynamic>.from(decoded),
            statusCode: res.statusCode,
          );
        }
      } catch (_) {}
    }

    return ApiResponse(
      success: false,
      message: 'Server returned an unexpected response.',
      statusCode: res.statusCode,
    );
  }

  Options? _opts(Map<String, String>? headers) =>
      (headers != null && headers.isNotEmpty) ? Options(headers: headers) : null;

  Future<ApiResponse> _get(
      String path, {
        Map<String, dynamic>? query,
        Map<String, String>? headers,
      }) async {
    try {
      final res = await _dio.get(
        path,
        queryParameters: query,
        options: _opts(headers),
      );
      return _parse(res);
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse> _post(
      String path, {
        dynamic data,
        Map<String, String>? headers,
        void Function(int, int)? onSendProgress,
      }) async {
    try {
      final res = await _dio.post(
        path,
        data: data,
        options: _opts(headers),
        onSendProgress: onSendProgress,
      );
      return _parse(res);
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse> _postMultipart(
      String path,
      Map<String, dynamic> fields, {
        Map<String, String>? headers,
        void Function(int, int)? onSendProgress,
      }) async {
    try {
      final formData = FormData.fromMap(fields);
      final res = await _dio.post(
        path,
        data: formData,
        options: _opts(headers),
        onSendProgress: onSendProgress,
      );
      return _parse(res);
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
        options: _opts(headers),
      );
      return _parse(res);
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
        options: _opts(headers),
      );
      return _parse(res);
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
        options: _opts(headers),
      );
      return _parse(res);
    } catch (e) {
      return _handleError(e);
    }
  }

  /// Append a single file to a FormData if the path is a non-empty string
  /// and the file exists. Silently skips missing files.
  Future<void> _appendFile(FormData formData, String key, dynamic path) async {
    if (path is! String || path.isEmpty) return;
    final file = File(path);
    if (!await file.exists()) return;
    formData.files.add(MapEntry(
      key,
      await MultipartFile.fromFile(
        file.path,
        filename: file.path.split(Platform.pathSeparator).last,
      ),
    ));
  }

  Future<void> _appendFiles(
      FormData formData,
      String key,
      dynamic paths,
      ) async {
    if (paths is! List) return;
    for (final p in paths) {
      await _appendFile(formData, key, p);
    }
  }

  ApiResponse _handleError(dynamic error) {
    // Shows the real server error in the debug console
    if (error is DioException) {
      debugPrint(
        '❌ ${error.requestOptions.path} → '
            '${error.response?.statusCode} ${error.response?.data}',
      );
    }

    if (error is! DioException) {
      return ApiResponse(
        success: false,
        message: 'Unexpected error. Please try again.',
      );
    }

    final isRegistrationCall =
    error.requestOptions.path.contains('/technicians/register/');

    // Network-level failures (statusCode stays null on purpose)
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiResponse(
          success: false,
          message:
          'Connection timed out. Please check your network and try again.',
        );
      case DioExceptionType.connectionError:
        return ApiResponse(
          success: false,
          message: 'No internet connection. Please check your network.',
        );
      case DioExceptionType.cancel:
        return ApiResponse(success: false, message: 'Request cancelled.');
      default:
        break;
    }

    final statusCode = error.response?.statusCode;
    final body = error.response?.data;

    if (statusCode == 401) {
      if (isRegistrationCall) {
        return ApiResponse(
          success: false,
          statusCode: statusCode,
          message: 'Registration session expired. Please start over.',
        );
      }

      // Wrong credentials / invalid saved login: NOT a session expiry.
      if (_isPublicAuthPath(error.requestOptions.path)) {
        final serverMessage = body is Map ? body['message']?.toString() : null;
        return ApiResponse(
          success: false,
          statusCode: statusCode,
          message: (serverMessage != null && serverMessage.isNotEmpty)
              ? serverMessage
              : 'Invalid credentials.',
        );
      }

      return ApiResponse(
        success: false,
        statusCode: statusCode,
        message: 'Session expired. Please log in again.',
        sessionExpired: true,
      );
    }

    if (body is Map) {
      final map = Map<String, dynamic>.from(body);
      final message = map['message']?.toString();
      final errors = map['errors'] is Map
          ? Map<String, dynamic>.from(map['errors'] as Map)
          : null;

      // Prefer the first validation error when the server sends one
      String? firstError;
      if (errors != null && errors.isNotEmpty) {
        final first = errors.values.first;
        firstError = (first is List && first.isNotEmpty)
            ? first.first.toString()
            : first.toString();
      }

      return ApiResponse(
        success: false,
        statusCode: statusCode,
        message: firstError ??
            ((message != null && message.isNotEmpty)
                ? message
                : 'Something went wrong (HTTP $statusCode).'),
        errors: errors,
      );
    }

    return ApiResponse(
      success: false,
      statusCode: statusCode,
      message: 'Something went wrong. Please try again.',
    );
  }
}