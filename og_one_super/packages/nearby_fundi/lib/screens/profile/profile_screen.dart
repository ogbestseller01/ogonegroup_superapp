import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../config/app_routes.dart';
import '../../config/app_theme.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../l10n/app_localizations.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    String initial = 'U';
    if (user != null && user.name.isNotEmpty) {
      initial = user.name[0].toUpperCase();
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final horizontalPadding = isTablet ? 32.0 : 20.0;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          l10n.profile,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        elevation: 0,
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white),
          onPressed: () =>
              Navigator.pushReplacementNamed(context, AppRoutes.home),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: () => context.read<AuthProvider>().loadUser(),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding:
        EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 20),
        child: Column(
          children: [
            // ─── Premium Profile Card ──────────────────────────────────
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.secondary.withOpacity(0.15),
                    Colors.transparent,
                    Colors.transparent,
                    AppTheme.secondary.withOpacity(0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.secondary.withOpacity(0.15),
                    blurRadius: 30,
                    offset: const Offset(0, 8),
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: AppTheme.secondary.withOpacity(0.2),
                    width: 1.5,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // ─── Avatar with Gold Gradient Border ────────────
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.secondary,
                              AppTheme.primary,
                              AppTheme.secondary.withOpacity(0.6),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.secondary.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 56,
                          backgroundColor: AppTheme.primary.withOpacity(0.08),
                          child: Text(
                            initial,
                            style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // ─── Name ──────────────────────────────────────────
                      Text(
                        user?.name ?? l10n.guest,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.email ?? '',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.hintColor,
                          fontSize: 14,
                        ),
                      ),
                      if (user?.phone != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.phone_outlined,
                              size: 14,
                              color: theme.hintColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              user!.phone!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.hintColor,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 16),
                      // ─── Gold Status Badge ─────────────────────────────
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.secondary.withOpacity(0.2),
                              AppTheme.secondary.withOpacity(0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppTheme.secondary.withOpacity(0.3),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Active',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppTheme.secondary,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ─── Action Buttons ──────────────────────────────────────────
            _buildActionButton(
              context,
              icon: Icons.edit_outlined,
              label: l10n.editProfile,
              onTap: () => Navigator.pushNamed(context, AppRoutes.editProfile),
              theme: theme,
              color: AppTheme.primary,
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              context,
              icon: Icons.settings_outlined,
              label: l10n.settings,
              onTap: () => Navigator.pushNamed(context, AppRoutes.settings),
              theme: theme,
              color: AppTheme.secondary,
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              context,
              icon: Icons.notifications_outlined,
              label: l10n.notifications,
              onTap: () =>
                  Navigator.pushNamed(context, AppRoutes.notifications),
              theme: theme,
              color: Colors.blueAccent,
            ),

            const SizedBox(height: 32),

            // ─── Logout Button ──────────────────────────────────────────
            _buildLogoutButton(context, auth, l10n, theme),

            const SizedBox(height: 8),
            Center(
              child: Text(
                'Version 0.0.1',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.hintColor,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  /// Reusable tappable card row.
  ///
  /// Wraps the [ListTile] in a [Material] so ink splashes render
  /// correctly on top of the custom background decoration.
  Widget _buildActionButton(
      BuildContext context, {
        required IconData icon,
        required String label,
        required VoidCallback onTap,
        required ThemeData theme,
        Color? color,
      }) {
    final iconColor = color ?? AppTheme.primary;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: iconColor.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      // ✅ Material provides the background + ink splash surface
      child: Material(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: iconColor.withOpacity(0.08),
                width: 0.5,
              ),
            ),
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // ─── Leading icon ────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        iconColor.withOpacity(0.15),
                        iconColor.withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 16),
                // ─── Label ───────────────────────────────────────
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                // ─── Trailing chevron ────────────────────────────
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: theme.hintColor.withOpacity(0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(
      BuildContext context,
      AuthProvider auth,
      AppLocalizations l10n,
      ThemeData theme,
      ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.error.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            final confirm = await showConfirmationDialog(
              context,
              l10n.logout,
              l10n.logoutConfirmation,
            );
            if (confirm == true) {
              await auth.logout();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, AppRoutes.login);
              }
            }
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.error.withOpacity(0.1),
                width: 0.5,
              ),
            ),
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: AppTheme.error,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    l10n.logout,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                      color: AppTheme.error,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: AppTheme.error.withOpacity(0.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}