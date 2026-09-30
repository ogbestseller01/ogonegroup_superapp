// lib/screens/chat/widgets/message_bubble.dart

import 'package:flutter/material.dart';
import '../../../models/chat_message.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isCurrentUser;
  final VoidCallback? onLongPress;
  final Function(String)? onReaction;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
    this.onLongPress,
    this.onReaction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        mainAxisAlignment: isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          GestureDetector(
            onLongPress: onLongPress,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isCurrentUser ? theme.primaryColor : Colors.grey.shade200,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isCurrentUser ? 16 : 4),
                  bottomRight: Radius.circular(isCurrentUser ? 4 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMessageContent(context),
                  if (onReaction != null) ...[
                    const SizedBox(height: 6),
                    _buildReactionButtons(context),
                  ],
                  const SizedBox(height: 4),
                  _buildTimestamp(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // REACTION BUTTONS
  // ================================================================

  Widget _buildReactionButtons(BuildContext context) {
    final reactions = ['❤️', '👍', '😂', '😮', '😢', '🙏'];

    return Wrap(
      spacing: 4,
      children: reactions.map((reaction) {
        return InkWell(
          onTap: () => onReaction?.call(reaction),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 3,
            ),
            decoration: BoxDecoration(
              color: Colors.grey.shade200.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              reaction,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ================================================================
  // MESSAGE CONTENT
  // ================================================================

  Widget _buildMessageContent(BuildContext context) {
    final theme = Theme.of(context);

    switch (message.messageType) {
      case 'text':
        return Text(
          message.content ?? '',
          style: TextStyle(
            color: isCurrentUser ? Colors.white : Colors.black87,
            fontSize: 15,
          ),
        );

      case 'image':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.file != null && message.file!.url != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  message.file!.url!,
                  width: 200,
                  height: 200,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      width: 200,
                      height: 200,
                      color: Colors.grey.shade300,
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 200,
                      height: 200,
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.broken_image, size: 50),
                    );
                  },
                ),
              ),
            if (message.content != null && message.content!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  message.content!,
                  style: TextStyle(
                    color: isCurrentUser ? Colors.white : Colors.black87,
                  ),
                ),
              ),
          ],
        );

      case 'voice':
        return Row(
          children: [
            Icon(
              Icons.play_circle_filled,
              color: isCurrentUser ? Colors.white : theme.primaryColor,
              size: 32,
            ),
            const SizedBox(width: 8),
            Container(
              width: 100,
              height: 4,
              decoration: BoxDecoration(
                color: isCurrentUser ? Colors.white.withOpacity(0.5) : Colors.grey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${message.voiceDuration ?? 0}s',
              style: TextStyle(
                color: isCurrentUser ? Colors.white : Colors.black87,
                fontSize: 12,
              ),
            ),
          ],
        );

      case 'video':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.file != null && message.file!.url != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.network(
                      message.file!.url!,
                      width: 200,
                      height: 150,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 200,
                          height: 150,
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.videocam_off, size: 50),
                        );
                      },
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(8),
                      child: const Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ],
                ),
              ),
            if (message.content != null && message.content!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  message.content!,
                  style: TextStyle(
                    color: isCurrentUser ? Colors.white : Colors.black87,
                  ),
                ),
              ),
          ],
        );

      case 'file':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isCurrentUser
                    ? Colors.white.withOpacity(0.2)
                    : theme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    // ✅ FIX: Provide a default empty string if extension is null
                    _getFileIcon(message.file?.extension ?? ''),
                    color: isCurrentUser ? Colors.white : theme.primaryColor,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message.file?.name ?? 'File',
                      style: TextStyle(
                        color: isCurrentUser ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (message.file?.size != null)
                    Text(
                      _formatFileSize(message.file!.size!),
                      style: TextStyle(
                        fontSize: 12,
                        color: isCurrentUser ? Colors.white70 : Colors.grey.shade600,
                      ),
                    ),
                ],
              ),
            ),
            if (message.content != null && message.content!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  message.content!,
                  style: TextStyle(
                    color: isCurrentUser ? Colors.white : Colors.black87,
                  ),
                ),
              ),
          ],
        );

      default:
        return const SizedBox.shrink();
    }
  }

  // ================================================================
  // TIMESTAMP
  // ================================================================

  Widget _buildTimestamp(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _formatTime(message.createdAt),
          style: TextStyle(
            fontSize: 10,
            color: isCurrentUser
                ? Colors.white.withOpacity(0.7)
                : Colors.grey.shade600,
          ),
        ),
        if (isCurrentUser) ...[
          const SizedBox(width: 4),
          Icon(
            message.isRead ? Icons.done_all : Icons.done,
            size: 14,
            color: message.isRead ? Colors.blue : Colors.grey,
          ),
        ],
      ],
    );
  }

  // ================================================================
  // HELPERS
  // ================================================================

  String _formatTime(String? timestamp) {
    if (timestamp == null) return '';
    try {
      final DateTime parsed = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(parsed);

      if (difference.inDays > 0) {
        return '${difference.inDays}d';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m';
      } else {
        return 'Just now';
      }
    } catch (_) {
      return '';
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  IconData _getFileIcon(String extension) {
    final ext = extension.toLowerCase();
    if (['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(ext)) {
      return Icons.image;
    } else if (['mp4', 'avi', 'mov', 'wmv', 'flv', 'mkv'].contains(ext)) {
      return Icons.video_file;
    } else if (['mp3', 'wav', 'aac', 'flac', 'ogg'].contains(ext)) {
      return Icons.audiotrack;
    } else if (['pdf'].contains(ext)) {
      return Icons.picture_as_pdf;
    } else if (['doc', 'docx'].contains(ext)) {
      return Icons.description;
    } else if (['xls', 'xlsx', 'csv'].contains(ext)) {
      return Icons.table_chart;
    } else if (['ppt', 'pptx'].contains(ext)) {
      return Icons.slideshow;
    } else if (['zip', 'rar', '7z', 'tar', 'gz'].contains(ext)) {
      return Icons.folder_zip;
    } else {
      return Icons.insert_drive_file;
    }
  }
}