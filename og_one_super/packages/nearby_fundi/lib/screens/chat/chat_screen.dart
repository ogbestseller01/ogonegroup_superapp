// lib/screens/chat/chat_screen.dart
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../config/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../models/chat_conversation.dart';
import '../../models/chat_message.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/chat_viewers.dart';
import '../../widgets/user_avatar.dart';
import 'chat_date_utils.dart';
import 'media_docs_screen.dart';
import 'starred_messages_screen.dart';
import 'widgets/chat_message_row.dart';
import 'widgets/forward_sheet.dart';
import 'widgets/message_actions.dart';
import 'widgets/message_info_sheet.dart';
import 'widgets/open_blog.dart';

const int _mb = 1024 * 1024;
const Set<String> _blocked = {
  'php', 'phtml', 'phar', 'exe', 'bat', 'cmd', 'com', 'sh', 'js',
  'html', 'htm', 'svg', 'jar', 'apk', 'msi', 'dll', 'vbs', 'ps1', 'py',
};
const Set<String> _imgExt = {'jpg', 'jpeg', 'png', 'webp', 'gif', 'heic', 'heif'};
const Set<String> _vidExt = {'mp4', 'mov', 'm4v', '3gp', 'webm', 'mkv'};
const List<String> _moreEmoji = [
  '👍', '👎', '❤️', '🔥', '😂', '😍', '😮', '😢', '😡', '🙏', '👏', '🎉',
  '💯', '✅', '❌', '🤝', '💪', '👌', '🤔', '😅', '😎', '🥰', '😭', '🙌',
];

class ChatScreen extends StatefulWidget {
  final ChatConversation conversation;
  const ChatScreen({super.key, required this.conversation});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _text = TextEditingController();
  final _focus = FocusNode();
  final _picker = ImagePicker();
  final _itemScroll = ItemScrollController();
  final _positions = ItemPositionsListener.create();
  final _showDown = ValueNotifier<bool>(false);
  late final ChatProvider _chat;

  bool _firstLoadDone = false;
  ReplyRef? _replyTo;
  int? _highlightId;
  Timer? _hlTimer;
  int _lastKey = 0;
  int _pinCursor = 0;
  DateTime _lastTyping = DateTime.fromMillisecondsSinceEpoch(0);
  final Set<int> _selected = {};

  bool get _selecting => _selected.isNotEmpty;
  int get _cid => widget.conversation.id;
  String get _peer => widget.conversation.otherParty.name;

  @override
  void initState() {
    super.initState();
    _chat = context.read<ChatProvider>();
    _chat.addListener(_onChat);
    _positions.itemPositions.addListener(_onPositions);
    _text.addListener(_onText);
    WidgetsBinding.instance.addPostFrameCallback((_) => _open());
  }

  @override
  void dispose() {
    _hlTimer?.cancel();
    _chat.removeListener(_onChat);
    _positions.itemPositions.removeListener(_onPositions);
    _text.removeListener(_onText);
    _chat.closeConversation();
    _text.dispose();
    _focus.dispose();
    _showDown.dispose();
    super.dispose();
  }

  Future<void> _open() async {
    try {
      await _chat.openConversation(_cid);
      await _chat.markConversationAsRead(_cid);
    } catch (e) {
      _snack('$e', error: true);
    }
    if (mounted) setState(() => _firstLoadDone = true);
  }

