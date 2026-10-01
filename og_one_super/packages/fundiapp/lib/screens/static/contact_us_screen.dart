import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/app_localizations.dart';

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  static const String email = 'ogbestseller01@gmail.com';
  static const String website = 'https://ogonegroup.co.tz';
  static const List<String> phones = ['0679117297', '0752456880', '0612118849'];
  // WhatsApp numbers – include the country code (e.g., 255 for Tanzania)
  static const List<String> whatsappNumbers = ['0679117297', '0612118849', '0746382880'];

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

  Future<void> _launchWhatsApp(String number) async {
    // Remove any non-digit characters to get a clean international number
    final cleanNumber = number.replaceAll(RegExp(r'[^0-9]'), '');
    // Try the WhatsApp app deep link
    final Uri uri = Uri.parse('whatsapp://send?phone=$cleanNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      // Fallback to WhatsApp Web
      final Uri fallbackUri = Uri.parse('https://wa.me/$cleanNumber');
      if (await canLaunchUrl(fallbackUri)) {
        await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          l10n.contactUs,
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
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Container(
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: theme.shadowColor.withOpacity(0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.contact_mail_outlined,
                      size: 32,
                      color: theme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l10n.getInTouch,
                    style: theme.textTheme.headlineMedium,
                  ),
                  const Divider(height: 32),
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
                  const SizedBox(height: 24),
                  Text(
                    l10n.phoneNumbers,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  ...phones.map((phone) => _buildPhoneTile(phone, l10n.call, theme)),
                  const SizedBox(height: 24),
                  Text(
                    'WhatsApp',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  ...whatsappNumbers.map((phone) => _buildWhatsAppTile(phone, theme)),
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
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: theme.primaryColor, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    value,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: theme.hintColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneTile(String phone, String callLabel, ThemeData theme) {
    return InkWell(
      onTap: () => _launchPhone(phone),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.phone_android_outlined,
                size: 22,
                color: Color(0xFF075E54), // Use theme color if you prefer
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                phone,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                callLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWhatsAppTile(String phone, ThemeData theme) {
    return InkWell(
      onTap: () => _launchWhatsApp(phone),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.chat_rounded,
                size: 22,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'WhatsApp',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    phone,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Chat',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}