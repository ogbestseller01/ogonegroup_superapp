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

import '../chat/chat_list_screen.dart';
import 'fundi_posts_screen.dart';
import 'fundi_requests_screen.dart';
import '../jobs/job_detail_screen.dart';
import '../tickets/ticket_detail_screen.dart';
import 'profile/fundi_profile_screen.dart';

/// Color used for text/icons that must be readable in light and dark mode.
Color _ink(bool isDark) => isDark ? Colors.white : AppTheme.primary;

/// Relative time ("5m ago" / "Dakika 5 zilizopita").
String _relativeTime(BuildContext context, dynamic value) {
  if (value == null) return '';
  return context.read<NotificationProvider>().getFormattedTime(
    value.toString(),
    locale: Localizations.localeOf(context).languageCode,
  );
}

// ================================================================
// FUNDI HOME SCREEN
// ================================================================

class FundiHomeScreen extends StatefulWidget {
  const FundiHomeScreen({super.key});

  @override
  State<FundiHomeScreen> createState() => FundiHomeScreenState(); // <-- Public state
}

// Note: no underscore, so other screens can find it.
class FundiHomeScreenState extends State<FundiHomeScreen>
    with WidgetsBindingObserver {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  int _currentIndex = 0;
  bool _isRefreshing = false;

  late final NotificationProvider _notif;
  late final ChatProvider _chat;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();

    _notif = context.read<NotificationProvider>();
    _chat = context.read<ChatProvider>();

    WidgetsBinding.instance.addObserver(this);

    _screens = [
      const _HomeDashboardContent(),
      const FundiPostsScreen(),
      const FundiRequestsScreen(),
      const FundiChatListScreen(),
      const FundiProfileScreen(), // tab 5 = Settings (profile + settings menus)
    ];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _initializeData();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopPolling();
    super.dispose();
  }

  /// Pause the auto-checks in the background, resume on return.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    if (state == AppLifecycleState.resumed) {
      _loadAll();
      _startPolling();
    } else if (state == AppLifecycleState.paused) {
      _stopPolling();
    }
  }

  // ==============================================================
  // AUTO CHECK (notifications every 15s, chat every 3s)
  // ==============================================================

  void _startPolling() {
    _notif.startPolling();
    _chat.startPolling();
  }

  void _stopPolling() {
    _notif.stopPolling();
    _chat.stopPolling();
  }

  // ==============================================================
  // DATA
  // ==============================================================

  /// Each load is isolated: one failing request never blocks the others.
  Future<void> _safe(Future<dynamic> Function() load) async {
    try {
      await load();
    } catch (e) {
      debugPrint('Home load error: $e');
    }
  }

  Future<void> _loadAll() async {
    if (!mounted) return;
    await Future.wait([
      _safe(() => context.read<TechnicianProvider>().fetchMyProfile()),
      _safe(() => context.read<RequestProvider>().loadMyRequests()),
      _safe(() => _notif.loadNotifications(silent: true)),
      _safe(() => context.read<JobProvider>().loadJobs()),
      _safe(() => context.read<TicketProvider>().loadTickets()),
      _safe(() => _chat.refreshConversations(silent: true)),
    ]);
  }

  void _initializeData() {
    _initializeChat();
    _loadAll();
    _startPolling();
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

    final user = auth.user;
    final token = auth.token;

    if (user == null || token == null) return;

    _chat.initialize(
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

  // <-- Public so other tabs can call it
  void navigateToTab(int index) {
    if (!mounted) return;
    if (_currentIndex == index) return;
    setState(() => _currentIndex = index);
  }

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  // ==============================================================
  // NOTIFICATIONS
  // ==============================================================

  void _showNotifications() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isWide = MediaQuery.sizeOf(context).width >= 800;

    if (isWide) {
      // Desktop / Tablet: Show as a centered Dialog
      showDialog<void>(
        context: context,
        builder: (ctx) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(24),
          child: Container(
            width: 600,
            height: 700,
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            clipBehavior: Clip.antiAlias,
            child: _NotificationsSheet(
              controller: ScrollController(),
              showDragHandle: false,
              onClose: () => Navigator.of(ctx).pop(),
              onSelect: (notification) {
                _notif.markAsRead(notification['id']);
                Navigator.of(ctx).pop();
                if (mounted) _handleNotificationTap(notification);
              },
            ),
          ),
        ),
      );
    } else {
      // Mobile: Show as a standard Bottom Sheet
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        constraints: const BoxConstraints(maxWidth: 640),
        builder: (sheetCtx) {
          return DraggableScrollableSheet(
            initialChildSize: 0.85,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (_, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkSurface : Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                ),
                child: _NotificationsSheet(
                  controller: scrollController,
                  showDragHandle: true,
                  onClose: () => Navigator.of(sheetCtx).pop(),
                  onSelect: (notification) {
                    _notif.markAsRead(notification['id']);
                    Navigator.of(sheetCtx).pop();
                    if (mounted) _handleNotificationTap(notification);
                  },
                ),
              );
            },
          );
        },
      );
    }
  }

  void _handleNotificationTap(Map<String, dynamic> notification) {
    final type = notification['type']?.toString() ?? '';

    if (type == 'chat_message') {
      navigateToTab(3);
    } else if (type == 'new_request' ||
        type == 'request_accepted' ||
        type == 'request_rejected') {
      navigateToTab(2);
    } else if (type.contains('ticket')) {
      Navigator.pushNamed(context, AppRoutes.tickets);
    } else if (type.contains('job')) {
      Navigator.pushNamed(context, AppRoutes.jobs);
    } else {
      navigateToTab(0);
    }
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
      _stopPolling();
      _chat.disconnect(); // clears chat data for the next user

      if (!context.mounted) return;
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
        backgroundColor:
        isDark ? AppTheme.darkBackground : theme.scaffoldBackgroundColor,
        drawer: _FundiDrawer(onLogout: () => _logoutWithConfirmation(context)),
        appBar: AppBar(
          automaticallyImplyLeading: false,
          centerTitle: false,
          titleSpacing: 0,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
          ),
          leading: IconButton(
            icon: const Icon(Icons.menu_rounded, color: Colors.white),
            onPressed: _openDrawer,
            tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
          ),
          title: Row(
            children: [
              Container(
                width: 4,
                height: compact ? 18 : 22,
                decoration: BoxDecoration(
                  color: AppTheme.secondary,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
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
              ),
            ],
          ),
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              tooltip: l10n.refresh,
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
            // Bell updates by itself (auto-check every 15 seconds)
            NotificationBellIcon(onTap: _showNotifications),
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
        bottomNavigationBar: Consumer2<ChatProvider, RequestProvider>(
          builder: (context, chat, requests, _) => _FloatingNavBar(
            currentIndex: _currentIndex,
            onTap: navigateToTab,
            homeLabel: l10n.home,
            blogLabel: l10n.blog,
            requestsLabel: l10n.requests,
            chatLabel: l10n.chat,
            settingsLabel: l10n.settings, // <-- was l10n.profile
            requestsBadge: requests.pendingCount,
            chatBadge: chat.totalUnread,
          ),
        ),
      ),
    );
  }
}

