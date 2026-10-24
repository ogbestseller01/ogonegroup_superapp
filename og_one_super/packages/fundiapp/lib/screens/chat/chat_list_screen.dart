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

// ─── Shared look helpers ─────────────────────────────────────────────────
/// Navy is unreadable on the dark background, so gold is used in dark mode.
Color _accent(bool isDark) => isDark ? AppTheme.secondary : AppTheme.primary;
Color _cardBg(bool isDark) => isDark ? AppTheme.darkSurface : Colors.white;
Color _cardBorder(bool isDark) =>
    isDark ? AppTheme.darkBorder : AppTheme.borderLight.withOpacity(0.30);
Color _ink(bool isDark) => isDark ? Colors.white : AppTheme.primary;
Color _muted(bool isDark) =>
    isDark ? AppTheme.darkTextSecondary : AppTheme.greyText;
double _hPad(BuildContext context) =>
    MediaQuery.sizeOf(context).width < 360 ? 12.0 : 16.0;

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
        email: user.email ?? '',
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
        backgroundColor: _cardBg(isDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          l10n.deleteConversation,
          style: TextStyle(
            inherit: true,
            fontWeight: FontWeight.w800,
            color: _ink(isDark),
          ),
        ),
        content: Text(
          l10n.deleteConversationConfirmation,
          style: TextStyle(
            inherit: true,
            color: _muted(isDark),
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
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ─── Title row (replaces the second app bar) ──────────────────────────
  Widget _titleRow(BuildContext context, AppLocalizations l10n, bool isDark) {
    final h = _hPad(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(h + 2, 16, h, 4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              color: AppTheme.secondary,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.chat,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                inherit: true,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: _ink(isDark),
              ),
            ),
          ),
          Consumer<ChatProvider>(
            builder: (context, chatProvider, child) {
              final unread = chatProvider.totalUnread;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Tooltip(
                    message: l10n.markAllAsRead,
                    child: Material(
                      color: _accent(isDark).withOpacity(0.10),
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () async {
                          if (chatProvider.conversations.isNotEmpty) {
                            for (var conv in chatProvider.conversations) {
                              await chatProvider
                                  .markConversationAsRead(conv.id);
                            }
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(l10n.markAllAsRead),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          }
                        },
                        child: SizedBox(
                          width: 42,
                          height: 42,
                          child: Icon(Icons.mark_chat_read_outlined,
                              color: _accent(isDark), size: 22),
                        ),
                      ),
                    ),
                  ),
                  if (unread > 0)
                    Positioned(
                      top: -5,
                      right: -5,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        constraints:
                        const BoxConstraints(minWidth: 18, minHeight: 18),
                        decoration: BoxDecoration(
                          color: AppTheme.secondary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          unread > 9 ? '9+' : '$unread',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            inherit: true,
                            color: AppTheme.primary,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return MediaQuery.withClampedTextScaling(
      minScaleFactor: 0.85,
      maxScaleFactor: 1.25,
      child: Scaffold(
        backgroundColor:
        isDark ? AppTheme.darkBackground : AppTheme.scaffoldLight,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _titleRow(context, l10n, isDark),
              Expanded(
                child: _isInitializing
                    ? Center(
                  child: CircularProgressIndicator(
                      color: _accent(isDark)),
                )
                    : Consumer<ChatProvider>(
                  builder: (context, chatProvider, child) {
                    final conversations = chatProvider.conversations;

                    if (chatProvider.isLoading &&
                        conversations.isEmpty) {
                      return Center(
                        child: CircularProgressIndicator(
                            color: _accent(isDark)),
                      );
                    }

                    if (conversations.isEmpty) {
                      return _buildEmptyState(context, l10n, isDark);
                    }

                    final h = _hPad(context);

                    return RefreshIndicator(
                      color: AppTheme.primary,
                      onRefresh: () =>
                          chatProvider.refreshConversations(),
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(h, 10, h, 24),
                        itemCount: conversations.length,
                        itemBuilder: (context, index) {
                          final conversation = conversations[index];
                          return _ConversationTile(
                            conversation: conversation,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatScreen(
                                      conversation: conversation),
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(
      BuildContext context,
      AppLocalizations l10n,
      bool isDark,
      ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 104,
              height: 104,
              decoration: BoxDecoration(
                color: _cardBg(isDark),
                shape: BoxShape.circle,
                border: Border.all(color: _cardBorder(isDark)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.25 : 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(Icons.chat_outlined, size: 44, color: _muted(isDark)),
            ),
            const SizedBox(height: 18),
            Text(
              l10n.noConversationsYet,
              textAlign: TextAlign.center,
              style: TextStyle(
                inherit: true,
                fontSize: 17,
                color: _ink(isDark),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.startChattingWithFundis,
              textAlign: TextAlign.center,
              style: TextStyle(
                inherit: true,
                fontSize: 14,
                height: 1.4,
                color: _muted(isDark),
              ),
            ),
          ],
        ),
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
    final compact = MediaQuery.sizeOf(context).width < 360;
    final unread = conversation.unreadCount > 0;
    final avatarR = compact ? 22.0 : 26.0;

    final initial = conversation.otherParty.name.isNotEmpty
        ? conversation.otherParty.name[0].toUpperCase()
        : '?';

    final tileColor = unread
        ? Color.alphaBlend(
      _accent(isDark).withOpacity(isDark ? 0.10 : 0.06),
      _cardBg(isDark),
    )
        : _cardBg(isDark);

    return Dismissible(
      key: Key('conversation_${conversation.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        onDelete();
        return false;
      },
      background: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 22),
          decoration: BoxDecoration(
            color: AppTheme.error,
            borderRadius: BorderRadius.circular(22),
          ),
          child:
          const Icon(Icons.delete_outline, color: Colors.white, size: 28),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.22 : 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          // Material (not a coloured Container) so the tap splash is visible.
          child: Material(
            color: tileColor,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
              side: BorderSide(
                color: unread
                    ? _accent(isDark).withOpacity(0.25)
                    : _cardBorder(isDark),
              ),
            ),
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 10 : 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2.5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: unread
                              ? AppTheme.secondary
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: avatarR,
                        backgroundColor: isDark
                            ? AppTheme.darkSurfaceLight
                            : AppTheme.navy100,
                        child: conversation.otherParty.avatar != null
                            ? ClipOval(
                          child: Image.network(
                            conversation.otherParty.avatar!,
                            width: avatarR * 2,
                            height: avatarR * 2,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Text(
                              initial,
                              style: TextStyle(
                                inherit: true,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: _ink(isDark),
                              ),
                            ),
                          ),
                        )
                            : Text(
                          initial,
                          style: TextStyle(
                            inherit: true,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: _ink(isDark),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: compact ? 10 : 14),
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
                                    fontSize: 15.5,
                                    color: _ink(isDark),
                                    fontWeight: unread
                                        ? FontWeight.w800
                                        : FontWeight.w700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _formatTime(conversation.lastMessageAt, l10n),
                                style: TextStyle(
                                  inherit: true,
                                  fontSize: 11.5,
                                  fontWeight: unread
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: unread
                                      ? _accent(isDark)
                                      : _muted(isDark),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  conversation.lastMessage?.content ??
                                      l10n.noMessagesYet,
                                  style: TextStyle(
                                    inherit: true,
                                    fontSize: 13.5,
                                    color: unread
                                        ? _ink(isDark)
                                        : _muted(isDark),
                                    fontWeight: unread
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (unread) ...[
                                const SizedBox(width: 8),
                                Container(
                                  constraints: const BoxConstraints(
                                      minWidth: 22, minHeight: 22),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppTheme.secondary,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    conversation.unreadCount > 9
                                        ? '9+'
                                        : '${conversation.unreadCount}',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      inherit: true,
                                      color: AppTheme.primary,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
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