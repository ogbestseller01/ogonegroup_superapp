// lib/screens/fundi/fundi_home_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

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
  int _currentIndex = 0;
  late final List<Widget> _screens;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _screens = [
      const _HomeDashboardContent(),
      const FundiPostsScreen(),
      const FundiRequestsScreen(),
      const ChatListScreen(),
      const FundiProfileScreen(),
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
    _loadNotifications();
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
          email: user.email,
          phone: user.phone,
          avatar: null,
        ),
      );
    }
  }

  void _loadNotifications() {
    context.read<NotificationProvider>().loadNotifications();
  }

  void _navigateToTab(int index) {
    setState(() => _currentIndex = index);
  }

  // ============================================================
  // DRAWER – OG ONE GROUP + Mini Apps (Partnerships)
  // ============================================================
  Drawer _buildDrawer(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? Colors.white : AppTheme.primary;
    final mutedText = isDark ? AppTheme.darkTextSecondary : AppTheme.greyText;

    return Drawer(
      backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primary, AppTheme.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(6),
                    child: Image.asset(
                      'assets/images/nearbyfundi-logov1.png',
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.business_rounded,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'OG ONE GROUP',
                          style: TextStyle(
                            inherit: true,
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Other Services',
                          style: TextStyle(
                            inherit: true,
                            color: AppTheme.secondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text(
                'Partnerships',
                style: TextStyle(
                  inherit: true,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: mutedText,
                ),
              ),
            ),
            // Others – Coming soon
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: _MiniAppTile(
                item: _MiniAppItem(
                  name: 'Others',
                  subtitle: 'Coming soon',
                  icon: Icons.apps_rounded,
                  color: AppTheme.secondary,
                  onTap: () {
                    Navigator.pop(context);
                    _showComingSoon(context, 'Others');
                  },
                ),
              ),
            ),
            const Spacer(),
            Divider(color: isDark ? AppTheme.darkBorder : AppTheme.borderLight),
            ListTile(
              leading: const Icon(Icons.info_outline_rounded,
                  color: AppTheme.primary),
              title: Text(
                'About OG ONE GROUP',
                style: TextStyle(
                  inherit: true,
                  color: primaryText,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                launchUrl(
                  Uri.parse('https://ogonegroup.com'),
                  mode: LaunchMode.externalApplication,
                ).catchError((_) => false);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

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
                color: isDark ? AppTheme.darkSurface : theme.cardColor,
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(28)),
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
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: (isDark ? AppTheme.darkBorder : theme.dividerColor)
                          .withOpacity(0.6),
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
                            foregroundColor: AppTheme.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                          child: Text(
                            l10n.markAllAsRead,
                            style: const TextStyle(
                              inherit: true,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
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
                                Icon(
                                  Icons.notifications_off_outlined,
                                  size: 68,
                                  color: isDark
                                      ? AppTheme.darkTextSecondary
                                      : theme.hintColor.withOpacity(0.6),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  l10n.noNotificationsYet,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    inherit: true,
                                    color: isDark
                                        ? AppTheme.darkTextSecondary
                                        : theme.hintColor,
                                    fontWeight: FontWeight.w500,
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
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
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

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.construction_rounded,
                color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '$feature ${AppLocalizations.of(context)!.comingSoon} 🚀',
                style: const TextStyle(
                    inherit: true, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: const Duration(seconds: 2),
      ),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : theme.scaffoldBackgroundColor,
      drawer: _buildDrawer(context),
      appBar: AppBar(
        title: Text(
          l10n.fundiDashboard,
          style: const TextStyle(
            inherit: true,
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.3,
          ),
        ),
        elevation: 0,
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
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
            tooltip: 'Refresh',
            onPressed: _isRefreshing ? null : _manualRefresh,
          ),
          NotificationBellIcon(onTap: () => _showNotifications(context)),
          IconButton(
            icon: const Icon(Icons.smart_toy_rounded,
                color: Colors.white, size: 26),
            onPressed: () => _showComingSoon(context, l10n.aiAssistant),
            tooltip: '${l10n.aiAssistant} (${l10n.comingSoon})',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
            offset: const Offset(0, 50),
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 10,
            color: isDark ? AppTheme.darkSurface : Colors.white,
            itemBuilder: (context) => _buildMenuItems(context),
          ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : theme.cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.35 : 0.07),
              blurRadius: 12,
              offset: const Offset(0, -3),
            ),
          ],
          border: Border(
            top: BorderSide(
              color: isDark
                  ? AppTheme.darkBorder
                  : theme.dividerColor.withOpacity(0.45),
              width: 0.5,
            ),
          ),
        ),
        child: Consumer<ChatProvider>(
          builder: (context, chatProvider, _) {
            return BottomNavigationBar(
              currentIndex: _currentIndex,
              selectedItemColor: AppTheme.primary,
              unselectedItemColor: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.greyText,
              onTap: (i) => setState(() => _currentIndex = i),
              type: BottomNavigationBarType.fixed,
              backgroundColor: isDark ? AppTheme.darkSurface : theme.cardColor,
              elevation: 0,
              selectedFontSize: 12,
              unselectedFontSize: 11,
              items: [
                BottomNavigationBarItem(
                  icon: const Icon(Icons.home_outlined),
                  activeIcon: const Icon(Icons.home_rounded),
                  label: l10n.home,
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.article_outlined),
                  activeIcon: const Icon(Icons.article_rounded),
                  label: l10n.blog,
                ),
                BottomNavigationBarItem(
                  icon: Stack(
                    alignment: Alignment.topRight,
                    children: [
                      const Icon(Icons.list_alt_outlined),
                      if (chatProvider.totalUnread > 0)
                        _buildBadge(chatProvider.totalUnread),
                    ],
                  ),
                  activeIcon: Stack(
                    alignment: Alignment.topRight,
                    children: [
                      const Icon(Icons.list_alt_rounded),
                      if (chatProvider.totalUnread > 0)
                        _buildBadge(chatProvider.totalUnread),
                    ],
                  ),
                  label: l10n.requests,
                ),
                BottomNavigationBarItem(
                  icon: Stack(
                    alignment: Alignment.topRight,
                    children: [
                      const Icon(Icons.chat_bubble_outline_rounded),
                      if (chatProvider.totalUnread > 0)
                        _buildBadge(chatProvider.totalUnread),
                    ],
                  ),
                  activeIcon: Stack(
                    alignment: Alignment.topRight,
                    children: [
                      const Icon(Icons.chat_bubble_rounded),
                      if (chatProvider.totalUnread > 0)
                        _buildBadge(chatProvider.totalUnread),
                    ],
                  ),
                  label: l10n.chat,
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.person_outline),
                  activeIcon: const Icon(Icons.person_rounded),
                  label: l10n.profile,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBadge(int count) {
    return Container(
      padding: const EdgeInsets.all(3.5),
      decoration: const BoxDecoration(
        color: AppTheme.secondary,
        shape: BoxShape.circle,
      ),
      constraints: const BoxConstraints(minWidth: 15, minHeight: 15),
      child: Text(
        count > 9 ? '9+' : '$count',
        style: const TextStyle(
          inherit: true,
          color: AppTheme.primary,
          fontSize: 8.5,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  List<PopupMenuEntry<String>> _buildMenuItems(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      _buildPopupMenuItem(
        context,
        key: 'settings',
        icon: Icons.settings_outlined,
        title: l10n.settings,
        onTap: () => Navigator.pushNamed(context, AppRoutes.settings),
      ),
      _buildPopupMenuItem(
        context,
        key: 'portfolio',
        icon: Icons.photo_library_outlined,
        title: l10n.portfolio,
        onTap: () => Navigator.pushNamed(context, AppRoutes.portfolio),
      ),
      _buildPopupMenuItem(
        context,
        key: 'downloads',
        icon: Icons.file_download_rounded,
        title: 'Downloads',
        onTap: () => Navigator.pushNamed(context, AppRoutes.downloads),
      ),
      const PopupMenuDivider(),
      _buildPopupMenuItem(
        context,
        key: 'logout',
        icon: Icons.logout_rounded,
        title: l10n.logout,
        onTap: () => _logoutWithConfirmation(context),
        isDestructive: true,
      ),
    ];
  }

  PopupMenuItem<String> _buildPopupMenuItem(
      BuildContext context, {
        required String key,
        required IconData icon,
        required String title,
        required VoidCallback onTap,
        bool isDestructive = false,
      }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDestructive ? AppTheme.error : AppTheme.primary;
    return PopupMenuItem<String>(
      value: key,
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  inherit: true,
                  color: isDestructive
                      ? AppTheme.error
                      : (isDark ? Colors.white : AppTheme.primary),
                  fontWeight:
                  isDestructive ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Mini apps models / tiles (gold hover) ──────────────────────

class _MiniAppItem {
  final String name;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _MiniAppItem({
    required this.name,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

class _MiniAppTile extends StatefulWidget {
  final _MiniAppItem item;
  const _MiniAppTile({required this.item});

  @override
  State<_MiniAppTile> createState() => _MiniAppTileState();
}

class _MiniAppTileState extends State<_MiniAppTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = _hovered
        ? AppTheme.secondary.withOpacity(isDark ? 0.22 : 0.18)
        : Colors.transparent;
    final border = _hovered
        ? AppTheme.secondary
        : (isDark
        ? AppTheme.darkBorder
        : AppTheme.borderLight.withOpacity(0.4));

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Material(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: widget.item.onTap,
            onHighlightChanged: (v) => setState(() => _hovered = v),
            borderRadius: BorderRadius.circular(14),
            splashColor: AppTheme.secondary.withOpacity(0.25),
            highlightColor: AppTheme.secondary.withOpacity(0.12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: border, width: _hovered ? 1.5 : 1),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: widget.item.color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(widget.item.icon,
                        color: widget.item.color, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.item.name,
                          style: TextStyle(
                            inherit: true,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: isDark ? Colors.white : AppTheme.primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.item.subtitle,
                          style: TextStyle(
                            inherit: true,
                            fontSize: 12,
                            color: isDark
                                ? AppTheme.darkTextSecondary
                                : AppTheme.greyText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: _hovered
                        ? AppTheme.secondary
                        : (isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.greyText),
                  ),
                ],
              ),
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
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: isRead
                ? (isDark ? AppTheme.darkSurface : theme.cardColor)
                : AppTheme.primary.withOpacity(isDark ? 0.15 : 0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isRead
                  ? (isDark
                  ? AppTheme.darkBorder
                  : theme.dividerColor.withOpacity(0.45))
                  : AppTheme.primary.withOpacity(0.18),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isRead
                      ? (isDark
                      ? AppTheme.darkSurfaceLight
                      : theme.dividerColor.withOpacity(0.25))
                      : AppTheme.primary.withOpacity(0.12),
                  shape: BoxShape.circle,
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
                        fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
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
    final tech = context.watch<TechnicianProvider>().technician;
    final online = tech?.isOnline ?? false;
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
    final padding = isTablet ? 24.0 : 16.0;
    final cardPadding = isTablet ? 22.0 : 18.0;
    final gap = isTablet ? 16.0 : 12.0;

    final primaryText = isDark ? Colors.white : AppTheme.primary;
    final mutedText = isDark ? AppTheme.darkTextSecondary : AppTheme.greyText;
    final cardBg = isDark ? AppTheme.darkSurface : theme.cardColor;

    return SafeArea(
      bottom: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bottomPadding = MediaQuery.of(context).padding.bottom + 80.0;
          return RefreshIndicator(
            color: AppTheme.primary,
            onRefresh: () async {
              await context.read<RequestProvider>().loadMyRequests();
              await context.read<TechnicianProvider>().fetchMyProfile();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.only(
                left: padding,
                right: padding,
                top: padding,
                bottom: bottomPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(cardPadding),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primary, AppTheme.primaryDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withOpacity(0.32),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: isTablet ? 36 : 30,
                          backgroundColor: Colors.white,
                          child: Text(
                            user?.name.isNotEmpty == true
                                ? user!.name[0].toUpperCase()
                                : 'F',
                            style: TextStyle(
                              inherit: true,
                              color: AppTheme.primary,
                              fontSize: isTablet ? 28 : 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${l10n.hello}, ${user?.name ?? 'Fundi'}! 👋',
                                style: const TextStyle(
                                  inherit: true,
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.3,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  if (online) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.success,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.wifi_rounded,
                                              color: Colors.white, size: 13),
                                          const SizedBox(width: 4),
                                          Text(
                                            l10n.online,
                                            style: const TextStyle(
                                              inherit: true,
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  if (pendingRequests > 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.warning,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        '$pendingRequests ${l10n.pending}',
                                        style: const TextStyle(
                                          inherit: true,
                                          color: AppTheme.primary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.check_circle_rounded,
                            color: Colors.white, size: 28),
                      ],
                    ),
                  ),
                  SizedBox(height: gap + 8),
                  Row(
                    children: [
                      Flexible(
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
                      Flexible(
                        child: _buildStatCard(
                          context,
                          icon: Icons.pending_rounded,
                          label: l10n.pending,
                          value: pendingRequests.toString(),
                          color: AppTheme.warning,
                          isTablet: isTablet,
                          onTap: () => _navigateToTab(context, 2),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
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
                  SizedBox(height: gap + 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Latest Requests',
                        style: theme.textTheme.titleLarge?.copyWith(
                          inherit: true,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                          color: primaryText,
                        ),
                      ),
                      if (requests.isNotEmpty)
                        TextButton(
                          onPressed: () => _navigateToTab(context, 2),
                          child: const Text(
                            'View All',
                            style: TextStyle(
                              inherit: true,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (topFiveRequests.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 36, horizontal: 20),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isDark
                              ? AppTheme.darkBorder
                              : theme.dividerColor.withOpacity(0.5),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.inbox_outlined,
                              size: 48, color: mutedText),
                          const SizedBox(height: 14),
                          Text(
                            l10n.noRequests,
                            style: TextStyle(
                              inherit: true,
                              color: mutedText,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Column(
                      children: topFiveRequests
                          .map((r) => _buildLatestRequest(context, r))
                          .toList(),
                    ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
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
    final cardBg = isDark ? AppTheme.darkSurface : theme.cardColor;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToTab(context, 2),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark
                    ? AppTheme.darkBorder
                    : theme.dividerColor.withOpacity(0.5),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.25 : 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.13),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_requestStatusIcon(status),
                      color: statusColor, size: 22),
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
                                fontWeight: FontWeight.w700,
                                color: primaryText,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 4),
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
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.person_outline_rounded,
                              size: 14, color: mutedText),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              request.customerName.toString(),
                              style: TextStyle(
                                  inherit: true,
                                  color: mutedText,
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
                                size: 13, color: mutedText),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? AppTheme.darkSurface : theme.cardColor;
    final mutedText = isDark ? AppTheme.darkTextSecondary : AppTheme.greyText;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: isTablet ? 16.0 : 14.0,
            horizontal: isTablet ? 12.0 : 8.0,
          ),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: isDark
                ? Border.all(color: AppTheme.darkBorder)
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.25 : 0.07),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: isTablet ? 20 : 16, color: color),
                  const SizedBox(width: 5),
                  Text(
                    value,
                    style: TextStyle(
                      inherit: true,
                      fontSize: isTablet ? 20 : 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                label,
                style: TextStyle(
                  inherit: true,
                  fontSize: isTablet ? 11 : 10,
                  color: mutedText,
                  fontWeight: FontWeight.w500,
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