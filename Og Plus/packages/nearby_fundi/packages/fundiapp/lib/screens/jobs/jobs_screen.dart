// FILE: lib/screens/jobs/jobs_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_routes.dart';
import '../../config/app_theme.dart';
import '../../models/job.dart';
import '../../providers/job_provider.dart';
import '../../widgets/work_status_widgets.dart';
import '../../l10n/app_localizations.dart';
import 'job_detail_screen.dart';

class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  static const _filters = ['all', 'pending', 'on-progress', 'completed'];

  String _filter = 'all';
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<JobProvider>().loadJobs();
    });
  }

  List<WorkJob> _apply(List<WorkJob> all) {
    final q = _query.trim().toLowerCase();
    return all.where((j) {
      if (_filter != 'all' && j.status != _filter) return false;
      if (q.isEmpty) return true;
      return j.jobNumber.toLowerCase().contains(q) ||
          (j.customerName ?? '').toLowerCase().contains(q) ||
          (j.serviceName ?? '').toLowerCase().contains(q) ||
          (j.description ?? '').toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<JobProvider>();
    final filtered = _apply(provider.jobs);

    final counts = <String, int>{
      'all': provider.jobs.length,
      for (final s in _filters.skip(1)) s: provider.countByStatus(s),
    };

    return Scaffold(
      backgroundColor: isDark
          ? AppTheme.darkBackground
          : Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
        automaticallyImplyLeading: false,
        titleSpacing: 12,
        title: Row(
          children: [
            _AppBarButton(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: () =>
                  Navigator.pushReplacementNamed(context, AppRoutes.home),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                l10n.jobs,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            _AppBarButton(
              icon: Icons.refresh_rounded,
              onTap: provider.isLoading ? () {} : () => provider.loadJobs(),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          WorkSearchField(
            hint: l10n.searchJobsHint,
            onChanged: (v) => setState(() => _query = v),
          ),
          WorkFilterBar(
            options: _filters,
            selected: _filter,
            counts: counts,
            onSelected: (v) => setState(() => _filter = v), labels: {},
          ),
          const SizedBox(height: 8),
          Expanded(child: _buildBody(provider, filtered, l10n)),
        ],
      ),
    );
  }

  Widget _buildBody(
      JobProvider provider,
      List<WorkJob> filtered,
      AppLocalizations l10n,
      ) {
    if (provider.isLoading && provider.jobs.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      );
    }

    if (provider.error != null && provider.jobs.isEmpty) {
      return WorkEmptyState(
        icon: Icons.error_outline_rounded,
        message: provider.error!,
        onRetry: provider.loadJobs,
      );
    }

    return RefreshIndicator(
      color: AppTheme.primary,
      onRefresh: provider.loadJobs,
      child: filtered.isEmpty
          ? ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 80),
          WorkEmptyState(
            icon: Icons.work_outline_rounded,
            message: l10n.noJobsFound,
          ),
        ],
      )
          : ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: filtered.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _JobCard(job: filtered[i]),
      ),
    );
  }
}

class _AppBarButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _AppBarButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  final WorkJob job;

  const _JobCard({required this.job});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? Colors.white : AppTheme.primary;
    final color = workStatusColor(job.status);

    return WorkCard(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => JobDetailScreen(job: job)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.13),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(workStatusIcon(job.status), color: color, size: 24),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        job.jobNumber,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          inherit: true,
                          fontWeight: FontWeight.w800,
                          fontSize: 14.5,
                          color: primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    WorkStatusBadge(status: job.status),
                  ],
                ),
                WorkMetaLine(
                  icon: Icons.person_outline_rounded,
                  text: job.customerName ?? '—',
                ),
                WorkMetaLine(
                  icon: Icons.build_outlined,
                  text: job.serviceName ?? '—',
                ),
                WorkMetaLine(
                  icon: Icons.confirmation_number_outlined,
                  text: job.tickets.isEmpty
                      ? l10n.noTicket
                      : '${job.tickets.length} ${l10n.tickets.toLowerCase()} • ${job.tickets.last.ticketNumber}',
                ),
                WorkMetaLine(
                  icon: Icons.access_time_rounded,
                  text: '${l10n.created} ${formatEAT(job.createdAt)}',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}