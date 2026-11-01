// FILE: lib/screens/fundi/fundi_home_screen.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../config/app_routes.dart';
import '../../models/chat_user.dart';
import '../../models/job.dart';
import '../../providers/auth_provider.dart';
import '../../providers/technician_provider.dart';
import '../../providers/request_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/job_provider.dart';
import '../../providers/ticket_provider.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../widgets/notification_bell_icon.dart';
import '../../widgets/work_status_widgets.dart';
import '../../l10n/app_localizations.dart';

import 'fundi_posts_screen.dart';
import 'fundi_requests_screen.dart';
import '../chat/chat_list_screen.dart';
import '../jobs/job_detail_screen.dart';
import '../tickets/ticket_detail_screen.dart';
import 'profile/fundi_profile_screen.dart';

// ================================================================
// FUNDI HOME SCREEN
// ================================================================

class FundiHomeScreen extends StatefulWidget {
  const FundiHomeScreen({super.key});

  @override
  State<FundiHomeScreen> createState() => _FundiHomeScreenState();
}

class _FundiHomeScreenState extends State<FundiHomeScreen>
    with WidgetsBindingObserver {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  int _currentIndex = 0;
  bool _isRefreshing = false;

  late final List<Widget> _screens;

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
      _loadAll();
    }
  }

  // ==============================================================
  // DATA
  // ==============================================================

  Future<void> _loadAll() async {
    await Future.wait([
      context.read<TechnicianProvider>().fetchMyProfile(),
      context.read<RequestProvider>().loadMyRequests(),
      context.read<NotificationProvider>().loadNotifications(),
      context.read<JobProvider>().loadJobs(),
      context.read<TicketProvider>().loadTickets(),
    ]);
  }

  void _initializeData() {
    _loadAll();
    _initializeChat();
  }

  Future<void> _manualRefresh() async {
    if (_isRefreshing) return;

    setState(() => _isRefreshing = true);

    try {
      await _loadAll();
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  void _initializeChat() {
    final auth = context.read<AuthProvider>();
    final chat = context.read<ChatProvider>();

    final user = auth.user;
    final token = auth.token;

    if (user == null || token == null) return;

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

  void _navigateToTab(int index) {
    if (!mounted) return;
    setState(() => _currentIndex = index);
  }

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  // ==============================================================
  // NOTIFICATIONS
  // ==============================================================

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
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.dividerColor,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.notifications,
                            style: TextStyle(
                              inherit: true,
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : AppTheme.primary,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            provider.markAllAsRead();
                            Navigator.pop(ctx);
                          },
                          child: Text(
                            l10n.markAllAsRead,
                            style: const TextStyle(
                              inherit: true,
                              fontWeight: FontWeight.w700,
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
                              color: AppTheme.primary,
                            ),
                          );
                        }

                        if (notificationProvider.notifications.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.notifications_off_outlined,
                                  size: 55,
                                  color: theme.hintColor,
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  l10n.noNotificationsYet,
                                  style: TextStyle(
                                    inherit: true,
                                    color: theme.hintColor,
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
                                notificationProvider.markAsRead(
                                  notification['id'],
                                );

                                Navigator.pop(ctx);

                                final type =
                                    notification['type']?.toString() ?? '';

                                if (type == 'chat_message') {
                                  _navigateToTab(3);
                                } else if (type == 'new_request' ||
                                    type == 'request_accepted' ||
                                    type == 'request_rejected') {
                                  _navigateToTab(2);
                                } else if (type.contains('ticket')) {
                                  Navigator.pushNamed(
                                    context,
                                    AppRoutes.tickets,
                                  );
                                } else if (type.contains('job')) {
                                  Navigator.pushNamed(context, AppRoutes.jobs);
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

  // ==============================================================
  // LOGOUT
  // ==============================================================

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

  // ==============================================================
  // BUILD
  // ==============================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final isDark = theme.brightness == Brightness.dark;
    final compact = MediaQuery.sizeOf(context).width < 360;

    return MediaQuery.withClampedTextScaling(
      minScaleFactor: 0.85,
      maxScaleFactor: 1.25,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: isDark
            ? AppTheme.darkBackground
            : theme.scaffoldBackgroundColor,
        drawer: _FundiDrawer(onLogout: () => _logoutWithConfirmation(context)),
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
              tooltip: 'Refresh',
              onPressed: _isRefreshing ? null : _manualRefresh,
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
            ),
            NotificationBellIcon(onTap: () => _showNotifications(context)),
            const SizedBox(width: 8),
          ],
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final width =
            constraints.maxWidth > 900 ? 900.0 : constraints.maxWidth;

            return Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: width,
                height: constraints.maxHeight,
                child: _screens[_currentIndex],
              ),
            );
          },
        ),
        bottomNavigationBar: _FloatingNavBar(
          currentIndex: _currentIndex,
          onTap: _navigateToTab,
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
// FUNDI DRAWER
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
                'Premium version — Coming soon 🚀\n'
                    'Unlock more features and grow your business.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  inherit: true,
                  fontSize: 14,
                  height: 1.4,
                  color:
                  isDark ? AppTheme.darkTextSecondary : AppTheme.greyText,
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

  Widget? _countPill(int count) {
    if (count <= 0) return null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.secondary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: const TextStyle(
          inherit: true,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: AppTheme.primary,
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

    final totalJobs = context.watch<JobProvider>().jobs.length;
    final totalTickets = context.watch<TicketProvider>().tickets.length;

    final name = user?.name ?? 'Fundi';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'F';

    return Drawer(
      backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // Drawer header
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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3.5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.secondary,
                            width: 2.2,
                          ),
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
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      inherit: true,
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
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

            // Drawer menu
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
                children: [
                  _DrawerItem(
                    icon: Icons.photo_library_outlined,
                    label: l10n.portfolio,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, AppRoutes.portfolio);
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.confirmation_number_outlined,
                    label: 'Tickets',
                    trailing: _countPill(totalTickets),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, AppRoutes.tickets);
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.work_outline_rounded,
                    label: 'Jobs',
                    trailing: _countPill(totalJobs),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, AppRoutes.jobs);
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.workspace_premium_rounded,
                    label: 'Subscription',
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
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
                  _DrawerItem(
                    icon: Icons.file_download_rounded,
                    label: 'Downloads',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, AppRoutes.downloads);
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.settings_outlined,
                    label: l10n.settings,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, AppRoutes.settings);
                    },
                  ),
                ],
              ),
            ),

            // Logout
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
                      horizontal: 16,
                      vertical: 15,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppTheme.error.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: const Icon(
                            Icons.logout_rounded,
                            color: AppTheme.error,
                            size: 21,
                          ),
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

