// lib/screens/chat/chat_list_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/chat_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/chat_conversation.dart';
import '../../models/chat_user.dart';
import '../../l10n/app_localizations.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    if (_isInitialized) return;

    final authProvider = context.read<AuthProvider>();
    final chatProvider = context.read<ChatProvider>();

    final user = authProvider.user;
    final token = authProvider.token;

    if (user != null && token != null && !_isInitialized) {
      _isInitialized = true;

      final chatUser = ChatUser(
        id: user.id,
        name: user.name,
        email: user.email,
        phone: user.phone,
        avatar: user.profilePhoto,
      );

      chatProvider.initialize(
        token: token,
        currentUser: chatUser,
      );

      await chatProvider.refreshConversations();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.chat,
          style: const TextStyle(
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
                    icon: const Icon(Icons.refresh),
                    onPressed: () async {
                      await chatProvider.refreshConversations();
                    },
                  ),
                  if (chatProvider.totalUnread > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppTheme.error,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          chatProvider.totalUnread > 99
                              ? '99+'
                              : '${chatProvider.totalUnread}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
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
      body: Consumer<ChatProvider>(
        builder: (context, chatProvider, child) {
          if (chatProvider.isLoading && chatProvider.conversations.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (chatProvider.conversations.isEmpty) {
            return _buildEmptyState(context);
          }

          return RefreshIndicator(
            onRefresh: () => chatProvider.refreshConversations(),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              itemCount: chatProvider.conversations.length,
              itemBuilder: (context, index) {
                final conversation = chatProvider.conversations[index];
                return _ConversationTile(
                  conversation: conversation,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          conversation: conversation,
                        ),
                      ),
                    );
                    await chatProvider.refreshConversations();
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chat_outlined,
              size: 50,
              color: AppTheme.primary.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.noConversationsYet,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: theme.textTheme.titleLarge?.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.startChattingWithFundis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.search_rounded),
            label: const Text('Find Technicians'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primary,
              side: const BorderSide(color: AppTheme.primary),
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
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

  const _ConversationTile({
    required this.conversation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasUnread = conversation.unreadCount > 0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: hasUnread
              ? AppTheme.primary.withOpacity(0.06)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppTheme.primary.withOpacity(0.1),
              child: Text(
                conversation.otherParty.name.isNotEmpty
                    ? conversation.otherParty.name[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 14),
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
                            fontSize: 16,
                            fontWeight:
                            hasUnread ? FontWeight.w700 : FontWeight.w500,
                            color: hasUnread
                                ? theme.textTheme.titleMedium?.color
                                : theme.textTheme.titleMedium?.color
                                ?.withOpacity(0.8),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        conversation.getFormattedLastMessageTime(),
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.hintColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversation.getLastMessageDisplay(),
                          style: TextStyle(
                            fontSize: 14,
                            color: hasUnread
                                ? theme.colorScheme.onSurface
                                : theme.hintColor,
                            fontWeight: hasUnread
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            conversation.unreadCount > 99
                                ? '99+'
                                : '${conversation.unreadCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
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
    );
  }
}