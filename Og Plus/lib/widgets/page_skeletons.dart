import 'package:flutter/material.dart';
import '../config/app_theme.dart';

// ══════════════════════════════════════════════════════════════
// SHARED: pulse wrapper + bone (same look as dashboard skeleton)
// ══════════════════════════════════════════════════════════════
class SkeletonPulse extends StatefulWidget {
  final Widget child;
  const SkeletonPulse({super.key, required this.child});

  @override
  State<SkeletonPulse> createState() => _SkeletonPulseState();
}

class _SkeletonPulseState extends State<SkeletonPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _p;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _p = Tween<double>(begin: 0.45, end: 1.0).animate(
      CurvedAnimation(parent: _c, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: FadeTransition(opacity: _p, child: widget.child),
  );
}

class Bone extends StatelessWidget {
  final double width;
  final double height;
  final double radius;
  final Color? color;
  const Bone({
    super.key,
    required this.width,
    required this.height,
    this.radius = 6,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color ??
            (isDark ? AppTheme.darkSurfaceLight : const Color(0xFFE3EAF4)),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

BoxDecoration _skCard(bool isDark) => BoxDecoration(
  color: isDark ? AppTheme.darkSurface : Colors.white,
  borderRadius: BorderRadius.circular(18),
  border: isDark
      ? Border.all(color: AppTheme.darkBorder.withValues(alpha: 0.6))
      : Border.all(color: const Color(0xFFEEF2F8)),
);

const _heroGradient = LinearGradient(
  colors: [Color(0xFF001D45), Color(0xFF0A3670)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

// ══════════════════════════════════════════════════════════════
// DOCUMENT PAGE  (About / Terms / Privacy)
// ══════════════════════════════════════════════════════════════
class DocumentPageSkeleton extends StatelessWidget {
  final double hPad;
  const DocumentPageSkeleton({super.key, this.hPad = 20});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bone = isDark ? AppTheme.darkSurfaceLight : const Color(0xFFE3EAF4);
    final onGrad = Colors.white.withValues(alpha: 0.18);

    return SkeletonPulse(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 40),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: _heroGradient,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                Bone(color: onGrad, width: 54, height: 54, radius: 27),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Bone(color: onGrad, width: 170, height: 20, radius: 8),
                      const SizedBox(height: 8),
                      Bone(color: onGrad, width: 130, height: 12, radius: 6),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          for (int i = 0; i < 3; i++) ...[
            Container(
              padding: const EdgeInsets.all(18),
              decoration: _skCard(isDark),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Bone(color: bone, width: 140, height: 16, radius: 6),
                  const SizedBox(height: 12),
                  Bone(
                      color: bone,
                      width: double.infinity,
                      height: 12,
                      radius: 6),
                  const SizedBox(height: 8),
                  Bone(
                      color: bone,
                      width: double.infinity,
                      height: 12,
                      radius: 6),
                  const SizedBox(height: 8),
                  Bone(color: bone, width: 220, height: 12, radius: 6),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// FAQ
// ══════════════════════════════════════════════════════════════
class FaqPageSkeleton extends StatelessWidget {
  final double hPad;
  const FaqPageSkeleton({super.key, this.hPad = 20});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bone = isDark ? AppTheme.darkSurfaceLight : const Color(0xFFE3EAF4);

    return SkeletonPulse(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 40),
        children: [
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: _skCard(isDark),
            child: Row(
              children: [
                Bone(color: bone, width: 22, height: 22, radius: 11),
                const SizedBox(width: 14),
                Bone(color: bone, width: 140, height: 12, radius: 6),
              ],
            ),
          ),
          const SizedBox(height: 16),
          for (int i = 0; i < 6; i++) ...[
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
              decoration: _skCard(isDark),
              child: Row(
                children: [
                  Expanded(
                    child: Bone(
                      color: bone,
                      width: double.infinity,
                      height: 14,
                      radius: 6,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Bone(color: bone, width: 20, height: 20, radius: 6),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// CONTACT
// ══════════════════════════════════════════════════════════════
class ContactPageSkeleton extends StatelessWidget {
  final double hPad;
  const ContactPageSkeleton({super.key, this.hPad = 20});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bone = isDark ? AppTheme.darkSurfaceLight : const Color(0xFFE3EAF4);
    final onGrad = Colors.white.withValues(alpha: 0.18);

    Widget tile({required bool badge}) => Container(
      padding: const EdgeInsets.all(14),
      decoration: _skCard(isDark),
      child: Row(
        children: [
          Bone(color: bone, width: 42, height: 42, radius: 12),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Bone(color: bone, width: 60, height: 10, radius: 5),
                const SizedBox(height: 8),
                Bone(color: bone, width: 160, height: 14, radius: 6),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (badge)
            Bone(color: bone, width: 60, height: 26, radius: 20)
          else
            Bone(color: bone, width: 14, height: 14, radius: 4),
        ],
      ),
    );

    return SkeletonPulse(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 40),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: _heroGradient,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                Bone(color: onGrad, width: 54, height: 54, radius: 27),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Bone(color: onGrad, width: 140, height: 20, radius: 8),
                      const SizedBox(height: 8),
                      Bone(color: onGrad, width: 200, height: 12, radius: 6),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Bone(color: bone, width: 120, height: 12, radius: 6),
          const SizedBox(height: 12),
          tile(badge: false),
          const SizedBox(height: 10),
          tile(badge: false),
          const SizedBox(height: 24),
          Bone(color: bone, width: 130, height: 12, radius: 6),
          const SizedBox(height: 12),
          for (int i = 0; i < 3; i++) ...[
            tile(badge: true),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 14),
          Bone(color: bone, width: 100, height: 12, radius: 6),
          const SizedBox(height: 12),
          for (int i = 0; i < 3; i++) ...[
            tile(badge: true),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// FEEDBACK
// ══════════════════════════════════════════════════════════════
class FeedbackPageSkeleton extends StatelessWidget {
  final double hPad;
  const FeedbackPageSkeleton({super.key, this.hPad = 20});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bone = isDark ? AppTheme.darkSurfaceLight : const Color(0xFFE3EAF4);

    return SkeletonPulse(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 40),
        children: [
          Bone(color: bone, width: 200, height: 20, radius: 8),
          const SizedBox(height: 8),
          Bone(color: bone, width: double.infinity, height: 12, radius: 6),
          const SizedBox(height: 6),
          Bone(color: bone, width: 240, height: 12, radius: 6),
          const SizedBox(height: 24),
          Bone(color: bone, width: 120, height: 12, radius: 6),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(
              4,
                  (i) => Bone(
                color: bone,
                width: i == 0 ? 110 : 96,
                height: 34,
                radius: 20,
              ),
            ),
          ),
          const SizedBox(height: 22),
          Bone(color: bone, width: 100, height: 12, radius: 6),
          const SizedBox(height: 10),
          Row(
            children: List.generate(
              5,
                  (i) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Bone(color: bone, width: 34, height: 34, radius: 17),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Bone(color: bone, width: double.infinity, height: 56, radius: 14),
          const SizedBox(height: 14),
          Bone(color: bone, width: double.infinity, height: 56, radius: 14),
          const SizedBox(height: 14),
          Bone(color: bone, width: double.infinity, height: 130, radius: 14),
          const SizedBox(height: 24),
          Bone(color: bone, width: double.infinity, height: 52, radius: 16),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// SETTINGS
// ══════════════════════════════════════════════════════════════
class SettingsPageSkeleton extends StatelessWidget {
  final double hPad;
  const SettingsPageSkeleton({super.key, this.hPad = 20});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bone = isDark ? AppTheme.darkSurfaceLight : const Color(0xFFE3EAF4);

    Widget section({
      required int rows,
      required double titleW,
    }) =>
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Bone(color: bone, width: titleW, height: 12, radius: 6),
            const SizedBox(height: 12),
            Container(
              decoration: _skCard(isDark),
              child: Column(
                children: [
                  for (int i = 0; i < rows; i++) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Bone(color: bone, width: 42, height: 42, radius: 12),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Bone(
                                    color: bone,
                                    width: 120,
                                    height: 14,
                                    radius: 6),
                                const SizedBox(height: 8),
                                Bone(
                                    color: bone,
                                    width: 180,
                                    height: 11,
                                    radius: 6),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Bone(color: bone, width: 22, height: 22, radius: 6),
                        ],
                      ),
                    ),
                    if (i != rows - 1)
                      Divider(
                        height: 1,
                        thickness: 0.6,
                        color: isDark
                            ? AppTheme.darkBorder
                            : Colors.grey.shade200,
                        indent: 16,
                        endIndent: 16,
                      ),
                  ],
                ],
              ),
            ),
          ],
        );

    return SkeletonPulse(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 40),
        children: [
          section(rows: 3, titleW: 100),
          const SizedBox(height: 28),
          section(rows: 1, titleW: 90),
          const SizedBox(height: 28),
          section(rows: 2, titleW: 110),
          const SizedBox(height: 28),
          section(rows: 2, titleW: 120),
          const SizedBox(height: 28),
          section(rows: 3, titleW: 130),
          const SizedBox(height: 28),
          section(rows: 4, titleW: 100),
        ],
      ),
    );
  }
}