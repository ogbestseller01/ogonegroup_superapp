import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';

import '../../config/app_routes.dart';
import '../../config/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../models/post.dart';
import '../../providers/post_provider.dart';
import '../../widgets/app_network_image.dart';
import '../../widgets/custom_button.dart';

const int _maxImages = 10;
const double _maxCardWidth = 640;
const Color _gold = Color(0xFFF2B93B);

// ═══════════════════════════ MAIN SCREEN ═══════════════════════════════════

class FundiPostsScreen extends StatefulWidget {
  const FundiPostsScreen({super.key});

  @override
  State<FundiPostsScreen> createState() => _FundiPostsScreenState();
}

class _FundiPostsScreenState extends State<FundiPostsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<PostProvider>().fetchMyPosts();
    });
  }

  void _snack(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: error ? AppTheme.error : AppTheme.primary, behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _openForm({Post? post}) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      constraints: const BoxConstraints(maxWidth: 700),
      builder: (_) => _PostFormSheet(post: post),
    );
    if (saved == null || !mounted) return;
    final l10n = AppLocalizations.of(context)!;
    if (saved) {
      _snack(post != null ? l10n.postUpdated : l10n.postCreated);
    } else {
      _snack(context.read<PostProvider>().error ?? 'Failed to save post', error: true);
    }
  }

  Future<void> _confirmDelete(Post post) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deletePost),
        content: Text(l10n.areYouSure),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), style: TextButton.styleFrom(foregroundColor: AppTheme.error), child: Text(l10n.delete)),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    final ok = await context.read<PostProvider>().deletePost(post.id);
    if (!mounted) return;
    if (ok) _snack(l10n.postDeleted);
    else _snack(context.read<PostProvider>().error ?? 'Delete failed', error: true);
  }

  void _openImage(String url, String tag) {
    Navigator.of(context).push(PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black87,
      pageBuilder: (_, __, ___) => _FullscreenImageViewer(imagePath: url, heroTag: tag),
      transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PostProvider>();
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.primary,
          onRefresh: () => provider.fetchMyPosts(),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Row(
                    children: [
                      _SoftIconButton(icon: Icons.arrow_back_ios_new_rounded, tooltip: 'Back', onTap: () => Navigator.pushReplacementNamed(context, AppRoutes.home)),
                      const SizedBox(width: 12),
                      Container(width: 5, height: 28, decoration: BoxDecoration(color: _gold, borderRadius: BorderRadius.circular(3))),
                      const SizedBox(width: 10),
                      Expanded(child: Text(l10n.myPosts, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, color: AppTheme.primary))),
                      _SoftIconButton(icon: Icons.refresh_rounded, tooltip: 'Refresh', loading: provider.isLoading, onTap: provider.isLoading ? null : () => provider.fetchMyPosts()),
                      const SizedBox(width: 8),
                      _SoftIconButton(icon: Icons.add_rounded, tooltip: l10n.createPost, filled: true, onTap: () => _openForm()),
                    ],
                  ),
                ),
              ),

              if (provider.isLoading && provider.posts.isEmpty)
                const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
              else if (provider.posts.isEmpty)
                SliverFillRemaining(hasScrollBody: false, child: _EmptyState(title: l10n.noPosts, onCreate: () => _openForm()))
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, i) {
                      final post = provider.posts[i];
                      return Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: _maxCardWidth),
                          child: _PostCard(
                            key: ValueKey(post.id),
                            post: post,
                            onImageTap: _openImage,
                            onEdit: () => _openForm(post: post),
                            onDelete: () => _confirmDelete(post),
                            onLike: () => context.read<PostProvider>().likePost(post.id),
                          ),
                        ),
                      );
                    }, childCount: provider.posts.length),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────── SOFT ICON BUTTON ─────────────

