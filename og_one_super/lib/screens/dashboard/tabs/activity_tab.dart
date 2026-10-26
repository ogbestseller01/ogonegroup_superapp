import 'package:flutter/material.dart';

import '../../../config/app_strings.dart';
import '../../../config/app_theme.dart';
import '../../../services/mini_app_service.dart';
import '../../../widgets/dash_common.dart';
import '../../../widgets/dash_header.dart';
import '../core/app_launcher.dart';
import '../core/dash_theme.dart';

enum ActivityStatus { active, completed }

/// One booking / order / request coming from any mini app.
class ActivityItem {
  final String title;
  final String subtitle;
  final String appSlug;
  final ActivityStatus status;
  final DateTime time;

  const ActivityItem({
    required this.title,
    required this.subtitle,
    required this.appSlug,
    required this.status,
    required this.time,
  });
}

/// Activity: one place for bookings and orders from ALL mini apps.
/// The list is empty for now. Fill it from your Laravel API
/// (each mini app / partner reports its bookings to the super app).
class ActivityTab extends StatefulWidget {
  final VoidCallback onMenu;
  final VoidCallback onBrowseApps;

  const ActivityTab({
    super.key,
    required this.onMenu,
    required this.onBrowseApps,
  });

  @override
  State<ActivityTab> createState() => _ActivityTabState();
}

class _ActivityTabState extends State<ActivityTab> {
  // TODO: replace with data loaded from the server.
  final List<ActivityItem> _items = [];
  ActivityStatus? _filter; // null = all

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String _fmt(DateTime d) {
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '${d.day} ${_months[d.month - 1]}, $h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = context.t;
    final layout = DashGrid.of(context);

    final shown = _filter == null
        ? _items
        : _items.where((i) => i.status == _filter).toList();

    return CustomScrollView(
      physics:
      const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      slivers: [
        SliverToBoxAdapter(
          child: DashHeader(
            headline: t.navActivity,
            subline: t.activitySubtitle,
            hPad: layout.hPad,
            onMenu: widget.onMenu,
            onAiAgent: () => AppLauncher.snack(context, t.comingSoonMessage),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 16),
            child: SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: layout.hPad),
                physics: const BouncingScrollPhysics(),
                children: [
                  _FilterChip(
                    label: t.filterAll,
                    selected: _filter == null,
                    onTap: () => setState(() => _filter = null),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: t.filterActive,
                    selected: _filter == ActivityStatus.active,
                    onTap: () =>
                        setState(() => _filter = ActivityStatus.active),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: t.filterDone,
                    selected: _filter == ActivityStatus.completed,
                    onTap: () =>
                        setState(() => _filter = ActivityStatus.completed),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (shown.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 24),
              child: DashEmptyState(
                icon: Icons.receipt_long_rounded,
                title: t.activityEmptyTitle,
                message: t.activityEmptySub,
                actionLabel: t.browseApps,
                onAction: widget.onBrowseApps,
                isDark: isDark,
              ),
            ),
          )
        else
          SliverPadding(
            padding: EdgeInsets.fromLTRB(layout.hPad, 16, layout.hPad, 0),
            sliver: SliverList.separated(
              itemCount: shown.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) => _ActivityCard(
                item: shown[i],
                time: _fmt(shown[i].time),
                isDark: isDark,
              ),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 28)),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Pressable(
      label: label,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: selected ? kGoldGradient : null,
          color: selected ? null : dashSurface(isDark),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : (isDark
                ? Colors.white.withValues(alpha: 0.10)
                : Colors.black.withValues(alpha: 0.08)),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
            color: selected ? kNavy : dashInk(isDark),
          ),
        ),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final ActivityItem item;
  final String time;
  final bool isDark;

  const _ActivityCard({
    required this.item,
    required this.time,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final app = MiniAppService.instance.bySlug(item.appSlug);
    final color = app != null ? dashAppColor(app) : kGold;
    final active = item.status == ActivityStatus.active;
    final statusColor = active ? kGold : AppTheme.success;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: dashSurface(isDark),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.07)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              app != null ? dashIconFor(app.icon) : Icons.apps_rounded,
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: dashInk(isDark),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.subtitle} · $time',
                  maxLines: 1,
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
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              active ? t.filterActive : t.filterDone,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: active ? dashAccent(isDark) : AppTheme.success,
              ),
            ),
          ),
        ],
      ),
    );
  }
}