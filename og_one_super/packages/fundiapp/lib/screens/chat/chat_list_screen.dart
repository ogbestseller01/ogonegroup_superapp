// lib/screens/chat/fundi_chat_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fundiapp_sdk/screens/chat/widgets/user_avatar.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../models/chat_conversation.dart';
import '../../models/chat_user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../fundi/fundi_home_screen.dart';
import 'fundi_chat_screen.dart';

class FundiChatListScreen extends StatefulWidget {
  const FundiChatListScreen({super.key});

  @override
  State<FundiChatListScreen> createState() => _FundiChatListScreenState();
}

class _FundiChatListScreenState extends State<FundiChatListScreen> {
  final _search = TextEditingController();
  String _q = '';

  bool _showArchived = false;
  String _filter = 'all'; // all, unread, pinned

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final auth = context.read<AuthProvider>();
    final chat = context.read<ChatProvider>();
    final user = auth.user, token = auth.token;
    if (user == null || token == null) return;

    chat.initialize(
      token: token,
      currentUser: ChatUser(
        id: user.id,
        name: user.name,
        email: user.email ?? '',
        phone: user.phone,
        avatar: null,
      ),
    );
    await chat.refreshConversations();
  }

  void _handleBack() {
    final homeState = context.findAncestorStateOfType<FundiHomeScreenState>();
    if (homeState != null) {
      homeState.navigateToTab(0);
    } else {
      Navigator.maybePop(context);
    }
  }

  Future<void> _open(ChatConversation c) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FundiChatScreen(conversation: c),
      ),
    );
    if (mounted) await context.read<ChatProvider>().refreshConversations();
  }

  Future<void> _longPress(ChatConversation c) async {
    final chat = context.read<ChatProvider>();
    final act = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      constraints: const BoxConstraints(maxWidth: 600),
      builder: (s) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: Icon(c.isPinned
                ? Icons.push_pin_outlined
                : Icons.push_pin_rounded),
            title: Text(c.isPinned ? 'Unpin chat' : 'Pin chat'),
            onTap: () => Navigator.pop(s, 'pin'),
          ),
          ListTile(
            leading: Icon(c.isArchived
                ? Icons.unarchive_outlined
                : Icons.archive_outlined),
            title: Text(c.isArchived ? 'Unarchive chat' : 'Archive chat'),
            onTap: () => Navigator.pop(s, 'archive'),
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline_rounded, color: AppTheme.error),
            title: const Text('Delete chat',
                style: TextStyle(color: AppTheme.error)),
            onTap: () => Navigator.pop(s, 'delete'),
          ),
        ]),
      ),
    );
    if (act == null || !mounted) return;

    try {
      if (act == 'pin') {
        await chat.setConversationState(c.id, pinned: !c.isPinned);
      } else if (act == 'archive') {
        await chat.setConversationState(c.id, archived: !c.isArchived);
      } else if (act == 'delete') {
        final ok = await showDialog<bool>(
          context: context,
          builder: (d) => AlertDialog(
            title: Text('Delete chat with ${c.otherParty.name}?'),
            content: const Text(
                'All messages and files will be removed for both of you.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(d, false),
                  child: const Text('Cancel')),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: AppTheme.error),
                onPressed: () => Navigator.pop(d, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
        if (ok == true) await chat.deleteConversation(c.id);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: AppTheme.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final chat = context.watch<ChatProvider>();

    var list = _showArchived ? chat.archivedChats : chat.activeChats;

    // Apply Search Query
    final q = _q.toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((c) => c.otherParty.name.toLowerCase().contains(q)).toList();
    }

    // Apply Filter (All, Unread, Pinned)
    if (_filter == 'unread') {
      list = list.where((c) => c.unreadCount > 0).toList();
    } else if (_filter == 'pinned') {
      list = list.where((c) => c.isPinned).toList();
    }

    return Scaffold(
      backgroundColor: dark ? Theme.of(context).scaffoldBackgroundColor : Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: dark ? const Color(0xFF1F2C34) : AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Colors.white),
          onPressed: _handleBack,
        ),
        title: Text(
            _showArchived ? 'Archived Chats' : 'Customers',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 20)
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
            onSelected: (val) {
              if (val == 'archive') {
                setState(() => _showArchived = !_showArchived);
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'archive',
                child: Row(
                  children: [
                    Icon(_showArchived ? Icons.chat_bubble_outline_rounded : Icons.archive_outlined),
                    const SizedBox(width: 10),
                    Text(_showArchived ? 'View Active Chats' : 'View Archived Chats'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: chat.refreshConversations,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── SEARCH & FILTERS (From Screenshot) ──
          Container(
            color: dark ? const Color(0xFF1F2C34) : Colors.white,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Column(
              children: [
                Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: dark ? const Color(0xFF2A3942) : const Color(0xFFF0F2F5),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: TextField(
                    controller: _search,
                    onChanged: (v) => setState(() => _q = v.trim()),
                    decoration: InputDecoration(
                      hintText: 'Search customers',
                      prefixIcon: const Icon(Icons.search_rounded, size: 22),
                      suffixIcon: _q.isEmpty
                          ? null
                          : IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () {
                          _search.clear();
                          setState(() => _q = '');
                        },
                      ),
                      border: InputBorder.none,
                      filled: false,
                      contentPadding: const EdgeInsets.symmetric(vertical: 9),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'All',
                        isSelected: _filter == 'all',
                        onTap: () => setState(() => _filter = 'all'),
                        isDark: dark,
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: chat.unreadChats > 0 ? 'Unread ${chat.unreadChats}' : 'Unread',
                        isSelected: _filter == 'unread',
                        onTap: () => setState(() => _filter = 'unread'),
                        isDark: dark,
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Pinned',
                        isSelected: _filter == 'pinned',
                        onTap: () => setState(() => _filter = 'pinned'),
                        isDark: dark,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── CHAT LIST ──
          Expanded(
            child: RefreshIndicator(
              color: AppTheme.primary,
              onRefresh: chat.refreshConversations,
              child: (chat.isLoading && chat.conversations.isEmpty)
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                  : list.isEmpty
                  ? _Empty(
                isArchived: _showArchived,
                isFiltered: _q.isNotEmpty || _filter != 'all',
              )
                  : ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: list.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  thickness: 0.5,
                  indent: 78,
                  color: dark ? Colors.white10 : Colors.grey.withValues(alpha: 0.18),
                ),
                itemBuilder: (_, i) {
                  final c = list[i];
                  return _Tile(
                    conversation: c,
                    onTap: () => _open(c),
                    onLongPress: () => _longPress(c),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppTheme.secondary.withOpacity(0.2) : const Color(0xFFE8F0FE))
              : (isDark ? const Color(0xFF2A3942) : Colors.white),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected
                ? (isDark ? AppTheme.secondary : const Color(0xFF1A73E8))
                : (isDark ? Colors.transparent : Colors.grey.shade300),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? (isDark ? AppTheme.secondary : const Color(0xFF1A73E8))
                : (isDark ? Colors.white70 : Colors.black87),
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final ChatConversation conversation;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  const _Tile({
    required this.conversation,
    required this.onTap,
    required this.onLongPress,
  });

  static const _green = Color(0xFF25D366);

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final c = conversation;
    final unread = c.unreadCount > 0;
    final sub = dark ? Colors.white54 : Colors.grey.shade600;

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(children: [
          // ── USER AVATAR (Using the widget from your question) ──
          UserAvatar(
            name: c.otherParty.name,
            url: c.otherParty.avatar,
            radius: 26,
            hasStatus: c.hasNewPost, // Gold ring if there's a new status
            showOnline: c.otherParty.isOnline, // Green dot if online
            onTap: onTap,
          ),
          const SizedBox(width: 14),

          // ── CHAT INFO ──
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: Text(
                    c.otherParty.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16.5,
                      fontWeight: unread ? FontWeight.w700 : FontWeight.w500,
                      color: dark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                Text(
                  c.getFormattedLastMessageTime(),
                  style: TextStyle(
                    fontSize: 12,
                    color: unread ? _green : sub,
                    fontWeight: unread ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ]),
              const SizedBox(height: 3),
              Row(children: [
                Expanded(
                  child: Text(
                    c.getLastMessageDisplay(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: unread ? (dark ? Colors.white70 : Colors.black87) : sub,
                      fontStyle: c.lastMessage?.isDeleted == true
                          ? FontStyle.italic
                          : FontStyle.normal,
                    ),
                  ),
                ),
                if (c.isPinned)
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Icon(Icons.push_pin_rounded, size: 16, color: sub),
                  ),
                if (unread)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    constraints: const BoxConstraints(minWidth: 22),
                    decoration: BoxDecoration(
                      color: _green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      c.unreadCount > 99 ? '99+' : '${c.unreadCount}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final bool isArchived;
  final bool isFiltered;

  const _Empty({required this.isArchived, required this.isFiltered});

  @override
  Widget build(BuildContext context) {
    final hint = Theme.of(context).hintColor;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        const SizedBox(height: 110),
        Icon(
          isFiltered
              ? Icons.search_off_rounded
              : isArchived
              ? Icons.archive_outlined
              : Icons.chat_bubble_outline_rounded,
          size: 64,
          color: hint.withValues(alpha: 0.4),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            isFiltered
                ? 'No matching conversations'
                : isArchived
                ? 'No archived chats'
                : 'No conversations yet',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: hint),
            textAlign: TextAlign.center,
          ),
        ),
        if (!isArchived && !isFiltered) ...[
          const SizedBox(height: 6),
          Center(
            child: Text(
              'Customers will appear here when they message you',
              style: TextStyle(color: hint),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ],
    );
  }
}