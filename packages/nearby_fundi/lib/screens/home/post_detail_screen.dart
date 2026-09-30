import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../providers/post_provider.dart';
import '../../models/post.dart';
import '../../config/app_theme.dart';
import '../../config/app_routes.dart';
import '../../utils/image_utils.dart';
import '../../l10n/app_localizations.dart';

class PostDetailScreen extends StatefulWidget {
  final int postId;
  const PostDetailScreen({super.key, required this.postId});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  late Future<Post?> _postFuture;
  final TextEditingController _commentController = TextEditingController();
  final ApiService _api = ApiService();
  bool _isSubmittingComment = false;

  @override
  void initState() {
    super.initState();
    _loadPost();
  }

  void _loadPost() {
    setState(() {
      _postFuture = _fetchPost();
    });
  }

  Future<Post?> _fetchPost() async {
    try {
      final res = await _api.getPostDetail(widget.postId);
      if (res.success && res.data != null) {
        return Post.fromJson(res.data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> _addComment() async {
    final comment = _commentController.text.trim();
    if (comment.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please write a comment'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    setState(() {
      _isSubmittingComment = true;
    });

    try {
      final res = await _api.commentOnPost(widget.postId, comment);

      if (res.success) {
        _commentController.clear();
        _loadPost();

        final postProvider = context.read<PostProvider>();
        await postProvider.fetchPosts(refresh: true);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Comment added successfully!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(res.message ?? 'Failed to add comment'),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingComment = false;
        });
      }
    }
  }

  Future<void> _toggleLike() async {
    await context.read<PostProvider>().likePost(widget.postId);
    _loadPost();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final horizontalPadding = isTablet ? 32.0 : 20.0;
    final imageHeight = isTablet ? 320.0 : 240.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.blog,
          style: TextStyle(
            color: theme.colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        backgroundColor: theme.primaryColor,
        foregroundColor: theme.colorScheme.onPrimary,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadPost,
            color: theme.colorScheme.onPrimary,
          ),
        ],
      ),
      body: Container(
        color: theme.colorScheme.surface,
        child: FutureBuilder<Post?>(
          future: _postFuture,
          key: ValueKey(_postFuture),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError || snapshot.data == null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error.withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.error_outline_rounded,
                          size: 56,
                          color: theme.colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.noContent,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _loadPost,
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: Text(l10n.retry),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primaryColor,
                          foregroundColor: theme.colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final post = snapshot.data!;
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: 20,
              ),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                elevation: 2,
                shadowColor: theme.shadowColor.withOpacity(0.1),
                color: theme.cardColor,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Post Image
                      if (post.image != null && post.image!.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.network(
                            ImageUtils.getFullImageUrl(post.image!),
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: imageHeight,
                            errorBuilder: (_, __, ___) => Container(
                              height: imageHeight,
                              color: Colors.grey.shade200,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.broken_image,
                                    size: 60,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Image not available',
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                      const SizedBox(height: 20),

                      // Title
                      Text(
                        post.title,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Author Row
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: theme.primaryColor.withOpacity(0.1),
                            backgroundImage: post.technicianAvatar != null && post.technicianAvatar!.isNotEmpty
                                ? NetworkImage(ImageUtils.getFullImageUrl(post.technicianAvatar!))
                                : null,
                            child: post.technicianAvatar == null || post.technicianAvatar!.isEmpty
                                ? Text(
                              post.technicianName[0].toUpperCase(),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: theme.primaryColor,
                              ),
                            )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              post.technicianName,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                          Text(
                            _formatDate(post.createdAt),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.hintColor,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Content
                      Card(
                        color: isDark
                            ? Colors.grey.shade800
                            : theme.colorScheme.surfaceContainerHighest,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            post.content,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              height: 1.8,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Like & Comment Count
                      Row(
                        children: [
                          // Like Button
                          InkWell(
                            onTap: _toggleLike,
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: post.likedByUser
                                    ? Colors.red.withOpacity(0.1)
                                    : Colors.transparent,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    post.likedByUser
                                        ? Icons.favorite_rounded
                                        : Icons.favorite_border_rounded,
                                    color: post.likedByUser
                                        ? Colors.red
                                        : theme.hintColor,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${post.likesCount}',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w500,
                                      color: post.likedByUser
                                          ? Colors.red
                                          : theme.hintColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(width: 16),

                          // Comments Count
                          Row(
                            children: [
                              Icon(
                                Icons.comment_rounded,
                                color: theme.hintColor,
                                size: 20,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${post.commentsCount}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: theme.hintColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const Divider(
                        height: 32,
                        thickness: 1,
                      ),

                      // Comments Section Title
                      Text(
                        l10n.comments,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Comments List
                      if (post.comments.isEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          alignment: Alignment.center,
                          child: Column(
                            children: [
                              Icon(
                                Icons.comment_outlined,
                                size: 48,
                                color: theme.hintColor.withOpacity(0.4),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                l10n.noCommentsYet,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.hintColor,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: post.comments.length,
                          itemBuilder: (ctx, index) {
                            final comment = post.comments[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                              color: isDark
                                  ? Colors.grey.shade800
                                  : Colors.grey.shade50,
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundColor: theme.primaryColor.withOpacity(0.1),
                                      child: Text(
                                        comment.userName[0].toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: theme.primaryColor,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            comment.userName,
                                            style: theme.textTheme.titleSmall?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: theme.colorScheme.onSurface,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            comment.comment,
                                            style: theme.textTheme.bodyMedium?.copyWith(
                                              color: theme.colorScheme.onSurface.withOpacity(0.8),
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _formatDate(comment.createdAt),
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              fontSize: 11,
                                              color: theme.hintColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        decoration: BoxDecoration(
          color: theme.cardColor,
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withOpacity(0.12),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  color: isDark
                      ? Colors.grey.shade800
                      : theme.colorScheme.surfaceContainerHighest,
                ),
                child: TextField(
                  controller: _commentController,
                  enabled: !_isSubmittingComment,
                  decoration: InputDecoration(
                    hintText: l10n.writeComment,
                    hintStyle: TextStyle(
                      color: theme.hintColor,
                      fontSize: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  maxLines: 1,
                  onSubmitted: (_) => _addComment(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                color: _isSubmittingComment
                    ? theme.hintColor.withOpacity(0.5)
                    : theme.primaryColor,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: _isSubmittingComment
                    ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
                    : const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                ),
                onPressed: _isSubmittingComment ? null : _addComment,
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

    if (diff.inDays > 7) {
      return '${diff.inDays}d ago';
    }
    if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    }
    if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    }
    if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    }
    return 'Just now';
  }
}