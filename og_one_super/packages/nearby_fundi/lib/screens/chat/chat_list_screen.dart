// lib/screens/chat/chat_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../config/app_routes.dart';
import '../../providers/chat_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/chat_conversation.dart';
import '../../models/chat_user.dart';
import '../../l10n/app_localizations.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  /// Optional override for the back arrow. When null, the arrow goes to the
  /// home screen exactly like the My Requests screen does.
  final VoidCallback? onBack;

  const ChatListScreen({super.key, this.onBack});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  bool _isInitialized = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();

    // initState runs during build. Anything that notifies listeners must
    // wait until the first frame is finished.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _initializeChat();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeChat() async {
    if (_isInitialized) return;

    final authProvider = context.read<AuthProvider>();
    final chatProvider = context.read<ChatProvider>();

    final user = authProvider.user;
    final token = authProvider.token;

    if (user == null || token == null) return;

    _isInitialized = true;

    final chatUser = ChatUser(
      id: user.id,
      name: user.name,
      email: user.email,
      phone: user.phone,
      avatar: user.profilePhoto,
    );

    // Safe to call twice: the provider ignores repeat initialization.
    chatProvider.initialize(
      token: token,
      currentUser: chatUser,
    );

    await chatProvider.refreshConversations();
  }

  /// Same behaviour as the back arrow on the My Requests screen.
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
    final width = MediaQuery.of(context).size.width;
    final isTablet = width > 600;
    final hPad = isTablet ? 28.0 : 16.0;

    return Scaffold(
      backgroundColor:
      isDark ? theme.scaffoldBackgroundColor : const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: Text(
          l10n.chat,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        elevation: 0,
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        systemOverlayStyle: SystemUiOverlayStyle.light,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white),
          onPressed: _goHome,
        ),
        actions: [
          Consumer<ChatProvider>(
            builder: (context, chatProvider, child) {
              return Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      tooltip: l10n.refresh,
                      icon: const Icon(Icons.refresh_rounded,
                          color: Colors.white),
                      onPressed: () async {
                        await chatProvider.refreshConversations();
                      },
                    ),
                    if (chatProvider.totalUnread > 0)
                      Positioned(
                        top: 6,
                        right: 6,
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
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Consumer<ChatProvider>(
            builder: (context, chatProvider, child) {
              if (chatProvider.isLoading &&
                  chatProvider.conversations.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(color: AppTheme.primary),
                );
              }

              if (chatProvider.conversations.isEmpty) {
                return _buildEmptyState(context);
              }

              final q = _searchQuery.toLowerCase();
              final conversations = chatProvider.conversations.where((c) {
                if (q.isEmpty) return true;
                return c.otherParty.name.toLowerCase().contains(q);
              }).toList();

              return Column(
                children: [
                  // ── Search ───────────────────────────────────────
                  Padding(
                    padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 8),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (v) =>
                            setState(() => _searchQuery = v.trim()),
                        decoration: InputDecoration(
                          hintText: 'Search conversations...',
                          hintStyle: TextStyle(
                            color: theme.hintColor.withOpacity(0.7),
                            fontSize: 14,
                          ),
                          prefixIcon: Icon(Icons.search_rounded,
                              color: theme.hintColor, size: 22),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                            icon: Icon(Icons.close_rounded,
                                size: 18, color: theme.hintColor),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                              : null,
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding:
                          const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ),

                  // ── Section title ────────────────────────────────
                  Padding(
                    padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 4),
                    child: Row(
                      children: [
                        Text(
                          'Conversations',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${conversations.length}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color:
                              isDark ? Colors.white : AppTheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── List ─────────────────────────────────────────
                  Expanded(
                    child: RefreshIndicator(
                      color: AppTheme.primary,
                      onRefresh: () => chatProvider.refreshConversations(),
                      child: conversations.isEmpty
                          ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          const SizedBox(height: 80),
                          Icon(Icons.search_off_rounded,
                              size: 56,
                              color: theme.hintColor.withOpacity(0.45)),
                          const SizedBox(height: 14),
                          Center(
                            child: Text(
                              'No conversations match your search',
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(color: theme.hintColor),
                            ),
                          ),
                        ],
                      )
                          : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 28),
                        itemCount: conversations.length,
                        itemBuilder: (context, index) {
                          final conversation = conversations[index];
                          return _ConversationTile(
                            conversation: conversation,
                            isTablet: isTablet,
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatScreen(
                                    conversation: conversation,
                                  ),
                                ),
                              );
                              if (!mounted) return;
                              await chatProvider.refreshConversations();
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
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        return RefreshIndicator(
          color: AppTheme.primary,
          onRefresh: () => context.read<ChatProvider>().refreshConversations(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
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
                        textAlign: TextAlign.center,
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
                          color: theme.textTheme.bodyMedium?.color
                              ?.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 24),
                      OutlinedButton.icon(
                        onPressed: _goHome,
                        icon: const Icon(Icons.search_rounded),
                        label: const Text('Find Technicians'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primary,
                          side: const BorderSide(color: AppTheme.primary),
                          minimumSize: const Size(0, 48),
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
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final ChatConversation conversation;
  final VoidCallback onTap;
  final bool isTablet;

  const _ConversationTile({
    required this.conversation,
    required this.onTap,
    this.isTablet = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasUnread = conversation.unreadCount > 0;
    final titleColor = isDark ? Colors.white : const Color(0xFF1E293B);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: hasUnread
            ? Border.all(color: AppTheme.primary.withOpacity(0.35), width: 1.2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 14,
              vertical: isTablet ? 16 : 14,
            ),
            child: Row(
              children: [
                Container(
                  width: isTablet ? 56 : 50,
                  height: isTablet ? 56 : 50,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    conversation.otherParty.name.isNotEmpty
                        ? conversation.otherParty.name[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      fontSize: isTablet ? 21 : 19,
                      fontWeight: FontWeight.w800,
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
                              conversation.otherParty.name,
                              style: TextStyle(
                                fontSize: isTablet ? 17 : 16,
                                fontWeight: hasUnread
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: titleColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            conversation.getFormattedLastMessageTime(),
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.hintColor,
                              fontWeight: hasUnread
                                  ? FontWeight.w700
                                  : FontWeight.w500,
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
                                fontSize: 13.5,
                                color: hasUnread
                                    ? theme.colorScheme.onSurface
                                    : theme.hintColor,
                                fontWeight: hasUnread
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (hasUnread) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.error,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                conversation.unreadCount > 99
                                    ? '99+'
                                    : '${conversation.unreadCount}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
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
      ),
    );
  }
}