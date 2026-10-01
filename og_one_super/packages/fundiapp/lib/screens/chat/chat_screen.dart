// lib/screens/chat/chat_screen.dart
import 'dart:io';
import 'dart:async';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
    context.read<ChatProvider>().subscribeToUser(widget.conversation.otherParty.id);
  }

  Future<void> _loadMessages() async {
    await context.read<ChatProvider>().getMessages(conversationId: widget.conversation.id);
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
    await context.read<ChatProvider>().markConversationAsRead(widget.conversation.id);
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
      context.read<ChatProvider>().sendTypingStatus(
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
        await context.read<ChatProvider>().sendTypingStatus(
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
      await context.read<ChatProvider>().sendMessage(
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
      // FIXED: Use FilePicker.platform.pickFiles() to access the instance method.
      // The return type is FilePickerResult?, not List<PlatformFile>.
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
      await context.read<ChatProvider>().sendMessage(
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
        setState(() => _isPlayingVoice = false);
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
    setState(() {
      _isRecording = true;
      _recordingDuration = 0;
    });
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _recordingDuration++);
    });
  }

  void _onRecordingStopped(String path) {
    setState(() {
      _isRecording = false;
    });
    _recordingTimer?.cancel();
  }

  void _onPlaybackStarted() => setState(() => _isPlayingVoice = true);

  void _onPlaybackFinished() {
    setState(() {
      _isPlayingVoice = false;
      _playbackPosition = Duration.zero;
    });
  }

  void _onPlaybackPositionChanged(Duration position) {
    setState(() => _playbackPosition = position);
  }

  void _onPlaybackDurationChanged(Duration duration) {
    setState(() => _playbackDuration = duration);
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

      final result =
      await context.read<ChatProvider>().downloadFile(message.id, savePath);

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

  Future<void> _deleteConversation() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
        title: Text(
          'Delete Conversation',
          style: TextStyle(
            inherit: true,
            color: isDark ? Colors.white : AppTheme.primary,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this entire conversation? This cannot be undone.',
          style: TextStyle(
            inherit: true,
            color: isDark ? AppTheme.darkTextSecondary : AppTheme.greyText,
          ),
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
      ),
    );

    if (confirm == true) {
      final success = await context
          .read<ChatProvider>()
          .deleteConversation(widget.conversation.id);
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
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
        title: Text(
          'Delete File',
          style: TextStyle(
            inherit: true,
            color: isDark ? Colors.white : AppTheme.primary,
          ),
        ),
        content: Text(
          'Delete this file from the message?',
          style: TextStyle(
            inherit: true,
            color: isDark ? AppTheme.darkTextSecondary : AppTheme.greyText,
          ),
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
      ),
    );
    if (confirm == true) {
      await context.read<ChatProvider>().deleteFile(message.id);
    }
  }

  void _showMessageOptions(BuildContext context, ChatMessage message) {
    final l10n = AppLocalizations.of(context)!;
    final currentUserId = context.read<AuthProvider>().user?.id ?? 0;
    final isMine = message.isFromMe(currentUserId);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              if (message.content != null && message.content!.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.content_copy, color: AppTheme.primary),
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
                    color: AppTheme.primary,
                  ),
                  title: Text(_isPlayingVoice ? 'Pause Voice' : 'Play Voice'),
                  onTap: () {
                    Navigator.pop(context);
                    _playVoiceMessage(message);
                  },
                ),
              if (isMine)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: AppTheme.error),
                  title: Text(
                    l10n.deleteMessage,
                    style: const TextStyle(inherit: true, color: AppTheme.error),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    context.read<ChatProvider>().deleteMessage(message.id);
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

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.navy50,
      appBar: _buildAppBar(context, theme, l10n),
      body: Column(
        children: [
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading && provider.currentMessages.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  );
                }

                if (provider.currentMessages.isEmpty) {
                  return _buildEmptyState(context, l10n, isDark);
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  reverse: true,
                  itemCount: provider.currentMessages.length,
                  itemBuilder: (context, index) {
                    final message = provider.currentMessages[
                    provider.currentMessages.length - 1 - index];
                    final isCurrentUser = message.isFromMe(currentUserId);

                    return MessageBubble(
                      message: message,
                      isCurrentUser: isCurrentUser,
                      onLongPress: () => _showMessageOptions(context, message),
                      onDownload: message.file != null
                          ? () => _downloadFile(message)
                          : null,
                      onDeleteFile: message.file != null && isCurrentUser
                          ? () => _deleteFile(message)
                          : null,
                      onPlayVoice: message.isVoice && message.file?.url != null
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
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: TypingIndicator(),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          _buildMessageInput(context, theme, l10n, isDark),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
      BuildContext context,
      ThemeData theme,
      AppLocalizations l10n,
      ) {
    final otherParty = widget.conversation.otherParty;

    return AppBar(
      backgroundColor: AppTheme.primary,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: Text(
              otherParty.name.isNotEmpty
                  ? otherParty.name[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                inherit: true,
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  otherParty.name,
                  style: const TextStyle(
                    inherit: true,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  otherParty.isOnline ? l10n.online : l10n.lastSeen,
                  style: TextStyle(
                    inherit: true,
                    fontSize: 12,
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
          icon: Icon(Icons.videocam, color: Colors.white.withValues(alpha: 0.7)),
          tooltip: 'Video call – Coming soon',
          onPressed: () => _showComingSoon('Video call'),
        ),
        IconButton(
          icon: Icon(Icons.phone, color: Colors.white.withValues(alpha: 0.7)),
          tooltip: 'Voice call – Coming soon',
          onPressed: () => _showComingSoon('Voice call'),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor:
            isDark ? AppTheme.darkSurfaceLight : AppTheme.navy100,
            child: Icon(
              Icons.chat_bubble_outline,
              size: 50,
              color: isDark ? AppTheme.darkTextSecondary : AppTheme.greyText,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.noMessagesYet,
            style: TextStyle(
              inherit: true,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : AppTheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.sayHelloToStart,
            style: TextStyle(
              inherit: true,
              color: isDark ? AppTheme.darkTextSecondary : AppTheme.greyText,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput(
      BuildContext context,
      ThemeData theme,
      AppLocalizations l10n,
      bool isDark,
      ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.attach_file,
                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.greyText,
                  size: 26,
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
              const SizedBox(width: 4),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkSurfaceLight : AppTheme.navy50,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: TextField(
                    controller: _textController,
                    onChanged: _onTextChanged,
                    style: TextStyle(
                      inherit: true,
                      color: isDark ? Colors.white : AppTheme.primary,
                    ),
                    decoration: InputDecoration(
                      hintText: l10n.typeAMessage,
                      hintStyle: TextStyle(
                        inherit: true,
                        color: isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.greyText,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: Icon(
                  _showEmojiPicker
                      ? Icons.keyboard
                      : Icons.emoji_emotions_outlined,
                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.greyText,
                  size: 26,
                ),
                onPressed: () =>
                    setState(() => _showEmojiPicker = !_showEmojiPicker),
              ),
              if (_textController.text.trim().isNotEmpty)
                Container(
                  decoration: const BoxDecoration(
                    color: AppTheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: _isSending
                        ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : const Icon(Icons.send, color: Colors.white, size: 22),
                    onPressed: _isSending ? null : _sendMessage,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 44,
                      minHeight: 44,
                    ),
                  ),
                )
              else
                GestureDetector(
                  onLongPress: _startVoiceRecording,
                  onLongPressEnd: (_) => _stopVoiceRecording(),
                  child: Container(
                    decoration: BoxDecoration(
                      color: _isRecording
                          ? AppTheme.error.withValues(alpha: 0.1)
                          : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        _isRecording ? Icons.stop_circle : Icons.mic,
                        color: _isRecording
                            ? AppTheme.error
                            : (isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.greyText),
                        size: 26,
                      ),
                      onPressed: null,
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (_isRecording)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppTheme.error.withValues(alpha: 0.1),
            child: Row(
              children: [
                const Icon(Icons.circle, color: AppTheme.error, size: 12),
                const SizedBox(width: 8),
                Text(
                  'Recording... ${_recordingDuration}s',
                  style: const TextStyle(
                    inherit: true,
                    color: AppTheme.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: AppTheme.error),
                  onPressed: _cancelVoiceRecording,
                ),
              ],
            ),
          ),
        if (_showEmojiPicker)
          SizedBox(
            height: 280,
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
    );
  }
}