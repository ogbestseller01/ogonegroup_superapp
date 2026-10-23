import 'comment.dart';

class Post {
  final int id;
  final String title;
  final String content;
  final List<String> images;          // ← multiple images
  final String? youtubeUrl;
  final String? youtubeEmbed;
  int likesCount;
  int commentsCount;
  final String technicianName;
  final String? technicianAvatar;
  final DateTime createdAt;
  bool likedByUser;
  List<Comment> comments;

  Post({
    required this.id,
    required this.title,
    required this.content,
    this.images = const [],
    this.youtubeUrl,
    this.youtubeEmbed,
    required this.likesCount,
    required this.commentsCount,
    required this.technicianName,
    this.technicianAvatar,
    required this.createdAt,
    this.likedByUser = false,
    this.comments = const [],
  });

  /// Convenience: first image (backward compatible)
  String? get image => images.isNotEmpty ? images.first : null;

  bool get hasImages => images.isNotEmpty;

  factory Post.fromJson(Map<String, dynamic> json) {
    final commentsList = (json['comments'] as List? ?? [])
        .map((c) => Comment.fromJson(c))
        .toList();

    String techName = 'Fundi';
    if (json['technician'] != null) {
      if (json['technician']['user'] != null) {
        techName = json['technician']['user']['name'] ?? 'Fundi';
      } else if (json['technician']['name'] != null) {
        techName = json['technician']['name'];
      }
    } else if (json['technician_name'] != null) {
      techName = json['technician_name'];
    }

    String? techAvatar;
    if (json['technician'] != null) {
      techAvatar = json['technician']['profile_photo'];
    }

    // Support both new multi-image and old single image
    List<String> imagesList = [];
    if (json['image_urls'] != null && json['image_urls'] is List) {
      imagesList = (json['image_urls'] as List)
          .where((e) => e != null && e.toString().isNotEmpty)
          .map((e) => e.toString())
          .toList();
    } else if (json['images'] != null && json['images'] is List) {
      imagesList = (json['images'] as List)
          .where((e) => e != null && e.toString().isNotEmpty)
          .map((e) => e.toString())
          .toList();
    } else if (json['image'] != null && json['image'].toString().isNotEmpty) {
      imagesList = [json['image'].toString()];
    }

    return Post(
      id: json['id'],
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      images: imagesList,
      youtubeUrl: json['youtube_url'],
      youtubeEmbed: json['youtube_embed'],
      likesCount: json['likes_count'] ?? 0,
      commentsCount: json['comments_count'] ?? 0,
      technicianName: techName,
      technicianAvatar: techAvatar,
      createdAt: DateTime.parse(
          json['created_at'] ?? DateTime.now().toIso8601String()),
      likedByUser: json['liked_by_user'] ?? false,
      comments: commentsList,
    );
  }

  bool get hasYoutubeVideo =>
      (youtubeUrl != null && youtubeUrl!.isNotEmpty) ||
          (youtubeEmbed != null && youtubeEmbed!.isNotEmpty);
}