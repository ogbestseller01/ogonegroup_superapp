import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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

  Future<void> fetchPosts({bool refresh = false}) async {
    if (refresh) {
      _page = 1;
      _posts.clear();
      _hasMore = true;
    }
    if (!_hasMore) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    final res = await _api.getPosts(page: _page, technicianId: _filterTechnicianId);
    if (res.success && res.data != null) {
      final data = res.data as Map<String, dynamic>;
      final List<dynamic> items = data['data'] ?? [];
      final newPosts = items.map((e) => Post.fromJson(e)).toList();
      _posts.addAll(newPosts);
      _hasMore = data['next_page_url'] != null;
      _page++;
      _error = null;
    } else {
      _error = res.message;
    }
    _isLoading = false;
    notifyListeners();
  }

  // ---- Fundi CRUD ----
  Future<void> fetchMyPosts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final res = await _api.getMyPosts();
    if (res.success && res.data != null) {
      _posts = (res.data as List).map((e) => Post.fromJson(e)).toList();
      _error = null;

      // Debug all posts
      for (var p in _posts) {
        debugPrint('📌 Post #${p.id} | image: ${p.image}');
        debugPrint('   youtubeUrl: ${p.youtubeUrl}');
        debugPrint('   youtubeEmbed: ${p.youtubeEmbed}');
        debugPrint('   hasYoutubeVideo: ${p.hasYoutubeVideo}');
      }
    } else {
      _error = res.message;
      debugPrint('❌ fetchMyPosts error: $_error');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createPost(Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final res = await _api.createPost(data);
    _isLoading = false;
    if (res.success) {
      await fetchMyPosts();
      return true;
    }
    _error = res.message;
    notifyListeners();
    return false;
  }

  Future<bool> updatePost(int id, Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final res = await _api.updatePost(id, data);
    _isLoading = false;
    if (res.success) {
      await fetchMyPosts();
      return true;
    }
    _error = res.message;
    notifyListeners();
    return false;
  }

  Future<bool> deletePost(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final res = await _api.deletePost(id);
    _isLoading = false;
    if (res.success) {
      await fetchMyPosts();
      return true;
    }
    _error = res.message;
    notifyListeners();
    return false;
  }

  Future<void> likePost(int id) async {
    final res = await _api.likePost(id);
    if (!res.success) return;

    final index = _posts.indexWhere((p) => p.id == id);
    if (index != -1) {
      final post = _posts[index];
      final newLikesCount =
      post.likedByUser ? post.likesCount - 1 : post.likesCount + 1;

      // IMPORTANT: keep youtubeUrl & youtubeEmbed
      _posts[index] = Post(
        id: post.id,
        title: post.title,
        content: post.content,
        image: post.image,
        youtubeUrl: post.youtubeUrl,
        youtubeEmbed: post.youtubeEmbed,
        likesCount: newLikesCount,
        commentsCount: post.commentsCount,
        technicianName: post.technicianName,
        technicianAvatar: post.technicianAvatar,
        createdAt: post.createdAt,
        likedByUser: !post.likedByUser,
        comments: post.comments,
      );
      notifyListeners();
    }
  }

  Future<void> addComment(int postId, String comment) async {
    final res = await _api.commentOnPost(postId, comment);
    if (res.success) {
      await _refreshSinglePost(postId);
    }
  }

  Future<void> _refreshSinglePost(int postId) async {
    final res = await _api.getPostDetail(postId);
    if (res.success && res.data != null) {
      final updatedPost = Post.fromJson(res.data);
      final index = _posts.indexWhere((p) => p.id == postId);
      if (index != -1) {
        _posts[index] = updatedPost;
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