// lib/screens/chat/media_docs_screen.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/app_theme.dart';
import '../../models/chat_message.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/chat_viewers.dart';

/// Pops with a message id when the user taps "Show in chat".
class MediaDocsScreen extends StatelessWidget {
  final int conversationId;
  final String peerName;

  const MediaDocsScreen({
    super.key,
    required this.conversationId,
    required this.peerName
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: dark ? const Color(0xFF1F2C34) : AppTheme.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          // ADDED: Explicit white back arrow
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Colors.white),
            onPressed: () => Navigator.maybePop(context),
          ),
          title: Text(peerName, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
          bottom: const TabBar(
            indicatorColor: AppTheme.secondary,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [Tab(text: 'Media'), Tab(text: 'Docs'), Tab(text: 'Links')],
          ),
        ),
        // FIXED: Pass the actual conversationId instead of 0
        body: TabBarView(children: [
          _Pager(conversationId: conversationId, tab: 'media'),
          _Pager(conversationId: conversationId, tab: 'docs'),
          _Pager(conversationId: conversationId, tab: 'links'),
        ]),
      ),
    );
  }
}

class _Pager extends StatefulWidget {
  final int conversationId;
  final String tab;
  const _Pager({required this.conversationId, required this.tab});

  @override
  State<_Pager> createState() => _PagerState();
}

class _PagerState extends State<_Pager> with AutomaticKeepAliveClientMixin {
  final List<ChatMessage> _items = [];
  final _scroll = ScrollController();
  bool _loading = false, _more = true, _loaded = false;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.extentAfter < 300) _load();
    });
    _load();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (_loading || !_more) return;
    setState(() => _loading = true);
    try {
      final (list, more) = await context
          .read<ChatProvider>()
          .fetchMedia(widget.conversationId, widget.tab, beforeId: _items.isEmpty ? null : _items.last.id);
      if (!mounted) return;
      setState(() {
        _items.addAll(list);
        _more = more;
        _loaded = true;
        _error = null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formatDay(DateTime t) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(t.year, t.month, t.day);
    final diff = today.difference(date).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return DateFormat('EEEE').format(t);
    return DateFormat('MMMM d, yyyy').format(t);
  }

  static final _url = RegExp(r'https?://[^\s]+', caseSensitive: false);

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final hint = Theme.of(context).hintColor;

    if (!_loaded) {
      return Center(
        child: _error != null ? Text(_error!, style: TextStyle(color: hint)) : const CircularProgressIndicator(color: AppTheme.primary),
      );
    }
    if (_items.isEmpty) {
      final label = switch (widget.tab) { 'docs' => 'No documents', 'links' => 'No links', _ => 'No media' };
      return Center(child: Text(label, style: TextStyle(color: hint, fontSize: 16)));
    }

    final headers = context.read<ChatProvider>().authHeaders;

    if (widget.tab == 'media') {
      return GridView.builder(
        controller: _scroll,
        padding: const EdgeInsets.all(2),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 2, crossAxisSpacing: 2),
        itemCount: _items.length,
        itemBuilder: (_, i) {
          final m = _items[i];
          return GestureDetector(
            onTap: () => openChatFile(context, m),
            child: Stack(fit: StackFit.expand, children: [
              m.isImage
                  ? CachedNetworkImage(
                imageUrl: m.file?.url ?? '',
                httpHeaders: headers,
                cacheKey: 'chat_${m.id}',
                memCacheWidth: 300,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(color: Colors.grey.shade300, child: const Icon(Icons.broken_image)),
              )
                  : Container(
                color: const Color(0xFF1B1F23),
                child: const Center(child: Icon(Icons.play_circle_fill_rounded, color: Colors.white70, size: 36)),
              ),
            ]),
          );
        },
      );
    }

    if (widget.tab == 'docs') {
      return ListView.separated(
        controller: _scroll,
        itemCount: _items.length,
        separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
        itemBuilder: (_, i) {
          final m = _items[i];
          final f = m.file;
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
              child: Icon(switch (f?.kind) {
                ChatFileKind.pdf => Icons.picture_as_pdf_rounded,
                ChatFileKind.word => Icons.description_rounded,
                ChatFileKind.excel => Icons.table_chart_rounded,
                ChatFileKind.powerpoint => Icons.slideshow_rounded,
                _ => Icons.insert_drive_file_rounded,
              }, color: AppTheme.primary),
            ),
            title: Text(f?.name ?? 'File', maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text([
              if ((f?.ext ?? '').isNotEmpty) f!.ext!.toUpperCase(),
              f?.formattedSize ?? '',
              if (m.time != null) _formatDay(m.time!),
            ].where((e) => e.isNotEmpty).join(' · ')),
            trailing: IconButton(icon: const Icon(Icons.download_rounded), onPressed: () => saveChatFile(context, m)),
            onTap: () => openChatFile(context, m),
            onLongPress: () => Navigator.pop(context, m.id),
          );
        },
      );
    }

    // links
    final rows = <(String, ChatMessage)>[
      for (final m in _items)
        for (final x in _url.allMatches(m.content ?? '')) (x.group(0)!, m),
    ];
    return ListView.separated(
      controller: _scroll,
      itemCount: rows.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
      itemBuilder: (_, i) {
        final (url, m) = rows[i];
        return ListTile(
          leading: CircleAvatar(backgroundColor: AppTheme.primary.withValues(alpha: 0.12), child: const Icon(Icons.link_rounded, color: AppTheme.primary)),
          title: Text(url, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF1E6FD9))),
          subtitle: Text(m.time == null ? '' : _formatDay(m.time!)),
          onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
          onLongPress: () => Navigator.pop(context, m.id),
        );
      },
    );
  }
}