// ================================================================
// NOTIFICATIONS SHEET
// ================================================================

class _NotificationsSheet extends StatelessWidget {
  final ScrollController controller;
  final ValueChanged<Map<String, dynamic>> onSelect;
  final bool showDragHandle;
  final VoidCallback onClose;

  const _NotificationsSheet({
    required this.controller,
    required this.onSelect,
    this.showDragHandle = true,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        if (showDragHandle) ...[
          const SizedBox(height: 12),
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: theme.dividerColor,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          const SizedBox(height: 16),
        ] else
          const SizedBox(height: 16),

        // ── Header ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Consumer<NotificationProvider>(
            builder: (context, provider, _) {
              final unread = provider.unreadCount;
              return Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.secondary.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.notifications_active_rounded,
                      color: isDark ? AppTheme.secondary : AppTheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                l10n.notifications,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  inherit: true,
                                  fontSize: 21,
                                  fontWeight: FontWeight.w800,
                                  color: _ink(isDark),
                                ),
                              ),
                            ),
                            if (unread > 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppTheme.secondary,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  unread > 99 ? '99+' : '$unread',
                                  style: const TextStyle(
                                    inherit: true,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.homeNotificationsSubtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            inherit: true,
                            fontSize: 12.5,
                            color: isDark
                                ? AppTheme.darkTextSecondary
                                : AppTheme.greyText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (unread > 0)
                    TextButton.icon(
                      onPressed: provider.markAllAsRead,
                      icon: const Icon(Icons.done_all_rounded, size: 18),
                      style: TextButton.styleFrom(
                        foregroundColor: _ink(isDark),
                        backgroundColor:
                        AppTheme.primary.withValues(alpha: 0.08),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      label: Text(
                        l10n.markAllAsRead,
                        style: const TextStyle(
                          inherit: true,
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  if (!showDragHandle)
                    IconButton(
                      onPressed: onClose,
                      icon: Icon(
                        Icons.close_rounded,
                        color: _ink(isDark),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 10),

        // ── List ──
        Expanded(
          child: Consumer<NotificationProvider>(
            builder: (context, provider, _) {
              if (provider.isLoading && provider.notifications.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(color: AppTheme.primary),
                );
              }

              if (provider.notifications.isEmpty) {
                return RefreshIndicator(
                  color: AppTheme.primary,
                  onRefresh: () => provider.loadNotifications(silent: true),
                  child: ListView(
                    controller: controller,
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: 350,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 88,
                                height: 88,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppTheme.secondary
                                      .withValues(alpha: 0.14),
                                ),
                                child: Icon(
                                  Icons.notifications_off_outlined,
                                  size: 40,
                                  color: theme.hintColor,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                l10n.noNotificationsYet,
                                style: TextStyle(
                                  inherit: true,
                                  color: theme.hintColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Padding(
                                padding:
                                const EdgeInsets.symmetric(horizontal: 40),
                                child: Text(
                                  l10n.homeNotificationsEmptyHint,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    inherit: true,
                                    color:
                                    theme.hintColor.withValues(alpha: 0.7),
                                    fontSize: 13,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                color: AppTheme.primary,
                onRefresh: () => provider.loadNotifications(silent: true),
                child: ListView.separated(
                  controller: controller,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: provider.notifications.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final notification = provider.notifications[index];
                    return _NotificationTile(
                      notification: notification,
                      onTap: () => onSelect(notification),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
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
                      AppTheme.secondary.withValues(alpha: 0.25),
                      AppTheme.primary.withValues(alpha: 0.15),
                    ],
                  ),
                ),
                child: Icon(
                  Icons.workspace_premium_rounded,
                  size: 36,
                  color: _ink(isDark),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                l10n.comingSoonTitle,
                style: TextStyle(
                  inherit: true,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _ink(isDark),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.comingSoonBody,
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

  Widget _comingSoonBadge(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.secondary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        l10n.comingSoon,
        style: TextStyle(
          inherit: true,
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          color: isDark ? AppTheme.secondary : AppTheme.primary,
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

    final name = user?.name ?? l10n.homeDefaultName;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'F';

    return Drawer(
      backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // ── Drawer header ───────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 12, 8, 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primary, AppTheme.primaryLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomRight: Radius.circular(28),
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
                              color: AppTheme.secondary.withValues(alpha: 0.35),
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
                        tooltip: l10n.jobDialogClose,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.15),
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
                        color: Colors.white.withValues(alpha: 0.82),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // ── Drawer menu ─────────────────────────────────
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
                    label: l10n.tickets,
                    trailing: _countPill(totalTickets),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, AppRoutes.tickets);
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.work_outline_rounded,
                    label: l10n.jobs,
                    trailing: _countPill(totalJobs),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, AppRoutes.jobs);
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.account_balance_wallet_rounded,
                    label: l10n.myBalance,
                    trailing: _comingSoonBadge(context),
                    onTap: () {
                      Navigator.pop(context);
                      _showComingSoon(context);
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.workspace_premium_rounded,
                    label: l10n.subscriptions,
                    trailing: _comingSoonBadge(context),
                    onTap: () {
                      Navigator.pop(context);
                      _showComingSoon(context);
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.trending_up_rounded,
                    label: l10n.earnings,
                    trailing: _comingSoonBadge(context),
                    onTap: () {
                      Navigator.pop(context);
                      _showComingSoon(context);
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.bar_chart_rounded,
                    label: l10n.reports,
                    trailing: _comingSoonBadge(context),
                    onTap: () {
                      Navigator.pop(context);
                      _showComingSoon(context);
                    },
                  ),
                  // Downloads item removed as requested.
                  // Settings item removed from drawer – available only in bottom nav
                ],
              ),
            ),

            // ── Logout ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
              child: Material(
                color: AppTheme.error.withValues(alpha: 0.09),
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
                            color: AppTheme.error.withValues(alpha: 0.14),
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
    final color = _ink(isDark);

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
                    color: color.withValues(alpha: 0.09),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
// FLOATING BOTTOM NAV (with live badges)
// ================================================================

class _FloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final String homeLabel;
  final String blogLabel;
  final String requestsLabel;
  final String chatLabel;
  final String settingsLabel;
  final int requestsBadge;
  final int chatBadge;

  const _FloatingNavBar({
    required this.currentIndex,
    required this.onTap,
    required this.homeLabel,
    required this.blogLabel,
    required this.requestsLabel,
    required this.chatLabel,
    required this.settingsLabel,
    this.requestsBadge = 0,
    this.chatBadge = 0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Container(
          height: 68,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: isDark
                  ? AppTheme.darkBorder
                  : AppTheme.borderLight.withValues(alpha: 0.35),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.10),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                selectedIcon: Icons.home_rounded,
                label: homeLabel,
                selected: currentIndex == 0,
                onTap: () => onTap(0),
              ),
              _NavItem(
                icon: Icons.photo_library_outlined,
                selectedIcon: Icons.photo_library_rounded,
                label: blogLabel,
                selected: currentIndex == 1,
                onTap: () => onTap(1),
              ),
              _NavItem(
                icon: Icons.inbox_outlined,
                selectedIcon: Icons.inbox_rounded,
                label: requestsLabel,
                selected: currentIndex == 2,
                badge: requestsBadge,
                onTap: () => onTap(2),
              ),
              _NavItem(
                icon: Icons.chat_bubble_outline_rounded,
                selectedIcon: Icons.chat_bubble_rounded,
                label: chatLabel,
                selected: currentIndex == 3,
                badge: chatBadge,
                onTap: () => onTap(3),
              ),
              _NavItem(
                icon: Icons.settings_outlined,
                selectedIcon: Icons.settings_rounded,
                label: settingsLabel,
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
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final int badge;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = selected
        ? (isDark ? AppTheme.secondary : AppTheme.primary)
        : (isDark ? AppTheme.darkTextSecondary : AppTheme.greyText);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: selected
                    ? (isDark
                    ? AppTheme.secondary.withValues(alpha: 0.16)
                    : AppTheme.primary.withValues(alpha: 0.09))
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Badge(
                isLabelVisible: badge > 0,
                backgroundColor: AppTheme.error,
                label: Text(
                  badge > 99 ? '99+' : '$badge',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: Icon(selected ? selectedIcon : icon,
                    size: 24, color: color),
              ),
            ),
            const SizedBox(height: 3),
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
    final unreadChats = context.watch<ChatProvider>().totalUnread;

    final user = auth.user;
    final name = user?.name ?? l10n.homeDefaultName;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'F';

    final totalJobs = jobProvider.jobs.length;
    final totalTickets = ticketProvider.tickets.length;

    // Request stats
    final totalRequests = requestProvider.totalCount;
    final pendingCount = requestProvider.pendingCount;
    final completedCount = requestProvider.acceptedCount; // Accepted = Completed

    final greeting = _greeting(l10n);

    FundiHomeScreenState? homeState() =>
        context.findAncestorStateOfType<FundiHomeScreenState>();

    void goToRequests() => homeState()?.navigateToTab(2);
    void goToChat() => homeState()?.navigateToTab(3);

    return RefreshIndicator(
      color: AppTheme.primary,
      onRefresh: () async {
        await Future.wait([
          context.read<JobProvider>().loadJobs(),
          context.read<TicketProvider>().loadTickets(),
          context.read<RequestProvider>().loadMyRequests(),
          context.read<NotificationProvider>().loadNotifications(silent: true),
          context.read<ChatProvider>().refreshConversations(silent: true),
        ]);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          isTablet ? 24 : 16,
          16,
          isTablet ? 24 : 16,
          32,
        ),
        children: [
          // ── Hero Card ───────────────────────────────────────
          _HeroCard(
            name: name,
            initial: initial,
            greeting: greeting,
            pendingText:
            pendingCount > 0 ? l10n.pendingCount(pendingCount) : null,
            unreadChats: unreadChats,
            onChatTap: goToChat,
            onPendingTap: goToRequests,
            isTablet: isTablet,
          ),

          const SizedBox(height: 18),

          // ── Request stats ───────────────────────────────────
          _RequestStatsRow(
            total: totalRequests,
            pending: pendingCount,
            completed: completedCount,
            isDark: isDark,
            onTap: goToRequests,
            totalLabel: l10n.totalRequests,
            pendingLabel: l10n.pending,
            completedLabel: l10n.completed,
          ),

          const SizedBox(height: 18),

          // ── Quick actions ───────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _QuickAction(
                  icon: Icons.work_outline_rounded,
                  label: l10n.jobs,
                  subtitle: l10n.viewAllShort,
                  count: totalJobs,
                  color: AppTheme.primary,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.jobs),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickAction(
                  icon: Icons.confirmation_number_outlined,
                  label: l10n.tickets,
                  subtitle: l10n.viewAllShort,
                  count: totalTickets,
                  color: AppTheme.primary,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.tickets),
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // ── Recent requests ─────────────────────────────────
          _SectionHeader(
            title: l10n.latestRequests,
            showAction: requestProvider.requests.isNotEmpty,
            onViewAll: goToRequests,
            viewAllLabel: l10n.viewAll,
          ),
          const SizedBox(height: 12),

          if (requestProvider.isLoading && requestProvider.requests.isEmpty)
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

          // ── Recent jobs ─────────────────────────────────────
          _SectionHeader(
            title: l10n.recentJobs,
            showAction: jobProvider.jobs.isNotEmpty,
            onViewAll: () => Navigator.pushNamed(context, AppRoutes.jobs),
            viewAllLabel: l10n.viewAll,
          ),
          const SizedBox(height: 12),

          if (jobProvider.isLoading && jobProvider.jobs.isEmpty)
            const _InlineLoader()
          else if (jobProvider.jobs.isEmpty)
            _EmptyBox(
              icon: Icons.work_outline_rounded,
              message: l10n.noJobsYet,
              cardBg: isDark ? AppTheme.darkSurface : Colors.white,
              mutedText:
              isDark ? AppTheme.darkTextSecondary : AppTheme.greyText,
              isDark: isDark,
            )
          else
            ...jobProvider.jobs.take(3).map((j) => _JobTile(job: j)),

          const SizedBox(height: 28),

          // ── Recent tickets ──────────────────────────────────
          _SectionHeader(
            title: l10n.recentTickets,
            showAction: ticketProvider.tickets.isNotEmpty,
            onViewAll: () => Navigator.pushNamed(context, AppRoutes.tickets),
            viewAllLabel: l10n.viewAll,
          ),
          const SizedBox(height: 12),

          if (ticketProvider.isLoading && ticketProvider.tickets.isEmpty)
            const _InlineLoader()
          else if (ticketProvider.tickets.isEmpty)
            _EmptyBox(
              icon: Icons.confirmation_number_outlined,
              message: l10n.noTicketsYet,
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

  /// Greeting forced to East Africa Time (UTC+3)
  String _greeting(AppLocalizations l10n) {
    final eat = DateTime.now().toUtc().add(const Duration(hours: 3));
    final hour = eat.hour; // 0–23

    if (hour < 12) return l10n.goodMorning;
    if (hour < 17) return l10n.goodAfternoon;
    return l10n.goodEvening;
  }
}

// ================================================================
// REQUEST STATS ROW
// ================================================================

class _RequestStatsRow extends StatelessWidget {
  final int total;
  final int pending;
  final int completed;
  final bool isDark;
  final VoidCallback onTap;
  final String totalLabel;
  final String pendingLabel;
  final String completedLabel;

  const _RequestStatsRow({
    required this.total,
    required this.pending,
    required this.completed,
    required this.isDark,
    required this.onTap,
    required this.totalLabel,
    required this.pendingLabel,
    required this.completedLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.list_alt_rounded,
            value: total,
            label: totalLabel,
            iconBg: isDark
                ? AppTheme.primary.withValues(alpha: 0.25)
                : AppTheme.navy50,
            iconColor: isDark ? AppTheme.secondary : AppTheme.primary,
            isDark: isDark,
            onTap: onTap,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: Icons.more_horiz_rounded,
            value: pending,
            label: pendingLabel,
            iconBg: AppTheme.warning.withValues(alpha: isDark ? 0.22 : 0.15),
            iconColor: AppTheme.warning,
            isDark: isDark,
            onTap: onTap,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: Icons.check_circle_outline_rounded,
            value: completed,
            label: completedLabel,
            iconBg: AppTheme.success.withValues(alpha: isDark ? 0.22 : 0.14),
            iconColor: AppTheme.success,
            isDark: isDark,
            onTap: onTap,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final int value;
  final String label;
  final Color iconBg;
  final Color iconColor;
  final bool isDark;
  final VoidCallback onTap;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.iconBg,
    required this.iconColor,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? AppTheme.darkSurface : Colors.white;
    final textColor = _ink(isDark);
    final muted = isDark ? AppTheme.darkTextSecondary : AppTheme.greyText;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? AppTheme.darkBorder
                  : AppTheme.borderLight.withValues(alpha: 0.35),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            child: Column(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 20, color: iconColor),
                ),
                const SizedBox(height: 10),
                Text(
                  '$value',
                  style: TextStyle(
                    inherit: true,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    inherit: true,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: muted,
                  ),
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
// NOTIFICATION TILE
// ================================================================

class _NotificationTile extends StatelessWidget {
  final Map<String, dynamic> notification;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
  });

  Color _typeColor(String type, bool isDark) {
    switch (type) {
      case 'request_accepted':
      case 'request_completed':
        return AppTheme.success;
      case 'request_rejected':
      case 'request_cancelled':
        return AppTheme.error;
      case 'new_request':
        return AppTheme.warning;
      default:
        return isDark ? AppTheme.secondary : AppTheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.read<NotificationProvider>();

    final isRead = provider.isNotificationRead(notification);
    final type = notification['type']?.toString() ?? '';
    final color = _typeColor(type, isDark);
    final time = _relativeTime(context, notification['created_at']);
    final body = notification['body']?.toString() ?? '';

    return Material(
      color: isRead
          ? (isDark ? AppTheme.darkSurface : Colors.white)
          : (isDark
          ? AppTheme.secondary.withValues(alpha: 0.08)
          : AppTheme.secondary.withValues(alpha: 0.10)),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isRead
                  ? (isDark
                  ? AppTheme.darkBorder
                  : AppTheme.borderLight.withValues(alpha: 0.35))
                  : AppTheme.secondary.withValues(alpha: 0.6),
              width: 1.2,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(provider.getNotificationIcon(type),
                    color: color, size: 21),
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
                            notification['title']?.toString() ??
                                AppLocalizations.of(context)!
                                    .homeNotificationFallback,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              inherit: true,
                              fontWeight:
                              isRead ? FontWeight.w600 : FontWeight.w800,
                              fontSize: 14,
                              color: _ink(isDark),
                            ),
                          ),
                        ),
                        if (!isRead)
                          Container(
                            width: 9,
                            height: 9,
                            margin: const EdgeInsets.only(left: 8),
                            decoration: const BoxDecoration(
                              color: AppTheme.secondary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    if (body.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          inherit: true,
                          fontSize: 13,
                          height: 1.35,
                          color: isDark
                              ? AppTheme.darkTextSecondary
                              : AppTheme.greyText,
                        ),
                      ),
                    ],
                    if (time.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            size: 13,
                            color: isDark
                                ? AppTheme.darkTextSecondary
                                : AppTheme.greyText,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            time,
                            style: TextStyle(
                              inherit: true,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppTheme.darkTextSecondary
                                  : AppTheme.greyText,
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
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = _ink(isDark);
    final mutedText = isDark ? AppTheme.darkTextSecondary : AppTheme.greyText;

    final status = request.status?.toString() ?? 'pending';
    final statusColor = _requestStatusColor(status);
    final created =
    request.createdAt != null ? _formatDate(request.createdAt) : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () {
            final homeState =
            context.findAncestorStateOfType<FundiHomeScreenState>();
            homeState?.navigateToTab(2);
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? AppTheme.darkBorder
                    : AppTheme.borderLight.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.13),
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
                              color: statusColor.withValues(alpha: 0.13),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _requestStatusLabel(status, l10n),
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

  String _requestStatusLabel(String status, AppLocalizations l10n) {
    switch (status) {
      case 'accepted':
        return l10n.acceptedStatus;
      case 'rejected':
        return l10n.rejectedStatus;
      case 'cancelled':
        return l10n.cancelledStatus;
      case 'pending':
      default:
        return l10n.pendingStatus;
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
  final String viewAllLabel;

  const _SectionHeader({
    required this.title,
    required this.showAction,
    required this.onViewAll,
    required this.viewAllLabel,
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
                    color: _ink(isDark),
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
              backgroundColor: accent.withValues(alpha: 0.08),
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 6,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text(
              viewAllLabel,
              style: const TextStyle(
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
              : AppTheme.borderLight.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.secondary.withValues(alpha: 0.14),
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
  final int? count;
  final bool highlightCount;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    required this.color,
    this.count,
    this.highlightCount = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppTheme.darkSurface : Colors.white;
    final primaryText = _ink(isDark);
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
                color: highlightCount
                    ? AppTheme.secondary.withValues(alpha: 0.7)
                    : (isDark
                    ? AppTheme.darkBorder
                    : AppTheme.borderLight.withValues(alpha: 0.35)),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.045),
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
                    color: color.withValues(alpha: isDark ? 0.20 : 0.09),
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
                    if (count != null)
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
                          color: highlightCount
                              ? AppTheme.secondary
                              : color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Text(
                          count! > 99 ? '99+' : '$count',
                          style: TextStyle(
                            inherit: true,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: highlightCount
                                ? AppTheme.primary
                                : (isDark ? AppTheme.secondary : color),
                          ),
                        ),
                      ),
                    if (count != null) const SizedBox(height: 5),
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
// HERO CARD
// ================================================================

class _HeroCard extends StatelessWidget {
  final String name;
  final String initial;
  final String greeting;
  final String? pendingText;
  final int unreadChats;
  final VoidCallback onChatTap;
  final VoidCallback onPendingTap;
  final bool isTablet;

  const _HeroCard({
    required this.name,
    required this.initial,
    required this.greeting,
    required this.pendingText,
    required this.unreadChats,
    required this.onChatTap,
    required this.onPendingTap,
    required this.isTablet,
  });

  Widget _chip(
      String text, {
        bool filled = false,
        IconData? icon,
        VoidCallback? onTap,
      }) {
    final fg = filled ? AppTheme.primary : Colors.white;
    return Material(
      color: filled ? AppTheme.secondary : Colors.white.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: fg),
                const SizedBox(width: 5),
              ],
              Text(
                text,
                style: TextStyle(
                  inherit: true,
                  color: fg,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
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
            AppTheme.primary,
            AppTheme.primaryDark,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.35),
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
                    AppTheme.secondary.withValues(alpha: 0.28),
                    AppTheme.secondary.withValues(alpha: 0),
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
                  color: Colors.white.withValues(alpha: 0.10),
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
                        color: Colors.white.withValues(alpha: 0.80),
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
                    if (pendingText != null || unreadChats > 0) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          if (pendingText != null)
                            _chip(
                              pendingText!,
                              filled: true,
                              onTap: onPendingTap,
                            ),
                          if (unreadChats > 0)
                            _chip(
                              unreadChats > 99 ? '99+' : '$unreadChats',
                              icon: Icons.chat_bubble_rounded,
                              onTap: onChatTap,
                            ),
                        ],
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

// ================================================================
// JOB TILE
// ================================================================

class _JobTile extends StatelessWidget {
  final WorkJob job;

  const _JobTile({required this.job});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = _ink(isDark);
    final color = workStatusColor(job.status);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: WorkCard(
        onTap: () => JobDetailDialog.show(context, job),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.13),
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
                      JobStatusBadge(status: job.status),
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
    final primary = _ink(isDark);
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
                color: color.withValues(alpha: 0.13),
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