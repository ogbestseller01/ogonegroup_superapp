// FILE: lib/screens/home/blogs_screen.dart
// Posts feed: each post is media only (images + optional video) by a fundi,
// with likes and comments. No title / content / YouTube any more.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/post_provider.dart';
import '../../models/post.dart';
import '../../config/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../config/app_routes.dart';
import '../../utils/image_utils.dart';
import '../../widgets/app_network_image.dart';
import '../modals.dart';

const double _maxCardWidth = 640;
const double _loadMoreThreshold = 400;

class BlogsScreen extends StatefulWidget {
  const BlogsScreen({super.key});

  @override
  State<BlogsScreen> createState() => _BlogsScreenState();
}

class _BlogsScreenState extends State<BlogsScreen> {
  final TextEditingController _filterController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _filterQuery = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<PostProvider>().fetchPosts(refresh: true);
    });
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _filterController.dispose();
    super.dispose();
  }

  /// Loads the next page when the user nears the bottom.
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - _loadMoreThreshold) {
      final provider = context.read<PostProvider>();
      if (provider.hasMore && !provider.isLoading) {
        provider.fetchPosts();
      }
    }
  }

  List<Post> _applyFilter(List<Post> posts) {
    final q = _filterQuery.trim().toLowerCase();
    if (q.isEmpty) return posts;
    return posts
        .where((p) => p.technicianName.toLowerCase().contains(q))
        .toList();
  }

  void _goToTechnicianDetail(int technicianId) {
    if (technicianId <= 0) return;
    Navigator.pushNamed(
      context,
      AppRoutes.technicianDetail,
      arguments: technicianId,
    );
  }

  void _openImage(String url, String tag) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (_, __, ___) =>
            _FullscreenImageViewer(imagePath: url, heroTag: tag),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PostProvider>();
    final posts = provider.posts;
    final filteredPosts = _applyFilter(posts);
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isTablet = MediaQuery.sizeOf(context).width > 600;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.primary,
          onRefresh: () => provider.fetchPosts(refresh: true),
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics()),
            slivers: [
              _buildSliverAppBar(context, l10n, provider),
              SliverToBoxAdapter(
                child: _buildSearchBar(
                  context,
                  total: posts.length,
                  shown: filteredPosts.length,
                ),
              ),
              if (provider.isLoading && posts.isEmpty)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  ),
                )
              else if (posts.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyState(context, l10n),
                )
              else if (filteredPosts.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildNoResultsState(context),
                  )
                else
                  SliverPadding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 24.0 : 16.0,
                      vertical: 8.0,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                            (ctx, i) {
                          final post = filteredPosts[i];
                          return Center(
                            child: ConstrainedBox(
                              constraints:
                              const BoxConstraints(maxWidth: _maxCardWidth),
                              child: _PostCard(
                                key: ValueKey(post.id),
                                post: post,
                                onImageTap: _openImage,
                                onTechnicianTap: _goToTechnicianDetail,
                                onLike: () => context
                                    .read<PostProvider>()
                                    .likePost(post.id),
                              ),
                            ),
                          );
                        },
                        childCount: filteredPosts.length,
                      ),
                    ),
                  ),

              // Loading more indicator
              if (provider.isLoading && posts.isNotEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ),
      ),
    );
  }

  // ==============================================================
  // APP BAR / SEARCH
  // ==============================================================

  Widget _buildSliverAppBar(
      BuildContext context,
      AppLocalizations l10n,
      PostProvider provider,
      ) {
    final theme = Theme.of(context);
    return SliverAppBar(
      pinned: true,
      floating: true,
      elevation: 0,
      scrolledUnderElevation: 1,
      backgroundColor: theme.scaffoldBackgroundColor,
      surfaceTintColor: Colors.transparent,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        onPressed: () =>
            Navigator.pushReplacementNamed(context, AppRoutes.home),
      ),
      title: Text(
        l10n.blog,
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
      ),
      actions: [
        IconButton(
          tooltip: 'Refresh',
          icon: provider.isLoading
              ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : const Icon(Icons.refresh_rounded),
          onPressed: provider.isLoading
              ? null
              : () => provider.fetchPosts(refresh: true),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildSearchBar(
      BuildContext context, {
        required int total,
        required int shown,
      }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _filterController,
                onChanged: (v) => setState(() => _filterQuery = v),
                decoration: InputDecoration(
                  hintText: 'Search by fundi name...',
                  hintStyle: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    fontSize: 15,
                  ),
                  prefixIcon: const Icon(Icons.search_rounded, size: 22),
                  suffixIcon: _filterQuery.isEmpty
                      ? null
                      : IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 20),
                    onPressed: () {
                      _filterController.clear();
                      setState(() => _filterQuery = '');
                    },
                  ),
                  border: InputBorder.none,
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
          ),
          if (total > 0) ...[
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                _filterQuery.isNotEmpty ? '$shown' : '$total',
                style: const TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ==============================================================
  // EMPTY STATES
  // ==============================================================

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.photo_library_rounded,
                  size: 48, color: AppTheme.primary.withValues(alpha: 0.8)),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.noBlogPosts,
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Check back later for updates from our technicians.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded,
                size: 56,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
            const SizedBox(height: 16),
            Text(
              'No posts match "$_filterQuery"',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════ FULLSCREEN IMAGE ═══════════════════════════

class _FullscreenImageViewer extends StatelessWidget {
  final String imagePath;
  final String heroTag;

  const _FullscreenImageViewer({
    required this.imagePath,
    required this.heroTag,
  });

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
                minScale: 0.5,
                maxScale: 4,
                child: AppNetworkImage(
                  path: imagePath,
                  fit: BoxFit.contain,
                  fallback: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.broken_image, size: 60, color: Colors.white54),
                      SizedBox(height: 8),
                      Text('Image not available',
                          style: TextStyle(color: Colors.white54)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: SafeArea(
              child: IconButton(
                style: IconButton.styleFrom(backgroundColor: Colors.black45),
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════ CARD ═══════════════════════════════════

Future<void> _openVideo(String url) async {
  final uri = Uri.tryParse(ImageUtils.getFullImageUrl(url));
  if (uri == null) return;
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

class _PostCard extends StatefulWidget {
  final Post post;
  final void Function(String url, String tag) onImageTap;
  final void Function(int technicianId) onTechnicianTap;
  final VoidCallback onLike;

  const _PostCard({
    super.key,
    required this.post,
    required this.onImageTap,
    required this.onTechnicianTap,
    required this.onLike,
  });

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> {
  bool _heart = false;

  void _doubleTapLike() {
    HapticFeedback.mediumImpact();
    if (!widget.post.likedByUser) widget.onLike();
    setState(() => _heart = true);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _heart = false);
    });
  }

  void _openPostModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PostModal(post: widget.post),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final post = widget.post;
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.7);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.05),
      clipBehavior: Clip.antiAlias,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(theme, post),

          // Media (multi-image + optional video)
          if (post.hasMedia)
            GestureDetector(
              onDoubleTap: post.hasImages ? _doubleTapLike : null,
              onTap: post.hasImages ? _openPostModal : null,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  _MediaSection(
                    images: post.images,
                    videoUrl: post.hasVideo ? post.video : null,
                    postId: post.id,
                    onImageTap: widget.onImageTap,
                  ),
                  IgnorePointer(
                    child: AnimatedOpacity(
                      opacity: _heart ? 1 : 0,
                      duration: const Duration(milliseconds: 150),
                      child: AnimatedScale(
                        scale: _heart ? 1.2 : 0.5,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutBack,
                        child: const Icon(
                          Icons.favorite_rounded,
                          size: 100,
                          color: Colors.white,
                          shadows: [
                            Shadow(color: Colors.black38, blurRadius: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Footer actions
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    post.likedByUser
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: post.likedByUser ? Colors.red : muted,
                    size: 26,
                  ),
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    widget.onLike();
                  },
                ),
                Text(
                  '${post.likesCount}',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: Icon(Icons.chat_bubble_outline_rounded,
                      size: 24, color: muted),
                  onPressed: _openPostModal,
                ),
                Text(
                  '${post.commentsCount}',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, Post post) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => widget.onTechnicianTap(post.technicianId),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.primary.withValues(alpha: 0.2),
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: SizedBox(
                  width: 42,
                  height: 42,
                  child: AppNetworkImage(
                    path: post.technicianAvatar,
                    fallback: Container(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      alignment: Alignment.center,
                      child: Text(
                        post.technicianName.isNotEmpty
                            ? post.technicianName[0].toUpperCase()
                            : 'F',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () => widget.onTechnicianTap(post.technicianId),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.technicianName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _ago(post.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color:
                      theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_horiz_rounded,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            onSelected: (v) {
              if (v == 'profile') widget.onTechnicianTap(post.technicianId);
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'profile',
                child: ListTile(
                  leading: Icon(Icons.person_outline),
                  title: Text('View Profile'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _ago(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inDays > 7) return '${t.day}/${t.month}/${t.year}';
    if (d.inDays > 0) return '${d.inDays}d ago';
    if (d.inHours > 0) return '${d.inHours}h ago';
    if (d.inMinutes > 0) return '${d.inMinutes}m ago';
    return 'Just now';
  }
}

// ───────────── MEDIA (multi-image + video) ─────────────

class _MediaSection extends StatefulWidget {
  final List<String> images;
  final String? videoUrl;
  final int postId;
  final void Function(String url, String tag) onImageTap;

  const _MediaSection({
    required this.images,
    required this.videoUrl,
    required this.postId,
    required this.onImageTap,
  });

  @override
  State<_MediaSection> createState() => _MediaSectionState();
}

class _MediaSectionState extends State<_MediaSection> {
  final PageController _pageC = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pageC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.images;
    final video = widget.videoUrl;

    // Video only (no images)
    if (images.isEmpty) {
      return video == null
          ? const SizedBox.shrink()
          : _VideoTile(url: video, height: 220);
    }

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
                child: Hero(
                  tag: tag,
                  child: AppNetworkImage(
                    path: images[i],
                    width: double.infinity,
                  ),
                ),
              );
            },
          ),
        ),
        if (images.length > 1) ...[
          Positioned(
            top: 12,
            right: 12,
            child: _OverlayChip(label: '${_page + 1}/${images.length}'),
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
                    width: _page == i ? 10 : 6,
                    height: _page == i ? 10 : 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _page == i
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
              ],
            ),
          ),
        ],
        if (video != null)
          Positioned(
            top: 12,
            left: 12,
            child: GestureDetector(
              onTap: () => _openVideo(video),
              child: const _OverlayChip(
                label: 'Video',
                icon: Icons.play_circle_fill_rounded,
              ),
            ),
          ),
      ],
    );
  }
}

class _OverlayChip extends StatelessWidget {
  final String label;
  final IconData? icon;

  const _OverlayChip({required this.label, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: icon == null ? 10 : 12, vertical: 5),
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

/// Shown when a post has a video but no images.
class _VideoTile extends StatelessWidget {
  final String url;
  final double height;

  const _VideoTile({required this.url, required this.height});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openVideo(url),
      child: Container(
        height: height,
        width: double.infinity,
        color: Colors.grey.shade900,
        alignment: Alignment.center,
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: Colors.white24,
              child: Icon(Icons.play_arrow_rounded,
                  color: Colors.white, size: 48),
            ),
            SizedBox(height: 10),
            Text(
              'Tap to play video',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}