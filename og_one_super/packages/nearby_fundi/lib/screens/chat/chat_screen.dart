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
import '../../widgets/swipe_to_reply.dart';
import 'starred_messages_screen.dart';
import 'widgets/forward_sheet.dart';
import 'widgets/message_bubble.dart';
import 'widgets/message_info_sheet.dart';

const int _mb = 1024 * 1024;
const int _maxImageBytes = 5 * _mb;
const int _maxVideoBytes = 20 * _mb;
const int _maxFileBytes = 15 * _mb;

const Set<String> _blockedExtensions = {
  'php', 'phtml', 'phar', 'exe', 'bat', 'cmd', 'com', 'sh', 'js',
  'html', 'htm', 'svg', 'jar', 'apk', 'msi', 'dll', 'vbs', 'ps1', 'py',
};
const Set<String> _imageExtensions = {'jpg', 'jpeg', 'png', 'webp', 'gif', 'heic', 'heif'};
const Set<String> _videoExtensions = {'mp4', 'mov', 'm4v', '3gp', 'webm', 'mkv'};

const List<String> _quickReactions = ['👍', '❤️', '😂', '😮', '😢', '🙏'];
const List<String> _moreReactions = [
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
  final TextEditingController _text = TextEditingController();
  final FocusNode _focus = FocusNode();
  final ImagePicker _picker = ImagePicker();
  final ItemScrollController _itemScroll = ItemScrollController();
  final ItemPositionsListener _positions = ItemPositionsListener.create();
  final ValueNotifier<bool> _showDown = ValueNotifier<bool>(false);

  late final ChatProvider _chat;

  bool _firstLoadDone = false;
  ReplyRef? _replyTo;
  int? _highlightId;
  Timer? _highlightTimer;
  int _lastKey = 0;
  int _pinCursor = 0;
  DateTime _lastTyping = DateTime.fromMillisecondsSinceEpoch(0);

  /// Selection mode ("Select messages"): ids of selected messages.
  final Set<int> _selected = {};
  bool get _selecting => _selected.isNotEmpty;

  int get _conversationId => widget.conversation.id;
  String get _peerName => widget.conversation.otherParty.name;

  @override
  void initState() {
    super.initState();
    _chat = context.read<ChatProvider>();
    _chat.addListener(_onChat);
    _positions.itemPositions.addListener(_onPositions);
    _text.addListener(_onTextChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _open());
  }

  @override
  void dispose() {
    _highlightTimer?.cancel();
    _chat.removeListener(_onChat);
    _positions.itemPositions.removeListener(_onPositions);
    _text.removeListener(_onTextChanged);
    _chat.closeConversation();
    _text.dispose();
    _focus.dispose();
    _showDown.dispose();
    super.dispose();
  }

  Future<void> _open() async {
    if (!mounted) return;
    try {
      await _chat.openConversation(_conversationId);
      await _chat.markConversationAsRead(_conversationId);
    } catch (e) {
      _snack('$e', error: true);
    }
    if (mounted) setState(() => _firstLoadDone = true);
  }

  void _snack(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: error ? AppTheme.error : AppTheme.success,
        behavior: SnackBarBehavior.floating,
      ));
  }

  void _onChat() {
    final list = _chat.messages;
    if (list.isEmpty) return;
    final last = list.last;
    if (last.id == _lastKey) return;
    _lastKey = last.id;
    final mine = last.senderId == _chat.currentUser?.id;
    if (mine || !_showDown.value) _scrollToBottom();
  }

  void _onPositions() {
    final pos = _positions.itemPositions.value;
    if (pos.isEmpty) return;
    final minI = pos.map((e) => e.index).reduce(math.min);
    final maxI = pos.map((e) => e.index).reduce(math.max);

    _showDown.value = minI > 1;
    if (_chat.hasMoreOlder && maxI >= _chat.messages.length - 3) {
      _chat.loadOlder();
    }
  }

  void _onTextChanged() {
    if (_text.text.trim().isEmpty) return;
    final now = DateTime.now();
    if (now.difference(_lastTyping) > const Duration(seconds: 3)) {
      _lastTyping = now;
      _chat.sendTyping(_conversationId);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_itemScroll.isAttached) return;
      _itemScroll.scrollTo(
        index: 0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  // ── Reply ──────────────────────────────────────────────────────────────

  void _startReply(ChatMessage m) {
    HapticFeedback.selectionClick();
    setState(() => _replyTo = ReplyRef.fromMessage(m));
    _focus.requestFocus();
  }

  void _cancelReply() => setState(() => _replyTo = null);

  ReplyRef? _takeReply() {
    final r = _replyTo;
    if (r != null) setState(() => _replyTo = null);
    return r;
  }

  /// Tap on a quoted message / pinned bar / starred item: scroll to it and flash it.
  Future<void> _jumpTo(int id) async {
    if (!mounted) return;

    if (!_chat.messages.any((m) => m.id == id)) {
      final ok = await _chat.loadUntil(id);
      if (!ok || !mounted) {
        _snack('The original message is no longer available.');
        return;
      }
      await WidgetsBinding.instance.endOfFrame; // let the list rebuild first
    }

    final list = _chat.messages;
    final idx = list.indexWhere((m) => m.id == id);
    if (idx == -1) {
      _snack('The original message is no longer available.');
      return;
    }
    if (_itemScroll.isAttached) {
      _itemScroll.scrollTo(
        index: list.length - 1 - idx,
        alignment: 0.4,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
    _flash(id);
  }

  void _flash(int id) {
    _highlightTimer?.cancel();
    setState(() => _highlightId = id);
    _highlightTimer = Timer(const Duration(milliseconds: 1300), () {
      if (mounted) setState(() => _highlightId = null);
    });
  }

  // ── Sending ────────────────────────────────────────────────────────────

  void _sendText() {
    final text = _text.text.trim();
    if (text.isEmpty) return;
    _chat.send(
      conversationId: _conversationId,
      content: text,
      replyTo: _takeReply(),
    );
    _text.clear();
    _scrollToBottom();
  }

  int _limitFor(String ext) {
    if (_imageExtensions.contains(ext)) return _maxImageBytes;
    if (_videoExtensions.contains(ext)) return _maxVideoBytes;
    return _maxFileBytes;
  }

  Future<void> _sendFile(File file) async {
    final ext = p.extension(file.path).replaceFirst('.', '').toLowerCase();
    if (_blockedExtensions.contains(ext)) {
      _snack('This file type is not allowed.', error: true);
      return;
    }
    final size = await file.length();
    final limit = _limitFor(ext);
    if (size > limit) {
      _snack('File is too large. Maximum for this type is ${limit ~/ _mb} MB.',
          error: true);
      return;
    }
    _chat.send(
      conversationId: _conversationId,
      file: file,
      replyTo: _takeReply(),
    );
    _scrollToBottom();
  }

  Future<void> _pickCamera() async {
    try {
      final x = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
        maxWidth: 1600,
        maxHeight: 1600,
      );
      if (x != null) await _sendFile(File(x.path));
    } catch (e) {
      _snack('$e', error: true);
    }
  }

  Future<void> _pickGallery() async {
    try {
      final list = await _picker.pickMultiImage(
        imageQuality: 70,
        maxWidth: 1600,
        maxHeight: 1600,
      );
      for (final x in list) {
        await _sendFile(File(x.path));
      }
    } catch (e) {
      _snack('$e', error: true);
    }
  }

  Future<void> _pickVideo() async {
    try {
      final x = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 1),
      );
      if (x != null) await _sendFile(File(x.path));
    } catch (e) {
      _snack('$e', error: true);
    }
  }

  Future<void> _pickDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(allowMultiple: false);
      final path = result?.files.first.path;
      if (path != null && path.isNotEmpty) await _sendFile(File(path));
    } catch (e) {
      _snack('$e', error: true);
    }
  }

  void _showAttachSheet() {
    Widget item(IconData icon, Color color, String label, VoidCallback onTap) {
      return InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.pop(context);
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: color.withValues(alpha: 0.14),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(height: 6),
              Text(label, style: const TextStyle(fontSize: 12.5)),
            ],
          ),
        ),
      );
    }

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      constraints: const BoxConstraints(maxWidth: 600),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  item(Icons.photo_camera_rounded, Colors.teal, 'Camera', _pickCamera),
                  item(Icons.photo_rounded, Colors.purple, 'Photos', _pickGallery),
                  item(Icons.videocam_rounded, Colors.red, 'Video', _pickVideo),
                  item(Icons.insert_drive_file_rounded, Colors.blue, 'Document', _pickDocument),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Photos 5 MB · Videos 20 MB · Files 15 MB',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).hintColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Actions: react / star / pin / forward / info / copy / delete ───────

  Future<void> _react(ChatMessage m, String emoji) async {
    final next = m.myReaction == emoji ? null : emoji; // same emoji again = remove
    HapticFeedback.selectionClick();
    try {
      await _chat.react(m.id, next);
    } catch (e) {
      _snack('$e', error: true);
    }
  }

  Future<void> _toggleStar(ChatMessage m) async {
    try {
      final now = await _chat.toggleStar(m.id);
      _snack(now ? 'Starred' : 'Removed from starred');
    } catch (e) {
      _snack('$e', error: true);
    }
  }

  Future<void> _togglePin(ChatMessage m) async {
    try {
      final now = await _chat.togglePin(m.id);
      _snack(now ? 'Message pinned' : 'Message unpinned');
    } catch (e) {
      _snack('$e', error: true); // e.g. "You can pin up to 3 messages"
    }
  }

  Future<void> _forward(List<int> ids) async {
    final ok = await showForwardSheet(context, ids);
    if (ok) {
      _clearSelection();
      _snack('Forwarded');
    }
  }

  Future<void> _copyText(String text) async {
    final l10n = AppLocalizations.of(context)!;
    await Clipboard.setData(ClipboardData(text: text));
    _snack(l10n.messageCopied);
  }

  void _pickMoreEmoji(ChatMessage m) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      constraints: const BoxConstraints(maxWidth: 600),
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final e in _moreReactions)
                InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () {
                    Navigator.pop(sheet);
                    _react(m, e);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(e, style: const TextStyle(fontSize: 30)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openStarred() async {
    final id = await Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (_) => StarredMessagesScreen(
          conversationId: _conversationId,
          peerName: _peerName,
        ),
      ),
    );
    if (id != null) _jumpTo(id);
  }

  // ── Selection mode ─────────────────────────────────────────────────────

  void _toggleSelect(ChatMessage m) {
    if (m.isPending) return;
    HapticFeedback.selectionClick();
    setState(() {
      if (!_selected.add(m.id)) _selected.remove(m.id);
    });
  }

  void _clearSelection() {
    if (_selected.isEmpty) return;
    setState(_selected.clear);
  }

  List<ChatMessage> get _selectedMessages =>
      _chat.messages.where((m) => _selected.contains(m.id)).toList();

  Future<void> _copySelected() async {
    final text = _selectedMessages
        .map((m) => (m.content ?? '').trim())
        .where((t) => t.isNotEmpty)
        .join('\n');
    if (text.isEmpty) {
      _snack('Nothing to copy');
      return;
    }
    await _copyText(text);
    _clearSelection();
  }

  Future<void> _starSelected() async {
    final msgs = _selectedMessages;
    final allStarred = msgs.isNotEmpty && msgs.every((m) => m.isStarred);
    try {
      for (final m in msgs) {
        if (m.isStarred == allStarred) await _chat.toggleStar(m.id);
      }
      _snack(allStarred ? 'Removed from starred' : 'Starred');
    } catch (e) {
      _snack('$e', error: true);
    }
    _clearSelection();
  }

  Future<void> _deleteSelected() async {
    final msgs = _selectedMessages;
    final me = _chat.currentUser?.id;
    if (msgs.isEmpty || msgs.any((m) => m.senderId != me)) {
      _snack('You can only delete your own messages.', error: true);
      return;
    }
    final ok = await _confirmDeleteDialog(count: msgs.length);
    if (ok != true) return;
    try {
      for (final m in msgs) {
        await _chat.deleteMessage(m.id);
      }
      _snack('Deleted');
    } catch (e) {
      _snack('$e', error: true);
    }
    _clearSelection();
  }

  Future<bool?> _confirmDeleteDialog({int count = 1}) {
    final l10n = AppLocalizations.of(context)!;
    return showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(count == 1 ? l10n.deleteMessage : 'Delete $count messages?'),
        content: Text(l10n.areYouSureDeleteMessage),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: Text(l10n.cancel)),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(d, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }

  // ── Long-press menu ────────────────────────────────────────────────────

  void _showMessageOptions(ChatMessage m, bool isMine) {
    final l10n = AppLocalizations.of(context)!;
    final text = (m.content ?? '').trim();
    final file = m.file;
    final kind = file?.kind;
    final isMedia = kind == ChatFileKind.image || kind == ChatFileKind.video;
    final failed = m.sendState == SendState.failed;

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      constraints: const BoxConstraints(maxWidth: 600),
      builder: (sheet) {
        Widget tile(IconData icon, String title, VoidCallback? onTap, {Color? color}) {
          return ListTile(
            leading: Icon(icon, color: color),
            title: Text(title, style: TextStyle(color: color)),
            onTap: onTap == null
                ? null
                : () {
              Navigator.pop(sheet);
              onTap();
            },
          );
        }

        Widget reactionRow() {
          return Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (final e in _quickReactions)
                  InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () {
                      Navigator.pop(sheet);
                      _react(m, e);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: m.myReaction == e
                            ? AppTheme.primary.withValues(alpha: 0.18)
                            : null,
                      ),
                      child: Text(e, style: const TextStyle(fontSize: 28)),
                    ),
                  ),
                InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () {
                    Navigator.pop(sheet);
                    _pickMoreEmoji(m);
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(7),
                    child: Icon(Icons.add_circle_outline_rounded, size: 30),
                  ),
                ),
              ],
            ),
          );
        }

        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (failed) ...[
                  tile(Icons.refresh_rounded, 'Retry', () => _chat.retry(m.id)),
                  tile(Icons.delete_outline, l10n.delete,
                          () => _chat.discardPending(m.id), color: AppTheme.error),
                ] else ...[
                  reactionRow(),
                  const Divider(height: 1),
                  tile(Icons.reply_rounded, 'Reply', () => _startReply(m)),
                  if (text.isNotEmpty)
                    tile(Icons.content_copy_outlined, l10n.copy, () => _copyText(text)),
                  tile(Icons.forward_rounded, 'Forward', () => _forward([m.id])),
                  tile(
                    m.isStarred ? Icons.star_rounded : Icons.star_border_rounded,
                    m.isStarred ? 'Unstar' : 'Star',
                        () => _toggleStar(m),
                  ),
                  tile(
                    m.isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                    m.isPinned ? 'Unpin' : 'Pin',
                        () => _togglePin(m),
                  ),
                  tile(Icons.info_outline_rounded, 'Info', () => showMessageInfo(context, m)),

                  if (file != null) ...[
                    const Divider(height: 1),
                    tile(Icons.visibility_outlined, 'View', () => openChatFile(context, m)),
                    tile(
                      isMedia ? Icons.download_rounded : Icons.save_alt_rounded,
                      isMedia ? 'Save to Downloads' : 'Save as...',
                          () => saveChatFile(context, m),
                    ),
                    if (isMedia)
                      tile(Icons.share_rounded, 'Share', () => shareChatFile(context, m)),
                  ],

                  if (isMine) ...[
                    const Divider(height: 1),
                    tile(Icons.delete_outline, 'Delete', () => _confirmDelete(m),
                        color: AppTheme.error),
                  ],

                  const Divider(height: 1),
                  tile(Icons.check_circle_outline_rounded, 'Select messages',
                          () => _toggleSelect(m)),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(ChatMessage message) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await _confirmDeleteDialog();
    if (ok != true) return;
    try {
      await _chat.deleteMessage(message.id);
      _snack(l10n.messageDeleted);
    } catch (e) {
      _snack('$e', error: true);
    }
  }

  // ── UI ─────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildSelectionBar(bool isDark) {
    final msgs = _selectedMessages;
    final allStarred = msgs.isNotEmpty && msgs.every((m) => m.isStarred);
    final hasText = msgs.any((m) => (m.content ?? '').trim().isNotEmpty);
    final me = _chat.currentUser?.id;
    final canDelete = msgs.isNotEmpty && msgs.every((m) => m.senderId == me);

    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: isDark ? const Color(0xFF1F2C34) : AppTheme.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      leading: IconButton(
        icon: const Icon(Icons.close_rounded, color: Colors.white),
        onPressed: _clearSelection,
      ),
      title: Text('${_selected.length}',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      actions: [
        if (_selected.length == 1)
          IconButton(
            tooltip: 'Reply',
            icon: const Icon(Icons.reply_rounded, color: Colors.white),
            onPressed: () {
              final m = msgs.first;
              _clearSelection();
              _startReply(m);
            },
          ),
        if (hasText)
          IconButton(
            tooltip: 'Copy',
            icon: const Icon(Icons.content_copy_outlined, color: Colors.white),
            onPressed: _copySelected,
          ),
        IconButton(
          tooltip: allStarred ? 'Unstar' : 'Star',
          icon: Icon(allStarred ? Icons.star_rounded : Icons.star_border_rounded,
              color: Colors.white),
          onPressed: _starSelected,
        ),
        IconButton(
          tooltip: 'Forward',
          icon: const Icon(Icons.forward_rounded, color: Colors.white),
          onPressed: () => _forward(msgs.map((m) => m.id).toList()),
        ),
        if (canDelete)
          IconButton(
            tooltip: 'Delete',
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            onPressed: _deleteSelected,
          ),
      ],
    );
  }

  PreferredSizeWidget _buildNormalBar(bool isDark) {
    final name = _peerName;
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: isDark ? const Color(0xFF1F2C34) : AppTheme.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      titleSpacing: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
        onPressed: () => Navigator.maybePop(context),
      ),
      title: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.white.withValues(alpha: 0.18),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600, fontSize: 17),
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: _chat.peerTyping,
                  builder: (_, typing, __) => AnimatedSize(
                    duration: const Duration(milliseconds: 150),
                    child: typing
                        ? const Text('typing…',
                        style: TextStyle(color: Colors.white70, fontSize: 12.5))
                        : const SizedBox.shrink(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
          onSelected: (v) {
            if (v == 'starred') _openStarred();
          },
          itemBuilder: (_) => const [
            PopupMenuItem(
              value: 'starred',
              child: Row(children: [
                Icon(Icons.star_border_rounded),
                SizedBox(width: 10),
                Text('Starred messages'),
              ]),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = Color.alphaBlend(
      AppTheme.primary.withValues(alpha: isDark ? 0.06 : 0.05),
      theme.scaffoldBackgroundColor,
    );

    return PopScope(
      canPop: !_selecting,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _clearSelection(); // back closes selection first
      },
      child: Scaffold(
        backgroundColor: bg,
        appBar: _selecting ? _buildSelectionBar(isDark) : _buildNormalBar(isDark),
        body: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusScope.of(context).unfocus(),
          child: Column(
            children: [
              ListenableBuilder(
                listenable: _chat,
                builder: (_, __) => _buildPinnedBar(isDark),
              ),
              Expanded(
                child: Stack(
                  children: [
                    _buildMessages(context),
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
                            backgroundColor: isDark ? const Color(0xFF2A3942) : Colors.white,
                            foregroundColor: AppTheme.primary,
                            elevation: 2,
                            onPressed: _scrollToBottom,
                            child: const Icon(Icons.keyboard_arrow_down_rounded, size: 28),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (!_selecting) ...[
                AnimatedSize(
                  duration: const Duration(milliseconds: 160),
                  alignment: Alignment.bottomCenter,
                  child: _replyTo == null
                      ? const SizedBox(width: double.infinity)
                      : _buildReplyBar(isDark),
                ),
                _buildInput(context),
              ] else
                SafeArea(top: false, child: const SizedBox(height: 4)),
            ],
          ),
        ),
      ),
    );
  }

  /// Pinned messages bar. Tap = jump (cycles through up to 3 pins). X = unpin.
  Widget _buildPinnedBar(bool isDark) {
    final pins = _chat.pins;
    if (pins.isEmpty) return const SizedBox.shrink();

    final i = _pinCursor % pins.length;
    final pin = pins[i];

    return Material(
      color: isDark ? const Color(0xFF1F2C34) : Colors.white,
      elevation: 1,
      child: InkWell(
        onTap: () {
          _jumpTo(pin.id);
          setState(() => _pinCursor = (i + 1) % pins.length);
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 34,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              const Icon(Icons.push_pin_rounded, size: 18, color: AppTheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pins.length > 1
                          ? 'Pinned message ${i + 1} of ${pins.length}'
                          : 'Pinned message',
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.primary),
                    ),
                    Text(
                      pin.getDisplayMessage(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Unpin',
                icon: Icon(Icons.close_rounded,
                    size: 20, color: isDark ? Colors.white54 : Colors.grey.shade700),
                onPressed: () => _togglePin(pin),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReplyBar(bool isDark) {
    final r = _replyTo!;
    final author = r.senderId == _chat.currentUser?.id
        ? 'You'
        : ((r.senderName ?? '').isNotEmpty ? r.senderName! : _peerName);

    return Container(
      width: double.infinity,
      color: isDark ? const Color(0xFF1F2C34) : const Color(0xFFECEFF1),
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 42,
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  author,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  r.snippet,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ],
            ),
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
          IconButton(
            tooltip: 'Cancel reply',
            icon: Icon(Icons.close_rounded,
                size: 22, color: isDark ? Colors.white54 : Colors.grey.shade700),
            onPressed: _cancelReply,
          ),
        ],
      ),
    );
  }

  bool _sameDay(DateTime? a, DateTime? b) =>
      a != null && b != null && a.year == b.year && a.month == b.month && a.day == b.day;

  Widget _buildMessages(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<ChatProvider>(
      builder: (context, provider, _) {
        final messages = provider.messages;

        if (!_firstLoadDone && messages.isEmpty) {
          return const Center(
              child: CircularProgressIndicator(color: AppTheme.primary));
        }

        if (messages.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.chat_bubble_outline_rounded,
                        size: 46, color: AppTheme.primary),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    l10n.noMessagesYet,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.sayHelloToStart,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white54 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final myId = provider.currentUser?.id;
        final showLoader = provider.hasMoreOlder;

        return ScrollablePositionedList.builder(
          itemScrollController: _itemScroll,
          itemPositionsListener: _positions,
          reverse: true,
          padding: const EdgeInsets.symmetric(vertical: 10),
          itemCount: messages.length + (showLoader ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == messages.length) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              );
            }

            final idx = messages.length - 1 - index;
            final m = messages[idx];
            final older = idx > 0 ? messages[idx - 1] : null;
            final mine = m.senderId == myId;
            final showDay = m.time != null &&
                (older == null || !_sameDay(older.time, m.time));
            final canReply = !m.isPending && m.sendState == SendState.sent;
            final selected = _selected.contains(m.id);

            Widget row = SwipeToReply(
              enabled: canReply && !_selecting,
              onReply: () => _startReply(m),
              child: MessageBubble(
                key: ValueKey(m.id),
                message: m,
                isMine: mine,
                myId: myId,
                peerName: _peerName,
                highlighted: _highlightId == m.id,
                authHeaders: provider.authHeaders,
                onLongPress: _selecting
                    ? () => _toggleSelect(m)
                    : () => _showMessageOptions(m, mine),
                onTap: _selecting
                    ? () => _toggleSelect(m)
                    : () => openChatFile(context, m),
                onSave: () => saveChatFile(context, m),
                onRetry: () => _chat.retry(m.id),
                onTapReactions: () => showMessageInfo(context, m),
                onTapReply: _selecting ? null : (id) => _jumpTo(id),
              ),
            );

            if (_selecting) {
              row = GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => _toggleSelect(m),
                child: row,
              );
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showDay) _DayChip(label: chatDayLabel(m.time!)),
                Container(
                  color: selected
                      ? AppTheme.primary.withValues(alpha: 0.18)
                      : Colors.transparent,
                  child: row,
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildInput(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return SafeArea(
      top: false,
      child: Container(
        color: isDark ? const Color(0xFF1F2C34) : const Color(0xFFF0F2F5),
        padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 130),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2A3942) : Colors.white,
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    IconButton(
                      tooltip: 'Attach',
                      icon: Icon(
                        Icons.attach_file_rounded,
                        color: isDark ? Colors.white70 : AppTheme.primary,
                      ),
                      onPressed: _showAttachSheet,
                    ),
                    Expanded(
                      child: TextField(
                        controller: _text,
                        focusNode: _focus,
                        minLines: 1,
                        maxLines: 5,
                        maxLength: 2000,
                        textCapitalization: TextCapitalization.sentences,
                        style: TextStyle(
                          fontSize: 16,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          hintText: _replyTo != null ? 'Reply…' : l10n.typeAMessage,
                          hintStyle: TextStyle(
                            color: isDark ? Colors.white54 : Colors.grey.shade500,
                            fontSize: 16,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Camera',
                      icon: Icon(
                        Icons.photo_camera_outlined,
                        color: isDark ? Colors.white70 : Colors.grey.shade700,
                      ),
                      onPressed: _pickCamera,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _text,
              builder: (_, v, __) {
                final has = v.text.trim().isNotEmpty;
                return Material(
                  color: has
                      ? AppTheme.primary
                      : (isDark ? const Color(0xFF2A3942) : Colors.grey.shade400),
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: has ? _sendText : null,
                    customBorder: const CircleBorder(),
                    child: const SizedBox(
                      width: 48,
                      height: 48,
                      child: Center(
                        child: Icon(Icons.send_rounded, color: Colors.white, size: 22),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
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
            color: dark ? const Color(0xFF1F2C34) : Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 2),
            ],
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: dark ? Colors.white70 : Colors.black54,
            ),
          ),
        ),
      ),
    );
  }
}
