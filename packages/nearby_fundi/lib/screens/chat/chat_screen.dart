// lib/screens/chat/chat_screen.dart

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../models/chat_conversation.dart';
import '../../models/chat_message.dart';
import '../../providers/chat_provider.dart';
import 'widgets/message_bubble.dart';
import 'widgets/typing_indicator.dart';

class ChatScreen extends StatefulWidget {
  final ChatConversation conversation;

  const ChatScreen({
    super.key,
    required this.conversation,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  bool _isSending = false;
  bool _isLoadingMore = false;
  int _currentOffset = 0;
  bool _hasMoreMessages = true;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _markConversationAsRead();
    _subscribeToUser();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _unsubscribeFromUser();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    try {
      final provider = context.read<ChatProvider>();
      await provider.getMessages(
        conversationId: widget.conversation.id,
        limit: 50,
        offset: 0,
      );
      if (!mounted) return;
      _currentOffset = 50;
      _hasMoreMessages = true;
      _scrollToBottom();
    } catch (e) {
      debugPrint('Error loading messages: $e');
    }
  }

  Future<void> _loadMoreMessages() async {
    if (_isLoadingMore || !_hasMoreMessages) return;
    if (!mounted) return;

    setState(() => _isLoadingMore = true);

    try {
      final provider = context.read<ChatProvider>();
      final messages = await provider.getMessages(
        conversationId: widget.conversation.id,
        limit: 50,
        offset: _currentOffset,
      );
      if (messages.length < 50) _hasMoreMessages = false;
      _currentOffset += messages.length;
    } catch (e) {
      debugPrint('Error loading more messages: $e');
    } finally {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _markConversationAsRead() async {
    try {
      await context.read<ChatProvider>().markConversationAsRead(
        widget.conversation.id,
      );
    } catch (e) {
      debugPrint('Error marking conversation as read: $e');
    }
  }

  void _subscribeToUser() {
    context.read<ChatProvider>().subscribeToUser(
      widget.conversation.otherParty.id,
    );
  }

  void _unsubscribeFromUser() {
    context.read<ChatProvider>().unsubscribeFromUser(
      widget.conversation.otherParty.id,
    );
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isSending) return;

    _textController.clear();
    if (mounted) setState(() => _isSending = true);

    try {
      await context.read<ChatProvider>().sendMessage(
        conversationId: widget.conversation.id,
        content: text,
        messageType: 'text',
      );
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n.failedToSend}: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _sendTypingStatus(bool typing) async {
    try {
      await context.read<ChatProvider>().sendTypingStatus(
        conversationId: widget.conversation.id,
        typing: typing,
      );
    } catch (e) {
      debugPrint('Typing status error: $e');
    }
  }

  Future<void> _pickImage() async {
    if (_isSending) return;
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (image == null) return;
      await _sendFile(File(image.path), 'image', '📷 Image');
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n.failedToSendFile}: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  Future<void> _pickFile() async {
    if (_isSending) return;
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.any,
      );
      if (result == null || result.files.isEmpty) return;
      final selectedFile = result.files.first;
      if (selectedFile.path == null || selectedFile.path!.isEmpty) return;
      final file = File(selectedFile.path!);
      await _sendFile(file, 'file', '📎 ${selectedFile.name}');
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n.failedToSendFile}: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  Future<void> _sendFile(File file, String type, String content) async {
    if (_isSending) return;
    if (mounted) setState(() => _isSending = true);

    try {
      await context.read<ChatProvider>().sendMessage(
        conversationId: widget.conversation.id,
        file: file,
        messageType: type,
        content: content,
      );
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n.failedToSendFile}: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _showMessageOptions(BuildContext context, ChatMessage message) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Wrap(
            children: [
              if (message.content != null &&
                  message.content!.trim().isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.content_copy_outlined),
                  title: Text(l10n.copy),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await Clipboard.setData(
                      ClipboardData(text: message.content!),
                    );
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.messageCopied),
                        backgroundColor: AppTheme.success,
                      ),
                    );
                  },
                ),
              ListTile(
                leading: const Icon(Icons.delete_outline,
                    color: AppTheme.error),
                title: Text(
                  l10n.delete,
                  style: const TextStyle(color: AppTheme.error),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _confirmDeleteMessage(context, message);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDeleteMessage(BuildContext context, ChatMessage message) {
    final l10n = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.deleteMessage),
          content: Text(l10n.areYouSureDeleteMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                try {
                  await context
                      .read<ChatProvider>()
                      .deleteMessage(message.id);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.messageDeleted),
                      backgroundColor: AppTheme.success,
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$e'),
                      backgroundColor: AppTheme.error,
                    ),
                  );
                }
              },
              style: TextButton.styleFrom(foregroundColor: AppTheme.error),
              child: Text(l10n.delete),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 8,
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.white.withOpacity(0.15),
              child: Text(
                widget.conversation.otherParty.name.isNotEmpty
                    ? widget.conversation.otherParty.name[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.conversation.otherParty.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  Consumer<ChatProvider>(
                    builder: (context, provider, child) {
                      if (provider.isTyping) {
                        return Text(
                          l10n.typing,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.secondary,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      }
                      if (widget.conversation.otherParty.isOnline) {
                        return Text(
                          l10n.online,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.secondary,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),

      body: Column(
        children: [
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading &&
                    provider.currentMessages.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.currentMessages.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.chat_bubble_outline,
                              size: 48,
                              color: AppTheme.primary,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            l10n.noMessagesYet,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.sayHelloToStart,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: theme.hintColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification.metrics.pixels <= 0 &&
                        !_isLoadingMore &&
                        _hasMoreMessages) {
                      _loadMoreMessages();
                    }
                    return false;
                  },
                  child: ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 8,
                    ),
                    itemCount: provider.currentMessages.length +
                        (_isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (_isLoadingMore &&
                          index == provider.currentMessages.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        );
                      }

                      final message = provider.currentMessages[
                      provider.currentMessages.length - 1 - index];

                      final isCurrentUser =
                          message.senderId == provider.currentUser?.id;

                      return MessageBubble(
                        message: message,
                        isCurrentUser: isCurrentUser,
                        onLongPress: () {
                          _showMessageOptions(context, message);
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),

          Consumer<ChatProvider>(
            builder: (context, provider, child) {
              if (!provider.isTyping) return const SizedBox.shrink();
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: TypingIndicator(),
              );
            },
          ),

          _buildMessageInput(context),
        ],
      ),
    );
  }

  Widget _buildMessageInput(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final hasText = _textController.text.trim().isNotEmpty;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton(
              tooltip: 'Photo',
              icon: Icon(
                Icons.photo_outlined,
                color: _isSending ? theme.hintColor : AppTheme.primary,
                size: isTablet ? 28 : 24,
              ),
              onPressed: _isSending ? null : _pickImage,
            ),

            IconButton(
              tooltip: 'Attach file',
              icon: Icon(
                Icons.attach_file,
                color: _isSending ? theme.hintColor : AppTheme.primary,
                size: isTablet ? 28 : 24,
              ),
              onPressed: _isSending ? null : _pickFile,
            ),

            Expanded(
              child: TextField(
                controller: _textController,
                focusNode: _focusNode,
                maxLines: 5,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (text) {
                  setState(() {});
                  _sendTypingStatus(text.trim().isNotEmpty);
                },
                decoration: InputDecoration(
                  hintText: l10n.typeAMessage,
                  hintStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.hintColor,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  fillColor: theme.colorScheme.surfaceContainerHighest,
                  filled: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 4),

            Material(
              color: hasText && !_isSending
                  ? AppTheme.primary
                  : theme.dividerColor,
              shape: const CircleBorder(),
              child: IconButton(
                tooltip: 'Send',
                icon: _isSending
                    ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : const Icon(Icons.send_rounded, color: Colors.white),
                onPressed: hasText && !_isSending ? _sendMessage : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}