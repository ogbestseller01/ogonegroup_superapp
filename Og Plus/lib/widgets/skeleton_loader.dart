import 'package:flutter/material.dart';
import '../config/app_theme.dart';

/// Full-screen, theme-aware skeleton for the super app dashboard.
/// Mirrors: header + search, slideshow (peeking next card + dots),
/// section title, chips and the services grid.
class SkeletonLoader extends StatefulWidget {
  final double hPad;
  final double crossAxisExtent;
  final double mainAxisExtent;
  final double iconSize;

  const SkeletonLoader({
    super.key,
    required this.hPad,
    required this.crossAxisExtent,
    required this.mainAxisExtent,
    required this.iconSize,
  });

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  // Same values as the real header / slideshow
  static const double _searchHeight = 52;
  static const double _overlap = 26;
  static const double _gap = 5;
  static const double _baseHeight = 122;

  static const _headerGradient = LinearGradient(
    colors: [Color(0xFF000C1F), Color(0xFF001D45), Color(0xFF0A3670)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  late final AnimationController _controller;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.45, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bone = isDark ? AppTheme.darkSurfaceLight : const Color(0xFFE3EAF4);
    final cardBg = isDark ? AppTheme.darkSurface : Colors.white;
    final cardBorder = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : AppTheme.borderLight.withValues(alpha: 0.5);
    final onHeader = Colors.white.withValues(alpha: 0.16);

    final hPad = widget.hPad;
    final width = MediaQuery.sizeOf(context).width;
    final top = MediaQuery.paddingOf(context).top;
    final scale =
    MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.3).scale(1.0);
    final slideHeight = _baseHeight + (scale - 1) * 72;
    // Same card width as the real PageView items
    final cardW = width - 2 * hPad;

    return ExcludeSemantics(
      child: FadeTransition(
        opacity: _pulse,
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header + floating search ─────────────────────
              Stack(
                children: [
                  Padding(
                    padding:
                    const EdgeInsets.only(bottom: _searchHeight - _overlap),
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.fromLTRB(
                          hPad, top + 12, hPad, _overlap + 20),
                      decoration: const BoxDecoration(
                        gradient: _headerGradient,
                        borderRadius:
                        BorderRadius.vertical(bottom: Radius.circular(32)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _Bone(
                                  color: onHeader,
                                  width: 42,
                                  height: 42,
                                  radius: 12),
                              const SizedBox(width: 12),
                              _Bone(
                                  color: onHeader,
                                  width: 40,
                                  height: 40,
                                  radius: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: _Bone(
                                      color: onHeader,
                                      width: 130,
                                      height: 14,
                                      radius: 7),
                                ),
                              ),
                              _Bone(
                                  color: onHeader,
                                  width: 42,
                                  height: 42,
                                  radius: 12),
                            ],
                          ),
                          const SizedBox(height: 26),
                          _Bone(
                              color: onHeader,
                              width: 170,
                              height: 30,
                              radius: 10),
                          const SizedBox(height: 8),
                          _Bone(
                              color: onHeader,
                              width: 240,
                              height: 13,
                              radius: 7),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: hPad,
                    right: hPad,
                    bottom: 0,
                    child: Container(
                      height: _searchHeight,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(color: cardBorder),
                      ),
                      child: Row(
                        children: [
                          _Bone(
                              color: bone, width: 22, height: 22, radius: 11),
                          const SizedBox(width: 16),
                          _Bone(color: bone, width: 130, height: 12, radius: 6),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // ── Slideshow (first card + peeking next card) ───
              const SizedBox(height: 20),
              SizedBox(
                height: slideHeight,
                child: Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    Positioned(
                      left: hPad,
                      width: cardW,
                      top: 0,
                      bottom: 0,
                      child: _SlideBone(
                          bg: cardBg, border: cardBorder, bone: bone),
                    ),
                    // next card peeking from the right edge
                    Positioned(
                      left: hPad + cardW + 2 * _gap,
                      width: cardW,
                      top: 0,
                      bottom: 0,
                      child: _SlideBone(
                          bg: cardBg, border: cardBorder, bone: bone),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  4,
                      (i) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: _Bone(
                      color: bone,
                      width: i == 0 ? 18 : 6,
                      height: 6,
                      radius: 3,
                    ),
                  ),
                ),
              ),

              // ── Section title ────────────────────────────────
              Padding(
                padding: EdgeInsets.fromLTRB(hPad, 22, hPad, 12),
                child: Row(
                  children: [
                    _Bone(color: bone, width: 4, height: 16, radius: 4),
                    const SizedBox(width: 10),
                    _Bone(color: bone, width: 120, height: 16, radius: 6),
                    const Spacer(),
                    _Bone(color: bone, width: 30, height: 22, radius: 11),
                  ],
                ),
              ),

              // ── Chips ────────────────────────────────────────
              SizedBox(
                height: 42,
                child: ListView.separated(
                  physics: const NeverScrollableScrollPhysics(),
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: hPad),
                  itemCount: 4,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => Align(
                    alignment: Alignment.center,
                    child: _Bone(
                      color: bone,
                      width: i == 0 ? 120 : 104,
                      height: 42,
                      radius: 21,
                    ),
                  ),
                ),
              ),

              // ── Grid ─────────────────────────────────────────
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(hPad, 14, hPad, 36),
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: widget.crossAxisExtent,
                  mainAxisExtent: widget.mainAxisExtent,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 10,
                ),
                itemCount: 12,
                itemBuilder: (_, i) => Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _Bone(
                      color: bone,
                      width: widget.iconSize,
                      height: widget.iconSize,
                      radius: widget.iconSize / 2,
                    ),
                    const SizedBox(height: 10),
                    _Bone(
                      color: bone,
                      width: widget.iconSize * (i % 3 == 0 ? 0.85 : 0.65),
                      height: 10,
                      radius: 5,
                    ),
                    const SizedBox(height: 6),
                    if (i % 3 == 2)
                      _Bone(
                        color: bone,
                        width: widget.iconSize * 0.45,
                        height: 10,
                        radius: 5,
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

/// One slideshow card: title bones, subtitle bones, icon circle.
class _SlideBone extends StatelessWidget {
  final Color bg;
  final Color border;
  final Color bone;
  const _SlideBone({
    required this.bg,
    required this.border,
    required this.bone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Bone(color: bone, width: 140, height: 16, radius: 8),
                const SizedBox(height: 10),
                _Bone(color: bone, width: 190, height: 12, radius: 6),
                const SizedBox(height: 6),
                _Bone(color: bone, width: 110, height: 12, radius: 6),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _Bone(color: bone, width: 52, height: 52, radius: 26),
        ],
      ),
    );
  }
}

class _Bone extends StatelessWidget {
  final Color color;
  final double width;
  final double height;
  final double radius;

  const _Bone({
    required this.color,
    required this.width,
    required this.height,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}