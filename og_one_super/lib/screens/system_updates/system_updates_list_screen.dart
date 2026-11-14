// lib/screens/system_updates/system_updates_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_strings.dart';
import '../../config/app_theme.dart';
import '../../models/system_update.dart';
import '../../providers/system_update_provider.dart';
import '../../widgets/system_update_sheet.dart';

/// Full list of ALL system updates — public endpoint (any date).
class SystemUpdatesListScreen extends StatefulWidget {
  const SystemUpdatesListScreen({super.key});

  static Route<void> route() =>
      MaterialPageRoute(builder: (_) => const SystemUpdatesListScreen());

  @override
  State<SystemUpdatesListScreen> createState() =>
      _SystemUpdatesListScreenState();
}

class _SystemUpdatesListScreenState extends State<SystemUpdatesListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<SystemUpdateProvider>().loadAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final t = context.t;

    return Scaffold(
      backgroundColor:
      isDark ? const Color(0xFF0F131A) : const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          t.systemUpdatesTitle,
          style: TextStyle(color: onSurface, fontWeight: FontWeight.w800),
        ),
        iconTheme: IconThemeData(color: onSurface),
      ),
      body: Consumer<SystemUpdateProvider>(
        builder: (context, p, _) {
          final items = p.all;

          // 1. Loading
          if (p.loading && items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2. Error
          if (p.error != null && items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        size: 48, color: Colors.redAccent),
                    const SizedBox(height: 16),
                    Text(
                      p.error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => p.loadAll(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          // 3. Empty
          if (items.isEmpty) {
            return RefreshIndicator(
              color: AppTheme.primary,
              onRefresh: () => p.loadAll(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withOpacity(0.04)
                                : Colors.black.withOpacity(0.03),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.inbox_rounded,
                            size: 56,
                            color: onSurface.withOpacity(0.35),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          t.systemUpdatesEmpty,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: onSurface,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          t.systemUpdatesEmptySub,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13.5,
                            height: 1.4,
                            color: onSurface.withOpacity(0.55),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          // 4. Data
          return RefreshIndicator(
            color: AppTheme.primary,
            onRefresh: () => p.loadAll(),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) =>
                  _UpdateTile(update: items[i], isDark: isDark),
            ),
          );
        },
      ),
    );
  }
}

class _UpdateTile extends StatelessWidget {
  final SystemUpdate update;
  final bool isDark;

  const _UpdateTile({required this.update, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Material(
      color: isDark ? const Color(0xFF222938) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => showSystemUpdateSheet(context, update),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.06)
                  : Colors.black.withOpacity(0.05),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.25 : 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(isDark ? 0.9 : 1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      update.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      update.description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: onSurface.withOpacity(0.62),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 13,
                          color: onSurface.withOpacity(0.45),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            formatSystemUpdateDate(update.publishedAt),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: onSurface.withOpacity(0.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: onSurface.withOpacity(0.35),
              ),
            ],
          ),
        ),
      ),
    );
  }
}