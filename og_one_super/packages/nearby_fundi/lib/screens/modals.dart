import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
  final ApiService _api = ApiService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _post = widget.post;
  }

  Future<void> _refreshPost() async {
    setState(() => _isLoading = true);
    final res = await _api.getPostDetail(_post.id);
    if (res.success && res.data != null) {
      setState(() {
        _post = Post.fromJson(res.data);
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addComment() async {
    final comment = _commentController.text.trim();
    if (comment.isEmpty) return;

    final res = await _api.commentOnPost(_post.id, comment);
    if (res.success) {
      _commentController.clear();
      await _refreshPost();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.message),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _toggleLike() async {
    await context.read<PostProvider>().likePost(_post.id);
    await _refreshPost();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.95,
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
              icon: Icon(Icons.close_rounded, color: theme.colorScheme.onSurface),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: theme.primaryColor))
                : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundImage: _post.technicianAvatar != null
                              ? CachedNetworkImageProvider(
                            ImageUtils.getFullImageUrl(_post.technicianAvatar!),
                          )
                              : null,
                          child: _post.technicianAvatar == null
                              ? Text(_post.technicianName[0].toUpperCase())
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _post.technicianName,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                _formatDate(_post.createdAt),
                                style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_post.image != null)
                    CachedNetworkImage(
                      imageUrl: ImageUtils.getFullImageUrl(_post.image!),
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        height: 350,
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: Center(child: CircularProgressIndicator(color: theme.primaryColor)),
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: 350,
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: Icon(Icons.broken_image, size: 60, color: theme.hintColor),
                      ),
                    ),
                  if (_post.image == null)
                    Container(
                      height: 100,
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: Center(
                        child: Text(
                          _post.title,
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      _post.title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      _post.content,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 16,
                        height: 1.5,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            _post.likedByUser ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            color: _post.likedByUser ? Colors.red : theme.hintColor,
                            size: 28,
                          ),
                          onPressed: _toggleLike,
                        ),
                        const SizedBox(width: 4),
                        Text('${_post.likesCount}', style: theme.textTheme.bodyMedium),
                        const SizedBox(width: 24),
                        IconButton(
                          icon: Icon(Icons.comment_rounded, size: 26, color: theme.hintColor),
                          onPressed: () {},
                        ),
                        const SizedBox(width: 4),
                        Text('${_post.commentsCount}', style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
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
                                style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
                              ),
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _post.comments.length,
                            itemBuilder: (ctx, i) {
                              final comment = _post.comments[i];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      radius: 14,
                                      child: Text(
                                        comment.userName[0].toUpperCase(),
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
                                          Text(
                                            comment.comment,
                                            style: theme.textTheme.bodyMedium,
                                          ),
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
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            decoration: BoxDecoration(
              color: theme.cardColor,
              boxShadow: [
                BoxShadow(
                  color: theme.shadowColor.withOpacity(0.12),
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
                    decoration: InputDecoration(
                      hintText: l10n.writeComment,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    maxLines: 2,
                    minLines: 1,
                  ),
                ),
                const SizedBox(width: 10),
                CircleAvatar(
                  backgroundColor: theme.primaryColor,
                  child: IconButton(
                    icon: Icon(Icons.send_rounded, color: theme.colorScheme.onPrimary),
                    onPressed: _addComment,
                  ),
                ),
              ],
            ),
          ),
        ],
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