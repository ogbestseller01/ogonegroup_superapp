// FILE: lib/screens/blog/post_detail_screen.dart
// Post = media only (images + optional video) by a fundi, with likes and
// comments. No title / content / YouTube any more (matches the backend).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/api_service.dart';
import '../../providers/post_provider.dart';
import '../../models/post.dart';
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
  final PageController _pageController = PageController();
  final ApiService _api = ApiService();

  bool _isSubmittingComment = false;
  int _imageIndex = 0;

  @override
  void initState() {
    super.initState();
    _postFuture = _fetchPost();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _loadPost() {
    setState(() => _postFuture = _fetchPost());
  }

  Future<Post?> _fetchPost() async {
    try {
      final res = await _api.getPostDetail(widget.postId);
      if (res.success && res.data != null) {
        return Post.fromJson(res.data);
      }
    } catch (_) {}
    return null;
  }

  void _snack(String message, {Color? color, int seconds = 3}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color ?? Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: Duration(seconds: seconds),
      ),
    );
  }

  Future<void> _addComment() async {
    final comment = _commentController.text.trim();
    if (comment.isEmpty) {
      _snack('Please write a comment');
      return;
    }

    setState(() => _isSubmittingComment = true);

    try {
      final res = await _api.commentOnPost(widget.postId, comment);

      if (res.success) {
        _commentController.clear();
        _loadPost();
        if (mounted) {
          // Update just this post in the feed (no full feed reload)
          context.read<PostProvider>().refreshPost(widget.postId);
        }
        _snack('Comment added successfully!', color: Colors.green, seconds: 2);
      } else {
        _snack(res.message ?? 'Failed to add comment', seconds: 4);
      }
    } catch (e) {
      _snack('Error: $e', seconds: 4);
    } finally {
      if (mounted) setState(() => _isSubmittingComment = false);
    }
  }

  Future<void> _toggleLike() async {
    await context.read<PostProvider>().likePost(widget.postId);
    if (mounted) _loadPost();
  }

  Future<void> _openVideo(String url) async {
    try {
      final ok = await launchUrl(
        Uri.parse(ImageUtils.getFullImageUrl(url)),
        mode: LaunchMode.externalApplication,
      );
      if (!ok) _snack('Could not open video.');
    } catch (_) {
      _snack('Could not open video.');
    }
  }

  // ==============================================================
  // BUILD
  // ==============================================================

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isTablet = MediaQuery.sizeOf(context).width > 600;
    final horizontalPadding = isTablet ? 32.0 : 20.0;
    final imageHeight = isTablet ? 360.0 : 280.0;

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
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError || snapshot.data == null) {
              return _buildError(theme, l10n);
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
                shadowColor: theme.shadowColor.withValues(alpha: 0.1),
                color: theme.cardColor,
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAuthorRow(theme, post),
                      const SizedBox(height: 16),

                      if (post.hasImages) ...[
                        _buildImageGallery(theme, post, imageHeight),
                        const SizedBox(height: 16),
                      ],

                      if (post.hasVideo) ...[
                        _buildVideoTile(theme, post),
                        const SizedBox(height: 16),
                      ],

                      _buildActionsRow(theme, post),

                      const Divider(height: 32, thickness: 1),

                      Text(
                        l10n.comments,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),

                      _buildComments(theme, l10n, post, isDark),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: _buildCommentInput(theme, l10n, isDark),
    );
  }

  // ==============================================================
  // PARTS
  // ==============================================================

  Widget _buildError(ThemeData theme, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withValues(alpha: 0.08),
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
                padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthorRow(ThemeData theme, Post post) {
    final hasAvatar =
        post.technicianAvatar != null && post.technicianAvatar!.isNotEmpty;
    final initial = post.technicianName.trim().isEmpty
        ? '?'
        : post.technicianName.trim()[0].toUpperCase();

    return Row(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
          backgroundImage: hasAvatar
              ? NetworkImage(
              ImageUtils.getFullImageUrl(post.technicianAvatar!))
              : null,
          child: hasAvatar
              ? null
              : Text(
            initial,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.primaryColor,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            post.technicianName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        Text(
          _formatDate(post.createdAt),
          style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
        ),
      ],
    );
  }

  Widget _buildImageGallery(ThemeData theme, Post post, double height) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final width = MediaQuery.sizeOf(context).width;
    final multiple = post.images.length > 1;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: post.images.length,
              onPageChanged: (i) => setState(() => _imageIndex = i),
              itemBuilder: (_, i) => Image.network(
                ImageUtils.getFullImageUrl(post.images[i]),
                fit: BoxFit.cover,
                width: double.infinity,
                height: height,
                cacheWidth: (width * dpr).round(),
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    color: theme.colorScheme.surfaceContainerHighest,
                    alignment: Alignment.center,
                    child: const CircularProgressIndicator(strokeWidth: 2.5),
                  );
                },
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey.shade200,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.broken_image,
                          size: 56, color: Colors.grey.shade400),
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
            if (multiple) ...[
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_imageIndex + 1}/${post.images.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 10,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(post.images.length, (i) {
                    final active = i == _imageIndex;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: active ? 18 : 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: active
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVideoTile(ThemeData theme, Post post) {
    return Material(
      color: theme.primaryColor.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _openVideo(post.video!),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.primaryColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.play_arrow_rounded,
                  color: theme.colorScheme.onPrimary,
                  size: 30,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Watch video',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              Icon(Icons.open_in_new_rounded, color: theme.hintColor, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionsRow(ThemeData theme, Post post) {
    final liked = post.likedByUser;

    return Row(
      children: [
        InkWell(
          onTap: _toggleLike,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: liked
                  ? Colors.red.withValues(alpha: 0.1)
                  : Colors.transparent,
            ),
            child: Row(
              children: [
                Icon(
                  liked
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: liked ? Colors.red : theme.hintColor,
                  size: 22,
                ),
                const SizedBox(width: 4),
                Text(
                  '${post.likesCount}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: liked ? Colors.red : theme.hintColor,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Icon(Icons.comment_rounded, color: theme.hintColor, size: 20),
        const SizedBox(width: 4),
        Text(
          '${post.commentsCount}',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: theme.hintColor,
          ),
        ),
      ],
    );
  }

  Widget _buildComments(
      ThemeData theme,
      AppLocalizations l10n,
      Post post,
      bool isDark,
      ) {
    if (post.comments.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        alignment: Alignment.center,
        child: Column(
          children: [
            Icon(
              Icons.comment_outlined,
              size: 48,
              color: theme.hintColor.withValues(alpha: 0.4),
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
      );
    }

    return Column(
      children: post.comments.map((comment) {
        final initial = comment.userName.trim().isEmpty
            ? '?'
            : comment.userName.trim()[0].toUpperCase();

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
                  child: Text(
                    initial,
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
                          color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.8),
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
      }).toList(),
    );
  }

  Widget _buildCommentInput(
      ThemeData theme,
      AppLocalizations l10n,
      bool isDark,
      ) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
                    hintStyle: TextStyle(color: theme.hintColor, fontSize: 14),
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
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _addComment(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                color: _isSubmittingComment
                    ? theme.hintColor.withValues(alpha: 0.5)
                    : theme.primaryColor,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: _isSubmittingComment
                    ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
                    : const Icon(Icons.send_rounded, color: Colors.white),
                onPressed: _isSubmittingComment ? null : _addComment,
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