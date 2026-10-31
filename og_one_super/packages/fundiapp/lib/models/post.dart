import 'comment.dart';

class Post {
  final int id;
  final List<String> images;
  final String? videoUrl;
  int likesCount;
  int commentsCount;
  final String technicianName;
  final String? technicianAvatar;
  final DateTime createdAt;
  bool likedByUser;
  List<Comment> comments;

  Post({
    required this.id,
    this.images = const [],
    this.videoUrl,
    required this.likesCount,
    required this.commentsCount,
    required this.technicianName,
    this.technicianAvatar,
    required this.createdAt,
    this.likedByUser = false,
    this.comments = const [],
  });

  bool get hasImages => images.isNotEmpty;
  bool get hasVideo => videoUrl != null && videoUrl!.isNotEmpty;

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
    }

    String? techAvatar;
    if (json['technician'] != null) {
      techAvatar = json['technician']['profile_photo'];
    }

    List<String> imagesList = [];
    if (json['image_urls'] != null && json['image_urls'] is List) {
      imagesList = (json['image_urls'] as List)
          .where((e) => e != null && e.toString().isNotEmpty)
          .map((e) => e.toString())
          .toList();
    }

    return Post(
      id: json['id'],
      images: imagesList,
      videoUrl: json['video_url'],
      likesCount: json['likes_count'] ?? 0,
      commentsCount: json['comments_count'] ?? 0,
      technicianName: techName,
      technicianAvatar: techAvatar,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      likedByUser: json['liked_by_user'] ?? false,
      comments: commentsList,
    );
  }
}