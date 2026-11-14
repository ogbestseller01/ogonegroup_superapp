// lib/widgets/system_update_card.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/app_strings.dart';
import '../config/app_theme.dart';
import '../models/system_update.dart';
import '../providers/system_update_provider.dart';
import 'system_update_sheet.dart';

class SystemUpdateCard extends StatelessWidget {
  final double hPad;
  const SystemUpdateCard({super.key, required this.hPad});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<SystemUpdateProvider>(
      builder: (context, p, _) {
        final items = p.visible;
        final top = items.isEmpty ? null : items.first;

        if (top != null) {
          WidgetsBinding.instance
              .addPostFrameCallback((_) => p.markViewed(top.id));
        }

        return AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: top == null
              ? const SizedBox(width: double.infinity)
              : Padding(
            padding: EdgeInsets.fromLTRB(
                hPad, 16, hPad, items.length > 1 ? 18 : 4),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween(
                      begin: const Offset(0, -0.08),
                      end: Offset.zero)
                      .animate(anim),
                  child: child,
                ),
              ),
              child: _Stack(
                key: ValueKey(top.id),
                update: top,
                extra: items.length - 1,
                isDark: isDark,
                onDismiss: () => p.dismiss(top.id),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Stack extends StatelessWidget {
  final SystemUpdate update;
  final int extra;
  final bool isDark;
  final VoidCallback onDismiss;

  const _Stack({
    super.key,
    required this.update,
    required this.extra,
    required this.isDark,
    required this.onDismiss,
  });

  Widget _layer(double inset, double bottom) => Positioned(
    left: inset,
    right: inset,
    bottom: bottom,
    height: 40,
    child: Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F2B) : const Color(0xFFF4F6FA),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.black.withOpacity(0.05)),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final bg = isDark ? const Color(0xFF222938) : Colors.white;
    final t = context.t;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (extra > 1) _layer(26, -12),
        if (extra > 0) _layer(13, -6),
        Material(
          color: bg,
          elevation: 0,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => showSystemUpdateSheet(context, update),
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 14, 6, 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.08)
                        : Colors.black.withOpacity(0.06)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.25 : 0.07),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(isDark ? 0.9 : 1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.system_update_rounded,
                        color: Colors.white, size: 22), // <-- New App Update Icon
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          update.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: onSurface),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          update.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 13,
                              height: 1.35,
                              color: onSurface.withOpacity(0.62)),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.schedule_rounded,
                                size: 13, color: onSurface.withOpacity(0.45)),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                formatSystemUpdateDate(update.publishedAt),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 11.5,
                                    color: onSurface.withOpacity(0.5)),
                              ),
                            ),
                            if (extra > 0) ...[
                              const SizedBox(width: 8),
                              Text(
                                t.appUpdatesMore(extra),
                                style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.primary),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: t.appUpdatesDismiss,
                    visualDensity: VisualDensity.compact,
                    icon: Icon(Icons.close_rounded,
                        size: 20, color: onSurface.withOpacity(0.55)),
                    onPressed: onDismiss,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}