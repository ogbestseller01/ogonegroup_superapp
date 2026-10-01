import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/notification_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../config/app_theme.dart';

class NotificationListScreen extends StatefulWidget {
  const NotificationListScreen({super.key});

  @override
  State<NotificationListScreen> createState() => _NotificationListScreenState();
}

class _NotificationListScreenState extends State<NotificationListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().loadNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<NotificationProvider>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          l10n.notifications,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (provider.notifications.isNotEmpty)
            TextButton(
              onPressed: () {
                provider.markAllAsRead();
              },
              child: Text(
                l10n.markAllRead,
                style: const TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: provider.isLoading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(l10n.loadingNotifications),
          ],
        ),
      )
          : provider.notifications.isEmpty
          ? _buildEmptyState(context, l10n)
          : RefreshIndicator(
        onRefresh: () => provider.loadNotifications(),
        child: ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: provider.notifications.length,
          itemBuilder: (context, index) {
            final notification = provider.notifications[index];
            return _NotificationTile(
              notification: notification,
              onTap: () {
                provider.markAsRead(notification['id']);
                final type = notification['type'] ?? '';
                if (type == 'chat_message') {
                  // Navigate to chat
                } else if (type == 'new_request' ||
                    type == 'request_accepted' ||
                    type == 'request_rejected') {
                  // Navigate to requests
                }
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_off_outlined,
              size: 80,
              color: theme.hintColor,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noNotifications,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.allCaughtUp,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.hintColor,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                context.read<NotificationProvider>().loadNotifications();
              },
              icon: const Icon(Icons.refresh),
              label: Text(l10n.refresh),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// NOTIFICATION TILE WIDGET
// ============================================================
class _NotificationTile extends StatelessWidget {
  final Map<String, dynamic> notification;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRead = notification['is_read'] ?? false;
    final title = notification['title'] ?? '';
    final body = notification['body'] ?? '';
    final type = notification['type'] ?? '';
    final createdAt = notification['created_at'] != null
        ? DateTime.tryParse(notification['created_at'])
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: isRead ? 0 : 1,
      color: isRead
          ? theme.cardColor
          : theme.primaryColor.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isRead ? Colors.transparent : theme.primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getIconColor(type).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Icon(
                    _getIcon(type),
                    color: _getIconColor(type),
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      body,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.hintColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (createdAt != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _formatTime(createdAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.hintColor.withOpacity(0.6),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Unread dot
              if (!isRead)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inDays > 7) {
      return '${time.day}/${time.month}/${time.year}';
    } else if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'chat_message':
        return Icons.chat_bubble_outline;
      case 'new_request':
        return Icons.request_page_outlined;
      case 'request_accepted':
        return Icons.check_circle_outline;
      case 'request_rejected':
        return Icons.cancel_outlined;
      case 'request_in_progress':
        return Icons.hourglass_top_outlined;
      case 'request_completed':
        return Icons.check_circle_outline;
      case 'subscription_approved':
        return Icons.verified_rounded;
      case 'subscription_rejected':
        return Icons.cancel_rounded;
      case 'subscription_expired':
        return Icons.warning_rounded;
      case 'subscription_expiring_soon':
        return Icons.timer_rounded;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _getIconColor(String type) {
    if (type.contains('chat')) return Colors.blue;
    if (type.contains('request') && type.contains('accepted')) return Colors.green;
    if (type.contains('request') && type.contains('rejected')) return Colors.red;
    if (type.contains('request')) return Colors.orange;
    if (type.contains('subscription') && type.contains('approved')) return Colors.green;
    if (type.contains('subscription') && type.contains('rejected')) return Colors.red;
    if (type.contains('subscription') && type.contains('expired')) return Colors.red;
    if (type.contains('subscription')) return Colors.purple;
    return Colors.grey;
  }
}