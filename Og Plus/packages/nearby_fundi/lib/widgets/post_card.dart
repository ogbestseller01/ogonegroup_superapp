// FILE: post_card.dart (same location and import paths as before)
// Compact post card: first image (+N more / video badge), the fundi, and
// like / comment counts. Tapping opens the post detail screen.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/post_provider.dart';
import '../models/post.dart';
import '../config/app_routes.dart';
import '../utils/image_utils.dart';

class PostCard extends StatelessWidget {
  final Post post;
  const PostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = post.technicianName.trim();
    final avatar = post.technicianAvatar;
    final hasAvatar = avatar != null && avatar.isNotEmpty;

    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        AppRoutes.postDetail,
        arguments: post.id,
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (post.hasMedia) _buildMedia(context, theme),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: hasAvatar
                        ? NetworkImage(ImageUtils.getFullImageUrl(avatar))
                        : null,
                    child: hasAvatar
                        ? null
                        : Text(name.isEmpty ? '?' : name[0].toUpperCase()),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.technicianName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          _formatDate(post.createdAt),
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: theme.hintColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      post.likedByUser
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: post.likedByUser ? Colors.red : theme.hintColor,
                    ),
                    onPressed: () =>
                        context.read<PostProvider>().likePost(post.id),
                  ),
                  Text('${post.likesCount}', style: theme.textTheme.bodyMedium),
                  const SizedBox(width: 20),
                  Icon(Icons.comment_rounded, color: theme.hintColor),
                  const SizedBox(width: 4),
                  Text('${post.commentsCount}',
                      style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedia(BuildContext context, ThemeData theme) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final width = MediaQuery.sizeOf(context).width;
    final extraImages = post.images.length - 1;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: SizedBox(
        height: 200,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (post.hasImages)
              Image.network(
                ImageUtils.getFullImageUrl(post.image!),
                fit: BoxFit.cover,
                cacheWidth: (width * dpr).round(),
                errorBuilder: (_, __, ___) => Container(
                  color: theme.colorScheme.surfaceContainerHighest,
                  child:
                  Icon(Icons.broken_image, size: 60, color: theme.hintColor),
                ),
              )
            else
              Container(
                color: Colors.grey.shade900,
                alignment: Alignment.center,
                child: const Icon(Icons.play_circle_fill_rounded,
                    color: Colors.white70, size: 64),
              ),
            if (extraImages > 0)
              Positioned(
                top: 12,
                right: 12,
                child: _Badge(label: '+$extraImages'),
              ),
            if (post.hasVideo && post.hasImages)
              const Positioned(
                top: 12,
                left: 12,
                child: _Badge(
                  label: 'Video',
                  icon: Icons.play_circle_fill_rounded,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final IconData? icon;

  const _Badge({required this.label, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}