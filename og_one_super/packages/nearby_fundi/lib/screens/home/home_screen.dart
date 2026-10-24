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

/// Warm accent used for highlights (title bar, selected icons, badges).
const Color _gold = Color(0xFFF2B93B);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  late final List<Widget> _screens;
  String _currentLocale = 'en';

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
      _showSnack(l10n.refreshed, AppTheme.success,
          Icons.check_circle_rounded, const Duration(seconds: 1));
    } catch (e) {
      debugPrint('Refresh error: $e');
      if (!mounted) return;
      _showSnack(l10n.refreshFailed, AppTheme.error,
          Icons.error_outline_rounded, const Duration(seconds: 3));
    }
  }

  void _showSnack(
      String message, Color color, IconData icon, Duration duration) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        duration: duration,
        backgroundColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                color: theme.scaffoldBackgroundColor,
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
                    child: Consumer<NotificationProvider>(
                      builder: (context, provider, child) {
                        final unread = provider.unreadCount;
                        return Row(
                          children: [
                            Container(
                              width: 5,
                              height: 36,
                              decoration: BoxDecoration(
                                color: _gold,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.notifications,
                                    style: theme.textTheme.titleLarge
                                        ?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    unread > 0
                                        ? '$unread unread notification${unread == 1 ? '' : 's'}'
                                        : 'You are all caught up',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: unread > 0
                                          ? theme.primaryColor
                                          : theme.hintColor,
                                      fontWeight: FontWeight.w600,
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
                                style: TextButton.styleFrom(
                                  foregroundColor: AppTheme.primary,
                                  backgroundColor:
                                  AppTheme.primary.withValues(alpha: 0.08),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  l10n.markAllAsRead,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12.5),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
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
                          child: ListView.separated(
                            controller: scrollController,
                            padding:
                            const EdgeInsets.fromLTRB(16, 4, 16, 30),
                            itemCount: provider.notifications.length,
                            separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final notification =
                              provider.notifications[index];
                              return _NotificationTile(
                                notification: notification,
                                locale: _currentLocale,
                                onTap: () async {
                                  final id = notification['id'];
                                  if (id != null) {
                                    await provider.markAsRead(id.toString());
                                  }
                                  if (!mounted) return;
                                  Navigator.pop(ctx);
                                  _handleNotificationNavigation(notification);
                                },
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
  // NAVIGATION RAIL (tablet / desktop)
  // ================================================================

  List<NavigationRailDestination> _railDestinations(
      AppLocalizations l10n, ChatProvider chatProvider) {
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

  Widget _buildLargeNavigation(
      ThemeData theme, AppLocalizations l10n, ChatProvider chatProvider) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.horizontal(right: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(4, 0),
          ),
        ],
      ),
      child: NavigationRail(
        backgroundColor: Colors.transparent,
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          if (_currentIndex == index) return;
          setState(() => _currentIndex = index);
        },
        labelType: NavigationRailLabelType.all,
        minWidth: 86,
        groupAlignment: -0.75,
        indicatorColor: AppTheme.primary,
        indicatorShape: const StadiumBorder(),
        selectedIconTheme: const IconThemeData(color: _gold),
        selectedLabelTextStyle: const TextStyle(
          color: AppTheme.primary,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
        unselectedLabelTextStyle: TextStyle(
          color: theme.hintColor,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        destinations: _railDestinations(l10n, chatProvider),
      ),
    );
  }

  // ================================================================
  // APP BAR (rounded, with tonal action buttons)
  // ================================================================

  PreferredSizeWidget _buildAppBar(ThemeData theme, AppLocalizations l10n) {
    return AppBar(
      backgroundColor: AppTheme.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      toolbarHeight: 66,
      automaticallyImplyLeading: false,
      centerTitle: false,
      titleSpacing: 18,
      iconTheme: const IconThemeData(color: Colors.white),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(26)),
      ),
      title: Row(
        children: [
          Container(
            width: 5,
            height: 24,
            decoration: BoxDecoration(
              color: _gold,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              l10n.appTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.nunito(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      actions: [
        _BarButton(
          tooltip: l10n.refresh,
          onTap: _refreshCurrentScreen,
          child: const Icon(Icons.refresh_rounded,
              color: Colors.white, size: 22),
        ),
        const SizedBox(width: 8),
        Consumer<NotificationProvider>(
          builder: (context, provider, child) {
            final unread = provider.unreadCount;
            return _BarButton(
              tooltip: l10n.notifications,
              onTap: () => _showNotifications(context),
              child: Badge(
                isLabelVisible: unread > 0,
                backgroundColor: AppTheme.error,
                label: Text(unread > 9 ? '9+' : '$unread'),
                child: const Icon(Icons.notifications_none_rounded,
                    color: Colors.white, size: 22),
              ),
            );
          },
        ),
        const SizedBox(width: 14),
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
    final settings = context.watch<SettingsProvider>();

    if (_currentLocale != settings.locale) {
      _currentLocale = settings.locale;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<ServiceProvider>().fetchServices(locale: _currentLocale);
      });
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final largeScreen = width >= _tabletBreakpoint;
        final veryLarge = width >= _desktopBreakpoint;

        return Scaffold(
          appBar: _buildAppBar(theme, l10n),
          body: Row(
            children: [
              if (largeScreen)
                Consumer<ChatProvider>(
                  builder: (context, chatProvider, child) {
                    return _buildLargeNavigation(theme, l10n, chatProvider);
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
          bottomNavigationBar:
          largeScreen ? null : _buildBottomNavigation(theme, l10n),
        );
      },
    );
  }

  // ================================================================
  // BOTTOM NAVIGATION (rounded top, navy pill indicator, gold icon)
  // ================================================================

  Widget _buildBottomNavigation(ThemeData theme, AppLocalizations l10n) {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.16),
                blurRadius: 22,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: NavigationBarTheme(
              data: NavigationBarThemeData(
                labelTextStyle: WidgetStateProperty.resolveWith((states) {
                  final selected = states.contains(WidgetState.selected);
                  return TextStyle(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    color: selected ? AppTheme.primary : theme.hintColor,
                  );
                }),
              ),
              child: NavigationBar(
                selectedIndex: _currentIndex,
                onDestinationSelected: (index) {
                  if (_currentIndex == index) return;
                  setState(() => _currentIndex = index);
                },
                height: 70,
                elevation: 0,
                backgroundColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                indicatorColor: AppTheme.primary,
                indicatorShape: const StadiumBorder(),
                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                destinations: [
                  NavigationDestination(
                    icon: const Icon(Icons.home_outlined),
                    selectedIcon:
                    const Icon(Icons.home_rounded, color: _gold),
                    label: l10n.nearby,
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.article_outlined),
                    selectedIcon:
                    const Icon(Icons.article_rounded, color: _gold),
                    label: l10n.blog,
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.list_alt_outlined),
                    selectedIcon:
                    const Icon(Icons.list_alt_rounded, color: _gold),
                    label: l10n.requests,
                  ),
                  NavigationDestination(
                    icon: _ChatIcon(
                        unread: chatProvider.totalUnread, active: false),
                    selectedIcon: _ChatIcon(
                        unread: chatProvider.totalUnread, active: true),
                    label: l10n.chat,
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.person_outline),
                    selectedIcon:
                    const Icon(Icons.person_rounded, color: _gold),
                    label: l10n.profile,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ==================================================================
// APP BAR BUTTON (soft tonal square)
// ==================================================================

class _BarButton extends StatelessWidget {
  final Widget child;
  final String tooltip;
  final VoidCallback onTap;

  const _BarButton({
    required this.child,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            width: 42,
            height: 42,
            child: Center(child: child),
          ),
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
    return Badge(
      isLabelVisible: unread > 0,
      backgroundColor: AppTheme.error,
      label: Text(unread > 9 ? '9+' : '$unread'),
      child: Icon(
        active ? Icons.chat_bubble_rounded : Icons.chat_bubble_outline_rounded,
        color: active ? _gold : null,
      ),
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
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.notifications_none_rounded,
                  size: 44, color: AppTheme.primary),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 6),
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

      final difference = DateTime.now().difference(dateTime);

      if (difference.inSeconds < 30) return 'Just now';
      if (difference.inMinutes < 60) return '${difference.inMinutes} min ago';
      if (difference.inHours < 24) return '${difference.inHours} hr ago';
      if (difference.inDays == 1) return 'Yesterday';
      if (difference.inDays < 7) return '${difference.inDays} days ago';
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
    final relativeTime = _getRelativeTime(notification['created_at']);
    final iconColor = _getIconColor(type, theme);

    return Material(
      color: theme.colorScheme.surface,
      elevation: isRead ? 1 : 3,
      shadowColor: Colors.black.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isRead ? Colors.transparent : _gold.withValues(alpha: 0.7),
              width: 1.5,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(_getIcon(type), color: iconColor, size: 22),
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
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.nunito(
                              fontSize: 14.5,
                              height: 1.25,
                              color: AppTheme.primary,
                              fontWeight:
                              isRead ? FontWeight.w600 : FontWeight.w800,
                            ),
                          ),
                        ),
                        if (!isRead)
                          Container(
                            width: 9,
                            height: 9,
                            margin: const EdgeInsets.only(left: 8),
                            decoration: const BoxDecoration(
                              color: _gold,
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
                        style: theme.textTheme.bodySmall?.copyWith(
                          height: 1.35,
                          color: theme.textTheme.bodySmall?.color
                              ?.withValues(alpha: 0.72),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (type.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: iconColor.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              _getTypeLabel(type),
                              style: GoogleFonts.nunito(
                                color: iconColor,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        if (relativeTime.isNotEmpty)
                          Text(
                            relativeTime,
                            style: GoogleFonts.nunito(
                              color: theme.hintColor,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
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