// screens/home/blogs_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/post_provider.dart';
import '../../models/post.dart';
import '../../config/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../config/app_routes.dart';
import '../../widgets/app_network_image.dart';
import '../modals.dart';

const double _maxCardWidth = 640;

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
    // Same pattern as FundiPostsScreen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<PostProvider>().fetchPosts(refresh: true);
    });
  }

  @override
  void dispose() {
    _filterController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<Post> get _filteredPosts {
    final posts = context.watch<PostProvider>().posts;
    if (_filterQuery.trim().isEmpty) return posts;
    final q = _filterQuery.toLowerCase().trim();
    return posts
        .where((p) =>
    p.title.toLowerCase().contains(q) ||
        p.content.toLowerCase().contains(q) ||
        p.technicianName.toLowerCase().contains(q))
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
    final filteredPosts = _filteredPosts;
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

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
              SliverToBoxAdapter(child: _buildSearchBar(context)),
              if (provider.isLoading && provider.posts.isEmpty)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  ),
                )
              else if (provider.posts.isEmpty)
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
                      horizontal: isTablet ? 24.0 : 12.0,
                      vertical: 4.0,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                            (ctx, i) {
                          final post = filteredPosts[i];
                          return Center(
                            child: ConstrainedBox(
                              constraints:
                              const BoxConstraints(maxWidth: _maxCardWidth),
                              child: _BlogPostCard(
                                key: ValueKey(post.id),
                                post: post,
                                onImageTap: _openImage,
                                onTechnicianTap: _goToTechnicianDetail,
                                onLike: () =>
                                    context.read<PostProvider>().likePost(post.id),
                              ),
                            ),
                          );
                        },
                        childCount: filteredPosts.length,
                      ),
                    ),
                  ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(
      BuildContext context, AppLocalizations l10n, PostProvider provider) {
    final theme = Theme.of(context);
    return SliverAppBar(
      pinned: true,
      elevation: 0,
      backgroundColor: theme.scaffoldBackgroundColor,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded),
        onPressed: () =>
            Navigator.pushReplacementNamed(context, AppRoutes.home),
      ),
      title: Text(
        l10n.blog,
        style: const TextStyle(fontWeight: FontWeight.w800),
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
          onPressed:
          provider.isLoading ? null : () => provider.fetchPosts(refresh: true),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final theme = Theme.of(context);
    final postCount = context.watch<PostProvider>().posts.length;
    final filteredCount = _filteredPosts.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _filterController,
              onChanged: (v) => setState(() => _filterQuery = v),
              decoration: InputDecoration(
                hintText: 'Search posts...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _filterQuery.isEmpty
                    ? null
                    : IconButton(
                  icon: const Icon(Icons.clear_rounded),
                  onPressed: () {
                    _filterController.clear();
                    setState(() => _filterQuery = '');
                  },
                ),
              ),
            ),
          ),
          if (postCount > 0) ...[
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(23),
              ),
              child: Text(
                _filterQuery.isNotEmpty ? '$filteredCount' : '$postCount',
                style: const TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.article_rounded,
                size: 56, color: AppTheme.primary.withOpacity(0.7)),
            const SizedBox(height: 16),
            Text(
              l10n.noBlogPosts,
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Check back later for updates from our technicians.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.55),
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
                size: 48, color: theme.colorScheme.onSurface.withOpacity(0.3)),
            const SizedBox(height: 12),
            Text(
              'No posts match "$_filterQuery"',
              style: theme.textTheme.bodyMedium,
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
  const _FullscreenImageViewer(
      {required this.imagePath, required this.heroTag});

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

String? _videoSource(Post post) {
  final url = post.youtubeUrl?.trim() ?? '';
  if (url.isNotEmpty) return url;
  final embed = post.youtubeEmbed?.trim() ?? '';
  return embed.isNotEmpty ? embed : null;
}

class _BlogPostCard extends StatefulWidget {
  final Post post;
  final void Function(String url, String tag) onImageTap;
  final void Function(int technicianId) onTechnicianTap;
  final VoidCallback onLike;

  const _BlogPostCard({
    super.key,
    required this.post,
    required this.onImageTap,
    required this.onTechnicianTap,
    required this.onLike,
  });

  @override
  State<_BlogPostCard> createState() => _BlogPostCardState();
}

class _BlogPostCardState extends State<_BlogPostCard> {
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
    final video = _videoSource(post);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: theme.dividerColor.withOpacity(0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => widget.onTechnicianTap(post.technicianId),
                  child: ClipOval(
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: AppNetworkImage(
                        path: post.technicianAvatar,
                        fallback: Container(
                          color: AppTheme.primary.withOpacity(0.1),
                          alignment: Alignment.center,
                          child: Text(
                            post.technicianName.isNotEmpty
                                ? post.technicianName[0].toUpperCase()
                                : 'F',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
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
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          _ago(post.createdAt),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_horiz_rounded),
                  onSelected: (v) {
                    if (v == 'profile') {
                      widget.onTechnicianTap(post.technicianId);
                    }
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
          ),

          // Media (multi-image + optional video)
          if (post.hasImages || video != null)
            GestureDetector(
              onDoubleTap: post.hasImages ? _doubleTapLike : null,
              onTap: _openPostModal,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  _MediaSection(
                    images: post.images,
                    videoUrl: video,
                    postId: post.id,
                    onImageTap: widget.onImageTap,
                  ),
                  IgnorePointer(
                    child: AnimatedOpacity(
                      opacity: _heart ? 1 : 0,
                      duration: const Duration(milliseconds: 150),
                      child: AnimatedScale(
                        scale: _heart ? 1.15 : 0.6,
                        duration: const Duration(milliseconds: 250),
                        child: const Icon(
                          Icons.favorite_rounded,
                          size: 90,
                          color: Colors.white,
                          shadows: [
                            Shadow(color: Colors.black38, blurRadius: 16)
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Footer
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 12, 0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    post.likedByUser
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: post.likedByUser
                        ? Colors.red
                        : theme.colorScheme.onSurface.withOpacity(0.75),
                  ),
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    widget.onLike();
                  },
                ),
                Text(
                  '${post.likesCount}',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 20,
                    color: theme.colorScheme.onSurface.withOpacity(0.75),
                  ),
                  onPressed: _openPostModal,
                ),
                Text(
                  '${post.commentsCount}',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (post.title.isNotEmpty)
                  Text(
                    post.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                const SizedBox(height: 3),
                GestureDetector(
                  onTap: _openPostModal,
                  child: Text(
                    post.content,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.4,
                      color: theme.colorScheme.onSurface.withOpacity(0.75),
                    ),
                  ),
                ),
              ],
            ),
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

// ───────────── MEDIA (multi-image) ─────────────

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
  final _pageC = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pageC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.images;

    if (images.isEmpty) {
      return widget.videoUrl == null
          ? const SizedBox.shrink()
          : _YouTubeThumbnail(videoUrl: widget.videoUrl!, height: 220);
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
              final tag = 'blog-image-${widget.postId}-$i';
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
            top: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_page + 1}/${images.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
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
              children: [
                for (var i = 0; i < images.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: _page == i ? 8 : 6,
                    height: _page == i ? 8 : 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _page == i
                          ? Colors.white
                          : Colors.white.withOpacity(0.5),
                    ),
                  ),
              ],
            ),
          ),
        ],
        if (widget.videoUrl != null)
          Positioned(
            top: 10,
            left: 10,
            child: GestureDetector(
              onTap: () => showModalBottomSheet(
                context: context,
                backgroundColor: Colors.black,
                builder: (_) => SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: _YouTubeThumbnail(
                        videoUrl: widget.videoUrl!, height: 240),
                  ),
                ),
              ),
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.play_circle_fill_rounded,
                        color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text('Video',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

String? _youtubeId(String input) {
  var working = input.trim();
  if (working.isEmpty) return null;

  if (working.toLowerCase().contains('<iframe')) {
    final src = RegExp(r'''src=["']([^"']+)["']''', caseSensitive: false)
        .firstMatch(working);
    if (src != null) working = src.group(1) ?? working;
  }

  final match = RegExp(
    r'(?:youtu\.be\/|youtube\.com\/(?:embed\/|v\/|watch\?v=|watch\?.+&v=|shorts\/)|youtube-nocookie\.com\/embed\/)([_\-\w]{11})',
    caseSensitive: false,
  ).firstMatch(working);
  if (match != null) return match.group(1);

  if (working.length == 11 &&
      !working.contains('/') &&
      !working.contains('?')) {
    return working;
  }
  return null;
}

class _YouTubeThumbnail extends StatelessWidget {
  final String videoUrl;
  final double height;
  const _YouTubeThumbnail({required this.videoUrl, required this.height});

  Future<void> _open(String id) async {
    final uri = Uri.parse('https://www.youtube.com/watch?v=$id');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final id = _youtubeId(videoUrl);

    if (id == null) {
      return Container(
        height: height,
        width: double.infinity,
        color: Colors.grey.shade900,
        alignment: Alignment.center,
        child: const Text('Invalid YouTube link',
            style: TextStyle(color: Colors.white54)),
      );
    }

    return GestureDetector(
      onTap: () => _open(id),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              'https://img.youtube.com/vi/$id/hqdefault.jpg',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Container(color: Colors.grey.shade900),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0x8C000000)],
                  stops: [0.5, 1],
                ),
              ),
            ),
            const Center(
              child: CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white24,
                child: Icon(Icons.play_arrow_rounded,
                    color: Colors.white, size: 44),
              ),
            ),
            const Positioned(
              bottom: 12,
              left: 12,
              child: Text('Tap to play on YouTube',
                  style: TextStyle(color: Colors.white, fontSize: 11)),
            ),
          ],
        ),
      ),
    );
  }
}