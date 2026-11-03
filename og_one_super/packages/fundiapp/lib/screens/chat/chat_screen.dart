// lib/screens/chat/chat_screen.dart
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../models/chat_conversation.dart';
import '../../models/chat_message.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/message_bubble.dart';

const int _mb = 1024 * 1024;
const int _maxImageBytes = 5 * _mb;
const int _maxVideoBytes = 20 * _mb;
const int _maxFileBytes = 15 * _mb;

const Set<String> _blockedExtensions = {
  'php', 'phtml', 'phar', 'exe', 'bat', 'cmd', 'com', 'sh', 'js',
  'html', 'htm', 'svg', 'jar', 'apk', 'msi', 'dll', 'vbs', 'ps1', 'py',
};
const Set<String> _imageExtensions = {
  'jpg', 'jpeg', 'png', 'webp', 'gif', 'heic'
};
const Set<String> _videoExtensions = {
  'mp4', 'mov', 'm4v', '3gp', 'webm', 'mkv'
};

Color _accent(bool isDark) => isDark ? AppTheme.secondary : AppTheme.primary;
Color _cardBg(bool isDark) => isDark ? AppTheme.darkSurface : Colors.white;
Color _cardBorder(bool isDark) =>
    isDark ? AppTheme.darkBorder : AppTheme.borderLight.withOpacity(0.30);
Color _ink(bool isDark) => isDark ? Colors.white : AppTheme.primary;
Color _muted(bool isDark) =>
    isDark ? AppTheme.darkTextSecondary : AppTheme.greyText;

class ChatScreen extends StatefulWidget {
  final ChatConversation conversation;

  const ChatScreen({super.key, required this.conversation});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  late final ChatProvider _chat;

  bool _sending = false;
  bool _firstLoadDone = false;
  ChatMessage? _replyingTo;

  int get _conversationId => widget.conversation.id;

