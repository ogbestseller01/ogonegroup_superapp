// lib/screens/chat/widgets/message_bubble.dart
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../config/app_theme.dart';
import '../../../models/chat_message.dart';

class _C {
  final Color bubble, text, meta, accent;
  final bool dark;
  const _C(this.bubble, this.text, this.meta, this.accent, this.dark);
}

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMine;
  final int? myId;
  final String peerName;
  final bool highlighted;
  final Map<String, String>? authHeaders;

  final VoidCallback? onLongPress;
  final VoidCallback? onTap;
  final VoidCallback? onSave;
  final VoidCallback? onRetry;
  final VoidCallback? onTapReactions;
  final ValueChanged<int>? onTapReply;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMine,
    required this.myId,
    required this.peerName,
    this.highlighted = false,
    this.authHeaders,
    this.onLongPress,
    this.onTap,
    this.onSave,
    this.onRetry,
    this.onTapReactions,
    this.onTapReply,
  });

  bool get _isMedia => message.isImage || message.isVideo;
  bool get _hasCaption => (message.content ?? '').trim().isNotEmpty;
  bool get _failed => message.sendState == SendState.failed;
  bool get _sending => message.sendState == SendState.sending;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;

    final bubble = isMine
        ? AppTheme.primary
        : (dark ? scheme.surfaceContainerHigh : Colors.white);
    final c = _C(
      bubble,
      isMine ? Colors.white : scheme.onSurface,
      isMine ? Colors.white70 : scheme.onSurface.withOpacity(0.55),
      isMine ? Colors.white : AppTheme.primary,
      dark,
    );

    final reply = message.replyTo;
    final content = _content(context, c);

    Widget inner = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment:
      reply != null ? CrossAxisAlignment.stretch : CrossAxisAlignment.start,
      children: [
        if (message.isForwarded) _forwardedLabel(c),
        if (reply != null) _quote(reply, c),
        content,
      ],
    );
    if (reply != null) inner = IntrinsicWidth(child: inner);

    final shown = highlighted
        ? Color.alphaBlend(Colors.amber.withOpacity(0.4), bubble)
        : bubble;

    final hasReactions = message.reactions.isNotEmpty;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.only(
          left: isMine ? 48 : 10,
          right: isMine ? 10 : 48,
          top: 2,
          bottom: hasReactions ? 8 : 2,
        ),
        child: Column(
          crossAxisAlignment:
          isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: _failed ? onRetry : onTap,
              onLongPress: _sending ? null : onLongPress,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                clipBehavior: Clip.antiAlias,
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.78,
                ),
                padding: _isMedia
                    ? const EdgeInsets.all(3)
                    : const EdgeInsets.fromLTRB(10, 6, 10, 6),
                decoration: BoxDecoration(
                  color: shown,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(14),
                    topRight: const Radius.circular(14),
                    bottomLeft: Radius.circular(isMine ? 14 : 3),
                    bottomRight: Radius.circular(isMine ? 3 : 14),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.07),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: inner,
              ),
            ),
            if (hasReactions)
              Transform.translate(
                offset: const Offset(0, -6),
                child: _reactionPill(c),
              ),
            if (_failed)
              Padding(
                padding: const EdgeInsets.only(top: 3, right: 2),
                child: Text(
                  (message.sendError ?? '').isNotEmpty
                      ? '${message.sendError} · Tap to retry'
                      : 'Not sent · Tap to retry',
                  style: const TextStyle(fontSize: 11.5, color: Colors.redAccent),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Small pieces ───────────────────────────────────────

  Widget _forwardedLabel(_C c) => Padding(
    padding: EdgeInsets.only(
        bottom: 3, left: _isMedia ? 6 : 0, top: _isMedia ? 3 : 0),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.forward_rounded, size: 14, color: c.meta),
        const SizedBox(width: 4),
        Text(
          'Forwarded',
          style: TextStyle(
              fontSize: 12, fontStyle: FontStyle.italic, color: c.meta),
        ),
      ],
    ),
  );

  /// WhatsApp-style emoji pill under the bubble: "👍❤️ 3".
  Widget _reactionPill(_C c) {
    final emojis = message.reactions.map((r) => r.emoji).take(3).join();
    final total = message.reactionTotal;
    final mine = message.myReaction != null;

    return GestureDetector(
      onTap: onTapReactions,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: c.dark ? const Color(0xFF2A3942) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: mine
                ? AppTheme.primary.withOpacity(0.6)
                : Colors.grey.withOpacity(0.25),
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 3),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emojis, style: const TextStyle(fontSize: 14)),
            if (total > 1) ...[
              const SizedBox(width: 3),
              Text(
                '$total',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: c.dark ? Colors.white70 : Colors.black54,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _content(BuildContext context, _C c) {
    switch (message.messageType) {
      case 'image':
        return _mediaWithCaption(c, _image(c));
      case 'video':
        return _mediaWithCaption(c, _video(c));
      case 'file':
        return _fileCard(c);
      default:
        return _textWithMeta((message.content ?? '').trim(), c);
    }
  }

  Widget _mediaWithCaption(_C c, Widget media) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        media,
        if (_hasCaption)
          Padding(
            padding: const EdgeInsets.fromLTRB(7, 6, 7, 3),
            child: _textWithMeta(message.content!.trim(), c),
          ),
      ],
    );
  }

  Widget _textWithMeta(String text, _C c) {
    final extra = (message.isStarred ? 3 : 0) + (message.isPinned ? 3 : 0);
    final gap = '\u00A0' * ((isMine ? 17 : 11) + extra);
    return Stack(
      children: [
        Text.rich(
          TextSpan(children: [
            TextSpan(
              text: text,
              style: TextStyle(color: c.text, fontSize: 15.5, height: 1.3),
            ),
            TextSpan(text: gap, style: const TextStyle(fontSize: 15.5)),
          ]),
        ),
        Positioned(right: 0, bottom: 0, child: _meta(c)),
      ],
    );
  }

  Widget _meta(_C c, {bool overlay = false}) {
    final color = overlay ? Colors.white : c.meta;
    Widget? status;
    if (isMine) {
      switch (message.sendState) {
        case SendState.sending:
          status = Icon(Icons.schedule_rounded, size: 13, color: color);
          break;
        case SendState.failed:
          status = const Icon(Icons.error_outline_rounded,
              size: 14, color: Colors.redAccent);
          break;
        case SendState.sent:
          status = Icon(
            message.isRead ? Icons.done_all_rounded : Icons.done_rounded,
            size: 16,
            color: message.isRead ? Colors.lightBlueAccent : color,
          );
      }
    }

    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (message.isPinned) ...[
          Icon(Icons.push_pin_rounded, size: 12, color: color),
          const SizedBox(width: 3),
        ],
        if (message.isStarred) ...[
          Icon(Icons.star_rounded, size: 13, color: color),
          const SizedBox(width: 3),
        ],
        Text(message.timeLabel, style: TextStyle(fontSize: 11, color: color)),
        if (status != null) ...[const SizedBox(width: 3), status],
      ],
    );

    if (!overlay) return row;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(10),
      ),
      child: row,
    );
  }

  /// The quoted message. TAP = jump to the original (handled by the screen).
  Widget _quote(ReplyRef r, _C c) {
    final mine = r.senderId == myId;
    final name = mine
        ? 'You'
        : ((r.senderName ?? '').isNotEmpty ? r.senderName! : peerName);
    final bar = isMine ? Colors.white : AppTheme.primary;

    return Padding(
      padding: EdgeInsets.only(bottom: 5, top: _isMedia ? 3 : 0, left: _isMedia ? 3 : 0, right: _isMedia ? 3 : 0),
      child: Material(
        color: isMine ? Colors.black.withOpacity(0.18) : AppTheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => onTapReply?.call(r.id),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 4, color: bar),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 5, 8, 5),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: bar,
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          r.snippet,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: c.text.withOpacity(0.8),
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (r.isImage)
                  SizedBox(
                    width: 46,
                    child: CachedNetworkImage(
                      imageUrl: ChatFile.urlFor(r.id),
                      httpHeaders: authHeaders,
                      cacheKey: 'chat_${r.id}',
                      memCacheWidth: 140,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) =>
                      const Icon(Icons.image_outlined, size: 20),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _placeholder(_C c, IconData icon) => Container(
    color: c.dark ? Colors.black26 : Colors.grey.shade300,
    child: Center(child: Icon(icon, size: 44, color: Colors.grey)),
  );

  Widget _image(_C c) {
    final f = message.file;
    if (f == null) return SizedBox(width: 230, height: 120, child: _placeholder(c, Icons.broken_image));

    final net = CachedNetworkImage(
      imageUrl: f.url ?? '',
      httpHeaders: authHeaders,
      cacheKey: 'chat_${message.id}',
      memCacheWidth: 700,
      fit: BoxFit.cover,
      placeholder: (_, __) => Container(
        color: c.dark ? Colors.black26 : Colors.grey.shade300,
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      errorWidget: (_, __, ___) => _placeholder(c, Icons.broken_image),
    );

    final local = f.localPath;
    final Widget img = local != null
        ? Image.file(File(local),
        fit: BoxFit.cover, cacheWidth: 700, errorBuilder: (_, __, ___) => net)
        : net;

    return ClipRRect(
      borderRadius: BorderRadius.circular(11),
      child: SizedBox(
        width: 230,
        height: 230,
        child: Stack(
          fit: StackFit.expand,
          children: [
            img,
            if (message.isPending) _uploadOverlay(),
            if (!_hasCaption)
              Positioned(right: 6, bottom: 6, child: _meta(c, overlay: true)),
          ],
        ),
      ),
    );
  }

  Widget _uploadOverlay() {
    return Container(
      color: Colors.black38,
      child: Center(
        child: _failed
            ? const Icon(Icons.refresh_rounded, color: Colors.white, size: 38)
            : SizedBox(
          width: 44,
          height: 44,
          child: CircularProgressIndicator(
            value: message.progress > 0 ? message.progress : null,
            strokeWidth: 3,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _video(_C c) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(11),
      child: SizedBox(
        width: 230,
        height: 150,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: const Color(0xFF1B1F23)),
            const Center(
              child: CircleAvatar(
                radius: 26,
                backgroundColor: Colors.black54,
                child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 36),
              ),
            ),
            Positioned(
              left: 8,
              bottom: 8,
              child: Row(
                children: [
                  const Icon(Icons.videocam_rounded, color: Colors.white70, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    message.file?.formattedSize ?? '',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (message.isPending) _uploadOverlay(),
            if (!_hasCaption)
              Positioned(right: 6, bottom: 6, child: _meta(c, overlay: true)),
          ],
        ),
      ),
    );
  }

  (IconData, Color) _fileStyle(ChatFileKind kind) {
    switch (kind) {
      case ChatFileKind.pdf:
        return (Icons.picture_as_pdf_rounded, const Color(0xFFE53935));
      case ChatFileKind.word:
        return (Icons.description_rounded, const Color(0xFF1E6FD9));
      case ChatFileKind.excel:
        return (Icons.table_chart_rounded, const Color(0xFF1E8E3E));
      case ChatFileKind.powerpoint:
        return (Icons.slideshow_rounded, const Color(0xFFE8710A));
      default:
        return (Icons.insert_drive_file_rounded, const Color(0xFF607D8B));
    }
  }

  Widget _fileCard(_C c) {
    final f = message.file;
    final (icon, color) = _fileStyle(f?.kind ?? ChatFileKind.other);
    final info = [
      if ((f?.ext ?? '').isNotEmpty) f!.ext.toUpperCase(),
      if ((f?.formattedSize ?? '').isNotEmpty) f!.formattedSize,
    ].join(' · ');

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 250,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isMine ? Colors.black.withOpacity(0.14) : color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      f?.name ?? 'File',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: c.text,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    if (info.isNotEmpty)
                      Text(info, style: TextStyle(color: c.meta, fontSize: 12)),
                  ],
                ),
              ),
              if (message.isPending)
                SizedBox(
                  width: 28,
                  height: 28,
                  child: _failed
                      ? const Icon(Icons.refresh_rounded, color: Colors.redAccent)
                      : CircularProgressIndicator(
                    value: message.progress > 0 ? message.progress : null,
                    strokeWidth: 2.5,
                    color: c.accent,
                  ),
                )
              else
                IconButton(
                  tooltip: 'Save / share',
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.download_rounded, color: c.text.withOpacity(0.8)),
                  onPressed: onSave,
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 3, right: 2),
          child: Align(alignment: Alignment.centerRight, child: _meta(c)),
        ),
        if (_hasCaption)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: _textWithMeta(message.content!.trim(), c),
          ),
      ],
    );
  }
}
