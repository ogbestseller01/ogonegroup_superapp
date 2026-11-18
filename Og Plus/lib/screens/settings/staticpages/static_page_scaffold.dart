// lib/screens/settings/staticpages/static_page_scaffold.dart
//
// Shared building blocks for every backend-driven static page:
// loading / error / retry / pull-to-refresh + a tolerant document renderer.

import 'package:flutter/material.dart';

import '../../../config/app_theme.dart';
import '../../../services/api_service.dart';

typedef PageLoader = Future<ApiResponse> Function();
typedef PageBuilder = List<Widget> Function(BuildContext context, dynamic data);

// ============================================================
// SCAFFOLD
// ============================================================
class StaticPageScaffold extends StatefulWidget {
  final String title;
  final PageLoader loader;
  final PageBuilder builder;

  /// Optional skeleton shown while loading (instead of a spinner).
  final Widget? skeleton;

  const StaticPageScaffold({
    super.key,
    required this.title,
    required this.loader,
    required this.builder,
    this.skeleton,
  });

  @override
  State<StaticPageScaffold> createState() => _StaticPageScaffoldState();
}

class _StaticPageScaffoldState extends State<StaticPageScaffold> {
  bool _loading = true;
  String? _error;
  dynamic _data;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    final res = await widget.loader();
    if (!mounted) return;

    if (res.success) {
      setState(() {
        _loading = false;
        _error = null;
        _data = res.data;
      });
    } else if (_data != null) {
      // Keep showing the old content on a failed refresh.
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.message)),
      );
    } else {
      setState(() {
        _loading = false;
        _error = res.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget body;
    if (_loading) {
      body = widget.skeleton ??
          const Center(
            child: CircularProgressIndicator(color: AppTheme.primary),
          );
    } else if (_error != null) {
      body = _ErrorView(message: _error!, onRetry: _load, isDark: isDark);
    } else {
      final children = widget.builder(context, _data);
      body = RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: () => _load(silent: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          children: children,
        ),
      );
    }

    return Scaffold(
      backgroundColor:
      isDark ? AppTheme.darkBackground : const Color(0xFFF4F7FC),
      appBar: staticAppBar(widget.title),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: KeyedSubtree(
          key: ValueKey(
              _loading ? 'sk' : (_error != null ? 'err' : 'content')),
          child: body,
        ),
      ),
    );
  }
}

AppBar staticAppBar(String title) => AppBar(
  title: Text(
    title,
    style: const TextStyle(
      fontWeight: FontWeight.w700,
      color: Colors.white,
    ),
  ),
  backgroundColor: AppTheme.primary,
  iconTheme: const IconThemeData(color: Colors.white),
  elevation: 0,
  centerTitle: true,
);

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final bool isDark;

  const _ErrorView({
    required this.message,
    required this.onRetry,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 56,
              color: isDark ? Colors.white38 : Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                height: 1.4,
                color: isDark ? Colors.white70 : Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// TEXT HELPERS
// ============================================================

/// Converts simple HTML (as often returned by CMS-style backends) to text.
String htmlToText(String input) {
  var s = input
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'</(p|div|h[1-6]|li|tr)>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<li[^>]*>', caseSensitive: false), '• ')
      .replaceAll(RegExp(r'<[^>]+>'), '')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'");
  s = s.replaceAll(RegExp(r'\n{3,}'), '\n\n');
  return s.trim();
}

String? _str(Map m, List<String> keys) {
  for (final k in keys) {
    final v = m[k];
    if (v is String && v.trim().isNotEmpty) return htmlToText(v);
    if (v is num) return v.toString();
  }
  return null;
}

String _pretty(String key) {
  final words = key.replaceAll('_', ' ').trim();
  if (words.isEmpty) return key;
  return words[0].toUpperCase() + words.substring(1);
}

String _shortDate(String s) =>
    RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(s) ? s.substring(0, 10) : s;

dynamic _unwrap(dynamic data) {
  if (data is Map && data.length == 1) {
    final v = data.values.first;
    if (v is Map || v is List) return _unwrap(v);
  }
  return data;
}

// ============================================================
// DOCUMENT (About / Terms / Privacy)
// ============================================================
class _Section {
  final String? heading;
  final String body;
  const _Section(this.heading, this.body);
}

const _titleKeys = ['title', 'name', 'heading'];
const _bodyKeys = [
  'content',
  'body',
  'description',
  'text',
  'policy',
  'terms',
  'about',
];
const _contactKeys = ['email', 'phone', 'website', 'address'];
const _metaKeys = {
  'id',
  'slug',
  'created_at',
  'updated_at',
  'last_updated',
  'version',
  'is_active',
  'status',
  ..._contactKeys,
  ..._titleKeys,
};

