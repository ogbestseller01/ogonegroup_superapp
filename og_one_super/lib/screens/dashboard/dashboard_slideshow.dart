import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Slide {
  final String title;
  final String subtitle;
  final List<Color> colors;
  final Color ink;
  final IconData icon;

  const Slide(this.title, this.subtitle, this.colors, this.ink, this.icon);
}

class DashboardSlideshow extends StatefulWidget {
  final List<Slide> slides;
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
  static const double _gap = 6;
  static const double _baseHeight = 100; // was 128
  static const double _dotsGap = 0;

  static const Duration _autoPlayEvery = Duration(seconds: 5);
  static const Duration _slideDuration = Duration(milliseconds: 500);
  static const Curve _slideCurve = Curves.easeOutCubic;

  PageController? _ctrl;
  double _fraction = 0;
  int _page = 0;
  bool _holding = false;

  late final AnimationController _progress;

  bool get _canAutoPlay => widget.slides.length > 1;

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
    if (c == null || !c.hasClients || widget.slides.isEmpty) return;
    _goTo((_page + 1) % widget.slides.length);
  }

  void _goTo(int index) {
    final c = _ctrl;
    if (c == null || !c.hasClients) return;
    c.animateToPage(index, duration: _slideDuration, curve: _slideCurve);
  }

  @override
  Widget build(BuildContext context) {
    final scale =
    MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.3).scale(1.0);
    final height = _baseHeight + (scale - 1) * 56;
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
              itemCount: widget.slides.length,
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

class _SlideCard extends StatelessWidget {
  static const double _radius = 22;

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
          borderRadius: BorderRadius.circular(_radius),
          boxShadow: [
            BoxShadow(
              color: s.colors.last.withValues(alpha: 0.28),
              blurRadius: 16,
              spreadRadius: -4,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_radius),
          child: Stack(
            children: [
              Positioned(
                right: -22,
                top: -36,
                child: _Orb(size: 104, color: s.ink.withValues(alpha: 0.09)),
              ),
              Positioned(
                left: -20,
                bottom: -40,
                child: _Orb(
                    size: 78, color: Colors.white.withValues(alpha: 0.08)),
              ),
              Positioned(
                right: 4,
                bottom: -22,
                child: Transform.rotate(
                  angle: -0.2,
                  child: Icon(
                    s.icon,
                    size: 92,
                    color: s.ink.withValues(alpha: 0.13),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 14, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            s.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: s.ink,
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              height: 1.18,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            s.subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: s.ink.withValues(alpha: 0.9),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              height: 1.28,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: s.ink.withValues(alpha: 0.18),
                        border: Border.all(
                          color: s.ink.withValues(alpha: 0.25),
                          width: 1.1,
                        ),
                      ),
                      child: Icon(s.icon, size: 22, color: s.ink),
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