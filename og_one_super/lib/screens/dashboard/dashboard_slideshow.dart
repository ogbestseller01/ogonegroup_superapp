import 'dart:async';
import 'package:flutter/material.dart';
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

class _DashboardSlideshowState extends State<DashboardSlideshow> {
  // ── Layout ──
  static const double _gap = 5; // horizontal padding around each card
  static const double _baseHeight = 112;
  static const double _dotsGap = 14;

  // ── Motion ──
  static const Duration _autoPlayEvery = Duration(seconds: 5);
  static const Duration _slideDuration = Duration(milliseconds: 450);
  static const Curve _slideCurve = Curves.easeOutCubic;

  PageController? _ctrl;
  double _fraction = 0;
  Timer? _timer;
  int _page = 0;

  bool get _canAutoPlay => widget.slides.length > 1;

  // ── Lifecycle ───────────────────────────────────────────

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
    _startTimer();
  }

  @override
  void didUpdateWidget(covariant DashboardSlideshow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Keep the current page valid if the slide list changes.
    if (_page >= widget.slides.length) {
      _page = widget.slides.isEmpty ? 0 : widget.slides.length - 1;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl?.dispose();
    super.dispose();
  }

  // ── Auto-play ───────────────────────────────────────────

  void _startTimer() {
    _timer?.cancel();
    if (!_canAutoPlay) return;
    _timer = Timer.periodic(_autoPlayEvery, (_) => _next());
  }

  void _stopTimer() => _timer?.cancel();

  void _next() {
    if (!mounted) return;
    final c = _ctrl;
    if (c == null || !c.hasClients || widget.slides.isEmpty) return;
    // Respect the OS "reduce motion" setting.
    if (MediaQuery.disableAnimationsOf(context)) return;
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
    final height = _baseHeight + (scale - 1) * 72;

    return Column(
      children: [
        SizedBox(
          height: height,
          child: Listener(
            // Pause while the finger is down so the card never moves away.
            onPointerDown: (_) => _stopTimer(),
            onPointerUp: (_) => _startTimer(),
            onPointerCancel: (_) => _startTimer(),
            child: PageView.builder(
              controller: _ctrl,
              clipBehavior: Clip.none, // do not crop the card shadows
              itemCount: widget.slides.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: _gap),
                child: _SlideCard(slide: widget.slides[i]),
              ),
            ),
          ),
        ),
        if (widget.slides.length > 1) ...[
          const SizedBox(height: _dotsGap),
          _PageDots(
            count: widget.slides.length,
            current: _page,
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
        padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: s.colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: s.colors.last.withValues(alpha: 0.30),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            // ── Text (left → right) ──
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
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                      letterSpacing: -0.2,
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
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // ── Icon badge ──
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: s.ink.withValues(alpha: 0.13),
                shape: BoxShape.circle,
              ),
              child: Icon(s.icon, size: 23, color: s.ink),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// PAGE DOTS
// ============================================================
class _PageDots extends StatelessWidget {
  final int count;
  final int current;

  /// Tapping a dot jumps to that slide.
  final ValueChanged<int> onSelect;

  const _PageDots({
    required this.count,
    required this.current,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final idle = isDark ? Colors.white24 : Colors.black12;

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
            onTap: () => onSelect(i),
            // Larger invisible tap area around the small dot.
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                width: on ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: on ? AppTheme.secondary : idle,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}