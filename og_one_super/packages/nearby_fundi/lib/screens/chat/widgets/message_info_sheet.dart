// lib/screens/chat/widgets/message_info_sheet.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/app_theme.dart';
import '../../../models/chat_message.dart';
import '../../../providers/chat_provider.dart';

Future<void> showMessageInfo(BuildContext context, ChatMessage message) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    constraints: const BoxConstraints(maxWidth: 600),
    builder: (_) => MessageInfoSheet(message: message),
  );
}

class MessageInfoSheet extends StatefulWidget {
  final ChatMessage message;
  const MessageInfoSheet({super.key, required this.message});

  @override
  State<MessageInfoSheet> createState() => _MessageInfoSheetState();
}

class _MessageInfoSheetState extends State<MessageInfoSheet> {
  late final Future<MessageInfo> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<ChatProvider>().fetchInfo(widget.message.id);
  }

  Widget _row(IconData icon, Color color, String label, DateTime? t) {
    return ListTile(
      dense: true,
      leading: Icon(icon, color: color, size: 22),
      title: Text(label),
      trailing: Text(
        t == null ? '—' : chatDateTimeLabel(t),
        style: TextStyle(color: Theme.of(context).hintColor, fontSize: 13),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final me = context.read<ChatProvider>().currentUser?.id;
    final theme = Theme.of(context);
    final m = widget.message;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text('Message info',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(m.getDisplayMessage(), maxLines: 4, overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(height: 8),
              FutureBuilder<MessageInfo>(
                future: _future,
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snap.hasError || !snap.hasData) {
                    return Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text('${snap.error ?? 'Could not load info'}',
                            style: TextStyle(color: theme.hintColor)),
                      ),
                    );
                  }
                  final info = snap.data!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (info.isMine) ...[
                        _row(Icons.done_all_rounded, Colors.lightBlue, 'Read', info.readAt),
                        _row(Icons.done_all_rounded, Colors.grey, 'Delivered', info.deliveredAt),
                      ],
                      _row(Icons.send_rounded, Colors.grey, 'Sent', info.sentAt),
                      if (info.reactions.isNotEmpty) ...[
                        const Divider(),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                          child: Text('Reactions · ${info.reactions.length}',
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                        ),
                        for (final r in info.reactions)
                          ListTile(
                            dense: true,
                            leading: CircleAvatar(
                              radius: 18,
                              backgroundColor: AppTheme.primary.withOpacity(0.12),
                              child: Text(r.name.isNotEmpty ? r.name[0].toUpperCase() : '?'),
                            ),
                            title: Text(r.userId == me ? 'You' : r.name),
                            trailing: Text(r.emoji, style: const TextStyle(fontSize: 24)),
                          ),
                      ],
                      const SizedBox(height: 12),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
