import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../config/app_theme.dart';
import '../screens/dashboard/core/dash_theme.dart';

// ════════════════════════════════════════════════
// Pressable (scale + haptic)
// ════════════════════════════════════════════════
class Pressable extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final Widget child;

  const Pressable({
    super.key,
    required this.label,
    required this.onTap,
    required this.child,
    this.onLongPress,
  });

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _pressed = false;

  void _set(bool v) {
    if (_pressed != v) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _set(true),
        onTapUp: (_) => _set(false),
        onTapCancel: () => _set(false),
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onTap();
        },
        onLongPress: widget.onLongPress == null
            ? null
            : () {
                _set(false);
                widget.onLongPress!();
              },
        child: AnimatedScale(
          scale: _pressed ? 0.92 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: widget.child,
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════
// Staggered reveal on first load
// ════════════════════════════════════════════════
class Reveal extends StatelessWidget {
  final int index;
  final bool animate;
  final Widget child;

  const Reveal({
    super.key,
    required this.index,
    required this.animate,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: animate ? 0 : 1, end: 1),
      duration: animate
          ? Duration(milliseconds: 340 + index.clamp(0, 10) * 48)
          : Duration.zero,
      curve: Curves.easeOutCubic,
      builder: (_, v, c) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, 16 * (1 - v)), child: c),
      ),
      child: child,
    );
  }
}

// ════════════════════════════════════════════════
// Label that shrinks to fit its longest word
// ════════════════════════════════════════════════
class FitLabel extends StatelessWidget {
  final String text;
  final TextStyle style;
  final double minFontSize;

  const FitLabel({
    super.key,
    required this.text,
    required this.style,
    this.minFontSize = kLabelMinFont,
  });

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final base = style.fontSize ?? kLabelFont;
        var size = base;

        if (maxW.isFinite) {
          final longest = text
              .split(RegExp(r'\s+'))
              .fold<String>('', (a, b) => b.length > a.length ? b : a);

          final painter = TextPainter(
            text: TextSpan(text: longest, style: style.copyWith(fontSize: base)),
            textDirection: direction,
            textScaler: scaler,
            maxLines: 1,
          )..layout();

          if (painter.width > maxW) {
            size = (base * maxW / painter.width)
                .clamp(minFontSize, base)
                .toDouble();
          }
          painter.dispose();
        }

        return Text(
          text,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: style.copyWith(fontSize: size),
        );
      },
    );
  }
}

// ════════════════════════════════════════════════
// Small buttons & logo
// ════════════════════════════════════════════════
class SoftButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool onDark;

  const SoftButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.onDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final light = onDark || isDark;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: light
            ? Colors.white.withValues(alpha: 0.14)
            : kNavy.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(icon, color: light ? Colors.white : kNavy, size: 21),
          ),
        ),
      ),
    );
  }
}

class DashLogo extends StatelessWidget {
  final double size;
  const DashLogo({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.09),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/images/homeimg.png',
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Icon(
            Icons.apps_rounded,
            color: AppTheme.primary,
            size: size * 0.5,
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════
// Section titles
// ════════════════════════════════════════════════
class SectionTitle extends StatelessWidget {
  final String title;
  final int? count;
  final bool isDark;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionTitle({
    super.key,
    required this.title,
    required this.isDark,
    this.count,
    this.icon,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final accent = dashAccent(isDark);

    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 19, color: accent),
          const SizedBox(width: 7),
        ],
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: dashInk(isDark),
            ),
          ),
        ),
        if (count != null)
          Container(
            constraints: const BoxConstraints(minWidth: 26),
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.secondary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 11.5,
                color: accent,
              ),
            ),
          ),
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(width: 8),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              HapticFeedback.selectionClick();
              onAction!();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    actionLabel!,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: accent,
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, size: 18, color: accent),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

SliverToBoxAdapter dashSection(
  double hPad,
  String title,
  bool isDark, {
  int? count,
  double top = 18,
  IconData? icon,
  String? actionLabel,
  VoidCallback? onAction,
}) {
  return SliverToBoxAdapter(
    child: Padding(
      padding: EdgeInsets.fromLTRB(hPad, top, hPad, 10),
      child: SectionTitle(
        title: title,
        count: count,
        isDark: isDark,
        icon: icon,
        actionLabel: actionLabel,
        onAction: onAction,
      ),
    ),
  );
}

// ════════════════════════════════════════════════
// Empty state
// ════════════════════════════════════════════════
class DashEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool isDark;

  const DashEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.isDark,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 32),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : AppTheme.primary.withValues(alpha: 0.06),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 32,
              color: isDark ? Colors.white38 : Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
              color: dashInk(isDark),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 6),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w500,
                color: dashMuted(isDark),
              ),
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 18),
            Pressable(
              label: actionLabel!,
              onTap: onAction!,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
                decoration: BoxDecoration(
                  gradient: kGoldGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  actionLabel!,
                  style: const TextStyle(
                    color: kNavy,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════
// "Coming soon" box (partner apps)
// ════════════════════════════════════════════════
class PartnerSoonBox extends StatelessWidget {
  final bool isDark;
  final String title;
  final String subtitle;

  const PartnerSoonBox({
    super.key,
    required this.isDark,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final accent = dashAccent(isDark);
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : const Color(0xFFFFF4D6),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.07)
                : kGold.withValues(alpha: 0.25),
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              bottom: -30,
              child: Icon(
                Icons.hourglass_top_rounded,
                size: 100,
                color: kGold.withValues(alpha: isDark ? 0.10 : 0.18),
              ),
            ),
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: isDark
                        ? AppTheme.secondary.withValues(alpha: 0.16)
                        : Colors.white,
                  ),
                  child:
                      Icon(Icons.hourglass_top_rounded, size: 22, color: accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: dashInk(isDark),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: dashMuted(isDark),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 36),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
