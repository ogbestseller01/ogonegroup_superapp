// lib/screens/chat/chat_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../models/chat_conversation.dart';
import '../../models/chat_user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    final authProvider = context.read<AuthProvider>();
    final chatProvider = context.read<ChatProvider>();

    final user = authProvider.user;
    final token = authProvider.token;

    if (user != null && token != null) {
      final chatUser = ChatUser(
        id: user.id,
        name: user.name,
        email: user.email,
        phone: user.phone,
        avatar: null,
        isOnline: false,
        lastSeen: null,
        fcmToken: null,
      );

      chatProvider.initialize(
        token: token,
        currentUser: chatUser,
      );
    }
    if (mounted) {
      setState(() => _isInitializing = false);
    }
  }

  Future<void> _confirmAndDelete(
    BuildContext context,
    ChatConversation conversation,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
        title: Text(
          l10n.deleteConversation,
          style: TextStyle(
            inherit: true,
            color: isDark ? Colors.white : AppTheme.primary,
          ),
        ),
        content: Text(
          l10n.deleteConversationConfirmation,
          style: TextStyle(
            inherit: true,
            color: isDark ? AppTheme.darkTextSecondary : AppTheme.greyText,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final success =
        await context.read<ChatProvider>().deleteConversation(conversation.id);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? l10n.conversationDeleted : 'Failed to delete conversation',
        ),
        backgroundColor: success ? AppTheme.success : AppTheme.error,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.scaffoldLight,
      appBar: AppBar(
        title: Text(
          l10n.chat,
          style: const TextStyle(
            inherit: true,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Consumer<ChatProvider>(
            builder: (context, chatProvider, child) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.mark_chat_read_outlined,
                      color: Colors.white,
                    ),
                    onPressed: () async {
                      if (chatProvider.conversations.isNotEmpty) {
                        for (var conv in chatProvider.conversations) {
                          await chatProvider.markConversationAsRead(conv.id);
                        }
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n.markAllAsRead),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      }
                    },
                  ),
                  if (chatProvider.totalUnread > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppTheme.secondary,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          chatProvider.totalUnread > 9
                              ? '9+'
                              : '${chatProvider.totalUnread}',
                          style: const TextStyle(
                            inherit: true,
                            color: AppTheme.primary,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: _isInitializing
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            )
          : Consumer<ChatProvider>(
              builder: (context, chatProvider, child) {
                final conversations = chatProvider.conversations;

                if (chatProvider.isLoading && conversations.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  );
                }

                if (conversations.isEmpty) {
                  return _buildEmptyState(context, l10n, isDark);
                }

                return RefreshIndicator(
                  color: AppTheme.primary,
                  onRefresh: () => chatProvider.refreshConversations(),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: conversations.length,
                    itemBuilder: (context, index) {
                      final conversation = conversations[index];
                      return _ConversationTile(
                        conversation: conversation,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ChatScreen(conversation: conversation),
                            ),
                          ).then((_) {
                            chatProvider.refreshConversations();
                          });
                        },
                        onDelete: () =>
                            _confirmAndDelete(context, conversation),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    AppLocalizations l10n,
    bool isDark,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_outlined,
            size: 80,
            color: isDark ? AppTheme.darkBorder : AppTheme.navy200,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.noConversationsYet,
            style: TextStyle(
              inherit: true,
              fontSize: 18,
              color: isDark ? Colors.white : AppTheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.startChattingWithFundis,
            textAlign: TextAlign.center,
            style: TextStyle(
              inherit: true,
              fontSize: 14,
              color: isDark ? AppTheme.darkTextSecondary : AppTheme.greyText,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final ChatConversation conversation;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ConversationTile({
    required this.conversation,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? Colors.white : AppTheme.primary;
    final mutedText =
        isDark ? AppTheme.darkTextSecondary : AppTheme.greyText;

    return Dismissible(
      key: Key('conversation_${conversation.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        onDelete();
        return false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: AppTheme.error,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          margin: const EdgeInsets.only(bottom: 4),
          decoration: BoxDecoration(
            color: conversation.unreadCount > 0
                ? AppTheme.primary.withOpacity(isDark ? 0.15 : 0.05)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor:
                    isDark ? AppTheme.darkSurfaceLight : AppTheme.navy100,
                child: conversation.otherParty.avatar != null
                    ? ClipOval(
                        child: Image.network(
                          conversation.otherParty.avatar!,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Text(
                            conversation.otherParty.name.isNotEmpty
                                ? conversation.otherParty.name[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              inherit: true,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: primaryText,
                            ),
                          ),
                        ),
                      )
                    : Text(
                        conversation.otherParty.name.isNotEmpty
                            ? conversation.otherParty.name[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          inherit: true,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: primaryText,
                        ),
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
                            conversation.otherParty.name,
                            style: TextStyle(
                              inherit: true,
                              fontSize: 16,
                              color: primaryText,
                              fontWeight: conversation.unreadCount > 0
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          _formatTime(conversation.lastMessageAt, l10n),
                          style: TextStyle(
                            inherit: true,
                            fontSize: 12,
                            color: mutedText,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conversation.lastMessage?.content ??
                                l10n.noMessagesYet,
                            style: TextStyle(
                              inherit: true,
                              fontSize: 14,
                              color: conversation.unreadCount > 0
                                  ? primaryText
                                  : mutedText,
                              fontWeight: conversation.unreadCount > 0
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (conversation.unreadCount > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppTheme.secondary,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              conversation.unreadCount > 9
                                  ? '9+'
                                  : '${conversation.unreadCount}',
                              style: const TextStyle(
                                inherit: true,
                                color: AppTheme.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
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

  String _formatTime(String? dateTime, AppLocalizations l10n) {
    if (dateTime == null) return '';
    try {
      final DateTime parsed = DateTime.parse(dateTime);
      final now = DateTime.now();
      final difference = now.difference(parsed);

      if (difference.inDays > 0) {
        return '${difference.inDays}d';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m';
      } else {
        return l10n.justNow;
      }
    } catch (_) {
      return '';
    }
  }
}
