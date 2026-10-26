import 'package:flutter/material.dart';

import '../../../config/app_theme.dart';
import '../screens/dashboard/core/dash_theme.dart';
import 'dash_common.dart';

class DashNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const DashNavItem(this.icon, this.activeIcon, this.label);
}

/// Standard 4-tab bottom bar (no center scan button anymore).
class DashBottomNav extends StatelessWidget {
  static const double _barH = 62;

  final int currentIndex;
  final List<DashNavItem> items;
  final ValueChanged<int> onSelect;

  const DashBottomNav({
    super.key,
    required this.currentIndex,
    required this.items,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final safeBottom = MediaQuery.paddingOf(context).bottom;

    return Container(
      height: _barH + safeBottom,
      padding: EdgeInsets.only(bottom: safeBottom),
      decoration: BoxDecoration(
        color: dashSurface(isDark),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        border: isDark
            ? Border(
                top: BorderSide(color: Colors.white.withValues(alpha: 0.08)))
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.40 : 0.08),
            blurRadius: 22,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++)
            Expanded(
              child: _NavItem(
                item: items[i],
                active: i == currentIndex,
                onTap: () => onSelect(i),
              ),
            ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final DashNavItem item;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    required this.item,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = active
        ? (isDark ? AppTheme.secondary : AppTheme.primary)
        : dashMuted(isDark);

    return Pressable(
      label: item.label,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            padding: EdgeInsets.symmetric(horizontal: active ? 18 : 12, vertical: 4),
            decoration: BoxDecoration(
              color: active
                  ? (isDark
                      ? AppTheme.secondary.withValues(alpha: 0.16)
                      : AppTheme.primary.withValues(alpha: 0.08))
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(active ? item.activeIcon : item.icon,
                size: 22, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: active ? FontWeight.w800 : FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