List<_Section> _sectionsFromList(List list) {
  final out = <_Section>[];
  for (final item in list) {
    if (item is String && item.trim().isNotEmpty) {
      out.add(_Section(null, htmlToText(item)));
    } else if (item is Map) {
      final body = _str(item, _bodyKeys);
      if (body != null) out.add(_Section(_str(item, _titleKeys), body));
    }
  }
  return out;
}

/// Builds the children for a document-style static page.
/// Works with a plain string, a map (title/content/sections/...) or a list.
List<Widget> buildDocumentChildren(
    BuildContext context,
    dynamic rawData, {
      required String fallbackTitle,
      required IconData icon,
    }) {
  final data = _unwrap(rawData);

  String title = fallbackTitle;
  String? updated;
  String? version;
  final sections = <_Section>[];
  final contacts = <String, String>{};

  if (data is String) {
    if (data.trim().isNotEmpty) sections.add(_Section(null, htmlToText(data)));
  } else if (data is List) {
    sections.addAll(_sectionsFromList(data));
  } else if (data is Map) {
    title = _str(data, _titleKeys) ?? fallbackTitle;
    updated = _str(data, ['updated_at', 'last_updated']);
    version = _str(data, ['version']);

    final body = _str(data, _bodyKeys);
    if (body != null) sections.add(_Section(null, body));

    for (final k in ['sections', 'items', 'points']) {
      if (data[k] is List) sections.addAll(_sectionsFromList(data[k] as List));
    }

    if (sections.isEmpty) {
      data.forEach((k, v) {
        if (_metaKeys.contains(k)) return;
        if (v is String && v.trim().isNotEmpty) {
          sections.add(_Section(_pretty(k.toString()), htmlToText(v)));
        }
      });
    }

    for (final k in _contactKeys) {
      final v = data[k];
      if (v is String && v.trim().isNotEmpty) contacts[k] = v.trim();
    }
  }

  final isDark = Theme.of(context).brightness == Brightness.dark;
  final children = <Widget>[
    _DocHeader(title: title, icon: icon, updated: updated, version: version),
    const SizedBox(height: 20),
  ];

  if (sections.isEmpty && contacts.isEmpty) {
    children.add(
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text(
            'Nothing to show yet.',
            style: TextStyle(
              color: isDark ? Colors.white54 : Colors.grey.shade600,
            ),
          ),
        ),
      ),
    );
    return children;
  }

  for (final s in sections) {
    children
      ..add(_SectionCard(section: s, isDark: isDark))
      ..add(const SizedBox(height: 12));
  }

  if (contacts.isNotEmpty) {
    children.add(_ContactCard(contacts: contacts, isDark: isDark));
  }
  return children;
}

BoxDecoration cardDecoration(bool isDark) => BoxDecoration(
  color: isDark ? AppTheme.darkSurface : Colors.white,
  borderRadius: BorderRadius.circular(18),
  border: isDark
      ? Border.all(color: AppTheme.darkBorder.withValues(alpha: 0.6))
      : null,
  boxShadow: isDark
      ? null
      : [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 10,
      offset: const Offset(0, 3),
    ),
  ],
);

class _DocHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final String? updated;
  final String? version;

  const _DocHeader({
    required this.title,
    required this.icon,
    this.updated,
    this.version,
  });

  @override
  Widget build(BuildContext context) {
    final meta = [
      if (version != null) 'Version $version',
      if (updated != null) 'Updated ${_shortDate(updated!)}',
    ].join('  •  ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF001D45), Color(0xFF0A3670)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppTheme.secondary, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                if (meta.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    meta,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final _Section section;
  final bool isDark;

  const _SectionCard({required this.section, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: cardDecoration(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (section.heading != null) ...[
            Text(
              section.heading!,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppTheme.primary,
              ),
            ),
            const SizedBox(height: 8),
          ],
          SelectableText(
            section.body,
            style: TextStyle(
              fontSize: 14.5,
              height: 1.6,
              color: isDark ? Colors.white70 : Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final Map<String, String> contacts;
  final bool isDark;

  const _ContactCard({required this.contacts, required this.isDark});

  static const _icons = {
    'email': Icons.email_rounded,
    'phone': Icons.phone_rounded,
    'website': Icons.language_rounded,
    'address': Icons.location_on_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: cardDecoration(isDark),
      clipBehavior: Clip.antiAlias,
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          children: contacts.entries.map((e) {
            return ListTile(
              leading: Icon(
                _icons[e.key] ?? Icons.info_outline_rounded,
                color: isDark ? AppTheme.secondary : AppTheme.primary,
              ),
              title: Text(
                _pretty(e.key),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: isDark ? Colors.white : AppTheme.primary,
                ),
              ),
              subtitle: SelectableText(
                e.value,
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.grey.shade700,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}