class _SoftIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final bool filled;
  final bool loading;
  const _SoftIconButton({required this.icon, required this.tooltip, required this.onTap, this.filled = false, this.loading = false});

  @override
  Widget build(BuildContext context) {
    final fg = filled ? Colors.white : AppTheme.primary;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: filled ? AppTheme.primary : AppTheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            width: 44, height: 44,
            child: Center(
              child: loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : Icon(icon, size: 22, color: fg),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String title;
  final VoidCallback onCreate;
  const _EmptyState({required this.title, required this.onCreate});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 96, height: 96, decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.08), shape: BoxShape.circle), child: const Icon(Icons.dynamic_feed_rounded, size: 44, color: AppTheme.primary)),
            const SizedBox(height: 20),
            Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text('Share your work with photos and videos to build your portfolio.', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: AppTheme.primary, minimumSize: const Size(160, 52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              onPressed: onCreate,
              icon: const Icon(Icons.add_rounded),
              label: const Text('New post'),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════ FULLSCREEN IMAGE VIEWER ═══════════════════════════

class _FullscreenImageViewer extends StatelessWidget {
  final String imagePath;
  final String heroTag;
  const _FullscreenImageViewer({required this.imagePath, required this.heroTag});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: Stack(
        children: [
          Center(
            child: Hero(
              tag: heroTag,
              child: InteractiveViewer(
                minScale: 0.5, maxScale: 4,
                child: AppNetworkImage(path: imagePath, fit: BoxFit.contain, fallback: const Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.broken_image, size: 60, color: Colors.white54), SizedBox(height: 8), Text('Image not available', style: TextStyle(color: Colors.white54))])),
              ),
            ),
          ),
          Positioned(top: 12, right: 12, child: SafeArea(child: IconButton(style: IconButton.styleFrom(backgroundColor: Colors.black45), icon: const Icon(Icons.close_rounded, color: Colors.white), onPressed: () => Navigator.pop(context)))),
        ],
      ),
    );
  }
}

// ═══════════════════════════════ FORM ══════════════════════════════════════

class _PostFormSheet extends StatefulWidget {
  final Post? post;
  const _PostFormSheet({this.post});

  @override
  State<_PostFormSheet> createState() => _PostFormSheetState();
}

class _PostFormSheetState extends State<_PostFormSheet> {
  final _picker = ImagePicker();

  late final List<String> _kept = List<String>.of(widget.post?.images ?? const []);
  final List<String> _new = [];

  String? _videoPath;
  bool _removeVideo = false;

  bool _saving = false;

  bool get _isEdit => widget.post != null;
  int get _total => _kept.length + _new.length;

  Future<void> _addPhotos() async {
    final room = _maxImages - _total;
    if (room <= 0) return;
    final files = await _picker.pickMultiImage(imageQuality: 85);
    if (files.isEmpty || !mounted) return;
    setState(() => _new.addAll(files.take(room).map((f) => f.path)));
  }

  Future<void> _pickVideo() async {
    final file = await _picker.pickVideo(source: ImageSource.gallery, maxDuration: const Duration(minutes: 2));
    if (file != null) {
      setState(() {
        _videoPath = file.path;
        _removeVideo = false;
      });
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);

    final provider = context.read<PostProvider>();

    final data = <String, dynamic>{
      if (_new.isNotEmpty) 'images': List<String>.of(_new),
      if (_isEdit) 'keep_images': List<String>.of(_kept),
      if (_videoPath != null) 'video': _videoPath,
      if (_removeVideo) 'remove_video': true,
    };

    final ok = _isEdit ? await provider.updatePost(widget.post!.id, data) : await provider.createPost(data);

    if (!mounted) return;
    Navigator.pop(context, ok);
  }

  Widget _thumb({required Widget image, required VoidCallback onRemove}) {
    return Stack(
      children: [
        ClipRRect(borderRadius: BorderRadius.circular(12), child: SizedBox(width: 76, height: 76, child: image)),
        Positioned(top: 2, right: 2, child: GestureDetector(onTap: onRemove, child: const CircleAvatar(radius: 10, backgroundColor: Colors.black54, child: Icon(Icons.close_rounded, size: 14, color: Colors.white)))),
      ],
    );
  }

