// lib/widgets/message_bubble.dart
import 'package:flutter/material.dart';

import '../../../config/app_theme.dart';
import '../../../models/chat_message.dart';



class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isCurrentUser;
  final VoidCallback? onLongPress;
  final Map<String, String>? authHeaders;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
    this.onLongPress,
    this.authHeaders,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bubbleColor = isCurrentUser
        ? AppTheme.primary
        : (isDark ? AppTheme.darkSurfaceLight : Colors.white);

    final textColor = isCurrentUser
        ? Colors.white
        : (isDark ? Colors.white : AppTheme.primary);

    final mutedColor = isCurrentUser
        ? Colors.white.withOpacity(0.75)
        : (isDark ? AppTheme.darkTextSecondary : AppTheme.greyText);

    final isMedia = message.isImage || message.isVideo;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      child: Row(
        mainAxisAlignment:
        isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: GestureDetector(
              onLongPress: onLongPress,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.78,
                ),
                padding: isMedia
                    ? EdgeInsets.zero
                    : const EdgeInsets.fromLTRB(12, 8, 12, 6),
                decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isCurrentUser ? 16 : 4),
                    bottomRight: Radius.circular(isCurrentUser ? 4 : 16),
                  ),
                  border: isCurrentUser
                      ? null
                      : Border.all(
                    color: isDark
                        ? AppTheme.darkBorder
                        : AppTheme.borderLight.withOpacity(0.5),
                    width: 0.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.22 : 0.05),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildContent(context, textColor, mutedColor, isDark),
                    Padding(
                      padding: EdgeInsets.only(
                        left: isMedia ? 8 : 0,
                        right: isMedia ? 8 : 0,
                        bottom: isMedia ? 6 : 0,
                        top: 3,
                      ),
                      child: _buildTimestamp(mutedColor),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
      BuildContext context,
      Color textColor,
      Color mutedColor,
      bool isDark,
      ) {
    switch (message.messageType) {
      case 'text':
        return Align(
          alignment: Alignment.centerLeft,
          child: Text(
            message.content ?? '',
            style: TextStyle(
              color: textColor,
              fontSize: 15.5,
              height: 1.3,
            ),
          ),
        );

      case 'image':
        final url = message.file?.url;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (url != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  url,
                  headers: authHeaders,
                  width: 220,
                  height: 220,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      width: 220,
                      height: 220,
                      color: isDark ? Colors.black26 : Colors.grey.shade200,
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  },
                  errorBuilder: (_, __, ___) => Container(
                    width: 220,
                    height: 220,
                    color: isDark ? AppTheme.darkSurfaceLight : AppTheme.navy50,
                    child: Icon(Icons.broken_image, size: 48, color: mutedColor),
                  ),
                ),
              ),
            if ((message.content ?? '').trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
                child: Text(
                  message.content!,
                  style: TextStyle(color: textColor, fontSize: 14.5),
                ),
              ),
          ],
        );

      case 'video':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 220,
                    height: 160,
                    color: isDark ? AppTheme.darkSurfaceLight : AppTheme.navy100,
                    child: const Icon(
                      Icons.videocam_rounded,
                      size: 48,
                      color: Colors.white54,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.45),
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(10),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                ],
              ),
            ),
            if ((message.content ?? '').trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
                child: Text(
                  message.content!,
                  style: TextStyle(color: textColor, fontSize: 14.5),
                ),
              ),
          ],
        );

      case 'file':
        final accent = isCurrentUser ? AppTheme.secondary : AppTheme.primary;
        return Container(
          margin: const EdgeInsets.only(bottom: 2),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: isCurrentUser
                ? Colors.white.withOpacity(0.12)
                : AppTheme.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_fileIcon(message.file?.ext ?? ''), color: accent, size: 26),
              const SizedBox(width: 10),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.file?.name ?? 'File',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 14.5,
                      ),
                    ),
                    if (message.file?.size != null)
                      Text(
                        message.file!.formattedSize,
                        style: TextStyle(fontSize: 12, color: mutedColor),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildTimestamp(Color mutedColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          message.timeLabel,
          style: TextStyle(fontSize: 11, color: mutedColor),
        ),
        if (isCurrentUser) ...[
          const SizedBox(width: 3),
          Icon(
            message.isRead ? Icons.done_all : Icons.done,
            size: 15,
            color: message.isRead
                ? AppTheme.secondary
                : Colors.white.withOpacity(0.6),
          ),
        ],
      ],
    );
  }

  IconData _fileIcon(String ext) {
    final e = ext.toLowerCase();
    if (e == 'pdf') return Icons.picture_as_pdf;
    if (['doc', 'docx'].contains(e)) return Icons.description;
    if (['xls', 'xlsx', 'csv'].contains(e)) return Icons.table_chart;
    if (['ppt', 'pptx'].contains(e)) return Icons.slideshow;
    if (['zip', 'rar', '7z'].contains(e)) return Icons.folder_zip;
    return Icons.insert_drive_file;
  }
}