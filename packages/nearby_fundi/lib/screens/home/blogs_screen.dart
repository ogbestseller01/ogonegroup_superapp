// screens/home/blogs_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../providers/post_provider.dart';
import '../../models/post.dart';
import '../../config/app_theme.dart';
import '../../utils/image_utils.dart';
import '../../l10n/app_localizations.dart';
import '../../config/app_routes.dart';
import '../../widgets/safe_youtube_embed.dart';
import '../modals.dart';

class BlogsScreen extends StatefulWidget {
  const BlogsScreen({super.key});

  @override
  State<BlogsScreen> createState() => _BlogsScreenState();
}

class _BlogsScreenState extends State<BlogsScreen> {
  final TextEditingController _filterController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _filterQuery = '';
  bool _searchExpanded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PostProvider>().fetchPosts(refresh: true);
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
    return posts.where((post) =>
    post.title.toLowerCase().contains(q) ||
        post.content.toLowerCase().contains(q)
    ).toList();
  }

  // ─── Navigation to technician detail ──────────────────────────────
  void _goToTechnicianDetail(int technicianId) {
    Navigator.pushNamed(
      context,
      AppRoutes.technicianDetail,
      arguments: technicianId,
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
          onRefresh: () => provider.fetchPosts(refresh: true),
          color: AppTheme.primary,
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
                      horizontal: isTablet ? 24.0 : 0.0,
                      vertical: 4.0,
                    ),
                    sliver: isTablet
                        ? _buildTabletGrid(context, filteredPosts)
                        : _buildMobileList(context, filteredPosts),
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
      floating: false,
      snap: false,
      elevation: 0,
      backgroundColor: theme.scaffoldBackgroundColor,
      surfaceTintColor: Colors.transparent,
      titleSpacing: 4,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            shape: BoxShape.circle,
            border: Border.all(color: theme.dividerColor),
          ),
          child: Icon(Icons.arrow_back_ios_new_rounded,
              size: 16, color: theme.colorScheme.onSurface),
        ),
        onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.home),
      ),
      title: ShaderMask(
        shaderCallback: (bounds) => LinearGradient(
          colors: [AppTheme.primary, AppTheme.primary.withOpacity(0.6)],
        ).createShader(bounds),
        child: Text(
          l10n.blog,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 22,
            letterSpacing: -0.5,
          ),
        ),
      ),
      centerTitle: false,
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              shape: BoxShape.circle,
              border: Border.all(color: theme.dividerColor),
            ),
            child: provider.isLoading
                ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                  strokeWidth: 2.0, color: AppTheme.primary),
            )
                : Icon(Icons.refresh_rounded,
                size: 18, color: theme.colorScheme.onSurface),
          ),
          onPressed: () => provider.fetchPosts(refresh: true),
          tooltip: 'Refresh',
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // ─── SEARCH BAR – Centered & Responsive ──────────────────────────
  Widget _buildSearchBar(BuildContext context) {
    final theme = Theme.of(context);
    final postCount = context.watch<PostProvider>().posts.length;
    final filteredCount = _filteredPosts.length;
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 40.0 : 16.0,
        vertical: 6.0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              height: 46,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(23),
                border: Border.all(
                  color: _searchExpanded
                      ? AppTheme.primary.withOpacity(0.5)
                      : theme.dividerColor,
                  width: _searchExpanded ? 1.4 : 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.shadowColor.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _filterController,
                style: theme.textTheme.bodyMedium,
                onTap: () => setState(() => _searchExpanded = true),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'Search posts...',
                  hintStyle: theme.textTheme.bodySmall?.copyWith(
                    color: theme.hintColor.withOpacity(0.6),
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    size: 20,
                    color: AppTheme.primary,
                  ),
                  suffixIcon: _filterQuery.isNotEmpty
                      ? IconButton(
                    icon: Icon(
                      Icons.clear_rounded,
                      size: 18,
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                    onPressed: () {
                      _filterController.clear();
                      setState(() => _filterQuery = '');
                    },
                  )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onChanged: (value) {
                  setState(() => _filterQuery = value);
                },
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
                style: TextStyle(
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

  Widget _buildMobileList(BuildContext context, List<Post> posts) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
            (ctx, i) {
          final post = posts[i];
          return _BlogPostCard(
            key: ValueKey(post.id),
            post: post,
            isGrid: false,
            onTechnicianTap: _goToTechnicianDetail,
          );
        },
        childCount: posts.length,
      ),
    );
  }

  Widget _buildTabletGrid(BuildContext context, List<Post> posts) {
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 480,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.78,
      ),
      delegate: SliverChildBuilderDelegate(
            (ctx, i) {
          final post = posts[i];
          return _BlogPostCard(
            key: ValueKey(post.id),
            post: post,
            isGrid: true,
            onTechnicianTap: _goToTechnicianDetail,
          );
        },
        childCount: posts.length,
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
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primary.withOpacity(0.15),
                    AppTheme.primary.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.article_rounded,
                  size: 48, color: AppTheme.primary),
            ),
            const SizedBox(height: 24),
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

