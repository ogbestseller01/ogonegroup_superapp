import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
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

    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final horizontalPadding = isTablet ? 32.0 : 16.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.faq,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        elevation: 0,
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        color: theme.colorScheme.surface,
        child: provider.isLoading
            ? const Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        )
            : provider.error != null
            ? _buildErrorState(provider, l10n, theme)
            : provider.faqs.isEmpty
            ? Center(
          child: Text(
            l10n.noFaqs,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.hintColor,
              fontSize: 18,
            ),
          ),
        )
            : ListView.builder(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: 16,
          ),
          itemCount: provider.faqs.length,
          itemBuilder: (ctx, i) {
            final faq = provider.faqs[i];
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                    color: theme.dividerColor, width: 1.5),
              ),
              elevation: 0,
              child: ExpansionTile(
                leading: CircleAvatar(
                  backgroundColor:
                  AppTheme.primary.withOpacity(0.15),
                  child: Text(
                    '${i + 1}',
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  faq.question,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                children: [
                  Padding(
                    padding:
                    const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: Text(
                      faq.answer,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.7,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildErrorState(
      StaticPageProvider provider,
      AppLocalizations l10n,
      ThemeData theme,
      ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 80, color: theme.hintColor),
            const SizedBox(height: 20),
            Text(
              provider.error!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.hintColor),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => provider.loadFaqs(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: 32, vertical: 14),
              ),
              child: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }
}