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
              color: theme.shadowColor.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (post.image != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                child: Image.network(
                  ImageUtils.getFullImageUrl(post.image!),
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 200,
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: Icon(Icons.broken_image, size: 60, color: theme.hintColor),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundImage: post.technicianAvatar != null
                            ? NetworkImage(ImageUtils.getFullImageUrl(post.technicianAvatar!))
                            : null,
                        child: post.technicianAvatar == null
                            ? Text(post.technicianName[0].toUpperCase())
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          post.technicianName,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      Text(
                        _formatDate(post.createdAt),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    post.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    post.content.length > 120 ? '${post.content.substring(0, 120)}...' : post.content,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          post.likedByUser ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: post.likedByUser ? Colors.red : theme.hintColor,
                        ),
                        onPressed: () => context.read<PostProvider>().likePost(post.id),
                      ),
                      Text('${post.likesCount}', style: theme.textTheme.bodyMedium),
                      const SizedBox(width: 20),
                      Icon(Icons.comment_rounded, color: theme.hintColor),
                      const SizedBox(width: 4),
                      Text('${post.commentsCount}', style: theme.textTheme.bodyMedium),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}