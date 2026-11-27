// lib/screens/chat/widgets/chat_viewers.dart
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:open_file/open_file.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

import '../../../config/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/chat_message.dart';
import '../../../providers/chat_provider.dart';

void _toast(ScaffoldMessengerState m, String text, {bool error = false}) {
  m.hideCurrentSnackBar();
  m.showSnackBar(SnackBar(
    content: Text(text),
    behavior: SnackBarBehavior.floating,
    backgroundColor: error ? AppTheme.error : null,
  ));
}

Future<File> _localCopy(BuildContext context, ChatMessage message) async {
  final lp = message.file?.localPath;
  if (lp != null && File(lp).existsSync()) return File(lp);

  final chat = context.read<ChatProvider>();
  final nav = Navigator.of(context, rootNavigator: true);
  showDialog<void>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: false,
    builder: (_) => const PopScope(
      canPop: false,
      child: Center(child: CircularProgressIndicator()),
    ),
  );
  try {
    return await chat.fetchForViewing(message);
  } finally {
    nav.pop();
  }
}

Rect? _shareOrigin(BuildContext context) {
  final box = context.findRenderObject();
  if (box is! RenderBox || !box.hasSize) return null;
  return box.localToGlobal(Offset.zero) & box.size;
}

Future<void> _shareLocal(BuildContext context, File f, MessageFile? meta) {
  return SharePlus.instance.share(
    ShareParams(
      files: [XFile(f.path, name: meta?.name, mimeType: meta?.openMime)],
      sharePositionOrigin: _shareOrigin(context),
    ),
  );
}

Future<void> openChatFile(BuildContext context, ChatMessage message) async {
  final file = message.file;
  if (file == null || message.isPending) return;

  switch (file.kind) {
    case ChatFileKind.image:
      await Navigator.of(context).push(PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (_, __, ___) => ChatImageViewer(message: message),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ));
      return;
    case ChatFileKind.video:
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ChatVideoViewer(message: message)),
      );
      return;
    default:
      break;
  }

  final l10n = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.of(context);
  try {
    final local = await _localCopy(context, message);
    final result = await OpenFile.open(local.path, type: file.openMime);
    if (result.type == ResultType.noAppToOpen) {
      _toast(messenger, l10n.noAppToOpen, error: true);
    } else if (result.type != ResultType.done) {
      _toast(messenger,
          result.message.isNotEmpty ? result.message : l10n.couldNotOpenFile,
          error: true);
    }
  } catch (e) {
    _toast(messenger, '$e', error: true);
  }
}

Future<void> saveChatFile(BuildContext context, ChatMessage message) async {
  final file = message.file;
  if (file == null) return;
  final l10n = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.of(context);
  final kind = file.kind;

  File local;
  try {
    local = await _localCopy(context, message);
  } catch (e) {
    _toast(messenger, '$e', error: true);
    return;
  }

  if (kind == ChatFileKind.image || kind == ChatFileKind.video) {
    try {
      if (!await Gal.hasAccess()) {
        if (!await Gal.requestAccess()) {
          _toast(messenger, l10n.allowGalleryAccess, error: true);
          return;
        }
      }
      if (kind == ChatFileKind.image) {
        await Gal.putImage(local.path);
      } else {
        await Gal.putVideo(local.path);
      }
      _toast(messenger, l10n.savedToGallery);
      return;
    } on MissingPluginException {
      _toast(messenger, l10n.galleryPluginMissing);
    } on GalException {
      _toast(messenger, l10n.couldNotSaveToGallery, error: true);
      return;
    } catch (e) {
      _toast(messenger, '$e', error: true);
      return;
    }
  }

  if (!context.mounted) return;
  try {
    await _shareLocal(context, local, file);
  } catch (e) {
    _toast(messenger, '$e', error: true);
  }
}

Future<void> shareChatFile(BuildContext context, ChatMessage message) async {
  final file = message.file;
  if (file == null) return;
  final messenger = ScaffoldMessenger.of(context);
  try {
    final local = await _localCopy(context, message);
    if (!context.mounted) return;
    await _shareLocal(context, local, file);
  } catch (e) {
    _toast(messenger, '$e', error: true);
  }
}

// ═══════════════════════════ IMAGE ═══════════════════════════

class ChatImageViewer extends StatefulWidget {
  final ChatMessage message;
  const ChatImageViewer({super.key, required this.message});

  @override
  State<ChatImageViewer> createState() => _ChatImageViewerState();
}

class _ChatImageViewerState extends State<ChatImageViewer> {
  final TransformationController _tc = TransformationController();
  Offset _tap = Offset.zero;
  bool _chrome = true;

  @override
  void dispose() {
    _tc.dispose();
    super.dispose();
  }

  void _toggleZoom() {
    if (_tc.value.getMaxScaleOnAxis() > 1.01) {
      _tc.value = Matrix4.identity();
    } else {
      _tc.value = Matrix4.identity()
        ..setEntry(0, 0, 2.5)
        ..setEntry(1, 1, 2.5)
        ..setEntry(0, 3, -_tap.dx * 1.5)
        ..setEntry(1, 3, -_tap.dy * 1.5);
    }
  }

