// home_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../providers/post_provider.dart';
import '../../providers/request_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/technician_provider.dart';
import '../../providers/service_provider.dart';
import '../../providers/settings_provider.dart';

import '../../models/chat_user.dart';
import '../../l10n/app_localizations.dart';

import 'nearby_screen.dart';
import 'blogs_screen.dart';

import '../requests/my_requests_screen.dart';
import '../profile/profile_screen.dart';
import '../chat/chat_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ================================================================
  // CURRENT TAB
  // ================================================================

  int _currentIndex = 0;

  // ================================================================
  // SCREENS
  // ================================================================

  late final List<Widget> _screens;

  // ================================================================
  // LOCALE
  // ================================================================

  String _currentLocale = 'en';

  // ================================================================
  // RESPONSIVE BREAKPOINTS
  // ================================================================

  static const double _tabletBreakpoint = 700;
  static const double _desktopBreakpoint = 1100;

  // ================================================================
  // INIT
  // ================================================================

  @override
  void initState() {
    super.initState();

    _screens = const [
      NearbyScreen(),
      BlogsScreen(),
      MyRequestsScreen(),
      ChatListScreen(),
      ProfileScreen(),
    ];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final settings = context.read<SettingsProvider>();
      _currentLocale = settings.locale;

      context.read<ServiceProvider>().fetchServices(locale: _currentLocale);
      _loadNotifications();
      _initializeChat();
    });
  }

  // ================================================================
  // CHAT INITIALIZATION
  // ================================================================

  void _initializeChat() {
    final authProvider = context.read<AuthProvider>();
    final chatProvider = context.read<ChatProvider>();
    final user = authProvider.user;
    final token = authProvider.token;

    if (user != null && token != null) {
      chatProvider.initialize(
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

  // ================================================================
  // LOAD NOTIFICATIONS
  // ================================================================

  Future<void> _loadNotifications() async {
    try {
      await context.read<NotificationProvider>().loadNotifications();
    } catch (e) {
      debugPrint('Notification loading error: $e');
    }
  }

  // ================================================================
  // REFRESH
  // ================================================================

  Future<void> _refreshCurrentScreen() async {
    final l10n = AppLocalizations.of(context)!;

    try {
      switch (_currentIndex) {
        case 0:
          await context.read<TechnicianProvider>().refreshLastSearch();
          break;
        case 1:
          await context.read<PostProvider>().fetchPosts(refresh: true);
          break;
        case 2:
          await context.read<RequestProvider>().loadMyRequests();
          break;
        case 3:
          await context.read<ChatProvider>().refreshConversations();
          break;
        case 4:
          await context.read<AuthProvider>().loadUser();
          break;
      }

      await context.read<NotificationProvider>().loadNotifications();

      final settings = context.read<SettingsProvider>();
      if (_currentLocale != settings.locale) {
        _currentLocale = settings.locale;
        await context
            .read<ServiceProvider>()
            .fetchServices(locale: _currentLocale);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text(l10n.refreshed)),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 1),
          backgroundColor: AppTheme.success,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      debugPrint('Refresh error: $e');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(child: Text(l10n.refreshFailed)),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppTheme.error,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  // ================================================================
  // MINI APPS
  // ================================================================

  void _showMiniAppsComingSoon() {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.widgets_rounded, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Mini Apps Coming Soon! 🚀',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: theme.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ================================================================
  // ABOUT OG ONE GROUP
  // ================================================================

  void _showAboutOgOneGroup() {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.info_outline_rounded, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'About OG ONE GROUP — Coming Soon',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: theme.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ================================================================
  // NOTIFICATIONS
  // ================================================================

  void _showNotifications(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.78,
          minChildSize: 0.50,
          maxChildSize: 0.96,
          expand: false,
          builder: (sheetContext, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  // HANDLE
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  // HEADER
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 12, 12),
                    child: Consumer<NotificationProvider>(
                      builder: (context, provider, child) {
                        final unread = provider.unreadCount;
                        return Row(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color:
                                theme.primaryColor.withOpacity(0.10),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.notifications_rounded,
                                color: theme.primaryColor,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.notifications,
                                    style: theme.textTheme.titleLarge
                                        ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    unread > 0
                                        ? '$unread unread notification${unread == 1 ? '' : 's'}'
                                        : 'You are all caught up',
                                    style: theme.textTheme.bodySmall
                                        ?.copyWith(
                                      color: unread > 0
                                          ? theme.primaryColor
                                          : theme.hintColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (unread > 0)
                              TextButton(
                                onPressed: () async {
                                  await provider.markAllAsRead();
                                },
                                child: Text(l10n.markAllAsRead),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                  Divider(
                    height: 1,
                    color: theme.dividerColor.withOpacity(0.4),
                  ),
                  // LIST
                  Expanded(
                    child: Consumer<NotificationProvider>(
                      builder: (context, provider, child) {
                        if (provider.isLoading) {
                          return Center(
                            child: CircularProgressIndicator(
                                color: theme.primaryColor),
                          );
                        }
                        if (provider.notifications.isEmpty) {
                          return _EmptyNotifications(
                            theme: theme,
                            title: l10n.noNotificationsYet,
                          );
                        }
                        return RefreshIndicator(
                          color: theme.primaryColor,
                          onRefresh: provider.loadNotifications,
                          child: ListView.builder(
                            controller: scrollController,
                            padding:
                            const EdgeInsets.fromLTRB(16, 14, 16, 30),
                            itemCount: provider.notifications.length,
                            itemBuilder: (context, index) {
                              final notification =
                              provider.notifications[index];
                              return Padding(
                                padding:
                                const EdgeInsets.only(bottom: 10),
                                child: _NotificationTile(
                                  notification: notification,
                                  locale: _currentLocale,
                                  onTap: () async {
                                    final id = notification['id'];
                                    if (id != null) {
                                      await provider
                                          .markAsRead(id.toString());
                                    }
                                    if (!mounted) return;
                                    Navigator.pop(ctx);
                                    _handleNotificationNavigation(
                                        notification);
                                  },
                                ),
                              );
                            },
                          ),
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

  // ================================================================
  // NOTIFICATION NAVIGATION
  // ================================================================

  void _handleNotificationNavigation(Map<String, dynamic> notification) {
    final type = notification['type']?.toString() ?? '';

    if (type == 'chat_message') {
      setState(() => _currentIndex = 3);
      return;
    }

    if (type == 'new_request' ||
        type == 'request_accepted' ||
        type == 'request_rejected' ||
        type == 'request_in_progress' ||
        type == 'request_completed') {
      setState(() => _currentIndex = 2);
    }
  }

  // ================================================================
  // LEFT DRAWER
  // ================================================================
  // Header:  logo + "OG ONE GROUP" + "Mini Apps" (gold)
  // Body:    "Partnerships" section label
  //          "Coming soon" tile with subtitle "OG ONE GROUP mini apps"
  // Footer:  info icon + "About OG ONE GROUP"
  // ================================================================

  Widget _buildDrawer(BuildContext context, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;

    return Drawer(
      backgroundColor: theme.colorScheme.surface,
      width: 320,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // ==========================================================
            // HEADER — Logo + OG ONE GROUP + Mini Apps (gold)
            // ==========================================================
            Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primary, AppTheme.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary
                        .withOpacity(isDark ? 0.5 : 0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Logo
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Image.asset(
                      'assets/images/app_icon.png',
                      fit: BoxFit.contain,
                    ),
                  ),

                  const SizedBox(width: 14),

                  // Text column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'OG ONE GROUP',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.nunito(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Mini Apps',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.nunito(
                            color: AppTheme.secondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ==========================================================
            // BODY — Partnerships section + Coming soon tile
            // ==========================================================
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
                    child: Text(
                      'Partnerships',
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface
                            .withOpacity(0.55),
                      ),
                    ),
                  ),

                  // Coming soon tile
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color:
                        theme.dividerColor.withOpacity(0.35),
                        width: 1,
                      ),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        Navigator.pop(context);
                        _showMiniAppsComingSoon();
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            // Icon box
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: AppTheme.secondary
                                    .withOpacity(0.18),
                                borderRadius:
                                BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.apps_rounded,
                                color: AppTheme.secondary,
                                size: 24,
                              ),
                            ),

                            const SizedBox(width: 14),

                            // Text column
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Coming soon',
                                    style: GoogleFonts.nunito(
                                      color: theme
                                          .colorScheme.onSurface,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'OG ONE GROUP mini apps',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.nunito(
                                      color: theme.colorScheme
                                          .onSurface
                                          .withOpacity(0.55),
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Chevron
                            Icon(
                              Icons.chevron_right_rounded,
                              color: theme.hintColor,
                              size: 22,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ==========================================================
            // FOOTER — About OG ONE GROUP
            // ==========================================================
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  Navigator.pop(context);
                  _showAboutOgOneGroup();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.10),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.info_outline_rounded,
                          color: AppTheme.primary,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'About OG ONE GROUP',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.nunito(
                            color: theme.colorScheme.onSurface,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // NAVIGATION DESTINATIONS
  // ================================================================

  List<NavigationRailDestination> _railDestinations(
      AppLocalizations l10n,
      ChatProvider chatProvider,
      ) {
    return [
      NavigationRailDestination(
        icon: const Icon(Icons.home_outlined),
        selectedIcon: const Icon(Icons.home_rounded),
        label: Text(l10n.nearby),
      ),
      NavigationRailDestination(
        icon: const Icon(Icons.article_outlined),
        selectedIcon: const Icon(Icons.article_rounded),
        label: Text(l10n.blog),
      ),
      NavigationRailDestination(
        icon: const Icon(Icons.list_alt_outlined),
        selectedIcon: const Icon(Icons.list_alt_rounded),
        label: Text(l10n.requests),
      ),
      NavigationRailDestination(
        icon: _ChatIcon(unread: chatProvider.totalUnread, active: false),
        selectedIcon:
        _ChatIcon(unread: chatProvider.totalUnread, active: true),
        label: Text(l10n.chat),
      ),
      NavigationRailDestination(
        icon: const Icon(Icons.person_outline),
        selectedIcon: const Icon(Icons.person_rounded),
        label: Text(l10n.profile),
      ),
    ];
  }

  // ================================================================
  // LARGE SCREEN NAVIGATION
  // ================================================================

  Widget _buildLargeNavigation(
      ThemeData theme,
      AppLocalizations l10n,
      ChatProvider chatProvider,
      ) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          right: BorderSide(color: theme.dividerColor.withOpacity(0.35)),
        ),
      ),
      child: NavigationRail(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          if (_currentIndex == index) return;
          setState(() => _currentIndex = index);
        },
        labelType: NavigationRailLabelType.all,
        minWidth: 82,
        groupAlignment: -0.75,
        destinations: _railDestinations(l10n, chatProvider),
      ),
    );
  }

  // ================================================================
  // APP BAR
  // ================================================================

  PreferredSizeWidget _buildAppBar(
      ThemeData theme,
      AppLocalizations l10n,
      bool largeScreen,
      ) {
    return AppBar(
      backgroundColor: AppTheme.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: !largeScreen,
      iconTheme: const IconThemeData(color: Colors.white),
      titleSpacing: largeScreen ? 20 : 8,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: largeScreen ? 40 : 38,
            height: largeScreen ? 40 : 38,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(Icons.handyman_rounded,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              l10n.appTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.nunito(
                fontSize: largeScreen ? 20 : 19,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      actions: [
        // REFRESH
        IconButton(
          onPressed: _refreshCurrentScreen,
          tooltip: l10n.refresh,
          icon: const Icon(Icons.refresh_rounded, size: 24),
        ),
        // NOTIFICATIONS
        Consumer<NotificationProvider>(
          builder: (context, provider, child) {
            final unread = provider.unreadCount;
            return IconButton(
              onPressed: () => _showNotifications(context),
              tooltip: l10n.notifications,
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.notifications_outlined, size: 26),
                  if (unread > 0)
                    Positioned(
                      right: -5,
                      top: -5,
                      child: Container(
                        constraints: const BoxConstraints(
                            minWidth: 18, minHeight: 18),
                        padding:
                        const EdgeInsets.symmetric(horizontal: 4),
                        decoration: const BoxDecoration(
                          color: AppTheme.error,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          unread > 9 ? '9+' : '$unread',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  // ================================================================
  // BUILD
  // ================================================================

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final settings = context.watch<SettingsProvider>();

    // LANGUAGE CHANGE
    if (_currentLocale != settings.locale) {
      _currentLocale = settings.locale;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context
            .read<ServiceProvider>()
            .fetchServices(locale: _currentLocale);
      });
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final largeScreen = width >= _tabletBreakpoint;
        final veryLarge = width >= _desktopBreakpoint;

        return Scaffold(
          drawer: largeScreen ? null : _buildDrawer(context, theme),
          appBar: _buildAppBar(theme, l10n, largeScreen),
          body: Row(
            children: [
              if (largeScreen)
                Consumer<ChatProvider>(
                  builder: (context, chatProvider, child) {
                    return _buildLargeNavigation(
                        theme, l10n, chatProvider);
                  },
                ),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: veryLarge ? 1400 : double.infinity,
                    ),
                    child: RefreshIndicator(
                      onRefresh: _refreshCurrentScreen,
                      color: theme.primaryColor,
                      backgroundColor: theme.colorScheme.surface,
                      child: _screens[_currentIndex],
                    ),
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: largeScreen
              ? null
              : _buildBottomNavigation(theme, l10n, isDark),
        );
      },
    );
  }

  // ================================================================
  // MOBILE BOTTOM NAVIGATION
  // ================================================================

  Widget _buildBottomNavigation(
      ThemeData theme,
      AppLocalizations l10n,
      bool isDark,
      ) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.dividerColor.withOpacity(0.35),
            width: 0.6,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.07),
            blurRadius: 15,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Consumer<ChatProvider>(
          builder: (context, chatProvider, child) {
            return BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                if (_currentIndex == index) return;
                setState(() => _currentIndex = index);
              },
              type: BottomNavigationBarType.fixed,
              backgroundColor: theme.colorScheme.surface,
              elevation: 0,
              selectedItemColor: theme.primaryColor,
              unselectedItemColor:
              isDark ? Colors.grey.shade500 : Colors.grey.shade600,
              selectedFontSize: 11,
              unselectedFontSize: 11,
              selectedLabelStyle:
              GoogleFonts.nunito(fontWeight: FontWeight.w700),
              unselectedLabelStyle:
              GoogleFonts.nunito(fontWeight: FontWeight.w500),
              items: [
                BottomNavigationBarItem(
                  icon: const Icon(Icons.home_outlined),
                  activeIcon: const Icon(Icons.home_rounded),
                  label: l10n.nearby,
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.article_outlined),
                  activeIcon: const Icon(Icons.article_rounded),
                  label: l10n.blog,
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.list_alt_outlined),
                  activeIcon: const Icon(Icons.list_alt_rounded),
                  label: l10n.requests,
                ),
                BottomNavigationBarItem(
                  icon: _ChatIcon(
                      unread: chatProvider.totalUnread, active: false),
                  activeIcon: _ChatIcon(
                      unread: chatProvider.totalUnread, active: true),
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
}

// ==================================================================
// CHAT ICON
// ==================================================================

class _ChatIcon extends StatelessWidget {
  final int unread;
  final bool active;

  const _ChatIcon({required this.unread, required this.active});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(
          active
              ? Icons.chat_bubble_rounded
              : Icons.chat_bubble_outline_rounded,
        ),
        if (unread > 0)
          Positioned(
            right: -8,
            top: -7,
            child: Container(
              constraints:
              const BoxConstraints(minWidth: 15, minHeight: 15),
              padding: const EdgeInsets.symmetric(horizontal: 3),
              decoration: const BoxDecoration(
                color: AppTheme.error,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                unread > 9 ? '9+' : '$unread',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ==================================================================
// EMPTY NOTIFICATIONS
// ==================================================================

class _EmptyNotifications extends StatelessWidget {
  final ThemeData theme;
  final String title;

  const _EmptyNotifications({required this.theme, required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_none_rounded,
                size: 46,
                color: theme.primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'We will notify you when there is something new.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.hintColor,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================================================================
// NOTIFICATION TILE
// ==================================================================

class _NotificationTile extends StatelessWidget {
  final Map<String, dynamic> notification;
  final VoidCallback onTap;
  final String locale;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
    required this.locale,
  });

  String _getTypeLabel(String? type) {
    switch (type) {
      case 'chat_message':
        return 'Chat';
      case 'new_request':
        return 'New Request';
      case 'request_accepted':
        return 'Request Accepted';
      case 'request_rejected':
        return 'Request Rejected';
      case 'request_in_progress':
        return 'In Progress';
      case 'request_completed':
        return 'Completed';
      default:
        return 'Notification';
    }
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
        return Icons.task_alt_rounded;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _getIconColor(String? type, ThemeData theme) {
    switch (type) {
      case 'request_accepted':
      case 'request_completed':
        return AppTheme.success;
      case 'request_rejected':
        return AppTheme.error;
      case 'request_in_progress':
        return AppTheme.warning;
      case 'chat_message':
        return AppTheme.accent;
      case 'new_request':
        return theme.primaryColor;
      default:
        return theme.primaryColor;
    }
  }

  String _formatCreatedAt(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) return '';
    try {
      DateTime dateTime = DateTime.parse(value.toString());
      if (dateTime.isUtc) dateTime = dateTime.toLocal();

      final day = dateTime.day.toString().padLeft(2, '0');
      final month = dateTime.month.toString().padLeft(2, '0');
      final year = dateTime.year.toString();
      final hour12 = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
      final hour = hour12.toString().padLeft(2, '0');
      final minute = dateTime.minute.toString().padLeft(2, '0');
      final period = dateTime.hour >= 12 ? 'PM' : 'AM';

      return '$day/$month/$year • $hour:$minute $period';
    } catch (e) {
      debugPrint('Invalid notification created_at: $value');
      return value.toString();
    }
  }

  String _getRelativeTime(dynamic value) {
    if (value == null) return '';
    try {
      DateTime dateTime = DateTime.parse(value.toString());
      if (dateTime.isUtc) dateTime = dateTime.toLocal();

      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inSeconds < 30) return 'Just now';
      if (difference.inMinutes < 60) {
        return '${difference.inMinutes} min ago';
      }
      if (difference.inHours < 24) {
        return '${difference.inHours} hr ago';
      }
      if (difference.inDays == 1) return 'Yesterday';
      if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      }
      return _formatCreatedAt(value);
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isReadValue = notification['is_read'];
    final isRead =
        isReadValue == true || isReadValue == 1 || isReadValue == '1';

    final title = notification['title']?.toString() ?? 'Notification';
    final body = notification['body']?.toString() ?? '';
    final type = notification['type']?.toString() ?? '';
    final createdAt = notification['created_at'];

    final exactDate = _formatCreatedAt(createdAt);
    final relativeTime = _getRelativeTime(createdAt);
    final iconColor = _getIconColor(type, theme);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: isRead
                ? theme.colorScheme.surface
                : theme.primaryColor.withOpacity(0.055),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isRead
                  ? theme.dividerColor.withOpacity(0.30)
                  : theme.primaryColor.withOpacity(0.16),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(_getIcon(type), color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.nunito(
                              fontSize: 14.5,
                              height: 1.25,
                              fontWeight: isRead
                                  ? FontWeight.w500
                                  : FontWeight.w700,
                            ),
                          ),
                        ),
                        if (!isRead)
                          Container(
                            width: 8,
                            height: 8,
                            margin:
                            const EdgeInsets.only(left: 8, top: 5),
                            decoration: BoxDecoration(
                              color: theme.primaryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    if (body.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          height: 1.35,
                          color: theme.textTheme.bodySmall?.color
                              ?.withOpacity(0.72),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 5,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (type.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: iconColor.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: Text(
                              _getTypeLabel(type),
                              style: GoogleFonts.nunito(
                                color: iconColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        if (relativeTime.isNotEmpty)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.access_time_rounded,
                                  size: 13, color: theme.hintColor),
                              const SizedBox(width: 4),
                              Text(
                                relativeTime,
                                style: GoogleFonts.nunito(
                                  color: theme.hintColor,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    if (exactDate.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Icon(Icons.calendar_today_outlined,
                              size: 11, color: theme.hintColor),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              exactDate,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.nunito(
                                color: theme.hintColor,
                                fontSize: 9.5,
                              ),
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