  Widget _photos(ThemeData theme) {
    final tiles = <Widget>[
      for (var i = 0; i < _kept.length; i++) _thumb(image: AppNetworkImage(path: _kept[i]), onRemove: () => setState(() => _kept.removeAt(i))),
      for (var i = 0; i < _new.length; i++) _thumb(image: Image.file(File(_new[i]), fit: BoxFit.cover), onRemove: () => setState(() => _new.removeAt(i))),
      if (_total < _maxImages)
        InkWell(
          onTap: _addPhotos,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 76, height: 76,
            decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3))),
            child: const Icon(Icons.add_photo_alternate_rounded, color: AppTheme.primary),
          ),
        ),
    ];
    return Wrap(spacing: 10, runSpacing: 10, children: tiles);
  }

  Widget _videoSection(ThemeData theme) {
    final hasExisting = widget.post?.hasVideo == true && !_removeVideo;

    if (_videoPath == null && !hasExisting) {
      return InkWell(
        onTap: _pickVideo,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3), style: BorderStyle.solid),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.video_call_rounded, color: AppTheme.primary),
              SizedBox(width: 8),
              Text('Attach a short video clip', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          const Icon(Icons.play_circle_fill_rounded, color: AppTheme.primary, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _videoPath != null ? _videoPath!.split('/').last : 'Existing Video Attached',
              style: const TextStyle(fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () {
              setState(() {
                _videoPath = null;
                _removeVideo = true;
              });
            },
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(_isEdit ? l10n.editPostTitle : l10n.createPostTitle, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 18),

            Text('Video Clip', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            _videoSection(theme),

            const SizedBox(height: 18),

            Row(
              children: [
                Text('Photos', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                Text('($_total/$_maxImages)', style: theme.textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 10),
            _photos(theme),
            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(child: TextButton(onPressed: _saving ? null : () => Navigator.pop(context), child: Text(l10n.cancel))),
                const SizedBox(width: 12),
                Expanded(flex: 2, child: CustomButton(text: _isEdit ? l10n.update : l10n.create, onPressed: _save, isLoading: _saving)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════ CARD ══════════════════════════════════════

class _PostCard extends StatefulWidget {
  final Post post;
  final void Function(String url, String tag) onImageTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onLike;

  const _PostCard({super.key, required this.post, required this.onImageTap, required this.onEdit, required this.onDelete, required this.onLike});

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> {
  bool _heart = false;

  void _doubleTapLike() {
    HapticFeedback.mediumImpact();
    if (!widget.post.likedByUser) widget.onLike();
    setState(() => _heart = true);
    Future.delayed(const Duration(milliseconds: 600), () { if (mounted) setState(() => _heart = false); });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final post = widget.post;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      clipBehavior: Clip.antiAlias,
      color: theme.colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PostHeader(post: post, onEdit: widget.onEdit, onDelete: widget.onDelete),

          // ✅ Video
          if (post.hasVideo)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: _DirectVideoPlayer(videoUrl: post.videoUrl!),
              ),
            ),

          // ✅ Images
          if (post.hasImages)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: GestureDetector(
                  onDoubleTap: _doubleTapLike,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      _MediaSection(images: post.images, postId: post.id, onImageTap: widget.onImageTap),
                      IgnorePointer(
                        child: AnimatedOpacity(
                          opacity: _heart ? 1 : 0,
                          duration: const Duration(milliseconds: 150),
                          child: AnimatedScale(
                            scale: _heart ? 1.15 : 0.6,
                            duration: const Duration(milliseconds: 250),
                            child: const Icon(Icons.favorite_rounded, size: 90, color: Colors.white, shadows: [Shadow(color: Colors.black38, blurRadius: 16)]),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          _PostFooter(post: post, onLike: widget.onLike),
          const SizedBox(height: 14),
        ],
      ),
    );
  }
}

class _DirectVideoPlayer extends StatefulWidget {
  final String videoUrl;
  const _DirectVideoPlayer({required this.videoUrl});

  @override
  State<_DirectVideoPlayer> createState() => _DirectVideoPlayerState();
}

class _DirectVideoPlayerState extends State<_DirectVideoPlayer> {
  late VideoPlayerController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        if (mounted) setState(() => _initialized = true);
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return Container(height: 220, color: Colors.black12, child: const Center(child: CircularProgressIndicator()));
    }

    return AspectRatio(
      aspectRatio: _controller.value.aspectRatio,
      child: Stack(
        alignment: Alignment.center,
        children: [
          VideoPlayer(_controller),
          GestureDetector(
            onTap: () {
              setState(() {
                _controller.value.isPlaying ? _controller.pause() : _controller.play();
              });
            },
            child: AnimatedOpacity(
              opacity: _controller.value.isPlaying ? 0 : 1,
              duration: const Duration(milliseconds: 300),
              child: Container(
                color: Colors.black26,
                child: const Center(child: Icon(Icons.play_arrow_rounded, size: 64, color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MediaSection extends StatefulWidget {
  final List<String> images;
  final int postId;
  final void Function(String url, String tag) onImageTap;

  const _MediaSection({required this.images, required this.postId, required this.onImageTap});

  @override
  State<_MediaSection> createState() => _MediaSectionState();
}

class _MediaSectionState extends State<_MediaSection> {
  final _pageC = PageController();
  int _page = 0;

  @override
  void dispose() { _pageC.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final images = widget.images;
    if (images.isEmpty) return const SizedBox.shrink();

    return Stack(
      children: [
        AspectRatio(
          aspectRatio: 4 / 3,
          child: PageView.builder(
            controller: _pageC,
            itemCount: images.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (context, i) {
              final tag = 'post-image-${widget.postId}-$i';
              return GestureDetector(
                onTap: () => widget.onImageTap(images[i], tag),
                child: Hero(tag: tag, child: AppNetworkImage(path: images[i], width: double.infinity)),
              );
            },
          ),
        ),
        if (images.length > 1) ...[
          Positioned(
            top: 10, right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
              child: Text('${_page + 1}/${images.length}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
            ),
          ),
          Positioned(
            bottom: 10, left: 0, right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < images.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: _page == i ? 8 : 6,
                    height: _page == i ? 8 : 6,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: _page == i ? Colors.white : Colors.white.withValues(alpha: 0.5)),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _PostHeader extends StatelessWidget {
  final Post post;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _PostHeader({required this.post, required this.onEdit, required this.onDelete});

  String _ago(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inDays > 7) return '${t.day}/${t.month}/${t.year}';
    if (d.inDays > 0) return '${d.inDays}d ago';
    if (d.inHours > 0) return '${d.inHours}h ago';
    if (d.inMinutes > 0) return '${d.inMinutes}m ago';
    return 'Just now';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initial = post.technicianName.isNotEmpty ? post.technicianName[0].toUpperCase() : 'F';
    final initialAvatar = Container(color: AppTheme.primary.withValues(alpha: 0.1), alignment: Alignment.center, child: Text(initial, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primary)));

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 8, 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: _gold, width: 2)),
            child: ClipOval(child: SizedBox(width: 40, height: 40, child: AppNetworkImage(path: post.technicianAvatar, fallback: initialAvatar))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(post.technicianName, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, color: AppTheme.primary)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.schedule_rounded, size: 13, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                    const SizedBox(width: 4),
                    Text(_ago(post.createdAt), style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            icon: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.more_horiz_rounded, size: 20, color: AppTheme.primary)),
            onSelected: (v) => v == 'edit' ? onEdit() : onDelete(),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit_outlined, color: AppTheme.primary), title: Text('Edit post'), contentPadding: EdgeInsets.zero)),
              PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete_outline_rounded, color: AppTheme.error), title: Text('Delete post', style: TextStyle(color: AppTheme.error)), contentPadding: EdgeInsets.zero)),
            ],
          ),
        ],
      ),
    );
  }
}

class _PostFooter extends StatelessWidget {
  final Post post;
  final VoidCallback onLike;
  const _PostFooter({required this.post, required this.onLike});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.7);
    final liked = post.likedByUser;

    Widget chip({required IconData icon, required Color color, required Color bg, required int count, VoidCallback? onTap}) {
      return Material(
        color: bg, borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap, borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 6),
                Text('$count', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700, color: color)),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        children: [
          chip(
            icon: liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            color: liked ? Colors.red : muted,
            bg: liked ? Colors.red.withValues(alpha: 0.1) : theme.colorScheme.onSurface.withValues(alpha: 0.05),
            count: post.likesCount,
            onTap: () { HapticFeedback.selectionClick(); onLike(); },
          ),
          const SizedBox(width: 10),
          chip(icon: Icons.chat_bubble_outline_rounded, color: muted, bg: theme.colorScheme.onSurface.withValues(alpha: 0.05), count: post.commentsCount),
        ],
      ),
    );
  }
}