  Widget _image() {
    final l10n = AppLocalizations.of(context)!;
    final f = widget.message.file!;
    final headers = context.read<ChatProvider>().authHeaders;

    final net = CachedNetworkImage(
      imageUrl: f.url,
      httpHeaders: headers,
      cacheKey: 'chat_${widget.message.id}',
      fit: BoxFit.contain,
      placeholder: (_, __) => const Center(child: CircularProgressIndicator()),
      errorWidget: (_, __, ___) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.broken_image, size: 60, color: Colors.white54),
          const SizedBox(height: 8),
          Text(l10n.imageNotAvailable,
              style: const TextStyle(color: Colors.white54)),
        ],
      ),
    );

    final lp = f.localPath;
    if (lp != null) {
      return Image.file(File(lp),
          fit: BoxFit.contain, errorBuilder: (_, __, ___) => net);
    }
    return net;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final name = widget.message.file?.name ?? l10n.photo;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => setState(() => _chrome = !_chrome),
              onDoubleTapDown: (d) => _tap = d.localPosition,
              onDoubleTap: _toggleZoom,
              child: InteractiveViewer(
                transformationController: _tc,
                minScale: 1,
                maxScale: 5,
                child: Center(child: _image()),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              ignoring: !_chrome,
              child: AnimatedOpacity(
                opacity: _chrome ? 1 : 0,
                duration: const Duration(milliseconds: 180),
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.black87, Colors.transparent],
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close_rounded,
                              color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 15),
                          ),
                        ),
                        IconButton(
                          tooltip: l10n.saveToGallery,
                          icon: const Icon(Icons.download_rounded,
                              color: Colors.white),
                          onPressed: () => saveChatFile(context, widget.message),
                        ),
                        Builder(
                          builder: (ctx) => IconButton(
                            tooltip: l10n.share,
                            icon: const Icon(Icons.share_rounded,
                                color: Colors.white),
                            onPressed: () => shareChatFile(ctx, widget.message),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════ VIDEO ═══════════════════════════

class ChatVideoViewer extends StatefulWidget {
  final ChatMessage message;
  const ChatVideoViewer({super.key, required this.message});

  @override
  State<ChatVideoViewer> createState() => _ChatVideoViewerState();
}

class _ChatVideoViewerState extends State<ChatVideoViewer> {
  VideoPlayerController? _controller;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final chat = context.read<ChatProvider>();
    final url = widget.message.file?.url;
    VideoPlayerController? c;

    if (url != null) {
      final streaming = VideoPlayerController.networkUrl(
        Uri.parse(url),
        httpHeaders: chat.authHeaders,
      );
      try {
        await streaming.initialize().timeout(const Duration(seconds: 20));
        c = streaming;
      } catch (_) {
        await streaming.dispose();
      }
    }

    if (c == null) {
      try {
        final local = await chat.fetchForViewing(widget.message);
        final fromFile = VideoPlayerController.file(local);
        try {
          await fromFile.initialize();
          c = fromFile;
        } catch (_) {
          await fromFile.dispose();
          rethrow;
        }
      } catch (_) {
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          setState(() {
            _loading = false;
            _error = l10n.couldNotPlayVideo;
          });
        }
        return;
      }
    }

    if (!mounted) {
      await c.dispose();
      return;
    }
    setState(() {
      _controller = c;
      _loading = false;
    });
    await c.play();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          widget.message.file?.name ?? l10n.video,
          style: const TextStyle(fontSize: 15),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            tooltip: l10n.saveToGallery,
            icon: const Icon(Icons.download_rounded),
            onPressed: () => saveChatFile(context, widget.message),
          ),
          Builder(
            builder: (ctx) => IconButton(
              tooltip: l10n.share,
              icon: const Icon(Icons.share_rounded),
              onPressed: () => shareChatFile(ctx, widget.message),
            ),
          ),
        ],
      ),
      body: Center(
        child: _loading
            ? const CircularProgressIndicator(color: Colors.white)
            : _error != null || c == null
            ? Text(_error ?? l10n.couldNotPlayVideo,
            style: const TextStyle(color: Colors.white70))
            : GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => c.value.isPlaying ? c.pause() : c.play(),
          child: AspectRatio(
            aspectRatio: c.value.aspectRatio > 0
                ? c.value.aspectRatio
                : 16 / 9,
            child: Stack(
              alignment: Alignment.center,
              children: [
                VideoPlayer(c),
                ValueListenableBuilder<VideoPlayerValue>(
                  valueListenable: c,
                  builder: (_, v, __) => v.isPlaying
                      ? const SizedBox.shrink()
                      : const Icon(
                      Icons.play_circle_fill_rounded,
                      size: 72,
                      color: Colors.white70),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child:
                  VideoProgressIndicator(c, allowScrubbing: true),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}