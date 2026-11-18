import 'package:flutter/material.dart';

import '../../config/app_strings.dart';
import '../../config/app_theme.dart';
import '../screens/dashboard/core/dash_theme.dart';
import 'dash_common.dart';

class DashDrawer extends StatelessWidget {
  const DashDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = context.t;

    return Drawer(
      backgroundColor: dashSurface(isDark),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(
                18, MediaQuery.paddingOf(context).top + 18, 14, 24),
            decoration: const BoxDecoration(gradient: kHeaderGradient),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const DashLogo(size: 44),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        t.appName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    SoftButton(
                      icon: Icons.close_rounded,
                      tooltip: t.close,
                      onTap: () => Navigator.of(context).pop(),
                      onDark: true,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  t.welcomePartnerships,
                  style: TextStyle(
                    color: AppTheme.secondary.withValues(alpha: 0.95),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
