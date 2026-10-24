// lib/screens/chat/chat_screen.dart
import 'dart:io';
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../models/chat_conversation.dart';
import '../../models/chat_message.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../services/voice_recording_service.dart';
import '../../widgets/message_bubble.dart';
import '../../widgets/typing_indicator.dart';

// ─── Shared look helpers ─────────────────────────────────────────────────
/// Navy is unreadable on the dark background, so gold is used in dark mode.
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
  final ImagePicker _imagePicker = ImagePicker();
  final VoiceRecordingService _voiceService = VoiceRecordingService();

  /// Kept so dispose() never has to look up a context.
  late final ChatProvider _chat;

  bool _isTyping = false;
  bool _isSending = false;
  bool _showEmojiPicker = false;
  Timer? _typingDebounce;

  bool _isRecording = false;
  bool _isPlayingVoice = false;
  Timer? _recordingTimer;
  int _recordingDuration = 0;
  Duration _playbackPosition = Duration.zero;
  Duration _playbackDuration = Duration.zero;

  int get _currentUserId => context.read<AuthProvider>().user?.id ?? 0;

  @override
  void initState() {
    super.initState();
    _chat = context.read<ChatProvider>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadMessages();
      _markConversationAsRead();
      _subscribeToUser();
    });

    _voiceService.onRecordingStarted = _onRecordingStarted;
    _voiceService.onRecordingStopped = _onRecordingStopped;
    _voiceService.onPlaybackStarted = _onPlaybackStarted;
    _voiceService.onPlaybackFinished = _onPlaybackFinished;
    _voiceService.onPlaybackPositionChanged = _onPlaybackPositionChanged;
    _voiceService.onPlaybackDurationChanged = _onPlaybackDurationChanged;
    _voiceService.onError = _onVoiceError;
  }

  @override
  void dispose() {
    _typingDebounce?.cancel();
    _forceStopTyping();
    _textController.dispose();
    _scrollController.dispose();
    _recordingTimer?.cancel();
    _voiceService.dispose();
    super.dispose();
  }

  void _subscribeToUser() {
    _chat.subscribeToUser(widget.conversation.otherParty.id);
  }

  Future<void> _loadMessages() async {
    await _chat.getMessages(conversationId: widget.conversation.id);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _markConversationAsRead() async {
    await _chat.markConversationAsRead(widget.conversation.id);
  }

  void _onTextChanged(String text) {
    setState(() {});
    _typingDebounce?.cancel();

    if (text.isEmpty) {
      _forceStopTyping();
      return;
    }

    if (!_isTyping) {
      _isTyping = true;
      _chat.sendTypingStatus(
        conversationId: widget.conversation.id,
        typing: true,
      );
    }

    _typingDebounce = Timer(const Duration(milliseconds: 1200), () {
      _forceStopTyping();
    });
  }

  Future<void> _forceStopTyping() async {
    _typingDebounce?.cancel();
    if (_isTyping) {
      _isTyping = false;
      try {
        await _chat.sendTypingStatus(
          conversationId: widget.conversation.id,
          typing: false,
        );
      } catch (_) {}
    }
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isSending) return;

    _textController.clear();
    setState(() => _isSending = true);
    await _forceStopTyping();

    try {
      await _chat.sendMessage(
        conversationId: widget.conversation.id,
        content: text,
        messageType: 'text',
      );
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.failedToSend}: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );
    if (image != null) {
      await _sendFile(File(image.path), 'image', '📷 Image');
    }
  }

  Future<void> _pickCamera() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );
    if (image != null) {
      await _sendFile(File(image.path), 'image', '📷 Photo');
    }
  }

  Future<void> _pickFile() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );

      if (result == null || result.files.isEmpty) return;

      final PlatformFile first = result.files.first;
      final String? path = first.path;
      if (path == null) return;

      await _sendFile(File(path), 'file', '📎 ${first.name}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick file: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _sendFile(
      File file,
      String type,
      String content, {
        int? voiceDuration,
      }) async {
    setState(() => _isSending = true);
    await _forceStopTyping();
    try {
      await _chat.sendMessage(
        conversationId: widget.conversation.id,
        file: file,
        messageType: type,
        content: content,
        voiceDuration: voiceDuration,
      );
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        final errorMsg =
        type == 'image' ? l10n.failedToSendImage : l10n.failedToSendFile;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$errorMsg: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _startVoiceRecording() async {
    try {
      await _voiceService.startRecording();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start recording: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  void _stopVoiceRecording() async {
    try {
      final path = await _voiceService.stopRecording();
      if (path != null && mounted) {
        final file = File(path);
        await _sendFile(
          file,
          'voice',
          '🎤 Voice message',
          voiceDuration: _recordingDuration > 0 ? _recordingDuration : 1,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to stop recording: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  void _cancelVoiceRecording() async {
    await _voiceService.cancelRecording();
    if (!mounted) return;
    setState(() {
      _isRecording = false;
      _recordingDuration = 0;
    });
  }

  Future<void> _playVoiceMessage(ChatMessage message) async {
    final url = message.file?.url;
    if (url == null || url.isEmpty) return;

    try {
      if (_voiceService.isPlaying) {
        await _voiceService.stopPlayback();
        if (mounted) setState(() => _isPlayingVoice = false);
        return;
      }

      String localPath;
      if (url.startsWith('http')) {
        final dir = await getTemporaryDirectory();
        final ext = message.file?.extension ?? 'm4a';
        localPath = '${dir.path}/voice_${message.id}.$ext';
        final file = File(localPath);
        if (!await file.exists()) {
          await Dio().download(url, localPath);
        }
      } else {
        localPath = url;
      }

      await _voiceService.playRecording(localPath);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to play voice: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  void _onRecordingStarted() {
    if (!mounted) return;
    setState(() {
      _isRecording = true;
      _recordingDuration = 0;
    });
    _recordingTimer?.cancel();
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _recordingDuration++);
    });
  }

  void _onRecordingStopped(String path) {
    _recordingTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _isRecording = false;
    });
  }

  void _onPlaybackStarted() {
    if (mounted) setState(() => _isPlayingVoice = true);
  }

  void _onPlaybackFinished() {
    if (!mounted) return;
    setState(() {
      _isPlayingVoice = false;
      _playbackPosition = Duration.zero;
    });
  }

  void _onPlaybackPositionChanged(Duration position) {
    if (mounted) setState(() => _playbackPosition = position);
  }

  void _onPlaybackDurationChanged(Duration duration) {
    if (mounted) setState(() => _playbackDuration = duration);
  }

  void _onVoiceError(String error) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Voice error: $error'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature – Coming soon'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _downloadFile(ChatMessage message) async {
    if (message.file == null) return;

    try {
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          if (!mounted) return;
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.storagePermissionDenied)),
          );
          return;
        }
      }

      String savePath;
      final fileName = message.file!.name ?? 'file_${message.id}';
      final extension = message.file!.extension ?? '';
      final fullFileName =
      extension.isNotEmpty && !fileName.endsWith('.$extension')
          ? '$fileName.$extension'
          : fileName;

      if (Platform.isAndroid) {
        final directory = await getExternalStorageDirectory();
        if (directory == null) throw Exception('Could not access storage');
        final downloadDir = Directory('${directory.path}/Download');
        if (!await downloadDir.exists()) {
          await downloadDir.create(recursive: true);
        }
        savePath = '${downloadDir.path}/$fullFileName';
      } else {
        final directory = await getApplicationDocumentsDirectory();
        savePath = '${directory.path}/$fullFileName';
      }

      final result = await _chat.downloadFile(message.id, savePath);

      if (result != null && mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.fileDownloaded}: $fullFileName'),
            backgroundColor: AppTheme.success,
            action: SnackBarAction(
              label: 'Open',
              textColor: Colors.white,
              onPressed: () => OpenFile.open(savePath),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.downloadFailed}: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Widget _confirmDialog({
    required bool isDark,
    required String title,
    required String body,
  }) {
    return AlertDialog(
      backgroundColor: _cardBg(isDark),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        title,
        style: TextStyle(
          inherit: true,
          fontWeight: FontWeight.w800,
          color: _ink(isDark),
        ),
      ),
      content: Text(
        body,
        style: TextStyle(inherit: true, color: _muted(isDark)),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: TextButton.styleFrom(foregroundColor: AppTheme.error),
          child: const Text('Delete'),
        ),
      ],
    );
  }

  Future<void> _deleteConversation() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => _confirmDialog(
        isDark: isDark,
        title: 'Delete Conversation',
        body:
        'Are you sure you want to delete this entire conversation? This cannot be undone.',
      ),
    );

    if (confirm == true) {
      final success = await _chat.deleteConversation(widget.conversation.id);
      if (success && mounted) {
        Navigator.pop(context);
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.conversationDeleted),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    }
  }

  Future<void> _deleteFile(ChatMessage message) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => _confirmDialog(
        isDark: isDark,
        title: 'Delete File',
        body: 'Delete this file from the message?',
      ),
    );
    if (confirm == true) {
      await _chat.deleteFile(message.id);
    }
  }

  void _showMessageOptions(BuildContext context, ChatMessage message) {
    final l10n = AppLocalizations.of(context)!;
    final currentUserId = context.read<AuthProvider>().user?.id ?? 0;
    final isMine = message.isFromMe(currentUserId);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: _cardBg(isDark),
      showDragHandle: true,
      constraints: const BoxConstraints(maxWidth: 560),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              if (message.content != null && message.content!.isNotEmpty)
                ListTile(
                  leading: Icon(Icons.content_copy, color: _accent(isDark)),
                  title: Text(l10n.copy),
                  onTap: () {
                    Navigator.pop(context);
                    Clipboard.setData(ClipboardData(text: message.content!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.messageCopied)),
                    );
                  },
                ),
              if (message.file != null)
                ListTile(
                  leading: const Icon(Icons.download, color: AppTheme.success),
                  title: Text(l10n.downloadFile),
                  onTap: () {
                    Navigator.pop(context);
                    _downloadFile(message);
                  },
                ),
              if (message.isVoice && message.file?.url != null)
                ListTile(
                  leading: Icon(
                    _isPlayingVoice ? Icons.pause : Icons.play_arrow,
                    color: _accent(isDark),
                  ),
                  title: Text(_isPlayingVoice ? 'Pause Voice' : 'Play Voice'),
                  onTap: () {
                    Navigator.pop(context);
                    _playVoiceMessage(message);
                  },
                ),
              if (isMine)
                ListTile(
                  leading:
                  const Icon(Icons.delete_outline, color: AppTheme.error),
                  title: Text(
                    l10n.deleteMessage,
                    style: const TextStyle(inherit: true, color: AppTheme.error),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _chat.deleteMessage(message.id);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final currentUserId = context.watch<AuthProvider>().user?.id ?? 0;
    final isDark = theme.brightness == Brightness.dark;

    return MediaQuery.withClampedTextScaling(
      minScaleFactor: 0.85,
      maxScaleFactor: 1.25,
      child: Scaffold(
        backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.navy50,
        appBar: _buildAppBar(context, theme, l10n),
        // On tablets / large screens the chat is centered with a max width.
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Column(
              children: [
                Expanded(
                  child: Consumer<ChatProvider>(
                    builder: (context, provider, child) {
                      if (provider.isLoading &&
                          provider.currentMessages.isEmpty) {
                        return Center(
                          child: CircularProgressIndicator(
                              color: _accent(isDark)),
                        );
                      }

                      if (provider.currentMessages.isEmpty) {
                        return _buildEmptyState(context, l10n, isDark);
                      }

                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 8),
                        reverse: true,
                        itemCount: provider.currentMessages.length,
                        itemBuilder: (context, index) {
                          final message = provider.currentMessages[
                          provider.currentMessages.length - 1 - index];
                          final isCurrentUser =
                          message.isFromMe(currentUserId);

                          return MessageBubble(
                            message: message,
                            isCurrentUser: isCurrentUser,
                            onLongPress: () =>
                                _showMessageOptions(context, message),
                            onDownload: message.file != null
                                ? () => _downloadFile(message)
                                : null,
                            onDeleteFile:
                            message.file != null && isCurrentUser
                                ? () => _deleteFile(message)
                                : null,
                            onPlayVoice:
                            message.isVoice && message.file?.url != null
                                ? () => _playVoiceMessage(message)
                                : null,
                            isPlaying: _isPlayingVoice,
                            playbackPosition: _playbackPosition,
                            playbackDuration: _playbackDuration,
                          );
                        },
                      );
                    },
                  ),
                ),
                Consumer<ChatProvider>(
                  builder: (context, provider, child) {
                    if (provider.isTyping) {
                      return const Padding(
                        padding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: TypingIndicator(),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                _buildMessageInput(context, theme, l10n, isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
      BuildContext context,
      ThemeData theme,
      AppLocalizations l10n,
      ) {
    final otherParty = widget.conversation.otherParty;
    final compact = MediaQuery.sizeOf(context).width < 360;
    final density = compact ? VisualDensity.compact : VisualDensity.standard;

    return AppBar(
      backgroundColor: AppTheme.primary,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleSpacing: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        visualDensity: density,
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: otherParty.isOnline
                    ? AppTheme.secondary
                    : Colors.white.withValues(alpha: 0.3),
                width: 1.6,
              ),
            ),
            child: CircleAvatar(
              radius: compact ? 16 : 19,
              backgroundColor: Colors.white.withValues(alpha: 0.18),
              child: Text(
                otherParty.name.isNotEmpty
                    ? otherParty.name[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  inherit: true,
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          SizedBox(width: compact ? 8 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  otherParty.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    inherit: true,
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: compact ? 15 : 16.5,
                  ),
                ),
                Text(
                  otherParty.isOnline ? l10n.online : l10n.lastSeen,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    inherit: true,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: otherParty.isOnline
                        ? AppTheme.secondary
                        : Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.videocam_rounded,
              color: Colors.white.withValues(alpha: 0.8)),
          visualDensity: density,
          tooltip: 'Video call – Coming soon',
          onPressed: () => _showComingSoon('Video call'),
        ),
        IconButton(
          icon: Icon(Icons.phone_rounded,
              color: Colors.white.withValues(alpha: 0.8)),
          visualDensity: density,
          tooltip: 'Voice call – Coming soon',
          onPressed: () => _showComingSoon('Voice call'),
        ),
        PopupMenuButton<String>(
          padding: EdgeInsets.symmetric(horizontal: compact ? 4 : 8),
          icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          onSelected: (value) {
            if (value == 'delete_conversation') _deleteConversation();
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'delete_conversation',
              child: Text(
                'Delete Conversation',
                style: TextStyle(inherit: true, color: AppTheme.error),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState(
      BuildContext context,
      AppLocalizations l10n,
      bool isDark,
      ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 104,
              height: 104,
              decoration: BoxDecoration(
                color: _cardBg(isDark),
                shape: BoxShape.circle,
                border: Border.all(color: _cardBorder(isDark)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.25 : 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(Icons.chat_bubble_outline_rounded,
                  size: 44, color: _muted(isDark)),
            ),
            const SizedBox(height: 18),
            Text(
              l10n.noMessagesYet,
              textAlign: TextAlign.center,
              style: TextStyle(
                inherit: true,
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: _ink(isDark),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.sayHelloToStart,
              textAlign: TextAlign.center,
              style: TextStyle(
                inherit: true,
                color: _muted(isDark),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput(
      BuildContext context,
      ThemeData theme,
      AppLocalizations l10n,
      bool isDark,
      ) {
    final hasText = _textController.text.trim().isNotEmpty;
    final screenH = MediaQuery.sizeOf(context).height;
    final emojiH = math.min(280.0, screenH * 0.38);

    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isRecording)
            Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.error.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                    color: AppTheme.error.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.circle, color: AppTheme.error, size: 11),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Recording... ${_recordingDuration}s',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        inherit: true,
                        color: AppTheme.error,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: AppTheme.error),
                    onPressed: _cancelVoiceRecording,
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: _cardBg(isDark),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: _cardBorder(isDark)),
                      boxShadow: [
                        BoxShadow(
                          color:
                          Colors.black.withOpacity(isDark ? 0.25 : 0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        PopupMenuButton<String>(
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18)),
                          icon: Icon(
                            Icons.attach_file_rounded,
                            color: _muted(isDark),
                            size: 24,
                          ),
                          onSelected: (value) {
                            if (value == 'camera') {
                              _pickCamera();
                            } else if (value == 'gallery') {
                              _pickImage();
                            } else if (value == 'document') {
                              _pickFile();
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: 'camera',
                              child: Row(
                                children: [
                                  Icon(Icons.camera_alt, size: 22),
                                  SizedBox(width: 12),
                                  Text('Camera'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'gallery',
                              child: Row(
                                children: [
                                  Icon(Icons.photo_library, size: 22),
                                  SizedBox(width: 12),
                                  Text('Gallery'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'document',
                              child: Row(
                                children: [
                                  Icon(Icons.insert_drive_file, size: 22),
                                  SizedBox(width: 12),
                                  Text('Document'),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Expanded(
                          child: ConstrainedBox(
                            constraints:
                            const BoxConstraints(maxHeight: 120),
                            child: TextField(
                              controller: _textController,
                              onChanged: _onTextChanged,
                              cursorColor: _accent(isDark),
                              style: TextStyle(
                                inherit: true,
                                fontSize: 15,
                                color: _ink(isDark),
                              ),
                              decoration: InputDecoration(
                                hintText: l10n.typeAMessage,
                                hintStyle: TextStyle(
                                  inherit: true,
                                  color: _muted(isDark),
                                ),
                                filled: false,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 13,
                                ),
                              ),
                              minLines: 1,
                              maxLines: 5,
                              textCapitalization:
                              TextCapitalization.sentences,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            _showEmojiPicker
                                ? Icons.keyboard_rounded
                                : Icons.emoji_emotions_outlined,
                            color: _muted(isDark),
                            size: 24,
                          ),
                          onPressed: () => setState(
                                  () => _showEmojiPicker = !_showEmojiPicker),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (hasText)
                  Material(
                    color: AppTheme.secondary,
                    shape: const CircleBorder(),
                    elevation: 3,
                    shadowColor: AppTheme.secondary.withValues(alpha: 0.5),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _isSending ? null : _sendMessage,
                      child: SizedBox(
                        width: 50,
                        height: 50,
                        child: Center(
                          child: _isSending
                              ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: AppTheme.primary,
                            ),
                          )
                              : const Icon(Icons.send_rounded,
                              color: AppTheme.primary, size: 22),
                        ),
                      ),
                    ),
                  )
                else
                  GestureDetector(
                    onLongPress: _startVoiceRecording,
                    onLongPressEnd: (_) => _stopVoiceRecording(),
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isRecording
                            ? AppTheme.error.withValues(alpha: 0.15)
                            : _cardBg(isDark),
                        border: Border.all(
                          color: _isRecording
                              ? AppTheme.error
                              : _cardBorder(isDark),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black
                                .withOpacity(isDark ? 0.25 : 0.06),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        _isRecording ? Icons.stop_circle : Icons.mic_rounded,
                        color: _isRecording ? AppTheme.error : _accent(isDark),
                        size: 25,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (_showEmojiPicker)
            SizedBox(
              height: emojiH,
              child: EmojiPicker(
                onEmojiSelected: (category, emoji) {
                  final text = _textController.text;
                  _textController.text = '$text${emoji.emoji}';
                  _textController.selection = TextSelection.fromPosition(
                    TextPosition(offset: _textController.text.length),
                  );
                  setState(() {});
                },
                onBackspacePressed: () {
                  final text = _textController.text;
                  if (text.isNotEmpty) {
                    _textController.text =
                        text.characters.skipLast(1).toString();
                  }
                },
              ),
            ),
        ],
      ),
    );
  }
}