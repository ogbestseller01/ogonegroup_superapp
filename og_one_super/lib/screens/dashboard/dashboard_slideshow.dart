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
  static const double _gap = 5; // horizontal padding around each card
  static const double _baseHeight = 122;
  static const Duration _autoPlayEvery = Duration(seconds: 5);

  PageController? _ctrl;
  double _fraction = 0;
  Timer? _timer;
  int _page = 0;

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

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(_autoPlayEvery, (_) {
      if (!mounted) return;
      final c = _ctrl;
      if (c == null || !c.hasClients || widget.slides.isEmpty) return;
      // Respect the OS "reduce motion" setting.
      if (MediaQuery.disableAnimationsOf(context)) return;
      c.animateToPage(
        (_page + 1) % widget.slides.length,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl?.dispose();
    super.dispose();
  }

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
            onPointerDown: (_) => _timer?.cancel(),
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
        const SizedBox(height: 14),
        _PageDots(count: widget.slides.length, current: _page),
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
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
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
                    fontSize: 16.5,
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
                  style: TextStyle(
                    color: s.ink.withValues(alpha: 0.88),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: s.ink.withValues(alpha: 0.13),
              shape: BoxShape.circle,
            ),
            child: Icon(s.icon, size: 26, color: s.ink),
          ),
        ],
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
  const _PageDots({required this.count, required this.current});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final on = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: on ? 18 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: on
                ? AppTheme.secondary
                : (isDark ? Colors.white24 : Colors.black12),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}