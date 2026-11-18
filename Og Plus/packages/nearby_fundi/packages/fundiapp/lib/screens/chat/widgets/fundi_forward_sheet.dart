// lib/screens/fundi/chat/widgets/fundi_forward_sheet.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../config/app_theme.dart';
import '../../../../providers/chat_provider.dart';

Future<bool> showFundiForwardSheet(
    BuildContext context, List<int> messageIds) async {
  final ok = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    constraints: const BoxConstraints(maxWidth: 600),
    builder: (_) => _FundiForwardSheet(messageIds: messageIds),
  );
  return ok == true;
}

class _FundiForwardSheet extends StatefulWidget {
  final List<int> messageIds;
  const _FundiForwardSheet({required this.messageIds});

  @override
  State<_FundiForwardSheet> createState() => _FundiForwardSheetState();
}

class _FundiForwardSheetState extends State<_FundiForwardSheet> {
  static const int _maxTargets = 5;

  final Set<int> _picked = {};
  String _q = '';
  bool _sending = false;

  Future<void> _send() async {
    if (_picked.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await context.read<ChatProvider>().forward(
        messageIds: widget.messageIds,
        conversationIds: _picked.toList(),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: AppTheme.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final q = _q.toLowerCase();

    final list = chat.conversations
        .where((c) => q.isEmpty || c.otherParty.name.toLowerCase().contains(q))
        .toList();

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(children: [
                Expanded(
                  child: Text(
                    widget.messageIds.length == 1
                        ? 'Forward message to…'
                        : 'Forward ${widget.messageIds.length} messages to…',
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                ),
                if (_picked.isNotEmpty)
                  Text('${_picked.length}/$_maxTargets',
                      style: TextStyle(color: theme.hintColor)),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: TextField(
                onChanged: (v) => setState(() => _q = v.trim()),
                decoration: InputDecoration(
                  hintText: 'Search',
                  prefixIcon: const Icon(Icons.search_rounded),
                  isDense: true,
                  filled: true,
                  fillColor: isDark
                      ? const Color(0xFF2A3942)
                      : const Color(0xFFF0F2F5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: list.isEmpty
                  ? Center(
                child: Text('No chats to forward to',
                    style: TextStyle(color: theme.hintColor)),
              )
                  : ListView.builder(
                itemCount: list.length,
                itemBuilder: (_, i) {
                  final c = list[i];
                  final name = c.otherParty.name;
                  final on = _picked.contains(c.id);
                  return CheckboxListTile(
                    value: on,
                    activeColor: AppTheme.primary,
                    controlAffinity: ListTileControlAffinity.trailing,
                    secondary: CircleAvatar(
                      backgroundColor:
                      AppTheme.primary.withValues(alpha: 0.15),
                      child: Text(
                        name.isNotEmpty
                            ? name[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                            color: isDark
                                ? Colors.white
                                : AppTheme.primary,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                    title: Text(name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    onChanged: (v) {
                      setState(() {
                        if (v == true) {
                          if (_picked.length < _maxTargets) {
                            _picked.add(c.id);
                          }
                        } else {
                          _picked.remove(c.id);
                        }
                      });
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24)),
                  ),
                  onPressed:
                  _picked.isEmpty || _sending ? null : _send,
                  icon: _sending
                      ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.send_rounded, size: 20),
                  label: Text(_sending ? 'Sending…' : 'Send'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}