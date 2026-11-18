// lib/models/chat_update.dart
class ChatUpdate {
  final int technicianId;
  final int userId;
  final String name;
  final String? photo;
  final int postsCount;
  final int newCount;
  final int latestPostId;
  final DateTime? latestAt;
  final String? thumb;
  final bool hasVideo;
  final bool hasNew;

  const ChatUpdate({
    required this.technicianId,
    required this.userId,
    required this.name,
    this.photo,
    this.postsCount = 0,
    this.newCount = 0,
    this.latestPostId = 0,
    this.latestAt,
    this.thumb,
    this.hasVideo = false,
    this.hasNew = false,
  });

  factory ChatUpdate.fromJson(Map<String, dynamic> json) => ChatUpdate(
    technicianId: _toInt(json['technician_id']),
    userId: _toInt(json['user_id']),
    name: json['name']?.toString() ?? 'Fundi',
    photo: json['profile_photo']?.toString(),
    postsCount: _toInt(json['posts_count']),
    newCount: _toInt(json['new_count']),
    latestPostId: _toInt(json['latest_post_id']),
    latestAt: json['latest_at'] != null ? DateTime.tryParse(json['latest_at'].toString()) : null,
    thumb: json['thumb']?.toString(),
    hasVideo: json['has_video'] == true,
    hasNew: json['has_new'] == true,
  );

  /// Returns a copy with new_count reset to 0 (used when opening a profile).
  ChatUpdate seen() => ChatUpdate(
    technicianId: technicianId,
    userId: userId,
    name: name,
    photo: photo,
    postsCount: postsCount,
    newCount: 0,
    latestPostId: latestPostId,
    latestAt: latestAt,
    thumb: thumb,
    hasVideo: hasVideo,
    hasNew: false,
  );

  static int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }
}