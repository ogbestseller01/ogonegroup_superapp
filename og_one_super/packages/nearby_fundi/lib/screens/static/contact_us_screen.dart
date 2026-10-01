import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/app_theme.dart';
import '../../l10n/app_localizations.dart';

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  static const String email = 'ogbestseller01@gmail.com';
  static const String website = 'https://ogonegroup.co.tz';
  static const List<String> phones = [
    '0679117297',
    '0612118849',
    '0746382880',
  ];

  Future<void> _launchEmail() async {
    final Uri uri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _launchWebsite() async {
    final Uri uri = Uri.parse(website);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _launchPhone(String number) async {
    final Uri uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final horizontalPadding = isTablet ? 32.0 : 20.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.contactUs,
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
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: 20,
          ),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.contact_mail_outlined,
                    size: 40,
                    color: AppTheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.getInTouch,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                  const Divider(height: 32, thickness: 1.5),
                  _buildContactTile(
                    icon: Icons.email_outlined,
                    title: l10n.email,
                    value: email,
                    onTap: _launchEmail,
                    theme: theme,
                  ),
                  const SizedBox(height: 16),
                  _buildContactTile(
                    icon: Icons.language_outlined,
                    title: l10n.website,
                    value: website,
                    onTap: _launchWebsite,
                    theme: theme,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.phoneNumbers,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...phones.map(
                        (phone) => _buildPhoneTile(phone, l10n.call, theme),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContactTile({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppTheme.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    value,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                size: 16, color: theme.hintColor),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneTile(
      String phone,
      String callLabel,
      ThemeData theme,
      ) {
    return InkWell(
      onTap: () => _launchPhone(phone),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.phone_android_outlined,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(phone, style: theme.textTheme.bodyMedium),
            ),
            Text(
              callLabel,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}