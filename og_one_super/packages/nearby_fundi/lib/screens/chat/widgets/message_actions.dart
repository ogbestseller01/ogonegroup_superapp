// lib/screens/chat/widgets/message_actions.dart  (NEW)
// The per-message dropdown: emoji row + Reply, Pin, Copy, Forward, Star, Info, Select, Delete.
import 'package:flutter/material.dart';

import '../../../config/app_theme.dart';
import '../../../models/chat_message.dart';

const List<String> kQuickReactions = ['👍', '❤️', '😂', '😮', '😢', '🙏'];

class MessageMenuActions {
  final void Function(String emoji) onReact;
  final VoidCallback onMoreEmoji;
  final VoidCallback onReply;
  final VoidCallback onPin;
  final VoidCallback onCopy;
  final VoidCallback onForward;
  final VoidCallback onStar;
  final VoidCallback onInfo;
  final VoidCallback onSelect;
  final VoidCallback onDelete;
  final VoidCallback onSave; // files / media

  const MessageMenuActions({
    required this.onReact,
    required this.onMoreEmoji,
    required this.onReply,
    required this.onPin,
    required this.onCopy,
    required this.onForward,
    required this.onStar,
    required this.onInfo,
    required this.onSelect,
    required this.onDelete,
    required this.onSave,
  });
}

Future<void> showMessageMenu(
    BuildContext context, {
      required Offset anchor,
      required ChatMessage message,
      required MessageMenuActions actions,
    }) async {
  final size = MediaQuery.of(context).size;
  final hasText = (message.content ?? '').trim().isNotEmpty;
  final hasFile = message.file != null;
  const more = '__more';

  PopupMenuItem<String> item(String v, IconData icon, String label, {Color? color}) => PopupMenuItem<String>(
    value: v,
    height: 44,
    child: Row(children: [
      Icon(icon, size: 20, color: color),
      const SizedBox(width: 14),
      Text(label, style: TextStyle(color: color)),
    ]),
  );

  final choice = await showMenu<String>(
    context: context,
    position: RelativeRect.fromLTRB(
      anchor.dx.clamp(8, size.width - 8),
      anchor.dy,
      size.width - anchor.dx,
      size.height - anchor.dy,
    ),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    items: [
      PopupMenuItem<String>(
        enabled: false,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Builder(
          builder: (ctx) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final e in kQuickReactions)
                InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => Navigator.pop(ctx, 'react:$e'),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: message.myReaction == e ? AppTheme.primary.withOpacity(0.18) : null,
                    ),
                    child: Text(e, style: const TextStyle(fontSize: 24)),
                  ),
                ),
              InkWell(
                customBorder: const CircleBorder(),
                onTap: () => Navigator.pop(ctx, more),
                child: const Padding(padding: EdgeInsets.all(6), child: Icon(Icons.add_circle_outline_rounded, size: 26)),
              ),
            ],
          ),
        ),
      ),
      const PopupMenuDivider(height: 1),
      item('reply', Icons.reply_rounded, 'Reply'),
      item('pin', message.isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined, message.isPinned ? 'Unpin' : 'Pin'),
      if (hasText) item('copy', Icons.content_copy_outlined, 'Copy'),
      item('forward', Icons.forward_rounded, 'Forward'),
      item('star', message.isStarred ? Icons.star_rounded : Icons.star_border_rounded, message.isStarred ? 'Unstar' : 'Star'),
      if (hasFile) item('save', Icons.download_rounded, 'Save'),
      item('info', Icons.info_outline_rounded, 'Info'),
      item('select', Icons.check_circle_outline_rounded, 'Select'),
      const PopupMenuDivider(height: 1),
      item('delete', Icons.delete_outline_rounded, 'Delete', color: AppTheme.error),
    ],
  );

  if (choice == null) return;
  if (choice.startsWith('react:')) return actions.onReact(choice.substring(6));
  switch (choice) {
    case more: actions.onMoreEmoji();
    case 'reply': actions.onReply();
    case 'pin': actions.onPin();
    case 'copy': actions.onCopy();
    case 'forward': actions.onForward();
    case 'star': actions.onStar();
    case 'save': actions.onSave();
    case 'info': actions.onInfo();
    case 'select': actions.onSelect();
    case 'delete': actions.onDelete();
  }
}
