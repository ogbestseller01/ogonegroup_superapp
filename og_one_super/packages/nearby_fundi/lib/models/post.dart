// FILE: lib/models/post.dart
// Matches the backend `posts` table exactly:
//   id, technician_id, images (json array), video, created_at, updated_at
// plus the relations the API returns: technician.user, comments.user,
// likes_count / comments_count, image_urls, video_url.
// (No title, content or YouTube fields any more.)

int _asInt(dynamic value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

DateTime _asDate(dynamic value) =>
    DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();

class Comment {
  final int id;
  final String comment;
  final String userName;
  final DateTime createdAt;

  const Comment({
    required this.id,
    required this.comment,
    required this.userName,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    final name = user is Map ? user['name']?.toString() : null;

    return Comment(
      id: _asInt(json['id']),
      comment: json['comment']?.toString() ?? '',
      userName: (name == null || name.trim().isEmpty) ? 'Anonymous' : name,
      createdAt: _asDate(json['created_at']),
    );
  }
}

class Post {
  final int id;
  final List<String> images;
  final String? video;
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
    this.images = const [],
    this.video,
    this.likesCount = 0,
    this.commentsCount = 0,
    required this.technicianName,
    this.technicianAvatar,
    required this.technicianId,
    required this.createdAt,
    this.likedByUser = false,
    this.comments = const [],
  });

  /// First image (handy for feed thumbnails)
  String? get image => images.isNotEmpty ? images.first : null;

  bool get hasImages => images.isNotEmpty;

  bool get hasVideo => video != null && video!.isNotEmpty;

  bool get hasMedia => hasImages || hasVideo;

  factory Post.fromJson(Map<String, dynamic> json) {
    // ---- technician ----
    String techName = 'Fundi';
    String? techAvatar;
    int techId = _asInt(json['technician_id']);

    final tech = json['technician'];
    if (tech is Map) {
      if (techId == 0) techId = _asInt(tech['id']);

      final user = tech['user'];
      if (user is Map && user['name'] != null) {
        techName = user['name'].toString();
      } else if (tech['name'] != null) {
        techName = tech['name'].toString();
      }

      final photo = tech['profile_photo']?.toString();
      if (photo != null && photo.isNotEmpty) techAvatar = photo;
    }

    if (json['technician_name'] != null) {
      techName = json['technician_name'].toString();
    }

    // ---- images: prefer full URLs from the API, fall back to raw paths ----
    List<String> clean(dynamic raw) => (raw as List)
        .where((e) => e != null && e.toString().isNotEmpty)
        .map((e) => e.toString())
        .toList();

    List<String> imagesList = [];
    if (json['image_urls'] is List) {
      imagesList = clean(json['image_urls']);
    } else if (json['images'] is List) {
      imagesList = clean(json['images']);
    }

    // ---- video ----
    String? videoUrl;
    final rawVideo = json['video_url'] ?? json['video'];
    if (rawVideo != null && rawVideo.toString().isNotEmpty) {
      videoUrl = rawVideo.toString();
    }

    // ---- comments ----
    final commentsList = (json['comments'] is List)
        ? (json['comments'] as List)
        .whereType<Map>()
        .map((c) => Comment.fromJson(Map<String, dynamic>.from(c)))
        .toList()
        : <Comment>[];

    final commentsCount = json['comments_count'] != null
        ? _asInt(json['comments_count'])
        : commentsList.length;

    final likesCount = json['likes_count'] != null
        ? _asInt(json['likes_count'])
        : (json['likes'] is List ? (json['likes'] as List).length : 0);

    return Post(
      id: _asInt(json['id']),
      images: imagesList,
      video: videoUrl,
      likesCount: likesCount,
      commentsCount: commentsCount,
      technicianName: techName,
      technicianAvatar: techAvatar,
      technicianId: techId,
      createdAt: _asDate(json['created_at']),
      likedByUser: json['liked_by_user'] == true,
      comments: commentsList,
    );
  }
}