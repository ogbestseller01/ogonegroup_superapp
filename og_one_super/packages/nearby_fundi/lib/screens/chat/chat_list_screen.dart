import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../config/app_routes.dart';
import '../../config/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../models/chat_conversation.dart';
import '../../models/chat_user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  /// Optional override for the back arrow. When null it goes to the home screen.
  final VoidCallback? onBack;

  const ChatListScreen({super.key, this.onBack});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _initializeChat();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeChat() async {
    final auth = context.read<AuthProvider>();
    final chat = context.read<ChatProvider>();

    final user = auth.user;
    final token = auth.token;
    if (user == null || token == null) return;

    // Safe to call repeatedly: the provider ignores repeat initialization.
    chat.initialize(
      token: token,
      currentUser: ChatUser(
        id: user.id,
        name: user.name,
        email: user.email,
        phone: user.phone,
        avatar: user.profilePhoto,
      ),
    );

    await chat.refreshConversations();
  }

  void _goHome() {
    if (widget.onBack != null) {
      widget.onBack!();
      return;
    }
    Navigator.pushReplacementNamed(context, AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? theme.scaffoldBackgroundColor : const Color(0xFFF0F2F5),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: isDark ? const Color(0xFF1F2C34) : AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        title: Text(
          l10n.chat,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: _goHome,
        ),
        actions: [
          Consumer<ChatProvider>(
            builder: (context, chat, _) => Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  tooltip: l10n.refresh,
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                  onPressed: () => chat.refreshConversations(),
                ),
                if (chat.totalUnread > 0)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                      decoration: const BoxDecoration(
                        color: Color(0xFF25D366), // WhatsApp green
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        chat.totalUnread > 99 ? '99+' : '${chat.totalUnread}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Consumer<ChatProvider>(
        builder: (context, chat, _) {
          if (chat.isLoading && chat.conversations.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            );
          }

          if (chat.conversations.isEmpty) {
            return _buildEmptyState(context);
          }

          final q = _searchQuery.toLowerCase();
          final list = chat.conversations
              .where((c) => q.isEmpty || c.otherParty.name.toLowerCase().contains(q))
              .toList();

          return Column(
            children: [
              // Search bar – WhatsApp style
              Container(
                color: isDark ? const Color(0xFF1F2C34) : Colors.white,
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2A3942) : const Color(0xFFF0F2F5),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v.trim()),
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 15,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search...',
                      hintStyle: TextStyle(
                        color: isDark ? Colors.white54 : Colors.grey.shade600,
                        fontSize: 15,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: isDark ? Colors.white54 : Colors.grey.shade600,
                        size: 22,
                      ),
                      suffixIcon: _searchQuery.isEmpty
                          ? null
                          : IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: isDark ? Colors.white54 : Colors.grey.shade600,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ),

              // Conversation list
              Expanded(
                child: RefreshIndicator(
                  color: AppTheme.primary,
                  onRefresh: () => chat.refreshConversations(),
                  child: list.isEmpty
                      ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: 80),
                      Icon(Icons.search_off_rounded,
                          size: 56, color: theme.hintColor.withOpacity(0.4)),
                      const SizedBox(height: 14),
                      Center(
                        child: Text(
                          'No conversations match your search',
                          style: TextStyle(color: theme.hintColor),
                        ),
                      ),
                    ],
                  )
                      : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(top: 4, bottom: 20),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      thickness: 0.5,
                      indent: 78,
                      color: isDark
                          ? Colors.white.withOpacity(0.06)
                          : Colors.grey.withOpacity(0.15),
                    ),
                    itemBuilder: (context, i) {
                      final conversation = list[i];
                      return _ConversationTile(
                        conversation: conversation,
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ChatScreen(conversation: conversation),
                            ),
                          );
                          if (!mounted) return;
                          await chat.refreshConversations();
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) => RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: () => context.read<ChatProvider>().refreshConversations(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.chat_bubble_outline_rounded,
                          size: 52, color: AppTheme.primary.withOpacity(0.65)),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      l10n.noConversationsYet,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: theme.textTheme.titleLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.startChattingWithFundis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14.5,
                        color: theme.textTheme.bodyMedium?.color?.withOpacity(0.65),
                      ),
                    ),
                    const SizedBox(height: 28),
                    OutlinedButton.icon(
                      onPressed: _goHome,
                      icon: const Icon(Icons.search_rounded, size: 20),
                      label: const Text('Find Technicians'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primary,
                        side: BorderSide(color: AppTheme.primary.withOpacity(0.7)),
                        minimumSize: const Size(0, 46),
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
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
    final name = conversation.otherParty.name;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(
            children: [
              // Circular avatar (WhatsApp style)
              CircleAvatar(
                radius: 26,
                backgroundColor: AppTheme.primary.withOpacity(0.15),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppTheme.primary,
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
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16.5,
                              fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w500,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          conversation.getFormattedLastMessageTime(),
                          style: TextStyle(
                            fontSize: 12,
                            color: hasUnread
                                ? const Color(0xFF25D366)
                                : (isDark ? Colors.white54 : Colors.grey.shade600),
                            fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conversation.getLastMessageDisplay(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              color: hasUnread
                                  ? (isDark ? Colors.white70 : Colors.black87)
                                  : (isDark ? Colors.white54 : Colors.grey.shade600),
                              fontWeight: hasUnread ? FontWeight.w500 : FontWeight.w400,
                            ),
                          ),
                        ),
                        if (hasUnread) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF25D366),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              conversation.unreadCount > 99
                                  ? '99+'
                                  : '${conversation.unreadCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
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
}