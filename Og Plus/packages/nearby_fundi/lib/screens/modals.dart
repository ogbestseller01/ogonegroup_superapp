// FILE: modals.dart (same location and import paths as before)
// PostModal: bottom sheet for a media-only post (images + optional video),
// with likes and comments. No title / content any more.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/post.dart';
import '../../providers/post_provider.dart';
import '../../services/api_service.dart';
import '../../utils/image_utils.dart';
import '../../l10n/app_localizations.dart';

class PostModal extends StatefulWidget {
  final Post post;
  const PostModal({super.key, required this.post});

  @override
  State<PostModal> createState() => _PostModalState();
}

class _PostModalState extends State<PostModal> {
  late Post _post;
  final TextEditingController _commentController = TextEditingController();
  final PageController _pageController = PageController();
  final ApiService _api = ApiService();

  bool _isLoading = false;
  bool _isSending = false;
  int _imageIndex = 0;

  @override
  void initState() {
    super.initState();
    _post = widget.post;
  }

  @override
  void dispose() {
    _commentController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Reloads the post (new comments / counts) but keeps the like state,
  /// because the server does not report it.
  Future<void> _refreshPost() async {
    setState(() => _isLoading = true);

    final res = await _api.getPostDetail(_post.id);
    if (!mounted) return;

    if (res.success && res.data != null) {
      final fresh = Post.fromJson(res.data);
      fresh.likedByUser = _post.likedByUser;
      _post = fresh;
    }
    setState(() => _isLoading = false);
  }

  Future<void> _addComment() async {
    final comment = _commentController.text.trim();
    if (comment.isEmpty || _isSending) return;

    setState(() => _isSending = true);

    final res = await _api.commentOnPost(_post.id, comment);
    if (!mounted) return;

    if (res.success) {
      _commentController.clear();
      await _refreshPost();
      if (!mounted) return;
      // Keep the feed's comment count in sync
      context.read<PostProvider>().refreshPost(_post.id);
    } else {
      _snack(res.message);
    }

    if (mounted) setState(() => _isSending = false);
  }

  Future<void> _toggleLike() async {
    final provider = context.read<PostProvider>();

    // If this very object is in the feed, the provider updates it for us.
    final sharedWithFeed = provider.posts.any((p) => identical(p, _post));

    final ok = await provider.likePost(_post.id);
    if (!mounted || !ok) return;

    setState(() {
      if (!sharedWithFeed) {
        _post.likesCount += _post.likedByUser ? -1 : 1;
        _post.likedByUser = !_post.likedByUser;
      }
    });
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

    return Container(
      height: MediaQuery.sizeOf(context).height * 0.95,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.hintColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              icon:
              Icon(Icons.close_rounded, color: theme.colorScheme.onSurface),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(
              child: CircularProgressIndicator(color: theme.primaryColor),
            )
                : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(theme),
                  _buildMedia(theme),
                  _buildActions(theme),
                  const Divider(height: 1),
                  _buildComments(theme, l10n),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          _buildCommentInput(theme, l10n),
        ],
      ),
    );
  }

  // ==============================================================
  // PARTS
  // ==============================================================

  Widget _buildHeader(ThemeData theme) {
    final avatar = _post.technicianAvatar;
    final hasAvatar = avatar != null && avatar.isNotEmpty;
    final name = _post.technicianName.trim();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundImage: hasAvatar
                ? CachedNetworkImageProvider(ImageUtils.getFullImageUrl(avatar))
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
                  _post.technicianName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  _formatDate(_post.createdAt),
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.hintColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedia(ThemeData theme) {
    final images = _post.images;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (images.isNotEmpty)
          SizedBox(
            height: 350,
            width: double.infinity,
            child: Stack(
              children: [
                PageView.builder(
                  controller: _pageController,
                  itemCount: images.length,
                  onPageChanged: (i) => setState(() => _imageIndex = i),
                  itemBuilder: (_, i) => CachedNetworkImage(
                    imageUrl: ImageUtils.getFullImageUrl(images[i]),
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: Center(
                        child: CircularProgressIndicator(
                            color: theme.primaryColor),
                      ),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: Icon(Icons.broken_image,
                          size: 60, color: theme.hintColor),
                    ),
                  ),
                ),
                if (images.length > 1) ...[
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_imageIndex + 1}/${images.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < images.length; i++)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: _imageIndex == i ? 10 : 6,
                            height: _imageIndex == i ? 10 : 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _imageIndex == i
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.5),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        if (_post.hasVideo)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Material(
              color: theme.primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _openVideo(_post.video!),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: theme.primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.play_arrow_rounded,
                          color: theme.colorScheme.onPrimary,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Watch video',
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Icon(Icons.open_in_new_rounded,
                          color: theme.hintColor, size: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildActions(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              _post.likedByUser
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              color: _post.likedByUser ? Colors.red : theme.hintColor,
              size: 28,
            ),
            onPressed: _toggleLike,
          ),
          const SizedBox(width: 4),
          Text('${_post.likesCount}', style: theme.textTheme.bodyMedium),
          const SizedBox(width: 24),
          Icon(Icons.comment_rounded, size: 26, color: theme.hintColor),
          const SizedBox(width: 8),
          Text('${_post.commentsCount}', style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildComments(ThemeData theme, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.comments,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          if (_post.comments.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  l10n.noCommentsYet,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.hintColor),
                ),
              ),
            )
          else
            for (final comment in _post.comments)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 14,
                      child: Text(
                        comment.userName.trim().isEmpty
                            ? '?'
                            : comment.userName.trim()[0].toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            comment.userName,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          Text(comment.comment,
                              style: theme.textTheme.bodyMedium),
                          Text(
                            _formatDate(comment.createdAt),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.hintColor,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildCommentInput(ThemeData theme, AppLocalizations l10n) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        8,
        16,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              enabled: !_isSending,
              decoration: InputDecoration(
                hintText: l10n.writeComment,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest,
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              maxLines: 2,
              minLines: 1,
            ),
          ),
          const SizedBox(width: 10),
          CircleAvatar(
            backgroundColor: theme.primaryColor,
            child: _isSending
                ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: theme.colorScheme.onPrimary,
              ),
            )
                : IconButton(
              icon: Icon(Icons.send_rounded,
                  color: theme.colorScheme.onPrimary),
              onPressed: _addComment,
            ),
          ),
        ],
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