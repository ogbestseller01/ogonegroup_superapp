import 'comment.dart';

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
    required this.createdAt,
    this.likedByUser = false,
    this.comments = const [],
  });

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

    return Post(
      id: json['id'],
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      image: json['image'],
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