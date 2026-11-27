// lib/screens/chat/tabs/updates_tab.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/chat_update.dart';
import '../../../providers/chat_provider.dart';
import '../../../widgets/user_avatar.dart';
import '../chat_date_utils.dart';
import '../widgets/open_blog.dart';

class UpdatesTab extends StatefulWidget {
  const UpdatesTab({super.key});

  @override
  State<UpdatesTab> createState() => _UpdatesTabState();
}

class _UpdatesTabState extends State<UpdatesTab> {
  List<ChatUpdate>? _items;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await context.read<ChatProvider>().fetchUpdates();
      if (mounted) {
        setState(() {
          _items = list;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  Future<void> _open(ChatUpdate u) async {
    setState(() => _items = [
      for (final x in _items!)
        x.technicianId == u.technicianId ? x.seen() : x
    ]);
    await openTechnicianBlog(context, u.technicianId);
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hint = Theme.of(context).hintColor;
    final items = _items;
    final screenW = MediaQuery.of(context).size.width;
    final isCompact = screenW < 360;

    Widget body;
    if (_error != null && items == null) {
      body = ListView(children: [
        const SizedBox(height: 120),
        Center(
          child: Text(_error!, style: TextStyle(color: hint)),
        ),
      ]);
    } else if (items == null) {
      body =
      const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    } else if (items.isEmpty) {
      body = ListView(children: [
        const SizedBox(height: 120),
        Icon(Icons.auto_awesome_outlined,
            size: 60, color: hint.withValues(alpha: 0.4)),
        const SizedBox(height: 14),
        Center(
          child: Text(
            l10n.noRecentUpdates,
            style: TextStyle(
              fontSize: isCompact ? 15 : 17,
              fontWeight: FontWeight.w600,
              color: hint,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              l10n.postsFromFundis,
              style: TextStyle(color: hint),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ]);
    } else {
      final fresh = items.where((e) => e.hasNew).toList();
      final seen = items.where((e) => !e.hasNew).toList();

      Widget tile(ChatUpdate u) => ListTile(
        onTap: () => _open(u),
        leading: UserAvatar(
          name: u.name,
          url: u.photo,
          radius: 26,
          hasStatus: u.hasNew,
        ),
        title: Text(
          u.name,
          style: TextStyle(
            fontWeight: u.hasNew ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        subtitle: Text(
          u.hasNew
              ? '${l10n.newPostsCount(u.newCount)} · ${chatRelativeTime(context, u.latestAt)}'
              : chatRelativeTime(context, u.latestAt),
        ),
        trailing: u.thumb == null
            ? (u.hasVideo ? const Icon(Icons.videocam_rounded) : null)
            : ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            u.thumb!,
            width: 44,
            height: 44,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
            const SizedBox(width: 44, height: 44),
          ),
        ),
      );

      Widget header(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
        child: Text(
          t,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: hint,
          ),
        ),
      );

      body = ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          if (fresh.isNotEmpty) header(l10n.newUpdates),
          ...fresh.map(tile),
          if (seen.isNotEmpty) header(l10n.viewedUpdates),
          ...seen.map(tile),
        ],
      );
    }

    return RefreshIndicator(
      color: AppTheme.primary,
      onRefresh: _load,
      child: body,
    );
  }
}