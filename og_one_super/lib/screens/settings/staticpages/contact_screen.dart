import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../config/app_strings.dart';
import '../../../config/app_theme.dart';
import '../../../widgets/page_skeletons.dart';
import 'static_page_scaffold.dart' show staticAppBar;

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  static const String email = 'ogbestseller01@gmail.com';
  static const String website = 'https://ogonegroup.co.tz';
  static const List<String> phones = [
    '0679117297',
    '0752456880',
    '0612118849',
  ];
  static const List<String> whatsappNumbers = [
    '0679117297',
    '0612118849',
    '0746382880',
  ];

  static const String _countryCode = '255';

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _loading = false);
    });
  }

  Future<void> _open(
      BuildContext context,
      Uri uri,
      String failMessage, {
        LaunchMode mode = LaunchMode.platformDefault,
      }) async {
    var ok = false;
    try {
      ok = await launchUrl(uri, mode: mode);
    } catch (_) {
      ok = false;
    }
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(failMessage)));
    }
  }

  String _intlNumber(String number) {
    final digits = number.replaceAll(RegExp(r'[^0-9]'), '');
    return digits.startsWith('0')
        ? '$_countryCode${digits.substring(1)}'
        : digits;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = context.t;
    final titleColor = isDark ? Colors.white : AppTheme.primary;
    final mutedColor = isDark ? Colors.white60 : Colors.grey.shade600;

    void openEmail() =>
        _open(context, Uri(scheme: 'mailto', path: email), t.couldNotOpen);
    void openWebsite() => _open(
      context,
      Uri.parse(website),
      t.couldNotOpen,
      mode: LaunchMode.externalApplication,
    );
    void call(String n) =>
        _open(context, Uri(scheme: 'tel', path: n), t.couldNotOpen);
    void whatsApp(String n) => _open(
      context,
      Uri.parse('https://wa.me/${_intlNumber(n)}'),
      t.couldNotOpen,
      mode: LaunchMode.externalApplication,
    );

    Widget sectionTitle(String text) => Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          color: mutedColor,
        ),
      ),
    );

    return Scaffold(
      backgroundColor:
      isDark ? AppTheme.darkBackground : const Color(0xFFF4F7FC),
      appBar: staticAppBar(t.contactUs),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: _loading
            ? const ContactPageSkeleton(key: ValueKey('sk'))
            : ListView(
          key: const ValueKey('content'),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          children: [
            Container(
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
                    child: const Icon(
                      Icons.contact_mail_outlined,
                      color: AppTheme.secondary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.getInTouch,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          t.getInTouchSub,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            sectionTitle(t.emailWebsite),
            _ContactTile(
              icon: Icons.email_outlined,
              label: t.email,
              value: email,
              isDark: isDark,
              onTap: openEmail,
            ),
            const SizedBox(height: 10),
            _ContactTile(
              icon: Icons.language_outlined,
              label: t.website,
              value: website,
              isDark: isDark,
              onTap: openWebsite,
            ),

            sectionTitle(t.phoneNumbers),
            for (final p in phones) ...[
              _ContactTile(
                icon: Icons.phone_android_outlined,
                value: p,
                badge: t.call,
                isDark: isDark,
                onTap: () => call(p),
              ),
              const SizedBox(height: 10),
            ],

            sectionTitle(t.whatsappSection),
            for (final p in whatsappNumbers) ...[
              _ContactTile(
                icon: Icons.chat_rounded,
                iconColor: const Color(0xFF25D366),
                label: 'WhatsApp',
                value: p,
                badge: t.chat,
                badgeColor: const Color(0xFF25D366),
                isDark: isDark,
                onTap: () => whatsApp(p),
              ),
              const SizedBox(height: 10),
            ],

            const SizedBox(height: 6),
            Center(
              child: Text(
                'OG ONE GROUP',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: titleColor.withValues(alpha: 0.4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String? label;
  final String value;
  final String? badge;
  final Color? badgeColor;
  final bool isDark;
  final VoidCallback onTap;

  const _ContactTile({
    required this.icon,
    required this.value,
    required this.isDark,
    required this.onTap,
    this.iconColor,
    this.label,
    this.badge,
    this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    final accent =
        iconColor ?? (isDark ? AppTheme.secondary : AppTheme.primary);
    final chipColor =
        badgeColor ?? (isDark ? AppTheme.secondary : AppTheme.primary);

    return Material(
      color: isDark ? AppTheme.darkSurface : Colors.white,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? AppTheme.darkBorder : const Color(0xFFE9EDF5),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accent, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (label != null)
                      Text(
                        label!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color:
                          isDark ? Colors.white54 : Colors.grey.shade600,
                        ),
                      ),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppTheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              if (badge != null)
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: chipColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    badge!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: chipColor,
                    ),
                  ),
                )
              else
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: isDark ? Colors.white54 : Colors.grey.shade400,
                ),
            ],
          ),
        ),
      ),
    );
  }
}