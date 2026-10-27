import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/banner.dart';

class DashboardSlideshow extends StatefulWidget {
  final List<BannerItem> banners;
  final double hPad;
  final bool loading;

  const DashboardSlideshow({
    super.key,
    required this.banners,
    this.hPad = 20,
    this.loading = false,
  });

  @override
  State<DashboardSlideshow> createState() => _DashboardSlideshowState();
}

class _DashboardSlideshowState extends State<DashboardSlideshow>
    with SingleTickerProviderStateMixin {
  static const double _gap = 6;
  static const double _baseHeight = 120;
  static const double _dotsGap = 0;

  static const Duration _autoPlayEvery = Duration(seconds: 5);
  static const Duration _slideDuration = Duration(milliseconds: 500);
  static const Curve _slideCurve = Curves.easeOutCubic;

  PageController? _ctrl;
  double _fraction = 0;
  int _page = 0;
  bool _holding = false;

  late final AnimationController _progress;

  bool get _canAutoPlay => widget.banners.length > 1;

  @override
  void initState() {
    super.initState();
    _progress = AnimationController(vsync: this, duration: _autoPlayEvery)
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) _next();
      });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final w = MediaQuery.sizeOf(context).width;
    final fraction =
    ((w - 2 * widget.hPad + 2 * _gap) / w).clamp(0.6, 0.95).toDouble();

    if (fraction != _fraction) {
      final old = _ctrl;
      _fraction = fraction;
      _ctrl = PageController(viewportFraction: fraction, initialPage: _page);
      if (old != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
      }
    }
    _restart();
  }

  @override
  void didUpdateWidget(covariant DashboardSlideshow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_page >= widget.banners.length) {
      _page = widget.banners.isEmpty ? 0 : widget.banners.length - 1;
    }
    if (oldWidget.banners.length != widget.banners.length) _restart();
  }

  @override
  void dispose() {
    _progress.dispose();
    _ctrl?.dispose();
    super.dispose();
  }

  void _restart() {
    _progress.stop();
    _progress.value = 0;
    if (!_canAutoPlay || _holding) return;
    if (MediaQuery.disableAnimationsOf(context)) return;
    _progress.forward();
  }

  void _pause() {
    _holding = true;
    _progress.stop();
  }

  void _resume() {
    _holding = false;
    _restart();
  }

  void _next() {
    if (!mounted) return;
    final c = _ctrl;
    if (c == null || !c.hasClients || widget.banners.isEmpty) return;
    _goTo((_page + 1) % widget.banners.length);
  }

  void _goTo(int index) {
    final c = _ctrl;
    if (c == null || !c.hasClients) return;
    c.animateToPage(index, duration: _slideDuration, curve: _slideCurve);
  }

  Future<void> _openLink(String? url) async {
    if (url == null || url.trim().isEmpty) return;
    final uri = Uri.tryParse(url.trim());
    if (uri == null) return;

    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open link')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open link')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Loading skeleton
    if (widget.loading && widget.banners.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: widget.hPad),
        child: Container(
          height: _baseHeight,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(22),
          ),
        ),
      );
    }

    // No banners → hide the whole slider
    if (widget.banners.isEmpty) {
      return const SizedBox.shrink();
    }

    final scale =
    MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.3).scale(1.0);
    final height = _baseHeight + (scale - 1) * 40;
    final ctrl = _ctrl!;

    return Column(
      children: [
        SizedBox(
          height: height,
          child: Listener(
            onPointerDown: (_) => _pause(),
            onPointerUp: (_) => _resume(),
            onPointerCancel: (_) => _resume(),
            child: PageView.builder(
              controller: ctrl,
              clipBehavior: Clip.none,
              physics: const BouncingScrollPhysics(),
              itemCount: widget.banners.length,
              onPageChanged: (i) {
                setState(() => _page = i);
                if (!_holding) HapticFeedback.selectionClick();
                _restart();
              },
              itemBuilder: (_, i) => AnimatedBuilder(
                animation: ctrl,
                builder: (_, child) {
                  final page = (ctrl.hasClients && ctrl.position.haveDimensions)
                      ? (ctrl.page ?? _page.toDouble())
                      : _page.toDouble();
                  final d = (page - i).abs().clamp(0.0, 1.0);
                  return Opacity(
                    opacity: 1 - 0.35 * d,
                    child: Transform.scale(
                      scale: 1 - 0.05 * d,
                      child: child,
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: _gap,
                    vertical: 4,
                  ),
                  child: _BannerCard(
                    banner: widget.banners[i],
                    onTap: () => _openLink(widget.banners[i].link),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (widget.banners.length > 1) ...[
          const SizedBox(height: _dotsGap),
          _PageDots(
            count: widget.banners.length,
            current: _page,
            progress: _progress,
            onSelect: _goTo,
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Banner card (image only)
// ─────────────────────────────────────────────────────────────
class _BannerCard extends StatelessWidget {
  static const double _radius = 22;

  final BannerItem banner;
  final VoidCallback onTap;

  const _BannerCard({
    required this.banner,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: banner.hasLink,
      label: banner.hasLink ? 'Open banner link' : 'Banner',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: banner.hasLink ? onTap : null,
          borderRadius: BorderRadius.circular(_radius),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(_radius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 14,
                  spreadRadius: -4,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(_radius),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Image
                  Image.network(
                    banner.image,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.broken_image_outlined, size: 40),
                    ),
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      );
                    },
                  ),

                  // Soft bottom gradient for better contrast (optional)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 40,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.25),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Dots (same as before)
// ─────────────────────────────────────────────────────────────
class _PageDots extends StatelessWidget {
  final int count;
  final int current;
  final Animation<double> progress;
  final ValueChanged<int> onSelect;

  const _PageDots({
    required this.count,
    required this.current,
    required this.progress,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final idle = isDark ? Colors.white24 : Colors.black12;
    final track =
    isDark ? Colors.white30 : Colors.black.withValues(alpha: 0.14);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final on = i == current;
        return Semantics(
          button: true,
          selected: on,
          label: '${i + 1} / $count',
          excludeSemantics: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              HapticFeedback.selectionClick();
              onSelect(i);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                width: on ? 22 : 6,
                height: 6,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: on ? track : idle,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: on
                    ? AnimatedBuilder(
                  animation: progress,
                  builder: (_, __) => Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: progress.value.clamp(0.0, 1.0),
                      heightFactor: 1,
                      child: const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFFFFC61F),
                              Color(0xFFF5A90E),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                )
                    : null,
              ),
            ),
          ),
        );
      }),
    );
  }
}