// lib/screens/scanner/app_qr_codes_screen.dart
//
// Shows one QR code per mini app. Scanning a code with the dashboard
// scanner opens that mini app.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../config/app_strings.dart';
import '../../data/mini_apps_data.dart';
import '../../models/mini_app.dart';
import '../../services/qr_service.dart';

const Color _navy = Color(0xFF1A2B4A);

Color _colorOf(MiniApp a) {
  switch (a.slug) {
    case 'nearbyfundi':
      return const Color(0xFF2B7BFF);
    case 'fundiapp':
      return const Color(0xFFFFB300);
    default:
      return Color(int.parse(a.color.replaceFirst('#', '0xFF')));
  }
}

class AppQrCodesScreen extends StatelessWidget {
  const AppQrCodesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sw = Localizations.localeOf(context).languageCode == 'sw';

    // Live apps first, "coming soon" last.
    final apps = [
      ...miniApps.where((a) => !a.isComingSoon),
      ...miniApps.where((a) => a.isComingSoon),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(sw ? 'QR za Apps' : 'App QR Codes'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        itemCount: apps.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, i) {
          if (i == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                sw
                    ? 'Changanua QR ya app kwa kitufe cha scan kwenye dashibodi ili kuifungua.'
                    : 'Scan an app QR code with the scan button on the dashboard to open it.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : const Color(0xFF5B6B82),
                ),
              ),
            );
          }
          final app = apps[i - 1];
          return _QrCard(
            app: app,
            title: t.serviceTitle(app.slug),
            soonLabel: sw ? 'Inakuja' : 'Soon',
            isDark: isDark,
          );
        },
      ),
    );
  }
}

class _QrCard extends StatelessWidget {
  final MiniApp app;
  final String title;
  final String soonLabel;
  final bool isDark;

  const _QrCard({
    required this.app,
    required this.title,
    required this.soonLabel,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final color = _colorOf(app);
    final soon = app.isComingSoon;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16233A) : Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: isDark ? 0.18 : 0.14),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : _navy,
                  ),
                ),
              ),
              if (soon)
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFB300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    soonLabel,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: _navy,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          // QR codes always need a light background to stay scannable.
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: QrImageView(
              data: QrService.payloadFor(app.slug),
              version: QrVersions.auto,
              size: 210,
              errorCorrectionLevel: QrErrorCorrectLevel.H,
              embeddedImage: const AssetImage('assets/images/homeimg.png'),
              embeddedImageStyle:
              const QrEmbeddedImageStyle(size: Size(42, 42)),
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: _navy,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: _navy,
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: soon
                ? null
                : () async {
              final text = QrService.payloadFor(app.slug);
              await Clipboard.setData(ClipboardData(text: text));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(
                  content: Text(text),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                ));
            },
            icon: const Icon(Icons.copy_rounded, size: 17),
            label: Text(
              QrService.payloadFor(app.slug),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}