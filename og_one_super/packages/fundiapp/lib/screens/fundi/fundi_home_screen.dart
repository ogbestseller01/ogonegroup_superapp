// lib/screens/fundi/fundi_home_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../config/app_routes.dart';
import '../../models/chat_user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/technician_provider.dart';
import '../../providers/request_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../widgets/notification_bell_icon.dart';
import '../../l10n/app_localizations.dart';

import 'fundi_posts_screen.dart';
import 'fundi_requests_screen.dart';
import '../chat/chat_list_screen.dart';
import 'profile/fundi_profile_screen.dart';

class FundiHomeScreen extends StatefulWidget {
  const FundiHomeScreen({super.key});

  @override
  State<FundiHomeScreen> createState() => _FundiHomeScreenState();
}

class _FundiHomeScreenState extends State<FundiHomeScreen>
    with WidgetsBindingObserver {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentIndex = 0;
  late final List<Widget> _screens;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _screens = const [
      _HomeDashboardContent(),
      FundiPostsScreen(),
      FundiRequestsScreen(),
      ChatListScreen(),
      FundiProfileScreen(),
    ];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<RequestProvider>().loadMyRequests();
      context.read<NotificationProvider>().loadNotifications();
      context.read<TechnicianProvider>().fetchMyProfile();
    }
  }

  void _initializeData() {
    context.read<TechnicianProvider>().fetchMyProfile();
    context.read<RequestProvider>().loadMyRequests();
    _initializeChat();
    context.read<NotificationProvider>().loadNotifications();
  }

  Future<void> _manualRefresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    await Future.wait([
      context.read<TechnicianProvider>().fetchMyProfile(),
      context.read<RequestProvider>().loadMyRequests(),
      context.read<NotificationProvider>().loadNotifications(),
    ]);
    if (mounted) setState(() => _isRefreshing = false);
  }

  void _initializeChat() {
    final auth = context.read<AuthProvider>();
    final chat = context.read<ChatProvider>();
    final user = auth.user;
    final token = auth.token;
    if (user != null && token != null) {
      chat.initialize(
        token: token,
        currentUser: ChatUser(
          id: user.id,
          name: user.name,
          email: user.email ?? '',
          phone: user.phone,
          avatar: null,
        ),
      );
    }
  }

  void _navigateToTab(int index) {
    setState(() => _currentIndex = index);
  }

  void _openDrawer() => _scaffoldKey.currentState?.openDrawer();

  // ── Notifications sheet ─────────────────────────────────────
  void _showNotifications(BuildContext context) {
    final provider = context.read<NotificationProvider>();
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.82,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurface : Colors.white,
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 24,
                    offset: const Offset(0, -8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 44,
                    height: 4.5,
                    decoration: BoxDecoration(
                      color: (isDark ? AppTheme.darkBorder : theme.dividerColor)
                          .withOpacity(0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Text(
                          l10n.notifications,
                          style: theme.textTheme.titleLarge?.copyWith(
                            inherit: true,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                            color: isDark ? Colors.white : AppTheme.primary,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            provider.markAllAsRead();
                            Navigator.pop(ctx);
                          },
                          style: TextButton.styleFrom(
                            foregroundColor:
                            isDark ? AppTheme.secondary : AppTheme.primary,
                            backgroundColor: (isDark
                                ? AppTheme.secondary
                                : AppTheme.primary)
                                .withOpacity(0.08),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Text(
                            l10n.markAllAsRead,
                            style: const TextStyle(
                              inherit: true,
                              fontWeight: FontWeight.w700,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: Consumer<NotificationProvider>(
                      builder: (context, notificationProvider, _) {
                        if (notificationProvider.isLoading) {
                          return const Center(
                            child: CircularProgressIndicator(
                                color: AppTheme.primary),
                          );
                        }
                        if (notificationProvider.notifications.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 88,
                                  height: 88,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppTheme.primary.withOpacity(0.06),
                                  ),
                                  child: Icon(
                                    Icons.notifications_off_outlined,
                                    size: 42,
                                    color: isDark
                                        ? AppTheme.darkTextSecondary
                                        : theme.hintColor.withOpacity(0.7),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  l10n.noNotificationsYet,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    inherit: true,
                                    color: isDark
                                        ? AppTheme.darkTextSecondary
                                        : theme.hintColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return ListView.separated(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemCount: notificationProvider.notifications.length,
                          separatorBuilder: (_, __) =>
                          const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final notification =
                            notificationProvider.notifications[index];
                            return _NotificationTile(
                              notification: notification,
                              onTap: () {
                                notificationProvider
                                    .markAsRead(notification['id']);
                                Navigator.pop(ctx);
                                final type =
                                    notification['type']?.toString() ?? '';
                                if (type == 'chat_message') {
                                  _navigateToTab(3);
                                } else if (type == 'new_request' ||
                                    type == 'request_accepted' ||
                                    type == 'request_rejected') {
                                  _navigateToTab(2);
                                } else {
                                  _navigateToTab(0);
                                }
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _logoutWithConfirmation(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showConfirmationDialog(
      context,
      l10n.logout,
      l10n.logoutConfirmation,
    );
    if (confirm == true) {
      await context.read<AuthProvider>().logout();
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      }
    }
  }

  // ── BUILD ───────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final compact = screenWidth < 360;

    return MediaQuery.withClampedTextScaling(
      minScaleFactor: 0.85,
      maxScaleFactor: 1.25,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor:
        isDark ? AppTheme.darkBackground : theme.scaffoldBackgroundColor,
        drawer: _FundiDrawer(
          onLogout: () => _logoutWithConfirmation(context),
        ),
        appBar: AppBar(
          automaticallyImplyLeading: false,
          centerTitle: false,
          titleSpacing: 0,
          leading: IconButton(
            icon: const Icon(Icons.menu_rounded, color: Colors.white),
            onPressed: _openDrawer,
            tooltip: 'Menu',
          ),
          title: Text(
            l10n.fundiDashboard,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              inherit: true,
              color: Colors.white,
              fontSize: compact ? 18 : 21,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: _isRefreshing
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: Colors.white,
                ),
              )
                  : const Icon(Icons.refresh_rounded, color: Colors.white),
              visualDensity:
              compact ? VisualDensity.compact : VisualDensity.standard,
              tooltip: 'Refresh',
              onPressed: _isRefreshing ? null : _manualRefresh,
            ),
            NotificationBellIcon(onTap: () => _showNotifications(context)),
            SizedBox(width: compact ? 4 : 8),
          ],
        ),
        body: LayoutBuilder(
          builder: (context, c) {
            final w = c.maxWidth > 900 ? 900.0 : c.maxWidth;
            return Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: w,
                height: c.maxHeight,
                child: _screens[_currentIndex],
              ),
            );
          },
        ),
        bottomNavigationBar: _FloatingNavBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          homeLabel: l10n.home,
          blogLabel: l10n.blog,
          requestsLabel: l10n.requests,
          chatLabel: l10n.chat,
          profileLabel: l10n.profile,
        ),
      ),
    );
  }
}

// ================================================================
// LEFT DRAWER
// ================================================================
class _FundiDrawer extends StatelessWidget {
  final VoidCallback onLogout;

  const _FundiDrawer({required this.onLogout});

  void _showComingSoon(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.secondary.withOpacity(0.25),
                      AppTheme.primary.withOpacity(0.15),
                    ],
                  ),
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  size: 36,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Subscription',
                style: TextStyle(
                  inherit: true,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppTheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Premium version — Coming soon 🚀\nUnlock more features and grow your business.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  inherit: true,
                  fontSize: 14,
                  height: 1.4,
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.greyText,
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    l10n.comingSoon,
                    style: const TextStyle(
                      inherit: true,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isDark = theme.brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    final name = user?.name ?? 'Fundi';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'F';

    return Drawer(
      backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // ── Header with Close button on top-right ─────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 12, 8, 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primary, AppTheme.primaryLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar + Close button
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3.5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border:
                          Border.all(color: AppTheme.secondary, width: 2.2),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.secondary.withOpacity(0.35),
                              blurRadius: 12,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.white,
                          child: Text(
                            initial,
                            style: const TextStyle(
                              inherit: true,
                              color: AppTheme.primary,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded,
                            color: Colors.white, size: 26),
                        tooltip: 'Close',
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.15),
                          padding: const EdgeInsets.all(8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    name,
                    style: const TextStyle(
                      inherit: true,
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (user?.phone != null && user!.phone!.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      user.phone!,
                      style: TextStyle(
                        inherit: true,
                        color: Colors.white.withOpacity(0.82),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // ── Menu items ───────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
                children: [
                  _DrawerItem(
                    icon: Icons.settings_outlined,
                    label: l10n.settings,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, AppRoutes.settings);
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.photo_library_outlined,
                    label: l10n.portfolio,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, AppRoutes.portfolio);
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.file_download_rounded,
                    label: 'Downloads',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, AppRoutes.downloads);
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.workspace_premium_rounded,
                    label: 'Subscription',
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.secondary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        l10n.comingSoon,
                        style: const TextStyle(
                          inherit: true,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _showComingSoon(context);
                    },
                  ),
                ],
              ),
            ),

            // ── Logout ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
              child: Material(
                color: AppTheme.error.withOpacity(0.09),
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    onLogout();
                  },
                  borderRadius: BorderRadius.circular(18),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 15),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppTheme.error.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: const Icon(Icons.logout_rounded,
                              color: AppTheme.error, size: 21),
                        ),
                        const SizedBox(width: 14),
                        Text(
                          l10n.logout,
                          style: const TextStyle(
                            inherit: true,
                            color: AppTheme.error,
                            fontWeight: FontWeight.w700,
                            fontSize: 15.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;
  final bool isDanger;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDanger
        ? AppTheme.error
        : (isDark ? Colors.white : AppTheme.primary);

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color.withOpacity(isDanger ? 0.12 : 0.09),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      inherit: true,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: isDanger
                          ? AppTheme.error
                          : (isDark ? Colors.white : AppTheme.primary),
                    ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ================================================================
// FLOATING BOTTOM NAV
// ================================================================
class _FloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final String homeLabel;
  final String blogLabel;
  final String requestsLabel;
  final String chatLabel;
  final String profileLabel;

  const _FloatingNavBar({
    required this.currentIndex,
    required this.onTap,
    required this.homeLabel,
    required this.blogLabel,
    required this.requestsLabel,
    required this.chatLabel,
    required this.profileLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final compact = MediaQuery.sizeOf(context).width < 360;
    final sideMargin = compact ? 8.0 : 14.0;

    return SafeArea(
      top: false,
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Container(
            margin: EdgeInsets.fromLTRB(sideMargin, 6, sideMargin, 10),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: isDark
                    ? AppTheme.darkBorder
                    : AppTheme.borderLight.withOpacity(0.35),
                width: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.40 : 0.10),
                  blurRadius: 22,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Consumer<ChatProvider>(
              builder: (context, chatProvider, _) {
                final unread = chatProvider.totalUnread;
                return Row(
                  children: [
                    Expanded(
                      child: _NavItem(
                        icon: Icons.home_outlined,
                        activeIcon: Icons.home_rounded,
                        label: homeLabel,
                        active: currentIndex == 0,
                        onTap: () => onTap(0),
                      ),
                    ),
                    Expanded(
                      child: _NavItem(
                        icon: Icons.article_outlined,
                        activeIcon: Icons.article_rounded,
                        label: blogLabel,
                        active: currentIndex == 1,
                        onTap: () => onTap(1),
                      ),
                    ),
                    Expanded(
                      child: _NavItem(
                        icon: Icons.list_alt_outlined,
                        activeIcon: Icons.list_alt_rounded,
                        label: requestsLabel,
                        active: currentIndex == 2,
                        onTap: () => onTap(2),
                      ),
                    ),
                    Expanded(
                      child: _NavItem(
                        icon: Icons.chat_bubble_outline_rounded,
                        activeIcon: Icons.chat_bubble_rounded,
                        label: chatLabel,
                        active: currentIndex == 3,
                        badge: unread,
                        onTap: () => onTap(3),
                      ),
                    ),
                    Expanded(
                      child: _NavItem(
                        icon: Icons.person_outline,
                        activeIcon: Icons.person_rounded,
                        label: profileLabel,
                        active: currentIndex == 4,
                        onTap: () => onTap(4),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool active;
  final int badge;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.active,
    required this.onTap,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = isDark ? AppTheme.secondary : AppTheme.primary;
    final idleColor = isDark ? AppTheme.darkTextSecondary : AppTheme.greyText;
    final color = active ? activeColor : idleColor;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.sizeOf(context).width < 360 ? 10 : 16,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: active
                    ? activeColor.withOpacity(isDark ? 0.16 : 0.10)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(active ? activeIcon : icon, size: 23, color: color),
                  if (badge > 0)
                    Positioned(
                      top: -6,
                      right: -9,
                      child: Container(
                        padding: const EdgeInsets.all(3.5),
                        constraints:
                        const BoxConstraints(minWidth: 16, minHeight: 16),
                        decoration: BoxDecoration(
                          color: AppTheme.secondary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color:
                            isDark ? AppTheme.darkSurface : Colors.white,
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          badge > 9 ? '9+' : '$badge',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            inherit: true,
                            color: AppTheme.primary,
                            fontSize: 8.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                inherit: true,
                fontSize: 11,
                fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// NOTIFICATION TILE
// ================================================================
class _NotificationTile extends StatelessWidget {
  final Map<String, dynamic> notification;
  final VoidCallback onTap;

  const _NotificationTile({required this.notification, required this.onTap});

  bool get _isRead {
    final v = notification['is_read'];
    if (v is bool) return v;
    if (v is int) return v == 1;
    if (v is String) return v == '1' || v.toLowerCase() == 'true';
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isRead = _isRead;
    final type = notification['type']?.toString();
    final primaryText = isDark ? Colors.white : AppTheme.primary;
    final mutedText = isDark ? AppTheme.darkTextSecondary : AppTheme.greyText;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: isRead
                ? (isDark ? AppTheme.darkSurface : Colors.white)
                : AppTheme.primary.withOpacity(isDark ? 0.15 : 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isRead
                  ? (isDark
                  ? AppTheme.darkBorder
                  : theme.dividerColor.withOpacity(0.4))
                  : AppTheme.primary.withOpacity(0.16),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: isRead
                      ? (isDark
                      ? AppTheme.darkSurfaceLight
                      : theme.dividerColor.withOpacity(0.22))
                      : AppTheme.primary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  _getIcon(type),
                  color: isRead ? mutedText : AppTheme.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification['title']?.toString() ?? '',
                      style: TextStyle(
                        inherit: true,
                        fontWeight: isRead ? FontWeight.w600 : FontWeight.w800,
                        height: 1.25,
                        color: primaryText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification['body']?.toString() ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        inherit: true,
                        color: mutedText,
                        height: 1.35,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isRead) ...[
                const SizedBox(width: 10),
                Container(
                  width: 9,
                  height: 9,
                  margin: const EdgeInsets.only(top: 6),
                  decoration: const BoxDecoration(
                    color: AppTheme.secondary,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIcon(String? type) {
    switch (type) {
      case 'chat_message':
        return Icons.chat_bubble_outline_rounded;
      case 'new_request':
        return Icons.request_page_outlined;
      case 'request_accepted':
        return Icons.check_circle_outline_rounded;
      case 'request_rejected':
        return Icons.cancel_outlined;
      case 'request_in_progress':
        return Icons.hourglass_top_rounded;
      case 'request_completed':
        return Icons.verified_rounded;
      case 'subscription_approved':
        return Icons.verified_rounded;
      case 'subscription_rejected':
        return Icons.cancel_rounded;
      case 'subscription_expired':
        return Icons.warning_amber_rounded;
      case 'subscription_expiring_soon':
        return Icons.timer_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }
}

// ================================================================
// HOME DASHBOARD CONTENT
// ================================================================
class _HomeDashboardContent extends StatelessWidget {
  const _HomeDashboardContent();

  DateTime _toEAT(DateTime dateTime) {
    return dateTime.toUtc().add(const Duration(hours: 3));
  }

  String _formatRequestDate(dynamic request) {
    final date = _requestCreatedAt(request);
    if (date.year <= 1970) return '';
    final eat = _toEAT(date);
    final day = eat.day.toString().padLeft(2, '0');
    final month = eat.month.toString().padLeft(2, '0');
    final year = eat.year.toString();
    final hour = eat.hour.toString().padLeft(2, '0');
    final minute = eat.minute.toString().padLeft(2, '0');
    return '$day/$month/$year • $hour:$minute';
  }

  DateTime _requestCreatedAt(dynamic request) {
    try {
      final value = request.createdAt;
      if (value is DateTime) return value;
      if (value != null) {
        return DateTime.tryParse(value.toString()) ??
            DateTime.fromMillisecondsSinceEpoch(0);
      }
    } catch (_) {}
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isDark = theme.brightness == Brightness.dark;

    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final requestProvider = context.watch<RequestProvider>();
    final requests = requestProvider.requests;

    final pendingRequests =
        requests.where((r) => r.status == 'pending').length;
    final completedRequests =
        requests.where((r) => r.status == 'completed').length;

    final latestRequests = List.of(requests);
    latestRequests.sort((a, b) {
      final aDate = _requestCreatedAt(a);
      final bDate = _requestCreatedAt(b);
      return bDate.compareTo(aDate);
    });
    final topFiveRequests = latestRequests.take(5).toList();

    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;
    final compactScreen = screenWidth < 360;
    final padding = isTablet ? 24.0 : (compactScreen ? 12.0 : 16.0);
    final gap = isTablet ? 16.0 : 12.0;

    final primaryText = isDark ? Colors.white : AppTheme.primary;
    final mutedText = isDark ? AppTheme.darkTextSecondary : AppTheme.greyText;
    final cardBg = isDark ? AppTheme.darkSurface : Colors.white;

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: () async {
          await context.read<RequestProvider>().loadMyRequests();
          await context.read<TechnicianProvider>().fetchMyProfile();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header band
              Container(
                padding: EdgeInsets.fromLTRB(padding, 4, padding, 44),
                color: AppTheme.primary,
                child: _HeroCard(
                  name: user?.name ?? 'Fundi',
                  initial: user?.name.isNotEmpty == true
                      ? user!.name[0].toUpperCase()
                      : 'F',
                  greeting: l10n.hello,
                  pendingText: pendingRequests > 0
                      ? '$pendingRequests ${l10n.pending}'
                      : null,
                  isTablet: isTablet,
                ),
              ),
              // Body sheet
              Container(
                transform: Matrix4.translationValues(0, -26, 0),
                padding: EdgeInsets.fromLTRB(padding, 20, padding, 24),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppTheme.darkBackground
                      : theme.scaffoldBackgroundColor,
                  borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            context,
                            icon: Icons.list_alt_rounded,
                            label: l10n.totalRequests,
                            value: requests.length.toString(),
                            color: AppTheme.accent,
                            isTablet: isTablet,
                            onTap: () => _navigateToTab(context, 2),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildStatCard(
                            context,
                            icon: Icons.pending_rounded,
                            label: l10n.pending,
                            value: pendingRequests.toString(),
                            color: AppTheme.gold600,
                            isTablet: isTablet,
                            onTap: () => _navigateToTab(context, 2),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildStatCard(
                            context,
                            icon: Icons.check_circle_rounded,
                            label: l10n.completed,
                            value: completedRequests.toString(),
                            color: AppTheme.success,
                            isTablet: isTablet,
                            onTap: () => _navigateToTab(context, 2),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: gap + 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 4,
                              height: 22,
                              decoration: BoxDecoration(
                                color: AppTheme.secondary,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Latest Requests',
                              style: theme.textTheme.titleLarge?.copyWith(
                                inherit: true,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.4,
                                color: primaryText,
                              ),
                            ),
                          ],
                        ),
                        if (requests.isNotEmpty)
                          TextButton(
                            onPressed: () => _navigateToTab(context, 2),
                            style: TextButton.styleFrom(
                              foregroundColor:
                              isDark ? AppTheme.secondary : AppTheme.primary,
                              backgroundColor: (isDark
                                  ? AppTheme.secondary
                                  : AppTheme.primary)
                                  .withOpacity(0.08),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: const Text(
                              'View All',
                              style: TextStyle(
                                inherit: true,
                                fontWeight: FontWeight.w700,
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (topFiveRequests.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            vertical: 40, horizontal: 20),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isDark
                                ? AppTheme.darkBorder
                                : AppTheme.borderLight.withOpacity(0.35),
                          ),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 76,
                              height: 76,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.primary.withOpacity(0.06),
                              ),
                              child: Icon(Icons.inbox_outlined,
                                  size: 36, color: mutedText),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              l10n.noRequests,
                              style: TextStyle(
                                inherit: true,
                                color: mutedText,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      LayoutBuilder(
                        builder: (context, c) {
                          if (c.maxWidth >= 640) {
                            const spacing = 12.0;
                            final itemW = (c.maxWidth - spacing) / 2;
                            return Wrap(
                              spacing: spacing,
                              children: topFiveRequests
                                  .map((r) => SizedBox(
                                width: itemW,
                                child: _buildLatestRequest(context, r),
                              ))
                                  .toList(),
                            );
                          }
                          return Column(
                            children: topFiveRequests
                                .map((r) => _buildLatestRequest(context, r))
                                .toList(),
                          );
                        },
                      ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLatestRequest(BuildContext context, dynamic request) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final status = request.status?.toString() ?? 'pending';
    final statusColor = _requestStatusColor(status);
    final created = _formatRequestDate(request);
    final primaryText = isDark ? Colors.white : AppTheme.primary;
    final mutedText = isDark ? AppTheme.darkTextSecondary : AppTheme.greyText;
    final cardBg = isDark ? AppTheme.darkSurface : Colors.white;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToTab(context, 2),
          borderRadius: BorderRadius.circular(22),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardBg,
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
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.13),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(_requestStatusIcon(status),
                      color: statusColor, size: 24),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              request.serviceName.toString(),
                              style: TextStyle(
                                inherit: true,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: primaryText,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.13),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _requestStatusLabel(status),
                              style: TextStyle(
                                inherit: true,
                                color: statusColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      Row(
                        children: [
                          Icon(Icons.person_outline_rounded,
                              size: 15, color: mutedText),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              request.customerName.toString(),
                              style: TextStyle(
                                  inherit: true,
                                  color: mutedText,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (created.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Icon(Icons.access_time_rounded,
                                size: 14, color: mutedText),
                            const SizedBox(width: 5),
                            Text(
                              created,
                              style: TextStyle(
                                inherit: true,
                                color: mutedText,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _requestStatusColor(String status) {
    switch (status) {
      case 'accepted':
      case 'in_progress':
        return AppTheme.primary;
      case 'on_the_way':
        return AppTheme.success;
      case 'arrived':
        return AppTheme.accent;
      case 'completed':
        return AppTheme.success;
      case 'rejected':
      case 'cancelled':
        return AppTheme.error;
      default:
        return AppTheme.warning;
    }
  }

  IconData _requestStatusIcon(String status) {
    switch (status) {
      case 'accepted':
      case 'in_progress':
        return Icons.check_circle_outline_rounded;
      case 'on_the_way':
        return Icons.directions_car_rounded;
      case 'arrived':
        return Icons.location_on_rounded;
      case 'completed':
        return Icons.verified_rounded;
      case 'rejected':
        return Icons.cancel_outlined;
      case 'cancelled':
        return Icons.do_not_disturb_on_outlined;
      default:
        return Icons.hourglass_empty_rounded;
    }
  }

  String _requestStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'PENDING';
      case 'accepted':
        return 'ACCEPTED';
      case 'on_the_way':
        return 'ON THE WAY';
      case 'arrived':
        return 'ARRIVED';
      case 'in_progress':
        return 'IN PROGRESS';
      case 'completed':
        return 'COMPLETED';
      case 'rejected':
        return 'REJECTED';
      case 'cancelled':
        return 'CANCELLED';
      default:
        return status.toUpperCase();
    }
  }

  void _navigateToTab(BuildContext context, int index) {
    final homeState =
    context.findAncestorStateOfType<_FundiHomeScreenState>();
    homeState?._navigateToTab(index);
  }

  Widget _buildStatCard(
      BuildContext context, {
        required IconData icon,
        required String label,
        required String value,
        required Color color,
        required bool isTablet,
        required VoidCallback onTap,
      }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppTheme.darkSurface : Colors.white;
    final mutedText = isDark ? AppTheme.darkTextSecondary : AppTheme.greyText;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: isTablet ? 18.0 : 14.0,
            horizontal: 8,
          ),
          decoration: BoxDecoration(
            color: cardBg,
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: isTablet ? 42 : 36,
                height: isTablet ? 42 : 36,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.13),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, size: isTablet ? 22 : 19, color: color),
              ),
              const SizedBox(height: 9),
              Text(
                value,
                style: TextStyle(
                  inherit: true,
                  fontSize: isTablet ? 24 : 21,
                  fontWeight: FontWeight.w800,
                  height: 1.0,
                  color: isDark ? Colors.white : AppTheme.primary,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                label,
                style: TextStyle(
                  inherit: true,
                  fontSize: isTablet ? 11.5 : 10.5,
                  color: mutedText,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================================================================
// HERO CARD
// ================================================================
class _HeroCard extends StatelessWidget {
  final String name;
  final String initial;
  final String greeting;
  final String? pendingText;
  final bool isTablet;

  const _HeroCard({
    required this.name,
    required this.initial,
    required this.greeting,
    required this.pendingText,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 360;

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      padding: EdgeInsets.all(isTablet ? 24 : (compact ? 14 : 20)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.10),
            Colors.white.withOpacity(0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.10), width: 1),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -40,
            top: -50,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.secondary.withOpacity(0.30),
                    AppTheme.secondary.withOpacity(0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: 14,
            bottom: -34,
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.08),
                  width: 1.4,
                ),
              ),
            ),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.secondary, width: 2),
                ),
                child: CircleAvatar(
                  radius: isTablet ? 34 : (compact ? 24 : 29),
                  backgroundColor: Colors.white,
                  child: Text(
                    initial,
                    style: TextStyle(
                      inherit: true,
                      color: AppTheme.primary,
                      fontSize: isTablet ? 28 : 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greeting,
                      style: TextStyle(
                        inherit: true,
                        color: Colors.white.withOpacity(0.75),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      name,
                      style: TextStyle(
                        inherit: true,
                        color: Colors.white,
                        fontSize: compact ? 17 : 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (pendingText != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppTheme.warning,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          pendingText!,
                          style: const TextStyle(
                            inherit: true,
                            color: AppTheme.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}