  @override
  void initState() {
    super.initState();
    _chat = context.read<ChatProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) => _open());
  }

  @override
  void dispose() {
    _chat.closeConversation();
    _textController.dispose();
    _scrollController.dispose();
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? AppTheme.error : AppTheme.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  // ── Send ───────────────────────────────────────────────────────────────
  Future<void> _sendText() async {
    final rawText = _textController.text.trim();
    if (rawText.isEmpty || _sending) return;

    String finalPayload = rawText;
    if (_replyingTo != null) {
      final myId = _chat.currentUser?.id;
      final isMine = _replyingTo!.senderId == myId;
      final senderName = isMine ? 'You' : widget.conversation.otherParty.name;
      final quoteText = _replyingTo!.content ?? (_replyingTo!.isImage ? '📷 Photo' : '📁 File');
      finalPayload = '↩ $senderName: $quoteText\n$rawText';
    }

    _textController.clear();
    final previousReply = _replyingTo;
    setState(() {
      _sending = true;
      _replyingTo = null;
    });

    try {
      await _chat.sendMessage(conversationId: _conversationId, content: finalPayload);
      _scrollToBottom();
    } catch (e) {
      _textController.text = rawText;
      setState(() => _replyingTo = previousReply);
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        _snack('${l10n.failedToSend}: $e', error: true);
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  int _limitFor(String ext) {
    if (_imageExtensions.contains(ext)) return _maxImageBytes;
    if (_videoExtensions.contains(ext)) return _maxVideoBytes;
    return _maxFileBytes;
  }

  Future<void> _sendFile(File file) async {
    if (_sending) return;

    final ext = p.extension(file.path).replaceFirst('.', '').toLowerCase();
    if (_blockedExtensions.contains(ext)) {
      _snack('This file type is not allowed.', error: true);
      return;
    }

    final size = await file.length();
    final limit = _limitFor(ext);
    if (size > limit) {
      _snack(
        'File is too large. Maximum for this type is ${limit ~/ _mb} MB.',
        error: true,
      );
      return;
    }

    setState(() => _sending = true);

    try {
      await _chat.sendMessage(conversationId: _conversationId, file: file);
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        _snack('${l10n.failedToSend}: $e', error: true);
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final x = await _picker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 1600,
        maxHeight: 1600,
      );
      if (x != null) await _sendFile(File(x.path));
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
    if (_sending) return;

    Widget option(IconData icon, Color color, String label, VoidCallback onTap) {
      return ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.12),
          child: Icon(icon, color: color),
        ),
        title: Text(label),
        onTap: () {
          Navigator.pop(context);
          onTap();
        },
      );
    }

    showModalBottomSheet<void>(
      context: context,
      constraints: const BoxConstraints(maxWidth: 600),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            option(Icons.photo_camera_rounded, Colors.teal, 'Camera',
                    () => _pickPhoto(ImageSource.camera)),
            option(Icons.photo_rounded, Colors.purple, 'Photo (max 5 MB)',
                    () => _pickPhoto(ImageSource.gallery)),
            option(Icons.videocam_rounded, Colors.red, 'Short video (max 20 MB)',
                _pickVideo),
            option(Icons.insert_drive_file_rounded, Colors.blue,
                'File (Excel, Word, PDF… max 15 MB)', _pickDocument),
          ],
        ),
      ),
    );
  }

  // ── Message actions ────────────────────────────────────────────────────
  void _showMessageOptions(ChatMessage message, bool isMine) {
    final l10n = AppLocalizations.of(context)!;
    final hasText = (message.content ?? '').trim().isNotEmpty;

    showModalBottomSheet<void>(
      context: context,
      constraints: const BoxConstraints(maxWidth: 600),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.reply_rounded, color: AppTheme.primary),
              title: const Text('Reply'),
              onTap: () {
                Navigator.pop(sheetContext);
                setState(() => _replyingTo = message);
              },
            ),
            if (hasText)
              ListTile(
                leading: const Icon(Icons.content_copy_outlined),
                title: Text(l10n.copy),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await Clipboard.setData(
                      ClipboardData(text: message.content!));
                  _snack(l10n.messageCopied);
                },
              ),
            if (isMine)
              ListTile(
                leading:
                const Icon(Icons.delete_outline, color: AppTheme.error),
                title: Text(l10n.delete,
                    style: const TextStyle(color: AppTheme.error)),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _confirmDelete(message);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(ChatMessage message) {
    final l10n = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteMessage),
        content: Text(l10n.areYouSureDeleteMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await _chat.deleteMessage(message.id);
                _snack(l10n.messageDeleted);
              } catch (e) {
                _snack('$e', error: true);
              }
            },
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }

  // ── UI ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final name = widget.conversation.otherParty.name;

    return Scaffold(
      backgroundColor:
      isDark ? AppTheme.darkBackground : const Color(0xFFE5DDD5),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: isDark ? const Color(0xFF1F2C34) : AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
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
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 17,
                ),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessages(context)),
          _buildUploadBar(),
          _buildReplyBar(isDark),
          _buildInput(context),
        ],
      ),
    );
  }

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
                  Icon(Icons.chat_bubble_outline_rounded,
                      size: 52, color: _muted(isDark)),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noMessagesYet,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: _ink(isDark),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.sayHelloToStart,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: _muted(isDark)),
                  ),
                ],
              ),
            ),
          );
        }

        final myId = provider.currentUser?.id;
        final showLoader = provider.hasMoreOlder;

        return NotificationListener<ScrollNotification>(
          onNotification: (n) {
            if (n.metrics.pixels >= n.metrics.maxScrollExtent - 200) {
              provider.loadOlder();
            }
            return false;
          },
          child: ListView.builder(
            controller: _scrollController,
            reverse: true,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
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

              final message = messages[messages.length - 1 - index];
              final isMine = message.senderId == myId;

              return MessageBubble(
                key: ValueKey(message.id),
                message: message,
                isCurrentUser: isMine,
                onLongPress: () => _showMessageOptions(message, isMine),
                authHeaders: provider.authHeaders,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildUploadBar() {
    return ValueListenableBuilder<double?>(
      valueListenable: _chat.uploadProgress,
      builder: (context, progress, _) {
        if (progress == null) return const SizedBox.shrink();
        final percent = (progress * 100).clamp(0, 100).toStringAsFixed(0);
        return Container(
          color: Theme.of(context).colorScheme.surface,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Sending… $percent%', style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: progress <= 0 ? null : progress,
                color: AppTheme.primary,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReplyBar(bool isDark) {
    if (_replyingTo == null) return const SizedBox.shrink();

    final myId = _chat.currentUser?.id;
    final isMine = _replyingTo!.senderId == myId;
    final senderName = isMine ? 'You' : widget.conversation.otherParty.name;
    final text = _replyingTo!.content ?? (_replyingTo!.isImage ? '📷 Photo' : '📁 File');

    return Container(
      color: isDark ? const Color(0xFF1F2C34) : const Color(0xFFF0F2F5),
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A3942) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border(
            left: BorderSide(
              color: AppTheme.primary,
              width: 4,
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    senderName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    text,
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
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 18),
              onPressed: () => setState(() => _replyingTo = null),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInput(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final hasText = _textController.text.trim().isNotEmpty;

    return SafeArea(
      top: false,
      child: Container(
        color: isDark ? const Color(0xFF1F2C34) : const Color(0xFFF0F2F5),
        padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton(
              tooltip: 'Attach',
              icon: Icon(
                Icons.add_circle_outline_rounded,
                size: 28,
                color: _sending
                    ? Theme.of(context).hintColor
                    : (isDark ? Colors.white70 : AppTheme.primary),
              ),
              onPressed: _sending ? null : _showAttachSheet,
            ),
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 120),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2A3942) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _textController,
                  minLines: 1,
                  maxLines: 5,
                  maxLength: 2000,
                  textCapitalization: TextCapitalization.sentences,
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: l10n.typeAMessage,
                    hintStyle: TextStyle(
                      color: isDark ? Colors.white54 : Colors.grey.shade500,
                      fontSize: 16,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 11,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Material(
              color: hasText && !_sending
                  ? const Color(0xFF25D366)
                  : (isDark ? const Color(0xFF2A3942) : Colors.grey.shade400),
              shape: const CircleBorder(),
              child: InkWell(
                onTap: hasText && !_sending ? _sendText : null,
                customBorder: const CircleBorder(),
                child: SizedBox(
                  width: 46,
                  height: 46,
                  child: Center(
                    child: _sending
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                        : const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}