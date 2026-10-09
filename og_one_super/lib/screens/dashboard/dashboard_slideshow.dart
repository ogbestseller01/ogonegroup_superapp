import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/app_theme.dart';

// ============================================================
// SLIDE MODEL
// ============================================================
class Slide {
  final String title;
  final String subtitle;
  final List<Color> colors;
  final Color ink;
  final IconData icon;

  const Slide(this.title, this.subtitle, this.colors, this.ink, this.icon);
}

// ============================================================
// SLIDESHOW WIDGET
// ============================================================
class DashboardSlideshow extends StatefulWidget {
  final List<Slide> slides;

  /// Horizontal page padding of the dashboard, so the first card lines up
  /// with the rest of the content while the next card peeks to the screen edge.
  final double hPad;

  const DashboardSlideshow({
    super.key,
    required this.slides,
    this.hPad = 20,
  });

  @override
  State<DashboardSlideshow> createState() => _DashboardSlideshowState();
}

class _DashboardSlideshowState extends State<DashboardSlideshow>
    with SingleTickerProviderStateMixin {
  // ── Layout ──
  static const double _gap = 5; // horizontal padding around each card
  static const double _baseHeight = 128;
  static const double _dotsGap = 12;

  // ── Motion ──
  static const Duration _autoPlayEvery = Duration(seconds: 5);
  static const Duration _slideDuration = Duration(milliseconds: 500);
  static const Curve _slideCurve = Curves.easeOutCubic;

  PageController? _ctrl;
  double _fraction = 0;
  int _page = 0;
  bool _holding = false; // finger is down on the slider

  /// Drives both auto-play and the fill inside the active dot (0 → 1).
  late final AnimationController _progress;

  bool get _canAutoPlay => widget.slides.length > 1;

  // ── Lifecycle ───────────────────────────────────────────

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
    // Keep the current page valid if the slide list changes.
    if (_page >= widget.slides.length) {
      _page = widget.slides.isEmpty ? 0 : widget.slides.length - 1;
    }
    if (oldWidget.slides.length != widget.slides.length) _restart();
  }

  @override
  void dispose() {
    _progress.dispose();
    _ctrl?.dispose();
    super.dispose();
  }

  // ── Auto-play ───────────────────────────────────────────

  /// Resets the progress and starts counting down to the next slide.
  void _restart() {
    _progress.stop();
    _progress.value = 0;
    if (!_canAutoPlay || _holding) return;
    // Respect the OS "reduce motion" setting.
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
    if (c == null || !c.hasClients || widget.slides.isEmpty) return;
    _goTo((_page + 1) % widget.slides.length);
  }

  void _goTo(int index) {
    final c = _ctrl;
    if (c == null || !c.hasClients) return;
    c.animateToPage(index, duration: _slideDuration, curve: _slideCurve);
  }

  // ── Build ───────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final scale =
    MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.3).scale(1.0);
    final height = _baseHeight + (scale - 1) * 76;
    final ctrl = _ctrl!;

    return Column(
      children: [
        SizedBox(
          height: height,
          child: Listener(
            // Pause while the finger is down so the card never moves away.
            onPointerDown: (_) => _pause(),
            onPointerUp: (_) => _resume(),
            onPointerCancel: (_) => _resume(),
            child: PageView.builder(
              controller: ctrl,
              clipBehavior: Clip.none, // do not crop the card shadows
              physics: const BouncingScrollPhysics(),
              itemCount: widget.slides.length,
              onPageChanged: (i) {
                setState(() => _page = i);
                if (!_holding) HapticFeedback.selectionClick();
                _restart();
              },
              itemBuilder: (_, i) => AnimatedBuilder(
                animation: ctrl,
                builder: (_, child) {
                  // 0 = centred card, 1 = a full page away.
                  final page = (ctrl.hasClients && ctrl.position.haveDimensions)
                      ? (ctrl.page ?? _page.toDouble())
                      : _page.toDouble();
                  final d = (page - i).abs().clamp(0.0, 1.0);
                  return Opacity(
                    opacity: 1 - 0.38 * d,
                    child: Transform.scale(
                      scale: 1 - 0.07 * d,
                      child: child,
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: _gap,
                    vertical: 6,
                  ),
                  child: _SlideCard(slide: widget.slides[i]),
                ),
              ),
            ),
          ),
        ),
        if (widget.slides.length > 1) ...[
          const SizedBox(height: _dotsGap),
          _PageDots(
            count: widget.slides.length,
            current: _page,
            progress: _progress,
            onSelect: _goTo,
          ),
        ],
      ],
    );
  }
}

// ============================================================
// SLIDE CARD
// ============================================================
class _SlideCard extends StatelessWidget {
  final Slide slide;
  const _SlideCard({required this.slide});

  @override
  Widget build(BuildContext context) {
    final s = slide;

    return Semantics(
      container: true,
      label: '${s.title}. ${s.subtitle}',
      excludeSemantics: true,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: s.colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            // Coloured glow
            BoxShadow(
              color: s.colors.last.withValues(alpha: 0.38),
              blurRadius: 22,
              spreadRadius: -2,
              offset: const Offset(0, 10),
            ),
            // Tight ambient shadow
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: Stack(
            children: [
              // ── Decorative shapes ──
              Positioned(
                right: -34,
                top: -40,
                child: _Orb(size: 130, color: s.ink.withValues(alpha: 0.08)),
              ),
              Positioned(
                right: 52,
                bottom: -34,
                child: _Orb(size: 80, color: s.ink.withValues(alpha: 0.06)),
              ),
              Positioned(
                left: -26,
                bottom: -40,
                child: _Orb(size: 90, color: Colors.white.withValues(alpha: 0.07)),
              ),
              // Soft sheen across the top edge
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 46,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.14),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),

              // ── Content ──
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
                child: Row(
                  children: [
                    // Text
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            s.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.start,
                            style: TextStyle(
                              color: s.ink,
                              fontSize: 16.5,
                              fontWeight: FontWeight.w800,
                              height: 1.2,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            s.subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.start,
                            style: TextStyle(
                              color: s.ink.withValues(alpha: 0.88),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Icon badge
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            s.ink.withValues(alpha: 0.24),
                            s.ink.withValues(alpha: 0.10),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.14),
                            blurRadius: 12,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Icon(s.icon, size: 26, color: s.ink),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  final double size;
  final Color color;
  const _Orb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
  );
}

// ============================================================
// PAGE DOTS
// The active dot is a pill that fills up as the auto-play timer runs,
// so people can see when the next slide is coming.
// ============================================================
class _PageDots extends StatelessWidget {
  final int count;
  final int current;
  final Animation<double> progress;

  /// Tapping a dot jumps to that slide.
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
    final track = isDark ? Colors.white30 : Colors.black.withValues(alpha: 0.14);

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
            // Larger invisible tap area around the small dot.
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                width: on ? 26 : 7,
                height: 7,
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