
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
    final isDark = theme.brightness == Brightness.dark;

    final displayName = user?.name ?? l10n.guest;
    final trimmedName = displayName.trim();

    final initial = trimmedName.isNotEmpty
        ? trimmedName[0].toUpperCase()
        : 'U';

    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontalPadding = screenWidth > 700 ? 32.0 : 20.0;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,

      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: Text(
          l10n.profile,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 21,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
          ),
          onPressed: () {
            Navigator.pushReplacementNamed(
              context,
              AppRoutes.home,
            );
          },
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh profile',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () async {
              await context.read<AuthProvider>().loadUser();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),

      body: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 720,
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                12,
                horizontalPadding,
                32,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // PROFILE HEADER
                  _ProfileHeader(
                    initial: initial,
                    name: displayName,
                    email: user?.email ?? '',
                    phone: user?.phone,
                    isDark: isDark,
                  ),

                  const SizedBox(height: 28),

                  // QUICK ACTIONS
                  const _SectionHeading(
                    title: 'YOUR ACCOUNT',
                    subtitle: 'Manage your personal account',
                  ),

                  const SizedBox(height: 14),

                  _ProfileActionCard(
                    icon: Icons.person_outline_rounded,
                    iconColor: const Color(0xFF1976D2),
                    title: l10n.editProfile,
                    subtitle: 'Update your personal information',
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.editProfile,
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  _ProfileActionCard(
                    icon: Icons.settings_outlined,
                    iconColor: const Color(0xFF00897B),
                    title: l10n.settings,
                    subtitle: 'Manage your app preferences',
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.settings,
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  _ProfileActionCard(
                    icon: Icons.notifications_none_rounded,
                    iconColor: const Color(0xFF8E5AC7),
                    title: l10n.notifications,
                    subtitle: 'View your latest notifications',
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.notifications,
                      );
                    },
                  ),

                  const SizedBox(height: 28),

                  // ACCOUNT STATUS
                  const _SectionHeading(
                    title: 'ACCOUNT STATUS',
                    subtitle: 'Your NearbyFundi account',
                  ),

                  const SizedBox(height: 14),

                  _AccountStatusCard(),

                  const SizedBox(height: 28),

                  // LOGOUT
                  _LogoutButton(
                    onTap: () => _confirmLogout(
                      context,
                      auth,
                      l10n,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // FOOTER
                  Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.verified_user_rounded,
                          size: 24,
                          color: theme.hintColor.withOpacity(0.55),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          'NearbyFundi',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          'Your trusted connection to local technicians.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.hintColor,
                            fontSize: 11,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          'Version 0.0.1',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.hintColor,
                            fontSize: 11,
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
      ),
    );
  }

  // ============================================================
  // LOGOUT CONFIRMATION
  // ============================================================

  Future<void> _confirmLogout(
      BuildContext context,
      AuthProvider auth,
      AppLocalizations l10n,
      ) async {
    final confirm = await showConfirmationDialog(
      context,
      l10n.logout,
      l10n.logoutConfirmation,
    );

    if (confirm != true) return;

    await auth.logout();

    if (!context.mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.login,
          (_) => false,
    );
  }
}

// ============================================================
// PROFILE HEADER
// ============================================================

class _ProfileHeader extends StatelessWidget {
  final String initial;
  final String name;
  final String email;
  final String? phone;
  final bool isDark;

  const _ProfileHeader({
    required this.initial,
    required this.name,
    required this.email,
    required this.phone,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final hasPhone = phone != null && phone!.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primary,
            AppTheme.primary.withOpacity(0.82),
            AppTheme.secondary.withOpacity(0.90),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.18),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // AVATAR
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.75),
                width: 2,
              ),
            ),
            child: CircleAvatar(
              radius: 48,
              backgroundColor: Colors.white.withOpacity(0.17),
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 38,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),

          const SizedBox(height: 18),

          // NAME
          Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 23,
            ),
          ),

          if (email.isNotEmpty) ...[
            const SizedBox(height: 7),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.email_outlined,
                  color: Colors.white70,
                  size: 15,
                ),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    email,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ],

          if (hasPhone) ...[
            const SizedBox(height: 7),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.phone_outlined,
                  color: Colors.white70,
                  size: 15,
                ),
                const SizedBox(width: 7),
                Text(
                  phone!,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 18),

          // STATUS
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Colors.white.withOpacity(0.25),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF8FF0B0),
                  size: 15,
                ),
                SizedBox(width: 7),
                Text(
                  'Active',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
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

// ============================================================
// SECTION HEADING
// ============================================================

class _SectionHeading extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeading({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w800,
            color: theme.hintColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.hintColor,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// PROFILE ACTION CARD
// ============================================================

class _ProfileActionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ProfileActionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(17),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 15,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: theme.dividerColor.withOpacity(0.13),
            ),
          ),
          child: Row(
            children: [
              // ICON
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 23,
                ),
              ),

              const SizedBox(width: 15),

              // TITLE AND SUBTITLE
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.hintColor,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 15,
                color: theme.hintColor.withOpacity(0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// ACCOUNT STATUS CARD
// ============================================================

class _AccountStatusCard extends StatelessWidget {
  const _AccountStatusCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: const Color(0xFF16A36A).withOpacity(0.07),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: const Color(0xFF16A36A).withOpacity(0.20),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF16A36A).withOpacity(0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.verified_user_rounded,
              color: Color(0xFF16A36A),
              size: 22,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Account active',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF16A36A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your account is ready to use.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.hintColor,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          const Icon(
            Icons.check_circle_rounded,
            color: Color(0xFF16A36A),
            size: 21,
          ),
        ],
      ),
    );
  }
}

// ============================================================
// LOGOUT BUTTON
// ============================================================

class _LogoutButton extends StatelessWidget {
  final VoidCallback onTap;

  const _LogoutButton({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: AppTheme.error.withOpacity(0.07),
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 16,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.error.withOpacity(0.16),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.logout_rounded,
                color: AppTheme.error,
                size: 22,
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Text(
                  'Logout',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppTheme.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 15,
                color: AppTheme.error.withOpacity(0.65),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