// ================================================================
// DRAWER ITEM
// ================================================================

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? Colors.white : AppTheme.primary;

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
                    color: color.withOpacity(0.09),
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
                      color: color,
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

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Container(
          height: 68,
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.35 : 0.10),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: homeLabel,
                selected: currentIndex == 0,
                onTap: () => onTap(0),
              ),
              _NavItem(
                icon: Icons.photo_library_outlined,
                label: blogLabel,
                selected: currentIndex == 1,
                onTap: () => onTap(1),
              ),
              _NavItem(
                icon: Icons.inbox_outlined,
                label: requestsLabel,
                selected: currentIndex == 2,
                onTap: () => onTap(2),
              ),
              _NavItem(
                icon: Icons.chat_bubble_outline_rounded,
                label: chatLabel,
                selected: currentIndex == 3,
                onTap: () => onTap(3),
              ),
              _NavItem(
                icon: Icons.person_outline_rounded,
                label: profileLabel,
                selected: currentIndex == 4,
                onTap: () => onTap(4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = selected
        ? (isDark ? AppTheme.secondary : AppTheme.primary)
        : (isDark ? AppTheme.darkTextSecondary : AppTheme.greyText);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                inherit: true,
                fontSize: 10.5,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
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
// HOME DASHBOARD CONTENT
// ================================================================

class _HomeDashboardContent extends StatelessWidget {
  const _HomeDashboardContent();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isDark = theme.brightness == Brightness.dark;
    final isTablet = MediaQuery.sizeOf(context).width >= 600;

    final auth = context.watch<AuthProvider>();
    final jobProvider = context.watch<JobProvider>();
    final ticketProvider = context.watch<TicketProvider>();
    final requestProvider = context.watch<RequestProvider>();

    final user = auth.user;
    final name = user?.name ?? 'Fundi';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'F';

    final totalJobs = jobProvider.jobs.length;
    final totalTickets = ticketProvider.tickets.length;
    final pendingRequests = requestProvider.pendingCount;

    final greeting = _greeting();

    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          context.read<JobProvider>().loadJobs(),
          context.read<TicketProvider>().loadTickets(),
          context.read<RequestProvider>().loadMyRequests(),
          context.read<NotificationProvider>().loadNotifications(),
        ]);
      },
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          isTablet ? 24 : 16,
          16,
          isTablet ? 24 : 16,
          32,
        ),
        children: [
          // ── Hero Card (always dark navy + white text) ─────────
          _HeroCard(
            name: name,
            initial: initial,
            greeting: greeting,
            pendingText:
            pendingRequests > 0 ? '$pendingRequests Pending' : null,
            activeJobs: totalJobs,
            openTickets: totalTickets,
            isTablet: isTablet,
          ),

          const SizedBox(height: 20),

          // ── Quick Actions (Jobs & Tickets) ────────────────────
          Row(
            children: [
              Expanded(
                child: _QuickAction(
                  icon: Icons.work_outline_rounded,
                  label: 'Jobs',
                  subtitle: 'View all',
                  count: totalJobs,
                  color: AppTheme.primary,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.jobs),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickAction(
                  icon: Icons.confirmation_number_outlined,
                  label: 'Tickets',
                  subtitle: 'View all',
                  count: totalTickets,
                  color: AppTheme.primary,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.tickets),
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // ── Recent Requests ───────────────────────────────────
          _SectionHeader(
            title: l10n.latestRequests,
            showAction: requestProvider.requests.isNotEmpty,
            onViewAll: () {
              final homeState =
              context.findAncestorStateOfType<_FundiHomeScreenState>();
              homeState?._navigateToTab(2);
            },
          ),
          const SizedBox(height: 12),

          if (requestProvider.isLoading)
            const _InlineLoader()
          else if (requestProvider.requests.isEmpty)
            _EmptyBox(
              icon: Icons.inbox_outlined,
              message: l10n.noRequests,
              cardBg: isDark ? AppTheme.darkSurface : Colors.white,
              mutedText:
              isDark ? AppTheme.darkTextSecondary : AppTheme.greyText,
              isDark: isDark,
            )
          else
            _ResponsiveList(
              children: requestProvider.requests
                  .take(4)
                  .map((r) => _RequestTile(request: r))
                  .toList(),
            ),

          const SizedBox(height: 28),

          // ── Recent Jobs ───────────────────────────────────────
          _SectionHeader(
            title: 'Recent Jobs',
            showAction: jobProvider.jobs.isNotEmpty,
            onViewAll: () => Navigator.pushNamed(context, AppRoutes.jobs),
          ),
          const SizedBox(height: 12),

          if (jobProvider.isLoading)
            const _InlineLoader()
          else if (jobProvider.jobs.isEmpty)
            _EmptyBox(
              icon: Icons.work_outline_rounded,
              message: 'No jobs yet',
              cardBg: isDark ? AppTheme.darkSurface : Colors.white,
              mutedText:
              isDark ? AppTheme.darkTextSecondary : AppTheme.greyText,
              isDark: isDark,
            )
          else
            ...jobProvider.jobs.take(3).map((j) => _JobTile(job: j)),

          const SizedBox(height: 28),

          // ── Recent Tickets ────────────────────────────────────
          _SectionHeader(
            title: 'Recent Tickets',
            showAction: ticketProvider.tickets.isNotEmpty,
            onViewAll: () => Navigator.pushNamed(context, AppRoutes.tickets),
          ),
          const SizedBox(height: 12),

          if (ticketProvider.isLoading)
            const _InlineLoader()
          else if (ticketProvider.tickets.isEmpty)
            _EmptyBox(
              icon: Icons.confirmation_number_outlined,
              message: 'No tickets yet',
              cardBg: isDark ? AppTheme.darkSurface : Colors.white,
              mutedText:
              isDark ? AppTheme.darkTextSecondary : AppTheme.greyText,
              isDark: isDark,
            )
          else
            ...ticketProvider.tickets
                .take(3)
                .map((t) => _TicketTile(ticket: t)),
        ],
      ),
    );
  }

  /// Greeting forced to East Africa Time (UTC+3) – 24-hour logic
  String _greeting() {
    final eat = DateTime.now().toUtc().add(const Duration(hours: 3));
    final hour = eat.hour; // 0–23

    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}

