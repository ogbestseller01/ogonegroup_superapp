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
  final String? image;
  final String? youtubeUrl;
  final String? youtubeEmbed;
  int likesCount;
  int commentsCount;
  final String technicianName;
  final String? technicianAvatar;
  final int technicianId;          // ← NEW
  final DateTime createdAt;
  bool likedByUser;
  List<Comment> comments;

  Post({
    required this.id,
    required this.title,
    required this.content,
    this.image,
    this.youtubeUrl,
    this.youtubeEmbed,
    required this.likesCount,
    required this.commentsCount,
    required this.technicianName,
    this.technicianAvatar,
    required this.technicianId,    // ← NEW
    required this.createdAt,
    this.likedByUser = false,
    this.comments = const [],
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    final commentsList = (json['comments'] as List? ?? [])
        .map((c) => Comment.fromJson(c))
        .toList();

    // ─── Extract technician info ──────────────────────────────────
    String techName = 'Fundi';
    String? techAvatar;
    int techId = 0;

    if (json['technician'] != null && json['technician'] is Map) {
      final techMap = json['technician'] as Map;
      // ID
      if (techMap['id'] != null) {
        techId = techMap['id'] as int;
      }
      // Name
      if (techMap['user'] != null && techMap['user'] is Map) {
        final userMap = techMap['user'] as Map;
        techName = userMap['name']?.toString() ?? 'Fundi';
        // Avatar might be on user too? Usually on technician.
      } else if (techMap['name'] != null) {
        techName = techMap['name'].toString();
      }
      // Avatar
      techAvatar = techMap['profile_photo']?.toString();
    }

    // Fallback if technician object missing but fields exist
    if (json['technician_id'] != null) {
      techId = json['technician_id'] as int;
    }
    if (json['technician_name'] != null) {
      techName = json['technician_name'].toString();
    }

    return Post(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      image: json['image'],
      youtubeUrl: json['youtube_url'],
      youtubeEmbed: json['youtube_embed'],
      likesCount: json['likes_count'] ?? 0,
      commentsCount: json['comments_count'] ?? 0,
      technicianName: techName,
      technicianAvatar: techAvatar,
      technicianId: techId,                          // ← NEW
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      likedByUser: json['liked_by_user'] ?? false,
      comments: commentsList,
    );
  }

  bool get hasYoutubeVideo =>
      (youtubeUrl != null && youtubeUrl!.isNotEmpty) ||
          (youtubeEmbed != null && youtubeEmbed!.isNotEmpty);
}