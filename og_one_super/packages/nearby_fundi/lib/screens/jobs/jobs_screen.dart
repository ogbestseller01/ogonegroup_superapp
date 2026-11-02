// lib/screens/jobs/jobs_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../config/app_routes.dart';
import '../../config/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../models/job.dart';
import '../../providers/job_provider.dart';
import 'job_review_sheet.dart';

String _formatDate(DateTime? d) {
  if (d == null) return '—';
  final l = d.toLocal();
  return '${l.day.toString().padLeft(2, '0')}/'
      '${l.month.toString().padLeft(2, '0')}/${l.year}';
}

class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  bool _initialLoadDone = false;

  // ── Filter state ──────────────────────────────────────────
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _statusFilter; // null = All

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await context.read<JobProvider>().loadJobs();
      if (mounted) setState(() => _initialLoadDone = true);
    });
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleBack() {
    Navigator.of(context)
        .pushNamedAndRemoveUntil(AppRoutes.home, (_) => false);
  }

  void _openChat(Job job) {
    if (job.technicianUserId == 0) return;
    Navigator.pushNamed(context, AppRoutes.chatScreen,
        arguments: job.technicianUserId);
  }

  void _openJob(Job job) {
    Navigator.pushNamed(context, AppRoutes.jobDetail, arguments: job.id);
  }

  Future<void> _rate(Job job) async {
    final submitted = await showJobReviewSheet(context, job);
    if (submitted == true && mounted) {
      await context.read<JobProvider>().refreshJob(job.id);
    }
  }

  Future<void> _refresh() => context.read<JobProvider>().loadJobs(silent: true);

  // ─────────────────────────────────────────────────────────────
  // Filtering helpers
  // ─────────────────────────────────────────────────────────────
  bool _matchesFilter(Job job) {
    if (_searchQuery.isNotEmpty) {
      final name = job.serviceName.toLowerCase();
      final tech = job.technicianName.toLowerCase();
      final desc = job.description.toLowerCase();
      final match = name.contains(_searchQuery) ||
          tech.contains(_searchQuery) ||
          desc.contains(_searchQuery);
      if (!match) return false;
    }
    if (_statusFilter != null && job.status != _statusFilter) {
      return false;
    }
    return true;
  }

  // ─────────────────────────────────────────────────────────────
  // Contact Fundi dialog
  // ─────────────────────────────────────────────────────────────
  void _showContactDialog(Job job, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final phone = job.technicianPhone;
    final email = job.technicianEmail;
    final hasPhone = phone != null && phone.isNotEmpty;
    final hasEmail = email != null && email.isNotEmpty;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(Icons.contact_phone_rounded, color: AppTheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${l10n.contact} ${job.technicianName}', // localized "Contact"
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!hasPhone && !hasEmail)
              Text(
                l10n.noContactDetails, // Added new key
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                ),
              ),
            if (hasPhone)
              _contactRow(
                icon: Icons.phone_rounded,
                label: l10n.phone,
                value: phone,
                theme: theme,
                l10n: l10n,
              ),
            if (hasPhone && hasEmail) const SizedBox(height: 12),
            if (hasEmail)
              _contactRow(
                icon: Icons.email_rounded,
                label: l10n.email,
                value: email,
                theme: theme,
                l10n: l10n,
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.closeAction),
          ),
        ],
      ),
    );
  }

  Widget _contactRow({
    required IconData icon,
    required String label,
    required String value,
    required ThemeData theme,
    required AppLocalizations l10n,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
                const SizedBox(height: 2),
                SelectableText(
                  value,
                  style: const TextStyle(
                      fontSize: 14.5, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: l10n.copy,
            icon: const Icon(Icons.copy_rounded, size: 18),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: value));
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$label ${l10n.copy}'), // localized "copied"
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<JobProvider>();
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final hPad = MediaQuery.of(context).size.width > 600 ? 28.0 : 16.0;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          l10n.jobs,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        elevation: 0,
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: _handleBack,
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: () => provider.loadJobs(),
            tooltip: l10n.refresh,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppTheme.primary,
        child: _body(provider, l10n, theme, hPad),
      ),
    );
  }

  Widget _body(
      JobProvider provider, AppLocalizations l10n, ThemeData theme, double hPad) {
    if (provider.jobs.isEmpty && (provider.isLoading || !_initialLoadDone)) {
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.primary));
    }

    if (provider.jobs.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 120),
          Icon(Icons.work_outline_rounded,
              size: 72,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Center(
            child: Text(
              provider.error ?? l10n.noJobsYet,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              l10n.noJobsHint,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      );
    }

    // ── Counts (from full list, not filtered) ─────────────────
    final allJobs = provider.jobs;
    final total = allJobs.length;
    final pendingCount = allJobs.where((j) => j.isPending).length;
    final inProgressCount = allJobs.where((j) => j.isOnProgress).length;

    // ── Filtered list ────────────────────────────────────────
    final filtered = allJobs.where(_matchesFilter).toList();
    final active = filtered.where((j) => !j.isCompleted).toList();
    final done = filtered.where((j) => j.isCompleted).toList();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 28),
      children: [
        // ── Search bar ────────────────────────────────────────
        _searchBar(theme, l10n),
        const SizedBox(height: 14),

        // ── Status chips ──────────────────────────────────────
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _chip(null, l10n.allLabel),
              const SizedBox(width: 8),
              _chip(Job.pendingStatus, l10n.statusPending),
              const SizedBox(width: 8),
              _chip(Job.onProgressStatus, l10n.statusInProgress), // New key
              const SizedBox(width: 8),
              _chip(Job.completedStatus, l10n.statusCompleted), // New key
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Stats cards ───────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: _statCard(
                icon: Icons.list_alt_rounded,
                iconColor: AppTheme.primary,
                value: total,
                label: l10n.statTotal,
                theme: theme,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _statCard(
                icon: Icons.hourglass_empty_rounded,
                iconColor: Colors.blueGrey.shade600,
                value: pendingCount,
                label: l10n.statusPending,
                theme: theme,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _statCard(
                icon: Icons.check_circle_outline_rounded,
                iconColor: Colors.green.shade700,
                value: inProgressCount,
                label: l10n.statusInProgress, // Replaced hardcoded 'In Progress'
                theme: theme,
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),

        // ── Empty filter state ────────────────────────────────
        if (filtered.isEmpty) ...[
          const SizedBox(height: 40),
          Icon(Icons.filter_alt_off_rounded,
              size: 56,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
          const SizedBox(height: 12),
          Center(
            child: Text(
              l10n.noJobsMatchFilter, // New key
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],

        // ── Lists ─────────────────────────────────────────────
        if (active.isNotEmpty) ...[
          _sectionTitle(l10n.activeJobs, active.length, theme),
          const SizedBox(height: 10),
          ...active.map((j) => _jobCard(j, l10n, theme)),
        ],
        if (done.isNotEmpty) ...[
          if (active.isNotEmpty) const SizedBox(height: 8),
          _sectionTitle(l10n.completedJobs, done.length, theme),
          const SizedBox(height: 10),
          ...done.map((j) => _jobCard(j, l10n, theme)),
        ],
      ],
    );
  }

  // ── Search bar ────────────────────────────────────────────
  Widget _searchBar(ThemeData theme, AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: l10n.filterByFundiOrService, // Using existing key
          hintStyle: TextStyle(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
            fontSize: 14,
          ),
          prefixIcon: Icon(Icons.search_rounded,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
          suffixIcon: _searchQuery.isEmpty
              ? null
              : IconButton(
            icon: const Icon(Icons.close_rounded, size: 18),
            onPressed: () => _searchController.clear(),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        ),
        style: TextStyle(
          fontSize: 14,
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }

  // ── Status chip ───────────────────────────────────────────
  Widget _chip(String? key, String label) {
    final selected = _statusFilter == key;
    return GestureDetector(
      onTap: () => setState(() => _statusFilter = key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected
                ? AppTheme.primary
                : AppTheme.primary.withValues(alpha: 0.25),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppTheme.primary,
          ),
        ),
      ),
    );
  }

  // ── Stat card ─────────────────────────────────────────────
  Widget _statCard({
    required IconData icon,
    required Color iconColor,
    required int value,
    required String label,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(height: 8),
          Text(
            '$value',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, int count, ThemeData theme) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _jobCard(Job job, AppLocalizations l10n, ThemeData theme) {
    final subColor = theme.colorScheme.onSurface.withValues(alpha: 0.65);
    final softColor = theme.colorScheme.onSurface.withValues(alpha: 0.5);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _openJob(job),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        job.serviceName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _StatusPill(label: job.statusLabel, color: job.statusColor),
                  ],
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Icon(Icons.handyman_rounded, size: 16, color: softColor),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        job.technicianName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.5,
                          color: subColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                if (job.technicianArea != null &&
                    job.technicianArea!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 15, color: softColor),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          job.technicianArea!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 13, color: subColor),
                        ),
                      ),
                    ],
                  ),
                ],

                if (job.description.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      job.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: subColor,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],

                if (job.startedAt != null || job.isCompleted) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 14,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (job.startedAt != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.play_circle_outline_rounded,
                                size: 14, color: softColor),
                            const SizedBox(width: 5),
                            Text(
                              '${l10n.startedOn} ${_formatDate(job.startedAt)}',
                              style: TextStyle(fontSize: 12.5, color: subColor),
                            ),
                          ],
                        ),
                      if (job.isCompleted)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle_outline_rounded,
                                size: 14, color: AppTheme.success),
                            const SizedBox(width: 5),
                            Text(
                              '${l10n.completedOnLabel} ${_formatDate(job.completedAt)}',
                              style: TextStyle(fontSize: 12.5, color: subColor),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],

                if (job.isCompleted) ...[
                  const SizedBox(height: 12),
                  if (job.review != null)
                    Row(
                      children: [
                        RatingStars(rating: job.review!.rating, size: 18),
                        const SizedBox(width: 8),
                        if (job.review!.comment != null)
                          Expanded(
                            child: Text(
                              job.review!.comment!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12.5, color: subColor),
                            ),
                          ),
                      ],
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _rate(job),
                        icon: const Icon(Icons.star_rounded, size: 18),
                        label: Text(
                          l10n.rateThisJob, // Added new key
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.amber.shade800,
                          side: BorderSide(color: Colors.amber.shade700),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                ],

                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _openJob(job),
                        icon: const Icon(Icons.visibility_outlined, size: 18),
                        label: Text(
                          l10n.viewDetails,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primary,
                          side: BorderSide(
                              color: AppTheme.primary.withValues(alpha: 0.4)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    if (job.technicianUserId != 0) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _openChat(job),
                          icon: const Icon(Icons.chat_bubble_outline_rounded,
                              size: 18),
                          label: Text(
                            l10n.chat,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showContactDialog(job, l10n),
                    icon: const Icon(Icons.contact_phone_rounded, size: 18),
                    label: Text(
                      l10n.contactFundi, // Added new key
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                      side: BorderSide(
                          color: AppTheme.primary.withValues(alpha: 0.4)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}