// lib/screens/chat/widgets/chat_message_row.dart
import 'package:flutter/material.dart';

import '../../../config/app_theme.dart';
import '../../../models/chat_message.dart';
import '../../../widgets/swipe_to_reply.dart';
import 'message_bubble.dart';

class ChatMessageRow extends StatelessWidget {
  final ChatMessage message;
  final bool isMine;
  final int? myId;
  final String peerName;
  final bool highlighted;
  final bool selecting;
  final bool selected;
  final Map<String, String>? authHeaders;

  final VoidCallback onToggleSelect;
  final void Function(Offset anchor) onOpenMenu;
  final VoidCallback onReply;
  final VoidCallback onOpen;
  final VoidCallback onSave;
  final VoidCallback onRetry;
  final VoidCallback onTapReactions;
  final ValueChanged<int> onTapReply;

  const ChatMessageRow({
    super.key,
    required this.message,
    required this.isMine,
    required this.myId,
    required this.peerName,
    required this.highlighted,
    required this.selecting,
    required this.selected,
    required this.authHeaders,
    required this.onToggleSelect,
    required this.onOpenMenu,
    required this.onReply,
    required this.onOpen,
    required this.onSave,
    required this.onRetry,
    required this.onTapReactions,
    required this.onTapReply,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final m = message;

    Widget bubble = m.isDeleted
        ? _Tombstone(isMine: isMine, time: m.timeLabel, dark: dark)
        : MessageBubble(
      message: m,
      isMine: isMine,
      myId: myId,
      peerName: peerName,
      highlighted: highlighted,
      authHeaders: authHeaders,
      onLongPress: onToggleSelect, // long-press = start selecting
      onTap: selecting ? onToggleSelect : onOpen,
      onSave: onSave,
      onRetry: onRetry,
      onTapReactions: selecting ? null : onTapReactions,
      onTapReply: selecting ? null : onTapReply,
    );

    if (!m.isDeleted && !m.isPending && !selecting) {
      bubble = Stack(
        children: [
          bubble,
          // dropdown chevron sits in the free gutter beside the bubble (top)
          Positioned(
            top: 2,
            left: isMine ? 6 : null,
            right: isMine ? null : 6,
            child: Builder(
              builder: (ctx) => InkResponse(
                radius: 18,
                onTap: () {
                  final box = ctx.findRenderObject() as RenderBox;
                  onOpenMenu(box.localToGlobal(Offset(isMine ? 0 : -150, box.size.height)));
                },
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    // Fixed: withOpacity -> withValues
                    color: dark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                  ),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: dark ? Colors.white60 : Colors.black45,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
      bubble = SwipeToReply(
        enabled: m.sendState == SendState.sent,
        onReply: onReply,
        child: bubble,
      );
    }

    return InkWell(
      onTap: selecting ? onToggleSelect : null,
      onLongPress: (m.isPending || selecting) ? null : onToggleSelect,
      child: Container(
        // Fixed: withOpacity -> withValues
        color: selected ? AppTheme.primary.withValues(alpha: 0.16) : Colors.transparent,
        child: Row(
          children: [
            if (selecting)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Checkbox(
                  value: selected,
                  shape: const CircleBorder(),
                  activeColor: AppTheme.primary,
                  visualDensity: VisualDensity.compact,
                  onChanged: m.isPending ? null : (_) => onToggleSelect(),
                ),
              ),
            Expanded(
              child: IgnorePointer(
                ignoring: selecting,
                child: bubble,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tombstone extends StatelessWidget {
  final bool isMine, dark;
  final String time;
  const _Tombstone({required this.isMine, required this.time, required this.dark});

  @override
  Widget build(BuildContext context) {
    final fg = dark ? Colors.white54 : Colors.black45;
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(left: isMine ? 48 : 10, right: isMine ? 10 : 48, top: 2, bottom: 2),
        padding: const EdgeInsets.fromLTRB(10, 7, 10, 7),
        decoration: BoxDecoration(
          // Fixed: withOpacity -> withValues
          color: dark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.block_rounded, size: 15, color: fg),
            const SizedBox(width: 6),
            Text(
              'This message was deleted',
              style: TextStyle(fontStyle: FontStyle.italic, color: fg, fontSize: 14),
            ),
            const SizedBox(width: 10),
            Text(time, style: TextStyle(fontSize: 11, color: fg)),
          ],
        ),
      ),
    );
  }
}