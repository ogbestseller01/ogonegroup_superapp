// lib/widgets/work_status_widgets.dart
// Shared UI pieces for the Jobs and Tickets modules.

import 'package:flutter/material.dart';
import '../config/app_theme.dart';

// ── Helpers ──────────────────────────────────────────────────
Color workStatusColor(String status) {
  switch (status) {
    case 'completed':
      return AppTheme.success;
    case 'on-progress':
      return AppTheme.primary;
    case 'pending':
      return AppTheme.warning;
    default:
      return AppTheme.greyText;
  }
}

IconData workStatusIcon(String status) {
  switch (status) {
    case 'completed':
      return Icons.verified_rounded;
    case 'on-progress':
      return Icons.autorenew_rounded;
    case 'pending':
      return Icons.hourglass_empty_rounded;
    default:
      return Icons.info_outline_rounded;
  }
}

String workStatusLabel(String status) =>
    status.replaceAll('-', ' ').toUpperCase();

/// Formats a date in East Africa Time: dd/MM/yyyy • HH:mm
String formatEAT(DateTime? d) {
  if (d == null) return '—';
  final eat = d.isUtc ? d.add(const Duration(hours: 3)) : d;
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(eat.day)}/${two(eat.month)}/${eat.year} • '
      '${two(eat.hour)}:${two(eat.minute)}';
}

// ── Status badge ─────────────────────────────────────────────
class WorkStatusBadge extends StatelessWidget {
  final String status;
  const WorkStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = workStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.13),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        workStatusLabel(status),
        style: TextStyle(
          inherit: true,
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ── Card container ───────────────────────────────────────────
class WorkCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;

  const WorkCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(14),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isDark
                  ? AppTheme.darkBorder
                  : AppTheme.borderLight.withOpacity(0.30),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.25 : 0.06),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

// ── Icon + text line ─────────────────────────────────────────
class WorkMetaLine extends StatelessWidget {
  final IconData icon;
  final String text;
  const WorkMetaLine({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppTheme.darkTextSecondary : AppTheme.greyText;
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Row(
        children: [
          Icon(icon, size: 15, color: muted),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                inherit: true,
                color: muted,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Detail row (label on top, value below) ──────────────────
class WorkInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  const WorkInfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppTheme.darkTextSecondary : AppTheme.greyText;
    final primary = isDark ? Colors.white : AppTheme.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.09),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 19, color: AppTheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          inherit: true,
                          fontSize: 11.5,
                          color: muted,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(value,
                      style: TextStyle(
                          inherit: true,
                          fontSize: 14.5,
                          color: primary,
                          fontWeight: FontWeight.w700,
                          height: 1.3)),
                ],
              ),
            ),
            if (onTap != null)
              Icon(Icons.chevron_right_rounded, color: muted),
          ],
        ),
      ),
    );
  }
}

// ── Filter chips ─────────────────────────────────────────────
class WorkFilterBar extends StatelessWidget {
  final List<String> options; // 'all' + statuses
  final String selected;
  final Map<String, int> counts;
  final ValueChanged<String> onSelected;

  const WorkFilterBar({
    super.key,
    required this.options,
    required this.selected,
    required this.counts,
    required this.onSelected, required Map<String, String> labels,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final o = options[i];
          final active = o == selected;
          final label = o == 'all' ? 'ALL' : workStatusLabel(o);
          final count = counts[o] ?? 0;
          return ChoiceChip(
            label: Text('$label ($count)'),
            selected: active,
            onSelected: (_) => onSelected(o),
            selectedColor: AppTheme.primary,
            backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
            labelStyle: TextStyle(
              inherit: true,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: active
                  ? Colors.white
                  : (isDark ? Colors.white : AppTheme.primary),
            ),
            side: BorderSide(
              color: active
                  ? AppTheme.primary
                  : (isDark
                  ? AppTheme.darkBorder
                  : AppTheme.borderLight.withOpacity(0.5)),
            ),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            showCheckmark: false,
          );
        },
      ),
    );
  }
}

// ── Search field ─────────────────────────────────────────────
class WorkSearchField extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;
  const WorkSearchField(
      {super.key, required this.hint, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: TextField(
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: const Icon(Icons.search_rounded),
          filled: true,
          fillColor: isDark ? AppTheme.darkSurface : Colors.white,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(
              color: isDark
                  ? AppTheme.darkBorder
                  : AppTheme.borderLight.withOpacity(0.5),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(
              color: isDark
                  ? AppTheme.darkBorder
                  : AppTheme.borderLight.withOpacity(0.5),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Empty / error states ─────────────────────────────────────
class WorkEmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final VoidCallback? onRetry;

  const WorkEmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppTheme.darkTextSecondary : AppTheme.greyText;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primary.withOpacity(0.06),
              ),
              child: Icon(icon, size: 38, color: muted),
            ),
            const SizedBox(height: 14),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(
                    inherit: true,
                    color: muted,
                    fontWeight: FontWeight.w600)),
            if (onRetry != null) ...[
              const SizedBox(height: 14),
              TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}