  void _snack(String m, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(m),
        backgroundColor: error ? AppTheme.error : AppTheme.success,
        behavior: SnackBarBehavior.floating,
      ));
  }

  void _onChat() {
    final list = _chat.messages;
    if (list.isEmpty || list.last.id == _lastKey) return;
    _lastKey = list.last.id;
    final mine = list.last.senderId == _chat.currentUser?.id;
    if (mine || !_showDown.value) _toBottom();
  }

  void _onPositions() {
    final pos = _positions.itemPositions.value;
    if (pos.isEmpty) return;
    final minI = pos.map((e) => e.index).reduce(math.min);
    final maxI = pos.map((e) => e.index).reduce(math.max);
    _showDown.value = minI > 1;
    if (_chat.hasMoreOlder && maxI >= _chat.messages.length - 3) _chat.loadOlder();
  }

  void _onText() {
    if (_text.text.trim().isEmpty) return;
    final now = DateTime.now();
    if (now.difference(_lastTyping) > const Duration(seconds: 3)) {
      _lastTyping = now;
      _chat.sendTyping(_cid);
    }
  }

  void _toBottom() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted && _itemScroll.isAttached) {
      _itemScroll.scrollTo(index: 0, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    }
  });

  void _startReply(ChatMessage m) {
    if (m.isDeleted) return;
    HapticFeedback.selectionClick();
    setState(() => _replyTo = ReplyRef.fromMessage(m));
    _focus.requestFocus();
  }

  ReplyRef? _takeReply() {
    final r = _replyTo;
    if (r != null) setState(() => _replyTo = null);
    return r;
  }

  Future<void> _jumpTo(int id) async {
    if (!mounted) return;
    if (!_chat.messages.any((m) => m.id == id)) {
      final ok = await _chat.loadUntil(id);
      if (!ok || !mounted) return _snack('The original message is no longer available.');
      await WidgetsBinding.instance.endOfFrame;
    }
    final list = _chat.messages;
    final idx = list.indexWhere((m) => m.id == id);
    if (idx == -1) return _snack('The original message is no longer available.');
    if (_itemScroll.isAttached) {
      _itemScroll.scrollTo(
        index: list.length - 1 - idx,
        alignment: 0.4,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
    _hlTimer?.cancel();
    setState(() => _highlightId = id);
    _hlTimer = Timer(const Duration(milliseconds: 1300), () {
      if (mounted) setState(() => _highlightId = null);
    });
  }

  void _sendText() {
    final t = _text.text.trim();
    if (t.isEmpty) return;
    _chat.send(conversationId: _cid, content: t, replyTo: _takeReply());
    _text.clear();
    _toBottom();
  }

  int _limit(String ext) => _imgExt.contains(ext) ? 5 * _mb : (_vidExt.contains(ext) ? 20 * _mb : 15 * _mb);

  Future<void> _sendFile(File f) async {
    final ext = p.extension(f.path).replaceFirst('.', '').toLowerCase();
    if (_blocked.contains(ext)) return _snack('This file type is not allowed.', error: true);
    final limit = _limit(ext);
    if (await f.length() > limit) return _snack('File too large. Max ${limit ~/ _mb} MB for this type.', error: true);
    _chat.send(conversationId: _cid, file: f, replyTo: _takeReply());
    _toBottom();
  }

  Future<void> _guard(Future<void> Function() job) async {
    try { await job(); } catch (e) { _snack('$e', error: true); }
  }

  Future<void> _camera() => _guard(() async {
    final x = await _picker.pickImage(source: ImageSource.camera, imageQuality: 70, maxWidth: 1600, maxHeight: 1600);
    if (x != null) await _sendFile(File(x.path));
  });

  Future<void> _gallery() => _guard(() async {
    for (final x in await _picker.pickMultiImage(imageQuality: 70, maxWidth: 1600, maxHeight: 1600)) {
      await _sendFile(File(x.path));
    }
  });

  Future<void> _video() => _guard(() async {
    final x = await _picker.pickVideo(source: ImageSource.gallery, maxDuration: const Duration(minutes: 1));
    if (x != null) await _sendFile(File(x.path));
  });

  Future<void> _document() => _guard(() async {
    final r = await FilePicker.platform.pickFiles(allowMultiple: false);
    final path = r?.files.first.path;
    if (path != null && path.isNotEmpty) await _sendFile(File(path));
  });

  void _attachSheet() {
    Widget item(IconData i, Color c, String l, VoidCallback f) => InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () { Navigator.pop(context); f(); },
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          CircleAvatar(radius: 28, backgroundColor: c.withValues(alpha: 0.14), child: Icon(i, color: c, size: 26)),
          const SizedBox(height: 6),
          Text(l, style: const TextStyle(fontSize: 12.5)),
        ]),
      ),
    );
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      constraints: const BoxConstraints(maxWidth: 600),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              item(Icons.photo_camera_rounded, Colors.teal, 'Camera', _camera),
              item(Icons.photo_rounded, Colors.purple, 'Photos', _gallery),
              item(Icons.videocam_rounded, Colors.red, 'Video', _video),
              item(Icons.insert_drive_file_rounded, Colors.blue, 'Document', _document),
            ]),
            const SizedBox(height: 10),
            Text('Photos 5 MB · Videos 20 MB · Files 15 MB',
                style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor)),
          ]),
        ),
      ),
    );
  }

  Future<void> _react(ChatMessage m, String e) => _guard(() async {
    HapticFeedback.selectionClick();
    await _chat.react(m.id, m.myReaction == e ? null : e);
  });

  void _moreEmojiSheet(ChatMessage m) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    constraints: const BoxConstraints(maxWidth: 600),
    builder: (s) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        child: Wrap(alignment: WrapAlignment.center, spacing: 6, runSpacing: 6, children: [
          for (final e in _moreEmoji)
            InkWell(
              customBorder: const CircleBorder(),
              onTap: () { Navigator.pop(s); _react(m, e); },
              child: Padding(padding: const EdgeInsets.all(8), child: Text(e, style: const TextStyle(fontSize: 30))),
            ),
        ]),
      ),
    ),
  );

  Future<void> _togglePin(ChatMessage m) => _guard(() async {
    final now = await _chat.togglePin(m.id);
    _snack(now ? 'Message pinned' : 'Message unpinned');
  });

  Future<void> _toggleStar(ChatMessage m) => _guard(() async {
    final now = await _chat.toggleStar(m.id);
    _snack(now ? 'Starred' : 'Removed from starred');
  });

  Future<void> _copy(String t) async {
    await Clipboard.setData(ClipboardData(text: t));
    _snack('Copied');
  }

  Future<void> _forward(List<int> ids) async {
    if (await showForwardSheet(context, ids)) {
      _clear();
      _snack('Forwarded');
    }
  }

  void _menu(ChatMessage m, Offset at) => showMessageMenu(
    context,
    anchor: at,
    message: m,
    actions: MessageMenuActions(
      onReact: (e) => _react(m, e),
      onMoreEmoji: () => _moreEmojiSheet(m),
      onReply: () => _startReply(m),
      onPin: () => _togglePin(m),
      onCopy: () => _copy((m.content ?? '').trim()),
      onForward: () => _forward([m.id]),
      onStar: () => _toggleStar(m),
      onInfo: () => showMessageInfo(context, m),
      onSelect: () => _toggleSelect(m),
      onDelete: () => _delete([m]),
      onSave: () => saveChatFile(context, m),
    ),
  );

  void _toggleSelect(ChatMessage m) {
    if (m.isPending) return;
    HapticFeedback.selectionClick();
    setState(() { if (!_selected.add(m.id)) _selected.remove(m.id); });
  }

  void _clear() {
    if (_selected.isNotEmpty) setState(_selected.clear);
  }

  List<ChatMessage> get _sel => _chat.messages.where((m) => _selected.contains(m.id)).toList();

  Future<void> _delete(List<ChatMessage> msgs) async {
    if (msgs.isEmpty) return;
    final me = _chat.currentUser?.id;
    final pendingOnly = msgs.every((m) => m.isPending);
    if (pendingOnly) {
      for (final m in msgs) { _chat.discardPending(m.id); }
      return _clear();
    }
    final real = msgs.where((m) => !m.isPending).toList();
    final everyoneOk = real.every((m) => m.senderId == me && m.canDeleteForEveryone);

    final choice = await showDialog<String>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(real.length == 1 ? 'Delete message?' : 'Delete ${real.length} messages?'),
        contentPadding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (everyoneOk)
            ListTile(
              dense: true,
              leading: const Icon(Icons.delete_forever_outlined, color: AppTheme.error),
              title: const Text('Delete for everyone'),
              subtitle: const Text('Removed for both of you'),
              onTap: () => Navigator.pop(d, 'everyone'),
            ),
          ListTile(
            dense: true,
            leading: const Icon(Icons.delete_outline_rounded),
            title: const Text('Delete for me'),
            subtitle: const Text('Only removed on this phone'),
            onTap: () => Navigator.pop(d, 'me'),
          ),
        ]),
        actions: [TextButton(onPressed: () => Navigator.pop(d), child: const Text('Cancel'))],
      ),
    );
    if (choice == null) return;

    await _guard(() async {
      final done = await _chat.deleteMessages(real.map((m) => m.id).toList(), forEveryone: choice == 'everyone');
      if (done.length < real.length) {
        _snack('${real.length - done.length} message(s) could not be deleted for everyone.', error: true);
      } else {
        _snack('Deleted');
      }
    });
    _clear();
  }

  PreferredSizeWidget _selectionBar(bool dark) {
    final msgs = _sel;
    final allStarred = msgs.isNotEmpty && msgs.every((m) => m.isStarred);
    final hasText = msgs.any((m) => (m.content ?? '').trim().isNotEmpty);

    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: dark ? const Color(0xFF1F2C34) : AppTheme.primary,
      foregroundColor: Colors.white,
      elevation: 2, // Added elevation so it doesn't visually merge with the background
      leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: _clear
      ),
      title: Text(
          '${_selected.length}',
          style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white)
      ),
      actions: [
        if (msgs.length == 1)
          IconButton(
              icon: const Icon(Icons.reply_rounded, color: Colors.white),
              onPressed: () {
                final m = msgs.first;
                _clear();
                _startReply(m);
              }
          ),
        if (hasText)
          IconButton(
              icon: const Icon(Icons.content_copy_outlined, color: Colors.white),
              onPressed: () {
                _copy(msgs.map((m) => (m.content ?? '').trim()).where((t) => t.isNotEmpty).join('\n'));
                _clear();
              }
          ),
        IconButton(
          icon: Icon(allStarred ? Icons.star_rounded : Icons.star_border_rounded, color: Colors.white),
          onPressed: () async {
            await _guard(() async {
              for (final m in msgs) { if (m.isStarred == allStarred) await _chat.toggleStar(m.id); }
            });
            _clear();
          },
        ),
        IconButton(
            icon: const Icon(Icons.forward_rounded, color: Colors.white),
            onPressed: () => _forward(msgs.map((m) => m.id).toList())
        ),
        IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.white),
            onPressed: () => _delete(msgs)
        ),
      ],
    );
  }

  PreferredSizeWidget _normalBar(bool dark) {
    final c = widget.conversation;
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: dark ? const Color(0xFF1F2C34) : AppTheme.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      titleSpacing: 0,
      leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Colors.white),
          onPressed: () => Navigator.maybePop(context)
      ),
      title: Row(children: [
        UserAvatar(
          name: _peer,
          url: c.otherParty.avatar,
          radius: 18,
          hasStatus: c.hasNewPost,
          onStatusTap: c.technicianId == null ? null : () => openTechnicianBlog(context, c.technicianId!),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_peer, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 17, color: Colors.white)),
            ValueListenableBuilder<bool>(
              valueListenable: _chat.peerTyping,
              builder: (_, typing, __) => AnimatedSize(
                duration: const Duration(milliseconds: 150),
                child: typing
                    ? const Text('typing…', style: TextStyle(color: Colors.white70, fontSize: 12.5))
                    : const SizedBox.shrink(),
              ),
            ),
          ]),
        ),
      ]),
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
          onSelected: (v) async {
            if (v == 'media') {
              final id = await Navigator.push<int>(
                  context, MaterialPageRoute(builder: (_) => MediaDocsScreen(conversationId: _cid, peerName: _peer)));
              if (id != null) _jumpTo(id);
            } else if (v == 'starred') {
              final id = await Navigator.push<int>(context,
                  MaterialPageRoute(builder: (_) => StarredMessagesScreen(conversationId: _cid, peerName: _peer)));
              if (id != null) _jumpTo(id);
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'media', child: Row(children: [Icon(Icons.perm_media_outlined), SizedBox(width: 10), Text('Media, links & docs')])),
            PopupMenuItem(value: 'starred', child: Row(children: [Icon(Icons.star_border_rounded), SizedBox(width: 10), Text('Starred messages')])),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final bg = dark ? theme.scaffoldBackgroundColor : const Color(0xFFEFEAE2).withValues(alpha: 0.55);

    return PopScope(
      canPop: !_selecting,
      onPopInvokedWithResult: (didPop, _) { if (!didPop) _clear(); },
      child: Scaffold(
        backgroundColor: bg,
        // Cleanly swaps the bar based on selection mode
        appBar: _selecting ? _selectionBar(dark) : _normalBar(dark),
        body: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusScope.of(context).unfocus(),
          child: Column(children: [
            ListenableBuilder(listenable: _chat, builder: (_, __) => _pinnedBar(dark)),
            Expanded(
              child: Stack(children: [
                _messages(context),
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: ValueListenableBuilder<bool>(
                    valueListenable: _showDown,
                    builder: (_, show, __) => AnimatedScale(
                      scale: show ? 1 : 0,
                      duration: const Duration(milliseconds: 150),
                      child: FloatingActionButton.small(
                        heroTag: 'chat_down',
                        backgroundColor: dark ? const Color(0xFF2A3942) : Colors.white,
                        foregroundColor: AppTheme.primary,
                        elevation: 2,
                        onPressed: _toBottom,
                        child: const Icon(Icons.keyboard_arrow_down_rounded, size: 28),
                      ),
                    ),
                  ),
                ),
              ]),
            ),
            if (!_selecting) ...[
              AnimatedSize(
                duration: const Duration(milliseconds: 160),
                alignment: Alignment.bottomCenter,
                child: _replyTo == null ? const SizedBox(width: double.infinity) : _replyBar(dark),
              ),
              _input(dark),
            ] else
              const SafeArea(top: false, child: SizedBox(height: 4)),
          ]),
        ),
      ),
    );
  }

  Widget _pinnedBar(bool dark) {
    final pins = _chat.pins;
    if (pins.isEmpty) return const SizedBox.shrink();
    final i = _pinCursor % pins.length;
    final pin = pins[i];
    return Material(
      color: dark ? const Color(0xFF1F2C34) : Colors.white,
      elevation: 1,
      child: InkWell(
        onTap: () {
          _jumpTo(pin.id);
          setState(() => _pinCursor = (i + 1) % pins.length);
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
          child: Row(children: [
            Container(width: 3, height: 34, decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 10),
            const Icon(Icons.push_pin_rounded, size: 18, color: AppTheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(pins.length > 1 ? 'Pinned ${i + 1} of ${pins.length}' : 'Pinned message',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.primary)),
                Text(pin.getDisplayMessage(), maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13.5, color: dark ? Colors.white70 : Colors.black87)),
              ]),
            ),
            IconButton(icon: const Icon(Icons.close_rounded, size: 20), onPressed: () => _togglePin(pin)),
          ]),
        ),
      ),
    );
  }

  Widget _replyBar(bool dark) {
    final r = _replyTo!;
    final author = r.senderId == _chat.currentUser?.id ? 'You' : ((r.senderName).isNotEmpty ? r.senderName : _peer);
    return Container(
      width: double.infinity,
      color: dark ? const Color(0xFF1F2C34) : const Color(0xFFECEFF1),
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      child: Row(children: [
        Container(width: 4, height: 42, decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(author, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.primary)),
            const SizedBox(height: 2),
            Text(r.snippet, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: dark ? Colors.white70 : Colors.black87)),
          ]),
        ),
        if (r.isImage)
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                width: 42,
                height: 42,
                child: CachedNetworkImage(
                  imageUrl: ChatFile.urlFor(r.id),
                  httpHeaders: _chat.authHeaders,
                  cacheKey: 'chat_${r.id}',
                  memCacheWidth: 120,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => const Icon(Icons.image_outlined),
                ),
              ),
            ),
          ),
        IconButton(icon: const Icon(Icons.close_rounded, size: 22), onPressed: () => setState(() => _replyTo = null)),
      ]),
    );
  }

  bool _sameDay(DateTime? a, DateTime? b) =>
      a != null && b != null && a.year == b.year && a.month == b.month && a.day == b.day;

  Widget _messages(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Consumer<ChatProvider>(builder: (context, provider, _) {
      final messages = provider.messages;
      if (!_firstLoadDone && messages.isEmpty) {
        return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
      }
      if (messages.isEmpty) {
        return Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            UserAvatar(name: _peer, url: widget.conversation.otherParty.avatar, radius: 42),
            const SizedBox(height: 14),
            Text(_peer, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: dark ? Colors.white70 : Colors.black87)),
            const SizedBox(height: 4),
            Text('Say hello to start the conversation', style: TextStyle(color: Theme.of(context).hintColor)),
          ]),
        );
      }

      final myId = provider.currentUser?.id;
      final loader = provider.hasMoreOlder;

      return ScrollablePositionedList.builder(
        itemScrollController: _itemScroll,
        itemPositionsListener: _positions,
        reverse: true,
        padding: const EdgeInsets.symmetric(vertical: 10),
        itemCount: messages.length + (loader ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == messages.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))),
            );
          }
          final idx = messages.length - 1 - index;
          final m = messages[idx];
          final older = idx > 0 ? messages[idx - 1] : null;
          final showDay = m.time != null && (older == null || !_sameDay(older.time, m.time));

          return Column(mainAxisSize: MainAxisSize.min, children: [
            if (showDay) _DayChip(label: chatDayLabel(context, m.time!)),
            ChatMessageRow(
              key: ValueKey(m.id),
              message: m,
              isMine: m.senderId == myId,
              myId: myId,
              peerName: _peer,
              highlighted: _highlightId == m.id,
              selecting: _selecting,
              selected: _selected.contains(m.id),
              authHeaders: provider.authHeaders,
              onToggleSelect: () => _toggleSelect(m),
              onOpenMenu: (at) => _menu(m, at),
              onReply: () => _startReply(m),
              onOpen: () => openChatFile(context, m),
              onSave: () => saveChatFile(context, m),
              onRetry: () => _chat.retry(m.id),
              onTapReactions: () => showMessageInfo(context, m),
              onTapReply: _jumpTo,
            ),
          ]);
        },
      );
    });
  }

  Widget _input(bool dark) {
    return SafeArea(
      top: false,
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 130),
              decoration: BoxDecoration(
                color: dark ? const Color(0xFF2A3942) : Colors.white,
                borderRadius: BorderRadius.circular(26),
              ),
              child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                IconButton(
                  icon: Icon(Icons.attach_file_rounded, color: dark ? Colors.white70 : AppTheme.primary),
                  onPressed: _attachSheet,
                ),
                Expanded(
                  child: TextField(
                    controller: _text,
                    focusNode: _focus,
                    minLines: 1,
                    maxLines: 5,
                    maxLength: 2000,
                    textCapitalization: TextCapitalization.sentences,
                    style: TextStyle(fontSize: 16, color: dark ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: _replyTo != null ? 'Reply…' : 'Message',
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.photo_camera_outlined, color: dark ? Colors.white70 : Colors.grey.shade700),
                  onPressed: _camera,
                ),
              ]),
            ),
          ),
          const SizedBox(width: 6),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _text,
            builder: (_, v, __) {
              final has = v.text.trim().isNotEmpty;
              return Material(
                color: has ? AppTheme.primary : (dark ? const Color(0xFF2A3942) : Colors.grey.shade400),
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: has ? _sendText : null,
                  customBorder: const CircleBorder(),
                  child: const SizedBox(width: 48, height: 48, child: Center(child: Icon(Icons.send_rounded, color: Colors.white, size: 22))),
                ),
              );
            },
          ),
        ]),
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  final String label;
  const _DayChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: dark ? const Color(0xFF1F2C34) : Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: dark ? Colors.white70 : Colors.black54)),
        ),
      ),
    );
  }
}