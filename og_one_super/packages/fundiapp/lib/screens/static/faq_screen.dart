import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/static_page_provider.dart';
import '../../l10n/app_localizations.dart';

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StaticPageProvider>().loadFaqs();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StaticPageProvider>();
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          l10n.faq,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: provider.isLoading
          ? Center(child: CircularProgressIndicator(color: theme.primaryColor))
          : provider.error != null
          ? _buildErrorView(provider, l10n, theme)
          : provider.faqs.isEmpty
          ? _buildEmptyView(l10n, theme)
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: provider.faqs.length,
        itemBuilder: (ctx, i) {
          final faq = provider.faqs[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: theme.shadowColor.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ExpansionTile(
              leading: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(
                      color: theme.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              title: Text(
                faq.question,
                style: theme.textTheme.titleMedium,
              ),
              trailing: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: theme.primaryColor,
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  child: Text(
                    faq.answer,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.7,
                      color: theme.colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorView(StaticPageProvider provider, AppLocalizations l10n, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Oops!',
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              provider.error!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.hintColor,
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () => provider.loadFaqs(),
              icon: const Icon(Icons.refresh_rounded),
              label: Text(l10n.retry),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView(AppLocalizations l10n, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.dividerColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.help_outline_rounded,
                size: 48,
                color: theme.hintColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.noFaqs,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.hintColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}