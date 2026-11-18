// lib/screens/fundi/chat/widgets/fundi_message_actions.dart
import 'package:flutter/material.dart';

import '../../../../config/app_theme.dart';
import '../../../../models/chat_message.dart';

const List<String> kFundiQuickReactions = ['👍', '❤️', '😂', '😮', '😢', '🙏'];

class FundiMessageMenuActions {
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
  final VoidCallback onSave;

  const FundiMessageMenuActions({
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

Future<void> showFundiMessageMenu(
    BuildContext context, {
      required Offset anchor,
      required ChatMessage message,
      required FundiMessageMenuActions actions,
    }) async {
  final media = MediaQuery.of(context);
  final size = media.size;
  final insets = media.viewPadding;
  final safeTop = insets.top + 8;
  final safeBottom = insets.bottom + 8;

  final hasText = (message.content ?? '').trim().isNotEmpty;
  final hasFile = message.file != null;
  const more = '__more';

  final clampedX = anchor.dx.clamp(8.0, size.width - 8.0);
  final clampedY = anchor.dy.clamp(safeTop, size.height - safeBottom);

  PopupMenuItem<String> item(
      String v, IconData icon, String label, {Color? color}) =>
      PopupMenuItem<String>(
        value: v,
        height: 44,
        child: Row(children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 14),
          Flexible(
            child: Text(label,
                style: TextStyle(color: color),
                overflow: TextOverflow.ellipsis),
          ),
        ]),
      );

  final choice = await showMenu<String>(
    context: context,
    position: RelativeRect.fromLTRB(
      clampedX,
      clampedY,
      size.width - clampedX,
      size.height - clampedY,
    ),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    items: [
      PopupMenuItem<String>(
        enabled: false,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: SizedBox(
          width: 250,
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 4,
            runSpacing: 4,
            children: [
              for (final e in kFundiQuickReactions)
                _EmojiButton(
                  emoji: e,
                  highlighted: message.myReaction == e,
                  onTap: () => Navigator.pop(context, 'react:$e'),
                ),
              _MoreButton(onTap: () => Navigator.pop(context, more)),
            ],
          ),
        ),
      ),
      const PopupMenuDivider(height: 1),
      item('reply', Icons.reply_rounded, 'Reply'),
      item(
        'pin',
        message.isPinned
            ? Icons.push_pin_rounded
            : Icons.push_pin_outlined,
        message.isPinned ? 'Unpin' : 'Pin',
      ),
      if (hasText) item('copy', Icons.content_copy_outlined, 'Copy'),
      item('forward', Icons.forward_rounded, 'Forward'),
      item(
        'star',
        message.isStarred ? Icons.star_rounded : Icons.star_border_rounded,
        message.isStarred ? 'Unstar' : 'Star',
      ),
      if (hasFile) item('save', Icons.download_rounded, 'Save'),
      item('info', Icons.info_outline_rounded, 'Info'),
      item('select', Icons.check_circle_outline_rounded, 'Select'),
      const PopupMenuDivider(height: 1),
      item('delete', Icons.delete_outline_rounded, 'Delete',
          color: AppTheme.error),
    ],
  );

  if (choice == null) return;
  if (choice.startsWith('react:')) return actions.onReact(choice.substring(6));

  switch (choice) {
    case more:
      actions.onMoreEmoji();
      break;
    case 'reply':
      actions.onReply();
      break;
    case 'pin':
      actions.onPin();
      break;
    case 'copy':
      actions.onCopy();
      break;
    case 'forward':
      actions.onForward();
      break;
    case 'star':
      actions.onStar();
      break;
    case 'save':
      actions.onSave();
      break;
    case 'info':
      actions.onInfo();
      break;
    case 'select':
      actions.onSelect();
      break;
    case 'delete':
      actions.onDelete();
      break;
  }
}

class _EmojiButton extends StatelessWidget {
  final String emoji;
  final bool highlighted;
  final VoidCallback onTap;
  const _EmojiButton({
    required this.emoji,
    required this.highlighted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: highlighted
              ? AppTheme.primary.withValues(alpha: 0.18)
              : null,
        ),
        child: FittedBox(
          fit: BoxFit.contain,
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: Text(emoji, style: const TextStyle(fontSize: 20)),
          ),
        ),
      ),
    );
  }
}

class _MoreButton extends StatelessWidget {
  final VoidCallback onTap;
  const _MoreButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: const SizedBox(
        width: 34,
        height: 34,
        child: Center(child: Icon(Icons.add_circle_outline_rounded, size: 22)),
      ),
    );
  }
}