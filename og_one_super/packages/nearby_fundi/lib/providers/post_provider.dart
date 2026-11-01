// FILE: lib/providers/post_provider.dart
import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../models/post.dart';

class PostProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<Post> _posts = [];
  int _page = 1;
  bool _hasMore = true;
  bool _isLoading = false;
  int? _filterTechnicianId;
  String? _error;

  List<Post> get posts => _posts;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  String? get error => _error;

  void setTechnicianFilter(int? id) {
    _filterTechnicianId = id;
    _page = 1;
    _posts.clear();
    _hasMore = true;
    fetchPosts(refresh: true);
  }

  /// Public posts feed
  Future<void> fetchPosts({bool refresh = false}) async {
    if (_isLoading && !refresh) return; // avoid duplicate page requests

    if (refresh) {
      _page = 1;
      _posts.clear();
      _hasMore = true;
    }
    if (!_hasMore) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    final res =
    await _api.getPosts(page: _page, technicianId: _filterTechnicianId);

    if (res.success && res.data != null) {
      final data = res.data as Map<String, dynamic>;
      final List<dynamic> items = data['data'] ?? [];
      _posts.addAll(items.map((e) => Post.fromJson(e)));
      _hasMore = data['next_page_url'] != null;
      _page++;
      _error = null;
    } else {
      _error = res.message;
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Fundi's own posts
  Future<void> fetchMyPosts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final res = await _api.getMyPosts();
    if (res.success && res.data != null) {
      _posts = (res.data as List).map((e) => Post.fromJson(e)).toList();
      _error = null;
    } else {
      _error = res.message;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createPost(Map<String, dynamic> data) =>
      _mutate(() => _api.createPost(data));

  Future<bool> updatePost(int id, Map<String, dynamic> data) =>
      _mutate(() => _api.updatePost(id, data));

  Future<bool> deletePost(int id) => _mutate(() => _api.deletePost(id));

  /// Shared flow for create / update / delete: run, then reload my posts.
  Future<bool> _mutate(Future<dynamic> Function() request) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final res = await request();
    _isLoading = false;

    if (res.success) {
      await fetchMyPosts();
      return true;
    }

    _error = res.message;
    notifyListeners();
    return false;
  }

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

  Future<void> addComment(int postId, String comment) async {
    final res = await _api.commentOnPost(postId, comment);
    if (res.success) {
      await refreshPost(postId);
    }
  }

  /// Reloads a single post (e.g. after a new comment) and updates the feed.
  Future<void> refreshPost(int postId) async {
    final res = await _api.getPostDetail(postId);
    if (res.success && res.data != null) {
      final index = _posts.indexWhere((p) => p.id == postId);
      if (index != -1) {
        _posts[index] = Post.fromJson(res.data);
        notifyListeners();
      }
    }
  }

  void clear() {
    _posts.clear();
    _page = 1;
    _hasMore = true;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}