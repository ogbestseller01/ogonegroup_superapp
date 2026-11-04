// lib/models/chat_update.dart  (NEW) — one row of the "Updates" tab
class ChatUpdate {
  final int technicianId;
  final int userId;
  final String name;
  final String? photo;
  final int postsCount;
  final int newCount;
  final bool hasNew;
  final bool hasVideo;
  final String? thumb;
  final DateTime? latestAt;

  const ChatUpdate({
    required this.technicianId,
    required this.userId,
    required this.name,
    this.photo,
    this.postsCount = 0,
    this.newCount = 0,
    this.hasNew = false,
    this.hasVideo = false,
    this.thumb,
    this.latestAt,
  });

  factory ChatUpdate.fromJson(Map<String, dynamic> j) => ChatUpdate(
    technicianId: int.tryParse('${j['technician_id']}') ?? 0,
    userId: int.tryParse('${j['user_id']}') ?? 0,
    name: j['name']?.toString() ?? 'Fundi',
    photo: j['profile_photo']?.toString(),
    postsCount: int.tryParse('${j['posts_count']}') ?? 0,
    newCount: int.tryParse('${j['new_count']}') ?? 0,
    hasNew: j['has_new'] == true,
    hasVideo: j['has_video'] == true,
    thumb: j['thumb']?.toString(),
    latestAt: DateTime.tryParse('${j['latest_at']}')?.toLocal(),
  );

  ChatUpdate seen() => ChatUpdate(
    technicianId: technicianId, userId: userId, name: name, photo: photo,
    postsCount: postsCount, newCount: 0, hasNew: false, hasVideo: hasVideo,
    thumb: thumb, latestAt: latestAt,
  );
}