// ================================================================
// NOTIFICATION TILE
// ================================================================

class _NotificationTile extends StatelessWidget {
  final Map notification;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isRead = notification['is_read'] == true ||
        notification['read_at'] != null;

    return Material(
      color: isRead
          ? (isDark ? AppTheme.darkSurface : Colors.white)
          : (isDark
          ? AppTheme.primary.withOpacity(0.12)
          : AppTheme.primary.withOpacity(0.06)),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.notifications_rounded,
                  color: AppTheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification['title']?.toString() ?? 'Notification',
                      style: TextStyle(
                        inherit: true,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: isDark ? Colors.white : AppTheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification['body']?.toString() ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        inherit: true,
                        fontSize: 13,
                        color: isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.greyText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================================================================
// REQUEST TILE
// ================================================================

class _RequestTile extends StatelessWidget {
  final dynamic request;

  const _RequestTile({required this.request});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? Colors.white : AppTheme.primary;
    final mutedText = isDark ? AppTheme.darkTextSecondary : AppTheme.greyText;

    final status = request.status?.toString() ?? 'pending';
    final statusColor = _requestStatusColor(status);
    final created = request.createdAt != null
        ? _formatDate(request.createdAt)
        : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () {
            final homeState =
            context.findAncestorStateOfType<_FundiHomeScreenState>();
            homeState?._navigateToTab(2);
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? AppTheme.darkBorder
                    : AppTheme.borderLight.withOpacity(0.35),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.13),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    _requestStatusIcon(status),
                    color: statusColor,
                    size: 22,
                  ),
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
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                inherit: true,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: primaryText,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
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
                          Icon(
                            Icons.person_outline_rounded,
                            size: 15,
                            color: mutedText,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              request.customerName.toString(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                inherit: true,
                                color: mutedText,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (created.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 14,
                              color: mutedText,
                            ),
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
        return AppTheme.primary;
      case 'rejected':
      case 'cancelled':
        return AppTheme.error;
      case 'pending':
      default:
        return AppTheme.warning;
    }
  }

  IconData _requestStatusIcon(String status) {
    switch (status) {
      case 'accepted':
        return Icons.verified_rounded;
      case 'rejected':
        return Icons.cancel_outlined;
      case 'cancelled':
        return Icons.do_not_disturb_on_outlined;
      case 'pending':
      default:
        return Icons.hourglass_empty_rounded;
    }
  }

  String _requestStatusLabel(String status) {
    switch (status) {
      case 'accepted':
        return 'ACCEPTED';
      case 'rejected':
        return 'REJECTED';
      case 'cancelled':
        return 'CANCELLED';
      case 'pending':
      default:
        return 'PENDING';
    }
  }

  String _formatDate(DateTime dt) {
    final eat = dt.toUtc().add(const Duration(hours: 3));
    return '${eat.day.toString().padLeft(2, '0')}/'
        '${eat.month.toString().padLeft(2, '0')}/'
        '${eat.year} • '
        '${eat.hour.toString().padLeft(2, '0')}:'
        '${eat.minute.toString().padLeft(2, '0')}';
  }
}

// ================================================================
// SECTION HEADER
// ================================================================

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool showAction;
  final VoidCallback onViewAll;

  const _SectionHeader({
    required this.title,
    required this.showAction,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = isDark ? AppTheme.secondary : AppTheme.primary;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Row(
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
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge?.copyWith(
                    inherit: true,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    color: isDark ? Colors.white : AppTheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showAction)
          TextButton(
            onPressed: onViewAll,
            style: TextButton.styleFrom(
              foregroundColor: accent,
              backgroundColor: accent.withOpacity(0.08),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
    );
  }
}

// ================================================================
// RESPONSIVE LIST
// ================================================================

class _ResponsiveList extends StatelessWidget {
  final List<Widget> children;

  const _ResponsiveList({required this.children});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 640) {
          const spacing = 12.0;
          final itemWidth = (constraints.maxWidth - spacing) / 2;

          return Wrap(
            spacing: spacing,
            children: children
                .map((widget) => SizedBox(width: itemWidth, child: widget))
                .toList(),
          );
        }

        return Column(children: children);
      },
    );
  }
}

