// lib/screens/chat/tabs/conversations_tab.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/app_theme.dart';
import '../../../models/chat_conversation.dart';
import '../../../providers/chat_provider.dart';
import '../chat_screen.dart';
import '../widgets/conversation_tile.dart';
import '../widgets/open_blog.dart';

enum _Filter { all, unread, pinned }

class ConversationsTab extends StatefulWidget {
  final bool archived;
  final VoidCallback onFindTechnicians;
  const ConversationsTab({
    super.key,
    this.archived = false,
    required this.onFindTechnicians,
  });

  @override
  State<ConversationsTab> createState() => _ConversationsTabState();
}

class _ConversationsTabState extends State<ConversationsTab> {
  final _search = TextEditingController();
  String _q = '';
  _Filter _filter = _Filter.all;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _snack(String m, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(m),
        backgroundColor: error ? AppTheme.error : null,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
      ));
  }

  Future<void> _openChat(ChatConversation c) async {
    final chat = context.read<ChatProvider>();
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ChatScreen(conversation: c)),
    );
    if (mounted) await chat.refreshConversations();
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
            leading: Icon(c.isPinned ? Icons.push_pin_outlined : Icons.push_pin_rounded),
            title: Text(c.isPinned ? 'Unpin chat' : 'Pin chat'),
            onTap: () => Navigator.pop(s, 'pin'),
          ),
          ListTile(
            leading: Icon(c.isArchived ? Icons.unarchive_outlined : Icons.archive_outlined),
            title: Text(c.isArchived ? 'Unarchive chat' : 'Archive chat'),
            onTap: () => Navigator.pop(s, 'archive'),
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline_rounded, color: AppTheme.error),
            title: const Text('Delete chat', style: TextStyle(color: AppTheme.error)),
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
        _snack(c.isArchived ? 'Chat unarchived' : 'Chat archived');
      } else if (act == 'delete') {
        final ok = await showDialog<bool>(
          context: context,
          builder: (d) => AlertDialog(
            title: Text('Delete chat with ${c.otherParty.name}?'),
            content: const Text(
              'All messages and files in this chat will be removed for both of you.',
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancel')),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: AppTheme.error),
                onPressed: () => Navigator.pop(d, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
        if (ok == true) {
          final done = await chat.deleteConversation(c.id);
          _snack(done ? 'Chat deleted' : 'Could not delete the chat', error: !done);
        }
      }
    } catch (e) {
      _snack('$e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final chat = context.watch<ChatProvider>();
    final screenW = MediaQuery.of(context).size.width;
    final isWide = screenW >= 700;

    var list = widget.archived ? chat.archivedChats : chat.activeChats;

    if (!widget.archived) {
      if (_filter == _Filter.unread) list = list.where((c) => c.unreadCount > 0).toList();
      if (_filter == _Filter.pinned) list = list.where((c) => c.isPinned).toList();
    }
    final q = _q.toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((c) => c.otherParty.name.toLowerCase().contains(q)).toList();
    }

    final total = widget.archived ? chat.archivedChats.length : chat.activeChats.length;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: isWide ? 900 : double.infinity),
        child: Column(children: [
          Container(
            color: dark ? const Color(0xFF1F2C34) : Colors.white,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
            child: Column(children: [
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
                    hintText: 'Search',
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
              if (!widget.archived)
                SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(top: 8),
                    children: [
                      for (final f in _Filter.values)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(switch (f) {
                              _Filter.all => 'All',
                              _Filter.unread =>
                              chat.unreadChats > 0 ? 'Unread ${chat.unreadChats}' : 'Unread',
                              _Filter.pinned => 'Pinned',
                            }),
                            selected: _filter == f,
                            showCheckmark: false,
                            selectedColor: AppTheme.primary.withValues(alpha: dark ? 0.55 : 0.14),
                            labelStyle: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _filter == f
                                  ? (dark ? Colors.white : AppTheme.primary)
                                  : null,
                            ),
                            onSelected: (_) => setState(() => _filter = f),
                          ),
                        ),
                    ],
                  ),
                ),
            ]),
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppTheme.primary,
              onRefresh: chat.refreshConversations,
              child: (chat.isLoading && chat.conversations.isEmpty)
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                  : list.isEmpty
                  ? _Empty(
                archived: widget.archived,
                noChatsAtAll: total == 0,
                onFind: widget.onFindTechnicians,
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
                  return ConversationTile(
                    conversation: c,
                    onTap: () => _openChat(c),
                    onLongPress: () => _longPress(c),
                    onStatusTap: c.technicianId == null
                        ? null
                        : () => openTechnicianBlog(context, c.technicianId!),
                  );
                },
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final bool archived, noChatsAtAll;
  final VoidCallback onFind;
  const _Empty({
    required this.archived,
    required this.noChatsAtAll,
    required this.onFind,
  });

  @override
  Widget build(BuildContext context) {
    final hint = Theme.of(context).hintColor;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        const SizedBox(height: 110),
        Icon(
          archived ? Icons.archive_outlined : Icons.chat_bubble_outline_rounded,
          size: 64,
          color: hint.withValues(alpha: 0.4),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            archived
                ? 'No archived chats'
                : (noChatsAtAll ? 'No conversations yet' : 'Nothing here'),
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: hint),
            textAlign: TextAlign.center,
          ),
        ),
        if (!archived && noChatsAtAll) ...[
          const SizedBox(height: 18),
          Center(
            child: OutlinedButton.icon(
              onPressed: onFind,
              icon: const Icon(Icons.search_rounded),
              label: const Text('Find technicians'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 44),
                shape: const StadiumBorder(),
              ),
            ),
          ),
        ],
      ],
    );
  }
}