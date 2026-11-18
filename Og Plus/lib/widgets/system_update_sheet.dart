// lib/widgets/system_update_sheet.dart
import 'package:flutter/material.dart';

import '../config/app_strings.dart';
import '../config/app_theme.dart';
import '../models/system_update.dart';

String formatSystemUpdateDate(DateTime? d) {
  if (d == null) return '';
  const m = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  final l = d.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${l.day} ${m[l.month - 1]} ${l.year} · ${two(l.hour)}:${two(l.minute)}';
}

/// Full-text view of an app update. Use from card tap, list tap, or push tap.
Future<void> showSystemUpdateSheet(BuildContext context, SystemUpdate u) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final onSurface = Theme.of(context).colorScheme.onSurface;
  final t = context.t;

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: isDark ? const Color(0xFF222938) : Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) => SafeArea(
      top: true,
      bottom: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header Row ──
            Row(
              children: [
                const Icon(Icons.system_update_rounded,
                    color: AppTheme.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    t.appUpdatesPublishedOn(
                      formatSystemUpdateDate(u.publishedAt),
                    ),
                    style: TextStyle(
                      fontSize: 12,
                      color: onSurface.withOpacity(0.55),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: t.close,
                  onPressed: () {
                    if (Navigator.of(sheetContext).canPop()) {
                      Navigator.of(sheetContext).pop();
                    }
                  },
                  icon: Icon(
                    Icons.close_rounded,
                    size: 22,
                    color: onSurface.withOpacity(0.55),
                  ),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // ── Title ──
            Text(
              u.title,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: onSurface,
              ),
            ),
            const SizedBox(height: 10),
            // ── Content ──
            Flexible(
              child: SingleChildScrollView(
                child: Text(
                  u.description,
                  style: TextStyle(
                    fontSize: 14.5,
                    height: 1.5,
                    color: onSurface.withOpacity(0.8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}