// ================================================================
// EMPTY STATE
// ================================================================

class _EmptyBox extends StatelessWidget {
  final IconData icon;
  final String message;
  final Color cardBg;
  final Color mutedText;
  final bool isDark;

  const _EmptyBox({
    required this.icon,
    required this.message,
    required this.cardBg,
    required this.mutedText,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
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
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primary.withOpacity(0.06),
            ),
            child: Icon(icon, size: 30, color: mutedText),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              inherit: true,
              color: mutedText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// INLINE LOADER
// ================================================================

class _InlineLoader extends StatelessWidget {
  const _InlineLoader();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.4,
            color: AppTheme.primary,
          ),
        ),
      ),
    );
  }
}

// ================================================================
// QUICK ACTION CARD
// ================================================================

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final int count;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    required this.color,
    this.count = 0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppTheme.darkSurface : Colors.white;
    final primaryText = isDark ? Colors.white : AppTheme.primary;
    final mutedText = isDark ? AppTheme.darkTextSecondary : AppTheme.greyText;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          child: Container(
            constraints: const BoxConstraints(minHeight: 88),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? AppTheme.darkBorder
                    : AppTheme.borderLight.withOpacity(0.35),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.18 : 0.045),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: color.withOpacity(isDark ? 0.20 : 0.09),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    icon,
                    size: 23,
                    color: isDark ? AppTheme.secondary : color,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          inherit: true,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: primaryText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          inherit: true,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          color: mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 5),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      constraints: const BoxConstraints(
                        minWidth: 25,
                        minHeight: 25,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Text(
                        count > 99 ? '99+' : '$count',
                        style: TextStyle(
                          inherit: true,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppTheme.secondary : color,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 11,
                      color: mutedText,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ================================================================
// HERO CARD  – always dark navy + white text
// ================================================================

class _HeroCard extends StatelessWidget {
  final String name;
  final String initial;
  final String greeting;
  final String? pendingText;
  final int activeJobs;
  final int openTickets;
  final bool isTablet;

  const _HeroCard({
    required this.name,
    required this.initial,
    required this.greeting,
    required this.pendingText,
    required this.activeJobs,
    required this.openTickets,
    required this.isTablet,
  });

  Widget _chip(String text, {bool filled = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: filled ? AppTheme.secondary : Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          inherit: true,
          color: filled ? AppTheme.primary : Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 360;

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      padding: EdgeInsets.all(
        isTablet
            ? 24
            : compact
            ? 14
            : 20,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppTheme.primary,     // #001D45
            AppTheme.primaryDark, // #001533
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
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
                    AppTheme.secondary.withOpacity(0.28),
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
                  color: Colors.white.withOpacity(0.10),
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
                  radius: isTablet
                      ? 34
                      : compact
                      ? 24
                      : 29,
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
                        color: Colors.white.withOpacity(0.80),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        inherit: true,
                        color: Colors.white,
                        fontSize: compact ? 17 : 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (pendingText != null)
                          _chip(pendingText!, filled: true),
                        if (activeJobs > 0) _chip('$activeJobs Jobs'),
                        if (openTickets > 0) _chip('$openTickets Tickets'),
                      ],
                    ),
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

// ================================================================
// JOB TILE
// ================================================================

class _JobTile extends StatelessWidget {
  final WorkJob job;

  const _JobTile({required this.job});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? Colors.white : AppTheme.primary;
    final color = workStatusColor(job.status);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: WorkCard(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => JobDetailScreen(job: job)),
          );
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.13),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(workStatusIcon(job.status), color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          job.jobNumber,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            inherit: true,
                            fontWeight: FontWeight.w800,
                            fontSize: 14.5,
                            color: primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      WorkStatusBadge(status: job.status),
                    ],
                  ),
                  WorkMetaLine(
                    icon: Icons.person_outline_rounded,
                    text: job.customerName ?? '—',
                  ),
                  WorkMetaLine(
                    icon: Icons.build_outlined,
                    text: job.serviceName ?? '—',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// TICKET TILE
// ================================================================

class _TicketTile extends StatelessWidget {
  final WorkTicket ticket;

  const _TicketTile({required this.ticket});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? Colors.white : AppTheme.primary;
    final color = workStatusColor(ticket.status);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: WorkCard(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TicketDetailScreen(ticket: ticket),
            ),
          );
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.13),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.confirmation_number_rounded,
                color: color,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          ticket.ticketNumber,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            inherit: true,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      WorkStatusBadge(status: ticket.status),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ticket.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      inherit: true,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: primary,
                    ),
                  ),
                  WorkMetaLine(
                    icon: Icons.work_outline_rounded,
                    text: ticket.jobNumber ?? '—',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}