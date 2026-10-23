
// models/post.dart
class Comment {
  final int id;
  final String comment;
  final String userName;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.comment,
    required this.userName,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] ?? 0,
      comment: json['comment'] ?? '',
      userName: json['user']?['name'] ?? 'Anonymous',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}


class Post {
  final int id;
  final String title;
  final String content;
  final List<String> images;
  final String? youtubeUrl;
  final String? youtubeEmbed;
  int likesCount;
  int commentsCount;
  final String technicianName;
  final String? technicianAvatar;
  final int technicianId;
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
    required this.technicianId,
    required this.createdAt,
    this.likedByUser = false,
    this.comments = const [],
  });

  /// Backward-compatible first image
  String? get image => images.isNotEmpty ? images.first : null;

  bool get hasImages => images.isNotEmpty;

  bool get hasYoutubeVideo =>
      (youtubeUrl != null && youtubeUrl!.isNotEmpty) ||
          (youtubeEmbed != null && youtubeEmbed!.isNotEmpty);

  factory Post.fromJson(Map<String, dynamic> json) {
    final commentsList = (json['comments'] as List? ?? [])
        .map((c) => Comment.fromJson(c))
        .toList();

    String techName = 'Fundi';
    String? techAvatar;
    int techId = 0;

    if (json['technician'] != null && json['technician'] is Map) {
      final techMap = json['technician'] as Map;
      if (techMap['id'] != null) techId = techMap['id'] as int;
      if (techMap['user'] != null && techMap['user'] is Map) {
        techName = techMap['user']['name']?.toString() ?? 'Fundi';
      } else if (techMap['name'] != null) {
        techName = techMap['name'].toString();
      }
      techAvatar = techMap['profile_photo']?.toString();
    }

    if (json['technician_id'] != null) {
      techId = json['technician_id'] as int;
    }
    if (json['technician_name'] != null) {
      techName = json['technician_name'].toString();
    }

    // Multi-image support + old single image
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
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      images: imagesList,
      youtubeUrl: json['youtube_url'],
      youtubeEmbed: json['youtube_embed'],
      likesCount: json['likes_count'] ?? 0,
      commentsCount: json['comments_count'] ?? 0,
      technicianName: techName,
      technicianAvatar: techAvatar,
      technicianId: techId,
      createdAt: DateTime.parse(
          json['created_at'] ?? DateTime.now().toIso8601String()),
      likedByUser: json['liked_by_user'] ?? false,
      comments: commentsList,
    );
  }
}