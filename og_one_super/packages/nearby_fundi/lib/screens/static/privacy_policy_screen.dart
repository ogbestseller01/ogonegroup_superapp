// screens/profile/privacy_policy_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../providers/static_page_provider.dart';
import '../../providers/settings_provider.dart';
import '../../l10n/app_localizations.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refresh();
    });
  }

  Future<void> _refresh() async {
    final settings = context.read<SettingsProvider>();
    final locale = settings.locale; // e.g., 'en' or 'sw'
    await context.read<StaticPageProvider>().loadPrivacyPolicy(locale: locale);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StaticPageProvider>();
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.privacyPolicy,
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _refresh,
            tooltip: l10n.refresh,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppTheme.primary,
        child: provider.isLoading
            ? const Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        )
            : provider.error != null
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 56,
                color: theme.hintColor,
              ),
              const SizedBox(height: 16),
              Text(
                provider.error!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.hintColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _refresh,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(l10n.retry),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        )
            : SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Text(
            provider.privacyPolicy?.content ?? l10n.noContent,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.8),
          ),
        ),
      ),
    );
  }
}