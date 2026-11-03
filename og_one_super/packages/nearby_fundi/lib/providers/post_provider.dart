// FILE: lib/providers/post_provider.dart
import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../models/post.dart';
import '../services/api_service.dart';

class PostProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  final List<Post> _posts = [];
  int _page = 1;
  bool _hasMore = true;
  bool _isLoading = false;
  int? _filterTechnicianId;
  String? _error;

  /// Incremented for every load; responses from older loads are ignored so a
  /// refresh can never be polluted by a slow page request.
  int _requestId = 0;

  UnmodifiableListView<Post> get posts => UnmodifiableListView(_posts);
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  String? get error => _error;

  void setTechnicianFilter(int? id) {
    _filterTechnicianId = id;
    fetchPosts(refresh: true);
  }

  // ───────────────────────── Public feed ─────────────────────────

  Future<void> fetchPosts({bool refresh = false}) async {
    if (_isLoading && !refresh) return; // avoid duplicate page requests

    if (refresh) {
      _page = 1;
      _hasMore = true;
      _posts.clear();
    }
    if (!_hasMore) return;

    final ticket = ++_requestId;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _api.getPosts(
        page: _page,
        technicianId: _filterTechnicianId,
      );
      if (ticket != _requestId) return; // a newer load took over

      final data = res.data;
      if (res.success && data is Map) {
        final items = data['data'] is List ? data['data'] as List : const [];
        _posts.addAll(items
            .whereType<Map>()
            .map((e) => Post.fromJson(Map<String, dynamic>.from(e))));
        _hasMore = data['next_page_url'] != null;
        _page++;
      } else {
        _error = res.success ? 'Unexpected response from server.' : res.message;
      }
    } catch (e) {
      if (ticket != _requestId) return;
      debugPrint('❌ fetchPosts error: $e');
      _error = 'Could not load posts.';
    }

    _isLoading = false;
    notifyListeners();
  }

  // ───────────────────────── Fundi's own posts ─────────────────────────

  Future<void> fetchMyPosts() async {
    final ticket = ++_requestId;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _api.getMyPosts();
      if (ticket != _requestId) return;

      final data = res.data;
      if (res.success && data is List) {
        _posts
          ..clear()
          ..addAll(data
              .whereType<Map>()
              .map((e) => Post.fromJson(Map<String, dynamic>.from(e))));
        _hasMore = false;
      } else {
        _error = res.success ? 'Unexpected response from server.' : res.message;
      }
    } catch (e) {
      if (ticket != _requestId) return;
      debugPrint('❌ fetchMyPosts error: $e');
      _error = 'Could not load your posts.';
    }

    _isLoading = false;
    notifyListeners();
  }

  // ───────────────────────── Create / update / delete ─────────────────────────

  Future<bool> createPost(Map<String, dynamic> data) =>
      _mutate(() => _api.createPost(data));

  Future<bool> updatePost(int id, Map<String, dynamic> data) =>
      _mutate(() => _api.updatePost(id, data));

  Future<bool> deletePost(int id) => _mutate(() => _api.deletePost(id));

  /// Shared flow for create / update / delete: run, then reload my posts.
  Future<bool> _mutate(Future<ApiResponse> Function() request) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await request();

      if (res.success) {
        await fetchMyPosts(); // also resets _isLoading and notifies
        return true;
      }
      _error = res.message;
    } catch (e) {
      debugPrint('❌ post mutation error: $e');
      _error = 'Something went wrong. Please try again.';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // ───────────────────────── Likes & comments ─────────────────────────

  /// Toggles like on the server. Returns true on success and updates the
  /// post in the feed (if it is there).
  Future<bool> likePost(int id) async {
    final res = await _api.likePost(id);
    if (!res.success) return false;

    final index = _posts.indexWhere((p) => p.id == id);
    if (index != -1) {
      final post = _posts[index];
      post.likesCount += post.likedByUser ? -1 : 1;
      post.likedByUser = !post.likedByUser;
      notifyListeners();
    }
    return true;
  }

  Future<bool> addComment(int postId, String comment) async {
    final res = await _api.commentOnPost(postId, comment);
    if (!res.success) return false;
    await refreshPost(postId);
    return true;
  }

  /// Reloads a single post (e.g. after a new comment) and updates the feed.
  Future<void> refreshPost(int postId) async {
    final res = await _api.getPostDetail(postId);
    final data = res.data;
    if (res.success && data is Map) {
      final index = _posts.indexWhere((p) => p.id == postId);
      if (index != -1) {
        _posts[index] = Post.fromJson(Map<String, dynamic>.from(data));
        notifyListeners();
      }
    }
  }

  void clear() {
    _requestId++; // invalidate anything still in flight
    _posts.clear();
    _page = 1;
    _hasMore = true;
    _isLoading = false;
    _error = null;
    _filterTechnicianId = null;
    notifyListeners();
  }
}