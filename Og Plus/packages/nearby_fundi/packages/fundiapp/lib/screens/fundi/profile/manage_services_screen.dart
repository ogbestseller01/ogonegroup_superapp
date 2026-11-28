// lib/screens/fundi/profile/manage_services_screen.dart
//
// UI-only refresh. ALL logic (load / submit / selection / rules) is the same
// as before. Only new l10n key used: svcBack.

import 'package:flutter/material.dart';

import '../../../config/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/service_change.dart';
import '../../../services/api_service.dart';

const int _kReasonMin = 10;
const int _kReasonMax = 1000;

const double _kMaxContentWidth = 1100;
const double _kMaxBarWidth = 720;
const double _kTwoColumnBreakpoint = 840;

Color _a(Color c, double opacity) => c.withAlpha((opacity * 255).round());

class ManageServicesScreen extends StatefulWidget {
  const ManageServicesScreen({super.key});

  @override
  State<ManageServicesScreen> createState() => _ManageServicesScreenState();
}

class _ManageServicesScreenState extends State<ManageServicesScreen> {
  final ApiService _api = ApiService();

  ServiceChangeOptions? _options;
  Set<int> _selected = {};
  String _query = '';
  String _draftReason = '';
  bool _loading = true;
  bool _submitting = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  // ── Data (unchanged) ──────────────────────────────────────

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = _options == null;
      _failed = false;
    });

    ServiceChangeOptions? options;
    try {
      final res = await _api.getServiceChangeOptions();
      if (res.success && res.data is Map) {
        options = ServiceChangeOptions.fromJson(
          Map<String, dynamic>.from(res.data as Map),
        );
      }
    } catch (e) {
      debugPrint('Load services failed: $e');
    }

    if (!mounted) return;
    setState(() {
      _loading = false;
      if (options == null) {
        _failed = true;
      } else {
        _options = options;
        _selected = {...options.currentIds};
      }
    });
  }

  bool get _hasPending => _options?.latest?.isPending ?? false;

  Set<int> get _added => _selected.difference(_options?.currentIds ?? {});

  Set<int> get _removed =>
      (_options?.currentIds ?? <int>{}).difference(_selected);

  bool get _canReview =>
      !_hasPending &&
          !_submitting &&
          _selected.isNotEmpty &&
          (_added.isNotEmpty || _removed.isNotEmpty);

  List<String> _names(Iterable<int> ids) {
    final lang = Localizations.localeOf(context).languageCode;
    final wanted = ids.toSet();
    return _options!.services
        .where((s) => wanted.contains(s.id))
        .map((s) => s.name(lang))
        .toList();
  }

  Future<void> _reviewAndSubmit() async {
    if (!_canReview) return;

    final reason = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: false,
      builder: (_) => _ReasonDialog(
        added: _names(_added),
        removed: _names(_removed),
        initialReason: _draftReason,
        onChanged: (v) => _draftReason = v,
      ),
    );

    if (reason == null || !mounted) return;

    final l10n = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;
    setState(() => _submitting = true);

    // Blocking modal spinner while the submit API call is in flight.
    // Prevents back navigation / double taps until the call completes.
    _showBlockingLoader(l10n);

    try {
      final res = await _api.submitServiceChange(
        serviceIds: _selected.toList(),
        reason: reason,
        locale: lang,
      );
      if (!mounted) return;

      // Close the blocking loader before showing the result snack.
      _hideBlockingLoader();

      if (res.success) {
        _draftReason = '';
        _snack(l10n.svcSubmitted, AppTheme.success);
        await _load();
      } else {
        final fromServer = res.statusCode == 409 || res.statusCode == 422;
        _snack(fromServer ? res.message : l10n.svcSubmitFailed, AppTheme.error);
        if (res.statusCode == 409) await _load();
      }
    } catch (e) {
      debugPrint('Submit services failed: $e');
      if (mounted) {
        _hideBlockingLoader();
        _snack(l10n.svcSubmitFailed, AppTheme.error);
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // ── Blocking loader helpers ───────────────────────────────

  void _showBlockingLoader(AppLocalizations l10n) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return PopScope(
          canPop: false,
          child: AlertDialog(
            backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 28,
              vertical: 24,
            ),
            content: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.6,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(width: 18),
                Flexible(
                  child: Text(
                    l10n.svcSubmitting,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _hideBlockingLoader() {
    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  void _snack(String message, Color color) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // ── UI ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mq = MediaQuery.of(context);

    return MediaQuery(
      data: mq.copyWith(textScaler: mq.textScaler.clamp(maxScaleFactor: 1.3)),
      child: Scaffold(
        backgroundColor: isDark
            ? AppTheme.darkBackground
            : Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          // Fix: Explicitly set the icon theme to white to guarantee
          // the back arrow is visible, matching the Settings screen.
          iconTheme: const IconThemeData(color: Colors.white),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: _submitting ? null : () => Navigator.pop(context),
          ),
          title: Text(l10n.svcTitle),
          actions: [
            IconButton(
              tooltip: l10n.refresh,
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _loading || _submitting ? null : _load,
            ),
          ],
        ),
        body: _buildBody(l10n, isDark),
        bottomNavigationBar: _options == null || _hasPending
            ? null
            : _buildBottomBar(l10n, isDark),
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n, bool isDark) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_options == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_rounded,
                  size: 48, color: _a(AppTheme.error, 0.7)),
              const SizedBox(height: 12),
              Text(l10n.svcLoadFailed, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _load, child: Text(l10n.svcRetry)),
            ],
          ),
        ),
      );
    }

    final latest = _options!.latest;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final wide = width >= _kTwoColumnBreakpoint;
        final side = width > _kMaxContentWidth
            ? (width - _kMaxContentWidth) / 2 + 16
            : (wide ? 24.0 : 16.0);

        return RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(side, 16, side, 24),
            children: [
              if (_failed) ...[
                _Banner(
                  color: AppTheme.error,
                  icon: Icons.error_outline_rounded,
                  title: l10n.svcLoadFailed,
                ),
                const SizedBox(height: 12),
              ],
              if (latest != null && latest.isPending) ...[
                _Banner(
                  color: AppTheme.warning,
                  icon: Icons.hourglass_top_rounded,
                  title: l10n.svcPendingTitle,
                  lines: [
                    l10n.svcPendingBody,
                    if (latest.addedIds.isNotEmpty)
                      '${l10n.svcToAdd}: ${_names(latest.addedIds).join(', ')}',
                    if (latest.removedIds.isNotEmpty)
                      '${l10n.svcToRemove}: ${_names(latest.removedIds).join(', ')}',
                    '${l10n.svcYourReason}: ${latest.reason}',
                  ],
                ),
                const SizedBox(height: 12),
              ],
              if (latest != null && latest.isRejected) ...[
                _Banner(
                  color: AppTheme.error,
                  icon: Icons.cancel_outlined,
                  title: l10n.svcRejectedTitle,
                  lines: [
                    if ((latest.rejectionReason ?? '').isNotEmpty)
                      '${l10n.svcRejectionReason}: ${latest.rejectionReason}',
                  ],
                ),
                const SizedBox(height: 12),
              ],
              if (!_hasPending) ...[
                _SummaryRow(
                  selected: _selected.length,
                  added: _added.length,
                  removed: _removed.length,
                  l10n: l10n,
                ),
                const SizedBox(height: 12),
              ],
              _buildSearch(l10n, isDark),
              const SizedBox(height: 12),
              _buildCategories(l10n, wide, isDark),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearch(AppLocalizations l10n, bool isDark) {
    return TextField(
      onChanged: (v) => setState(() => _query = v),
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: l10n.svcSearchHint,
        prefixIcon: const Icon(Icons.search_rounded),
        filled: true,
        fillColor: isDark ? AppTheme.darkSurface : Colors.white,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? AppTheme.darkBorder : Colors.grey.shade300,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppTheme.primary, width: 1.6),
        ),
      ),
    );
  }

  /// Services grouped by category (same grouping logic as before).
  List<MapEntry<String, List<CatalogService>>> _groups(
      AppLocalizations l10n,
      ) {
    final lang = Localizations.localeOf(context).languageCode;
    final query = _query.trim().toLowerCase();
    final groups = <String, List<CatalogService>>{};
    final other = <CatalogService>[];

    for (final s in _options!.services) {
      final serviceMatches =
          query.isEmpty || s.name(lang).toLowerCase().contains(query);

      if (s.categories.isEmpty) {
        if (serviceMatches) other.add(s);
        continue;
      }

      for (final c in s.categories) {
        final category = c.name(lang);
        if (serviceMatches || category.toLowerCase().contains(query)) {
          groups.putIfAbsent(category, () => []).add(s);
        }
      }
    }

    final names = groups.keys.toList()..sort();
    return [
      for (final name in names) MapEntry(name, groups[name]!),
      if (other.isNotEmpty) MapEntry(l10n.svcOtherCategory, other),
    ];
  }

  Widget _buildCategories(AppLocalizations l10n, bool wide, bool isDark) {
    final lang = Localizations.localeOf(context).languageCode;
    final entries = _groups(l10n);

    if (entries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
        child: Column(
          children: [
            Icon(Icons.search_off_rounded,
                size: 44, color: Theme.of(context).hintColor),
            const SizedBox(height: 10),
            Text(l10n.svcNoResults, textAlign: TextAlign.center),
          ],
        ),
      );
    }

    final searching = _query.trim().isNotEmpty;

    Widget card(MapEntry<String, List<CatalogService>> e) => _CategoryCard(
      key: ValueKey('${e.key}-$searching'),
      title: e.key,
      selectedCount: e.value.where((s) => _selected.contains(s.id)).length,
      totalCount: e.value.length,
      expandedByDefault: true,
      isDark: isDark,
      children: [for (final s in e.value) _serviceTile(s, lang, l10n)],
    );

    if (!wide) {
      return Column(children: [for (final e in entries) card(e)]);
    }

    final left = <Widget>[];
    final right = <Widget>[];
    for (var i = 0; i < entries.length; i++) {
      (i.isEven ? left : right).add(card(entries[i]));
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Column(children: left)),
        const SizedBox(width: 12),
        Expanded(child: Column(children: right)),
      ],
    );
  }

  Widget _serviceTile(CatalogService s, String lang, AppLocalizations l10n) {
    final isCurrent = _options!.currentIds.contains(s.id);
    final isBlocked = !isCurrent && _options!.blockedIds.contains(s.id);
    final enabled = !_hasPending && !_submitting && !isBlocked;

    String? note;
    Color? noteColor;
    if (isBlocked) {
      note = l10n.svcBlocked;
      noteColor = AppTheme.error;
    } else if (_added.contains(s.id)) {
      note = l10n.svcToAdd;
      noteColor = AppTheme.success;
    } else if (_removed.contains(s.id)) {
      note = l10n.svcToRemove;
      noteColor = AppTheme.error;
    } else if (isCurrent) {
      note = l10n.svcCurrent;
    }

    return CheckboxListTile(
      value: _selected.contains(s.id),
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      tileColor: noteColor == null || isBlocked ? null : _a(noteColor, 0.07),
      title: Text(s.name(lang)),
      subtitle: note == null
          ? null
          : Text(
        note,
        style: TextStyle(
          color: noteColor,
          fontSize: 12.5,
          fontWeight: noteColor == null ? null : FontWeight.w600,
        ),
      ),
      onChanged: enabled
          ? (checked) => setState(() {
        if (checked ?? false) {
          _selected.add(s.id);
        } else {
          _selected.remove(s.id);
        }
      })
          : null,
    );
  }

  Widget _buildBottomBar(AppLocalizations l10n, bool isDark) {
    return Material(
      color: isDark ? AppTheme.darkSurface : Colors.white,
      elevation: 12,
      shadowColor: Colors.black26,
      child: SafeArea(
        top: false,
        // heightFactor: 1 is REQUIRED - a plain Center would fill the whole
        // screen height and cover the app bar and the list.
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _kMaxBarWidth),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _selected.isEmpty
                        ? l10n.svcSelectOne
                        : l10n.svcSelectedCount(_selected.length),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: _selected.isEmpty ? AppTheme.error : null,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _canReview ? _reviewAndSubmit : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 50),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: _submitting
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                          : Text(l10n.svcReviewChanges),
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed:
                      _submitting ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 46),
                        foregroundColor:
                        isDark ? Colors.white : AppTheme.primary,
                        side: BorderSide(
                          color: isDark
                              ? AppTheme.darkBorder
                              : Colors.grey.shade300,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: Text(l10n.svcBack),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── SUMMARY (selected / to add / to remove) ───────────────
class _SummaryRow extends StatelessWidget {
  final int selected;
  final int added;
  final int removed;
  final AppLocalizations l10n;

  const _SummaryRow({
    required this.selected,
    required this.added,
    required this.removed,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _Pill(
          icon: Icons.check_circle_outline_rounded,
          text: l10n.svcSelectedCount(selected),
          color: AppTheme.primary,
        ),
        if (added > 0)
          _Pill(
            icon: Icons.add_circle_outline,
            text: '${l10n.svcToAdd}: $added',
            color: AppTheme.success,
          ),
        if (removed > 0)
          _Pill(
            icon: Icons.remove_circle_outline,
            text: '${l10n.svcToRemove}: $removed',
            color: AppTheme.error,
          ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _Pill({required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _a(color, 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _a(color, 0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── COLLAPSIBLE CATEGORY CARD ─────────────────────────────
class _CategoryCard extends StatelessWidget {
  final String title;
  final int selectedCount;
  final int totalCount;
  final bool expandedByDefault;
  final bool isDark;
  final List<Widget> children;

  const _CategoryCard({
    super.key,
    required this.title,
    required this.selectedCount,
    required this.totalCount,
    required this.expandedByDefault,
    required this.isDark,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      color: isDark ? AppTheme.darkSurface : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: isDark ? AppTheme.darkBorder : Colors.grey.shade200,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: expandedByDefault,
          shape: const Border(),
          collapsedShape: const Border(),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.only(bottom: 6),
          title: Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _a(
                selectedCount > 0
                    ? AppTheme.primary
                    : Theme.of(context).hintColor,
                0.12,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$selectedCount/$totalCount',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
          children: children,
        ),
      ),
    );
  }
}

// ─── STATUS BANNER ─────────────────────────────────────────
class _Banner extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;
  final List<String> lines;

  const _Banner({
    required this.color,
    required this.icon,
    required this.title,
    this.lines = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _a(color, 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _a(color, 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                for (final line in lines)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(line),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── CONFIRMATION MODAL WITH REASON ────────────────────────
class _ReasonDialog extends StatefulWidget {
  final List<String> added;
  final List<String> removed;
  final String initialReason;
  final ValueChanged<String> onChanged;

  const _ReasonDialog({
    required this.added,
    required this.removed,
    required this.initialReason,
    required this.onChanged,
  });

  @override
  State<_ReasonDialog> createState() => _ReasonDialogState();
}

class _ReasonDialogState extends State<_ReasonDialog> {
  late final TextEditingController _controller =
  TextEditingController(text: widget.initialReason);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _valid => _controller.text.trim().length >= _kReasonMin;

  Widget _changeBox(
      String title,
      List<String> names,
      Color color,
      IconData icon,
      ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _a(color, 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _a(color, 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final name in names)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '• $name',
                style:
                const TextStyle(fontWeight: FontWeight.w500, height: 1.3),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final narrow = MediaQuery.of(context).size.width < 360;

    final cancelBtn = OutlinedButton(
      onPressed: () => Navigator.pop(context),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        side: BorderSide(
          color: isDark ? AppTheme.darkBorder : Colors.grey.shade300,
        ),
        foregroundColor: isDark ? Colors.white : AppTheme.primary,
      ),
      child: Text(l10n.svcCancel),
    );

    final submitBtn = ElevatedButton(
      onPressed:
      _valid ? () => Navigator.pop(context, _controller.text.trim()) : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 48),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Text(
        l10n.svcSubmit,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      actionsPadding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _a(AppTheme.primary, 0.10),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.edit_document,
                    color: AppTheme.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.svcConfirmTitle,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n.svcConfirmBody,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white70 : Colors.black54,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.added.isNotEmpty)
                _changeBox(l10n.svcToAdd, widget.added, AppTheme.success,
                    Icons.add_circle_outline),
              if (widget.removed.isNotEmpty)
                _changeBox(l10n.svcToRemove, widget.removed, AppTheme.error,
                    Icons.remove_circle_outline),
              const SizedBox(height: 4),
              TextField(
                controller: _controller,
                minLines: 3,
                maxLines: 5,
                maxLength: _kReasonMax,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (v) {
                  widget.onChanged(v);
                  setState(() {});
                },
                decoration: InputDecoration(
                  labelText: l10n.svcReasonLabel,
                  hintText: l10n.svcReasonHint,
                  helperText: l10n.svcReasonMin,
                  helperMaxLines: 2,
                  alignLabelWithHint: true,
                  filled: true,
                  fillColor: isDark ? Colors.black12 : Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color:
                      isDark ? AppTheme.darkBorder : Colors.grey.shade300,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide:
                    const BorderSide(color: AppTheme.primary, width: 2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        if (narrow)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [submitBtn, const SizedBox(height: 8), cancelBtn],
          )
        else
          Row(
            children: [
              Expanded(child: cancelBtn),
              const SizedBox(width: 12),
              Expanded(flex: 2, child: submitBtn),
            ],
          ),
      ],
    );
  }
}