// ─── BLOG POST CARD ────────────────────────────────────────────────
class _BlogPostCard extends StatefulWidget {
  final Post post;
  final bool isGrid;
  final void Function(int technicianId) onTechnicianTap;

  const _BlogPostCard({
    super.key,
    required this.post,
    this.isGrid = false,
    required this.onTechnicianTap,
  });

  @override
  State<_BlogPostCard> createState() => _BlogPostCardState();
}

class _BlogPostCardState extends State<_BlogPostCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _heartController;
  bool _showBigHeart = false;

  @override
  void initState() {
    super.initState();
    _heartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
  }

  @override
  void dispose() {
    _heartController.dispose();
    super.dispose();
  }

  void _handleDoubleTapLike() {
    if (!widget.post.likedByUser) {
      context.read<PostProvider>().likePost(widget.post.id);
    }
    setState(() => _showBigHeart = true);
    _heartController.forward(from: 0).then((_) {
      if (mounted) setState(() => _showBigHeart = false);
    });
    HapticFeedback.mediumImpact();
  }

  void _openPostModal(BuildContext context) {
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
    final isTablet = MediaQuery.of(context).size.width > 600;
    final post = widget.post;

    final imageUrl = (post.image != null && post.image!.isNotEmpty)
        ? ImageUtils.getFullImageUrl(post.image!)
        : null;

    final hasVideo = post.hasYoutubeVideo;

    return GestureDetector(
      onTap: () => _openPostModal(context),
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: widget.isGrid ? 0.0 : 12.0,
          vertical: widget.isGrid ? 0.0 : 10.0,
        ),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: widget.isGrid ? MainAxisSize.max : MainAxisSize.min,
          children: [
            // ─── Header ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  // ─── Tappable Avatar ──────────────────────────────────
                  GestureDetector(
                    onTap: () => widget.onTechnicianTap(post.technicianId),
                    child: CircleAvatar(
                      radius: 20,
                      backgroundImage: post.technicianAvatar != null
                          ? CachedNetworkImageProvider(
                          ImageUtils.getFullImageUrl(post.technicianAvatar!))
                          : null,
                      child: post.technicianAvatar == null
                          ? Text(
                        post.technicianName[0].toUpperCase(),
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // ─── Tappable Name ────────────────────────────────────
                  Expanded(
                    child: GestureDetector(
                      onTap: () => widget.onTechnicianTap(post.technicianId),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post.technicianName,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            _formatDate(post.createdAt),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.hintColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // ─── Overflow Menu with "View Profile" ──────────────
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_horiz, size: 22, color: theme.hintColor),
                    onSelected: (value) {
                      if (value == 'profile') {
                        widget.onTechnicianTap(post.technicianId);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem<String>(
                        value: 'profile',
                        child: Row(
                          children: [
                            Icon(Icons.person_outline, size: 18),
                            SizedBox(width: 8),
                            Text('View Profile'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ─── Media (Image/Video) ───────────────────────────────────
            if (imageUrl != null || hasVideo)
              Expanded(
                flex: widget.isGrid ? 3 : 0,
                child: GestureDetector(
                  onDoubleTap: imageUrl != null ? _handleDoubleTapLike : null,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      _MediaSection(
                        imageUrl: imageUrl,
                        videoUrl: hasVideo
                            ? (post.youtubeUrl ?? post.youtubeEmbed)
                            : null,
                        isGrid: widget.isGrid,
                      ),
                      AnimatedOpacity(
                        opacity: _showBigHeart ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 150),
                        child: ScaleTransition(
                          scale: Tween<double>(begin: 0.6, end: 1.15)
                              .animate(CurvedAnimation(
                            parent: _heartController,
                            curve: const Interval(0, 0.5, curve: Curves.easeOut),
                          )),
                          child: Icon(
                            Icons.favorite_rounded,
                            color: Colors.white,
                            size: 90,
                            shadows: [
                              Shadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 16),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // ─── Footer ──────────────────────────────────────────────────
            Expanded(
              flex: widget.isGrid ? 2 : 0,
              child: Column(
                mainAxisSize: widget.isGrid ? MainAxisSize.max : MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Actions
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
                        Text('${post.likesCount}',
                            style: theme.textTheme.bodyMedium),
                        const SizedBox(width: 20),
                        IconButton(
                          icon: Icon(Icons.comment_rounded, color: theme.hintColor),
                          onPressed: () => _openPostModal(context),
                        ),
                        Text('${post.commentsCount}',
                            style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),

                  // Content
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                    child: RichText(
                      text: TextSpan(
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: theme.colorScheme.onSurface),
                        children: [
                          TextSpan(
                            text: '${post.technicianName} ',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(
                            text: post.content.length > 120
                                ? '${post.content.substring(0, 120)}...'
                                : post.content,
                          ),
                        ],
                      ),
                    ),
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

// ─── MEDIA SECTION ────────────────────────────────────────────────
class _MediaSection extends StatelessWidget {
  final String? imageUrl;
  final String? videoUrl;
  final bool isGrid;

  const _MediaSection({
    required this.imageUrl,
    required this.videoUrl,
    required this.isGrid,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;
    final hasVideo = videoUrl != null && videoUrl!.trim().isNotEmpty;

    if (!hasImage && !hasVideo) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isTablet = MediaQuery.of(context).size.width > 600;
    final double imageHeight = isTablet ? 380.0 : 280.0;

    if (hasImage) {
      return Stack(
        fit: StackFit.passthrough,
        children: [
          CachedNetworkImage(
            imageUrl: imageUrl!,
            width: double.infinity,
            fit: BoxFit.cover,
            height: isGrid ? double.infinity : imageHeight,
            placeholder: (context, url) => Container(
              height: isGrid ? double.infinity : imageHeight,
              color: theme.colorScheme.surfaceContainerHighest,
              child: Center(
                  child: CircularProgressIndicator(color: AppTheme.primary)),
            ),
            errorWidget: (context, url, error) => Container(
              height: isGrid ? double.infinity : imageHeight,
              color: theme.colorScheme.surfaceContainerHighest,
              child: Icon(Icons.broken_image, size: 60, color: theme.hintColor),
            ),
          ),
          if (hasVideo)
            Positioned(
              top: 10,
              right: 10,
              child: _VideoBadge(videoUrl: videoUrl!),
            ),
        ],
      );
    }

    // Show YouTube embed directly
    return SafeYoutubeEmbed(
      videoUrl: videoUrl!,
      height: isGrid ? double.infinity : imageHeight,
    );
  }
}

// ─── VIDEO BADGE ────────────────────────────────────────────────
class _VideoBadge extends StatelessWidget {
  final String videoUrl;

  const _VideoBadge({required this.videoUrl});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        backgroundColor: Colors.black,
        isScrollControlled: true,
        builder: (_) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: SafeYoutubeEmbed(videoUrl: videoUrl, height: 260),
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
    );
  }
}