// lib/screens/chat/widgets/conversation_tile.dart  (NEW)
import 'package:flutter/material.dart';

import '../../../config/app_theme.dart';
import '../../../models/chat_conversation.dart';
import '../../../widgets/user_avatar.dart';

class ConversationTile extends StatelessWidget {
  final ChatConversation conversation;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback? onStatusTap;

  const ConversationTile({
    super.key,
    required this.conversation,
    required this.onTap,
    required this.onLongPress,
    this.onStatusTap,
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
          UserAvatar(
            name: c.otherParty.name,
            url: c.otherParty.avatar,
            radius: 26,
            hasStatus: c.hasNewPost,
            onStatusTap: onStatusTap, // ring tap -> blog?technicianId=...
          ),
          const SizedBox(width: 14),
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
                      fontStyle: c.lastMessage?.isDeleted == true ? FontStyle.italic : FontStyle.normal,
                    ),
                  ),
                ),
                if (c.isPinned) Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Icon(Icons.push_pin_rounded, size: 16, color: sub),
                ),
                if (unread) Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  constraints: const BoxConstraints(minWidth: 22),
                  decoration: BoxDecoration(color: _green, borderRadius: BorderRadius.circular(12)),
                  child: Text(
                    c.unreadCount > 99 ? '99+' : '${c.unreadCount}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700),
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

/// Re-exported so the tabs only need one import for the brand colour.
const Color kChatPrimary = AppTheme.primary;
