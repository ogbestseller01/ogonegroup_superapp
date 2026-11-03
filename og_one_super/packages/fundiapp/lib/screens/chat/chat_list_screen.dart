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
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeChat());
  }

  Future<void> _initializeChat() async {
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
          avatar: null, // User model has no profilePhoto
        ),
      );
      await chat.refreshConversations();
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
            fontWeight: FontWeight.w800,
            color: _ink(isDark),
          ),
        ),
        content: Text(
          l10n.deleteConversationConfirmation,
          style: TextStyle(color: _muted(isDark)),
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
      ),
    );
  }

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
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: _ink(isDark),
              ),
            ),
          ),
          Consumer<ChatProvider>(
            builder: (context, chat, _) {
              final unread = chat.totalUnread;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Material(
                    color: _accent(isDark).withOpacity(0.10),
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () async {
                        for (final conv in chat.conversations) {
                          await chat.markConversationAsRead(conv.id);
                        }
                      },
                      child: SizedBox(
                        width: 42,
                        height: 42,
                        child: Icon(
                          Icons.mark_chat_read_outlined,
                          color: _accent(isDark),
                          size: 22,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
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
                child: CircularProgressIndicator(color: _accent(isDark)),
              )
                  : Consumer<ChatProvider>(
                builder: (context, chat, _) {
                  if (chat.isLoading && chat.conversations.isEmpty) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: _accent(isDark),
                      ),
                    );
                  }

                  if (chat.conversations.isEmpty) {
                    return _buildEmptyState(context, l10n, isDark);
                  }

                  final h = _hPad(context);

                  return RefreshIndicator(
                    color: AppTheme.primary,
                    onRefresh: () => chat.refreshConversations(),
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(h, 10, h, 24),
                      itemCount: chat.conversations.length,
                      itemBuilder: (context, index) {
                        final conversation = chat.conversations[index];
                        return _ConversationTile(
                          conversation: conversation,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatScreen(
                                  conversation: conversation,
                                ),
                              ),
                            ).then((_) => chat.refreshConversations());
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
              ),
              child: Icon(Icons.chat_outlined, size: 44, color: _muted(isDark)),
            ),
            const SizedBox(height: 18),
            Text(
              l10n.noConversationsYet,
              textAlign: TextAlign.center,
              style: TextStyle(
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
          child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
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
                  CircleAvatar(
                    radius: avatarR,
                    backgroundColor:
                    isDark ? AppTheme.darkSurfaceLight : AppTheme.navy100,
                    child: Text(
                      initial,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: _ink(isDark),
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
                              conversation.getFormattedLastMessageTime(),
                              style: TextStyle(
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
                                conversation.getLastMessageDisplay(),
                                style: TextStyle(
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
                                  minWidth: 22,
                                  minHeight: 22,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 3,
                                ),
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
    );
  }
}