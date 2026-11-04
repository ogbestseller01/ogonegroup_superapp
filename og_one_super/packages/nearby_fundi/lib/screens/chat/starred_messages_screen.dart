// lib/screens/chat/starred_messages_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../models/chat_message.dart';
import '../../providers/chat_provider.dart';

/// Pops with the tapped message id so the chat can jump to it.
class StarredMessagesScreen extends StatefulWidget {
  final int conversationId;
  final String peerName;

  const StarredMessagesScreen({
    super.key,
    required this.conversationId,
    required this.peerName,
  });

  @override
  State<StarredMessagesScreen> createState() => _StarredMessagesScreenState();
}

class _StarredMessagesScreenState extends State<StarredMessagesScreen> {
  List<ChatMessage>? _items;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await context.read<ChatProvider>().fetchStarred(widget.conversationId);
      if (mounted) setState(() => _items = list);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  Future<void> _unstar(ChatMessage m) async {
    try {
      await context.read<ChatProvider>().toggleStar(m.id);
      if (mounted) setState(() => _items = _items?.where((x) => x.id != m.id).toList());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: AppTheme.error),
      );
    }
  }

  String _formatDay(DateTime t) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(t.year, t.month, t.day);
    final diff = today.difference(date).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return DateFormat('EEEE').format(t);
    return DateFormat('MMMM d, yyyy').format(t);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final me = context.read<ChatProvider>().currentUser?.id;

    Widget body;
    if (_error != null) {
      body = Center(child: Text(_error!, style: TextStyle(color: theme.hintColor)));
    } else if (_items == null) {
      body = const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    } else if (_items!.isEmpty) {
      body = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star_border_rounded, size: 56, color: theme.hintColor.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text('No starred messages', style: TextStyle(color: theme.hintColor)),
          ],
        ),
      );
    } else {
      body = ListView.separated(
        itemCount: _items!.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final m = _items![i];
          final who = m.senderId == me ? 'You' : widget.peerName;
          return ListTile(
            leading: const Icon(Icons.star_rounded, color: Colors.amber),
            title: Text(who, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: Text(m.getDisplayMessage(), maxLines: 2, overflow: TextOverflow.ellipsis),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(m.time == null ? '' : _formatDay(m.time!),
                    style: TextStyle(fontSize: 12, color: theme.hintColor)),
                Text(m.timeLabel, style: TextStyle(fontSize: 12, color: theme.hintColor)),
              ],
            ),
            onTap: () => Navigator.pop(context, m.id),
            onLongPress: () => _unstar(m),
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1F2C34) : AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Starred messages',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: body,
    );
  }
}