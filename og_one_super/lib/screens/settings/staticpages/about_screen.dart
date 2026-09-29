import 'package:flutter/material.dart';
import '../../../config/app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : const Color(0xFFF4F7FC),
      appBar: AppBar(
        title: const Text('About', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
        backgroundColor: AppTheme.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 40),
            Icon(Icons.info_outline_rounded, size: 80, color: AppTheme.primary),
            const SizedBox(height: 20),
            Text('App Name', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppTheme.primary)),
            const SizedBox(height: 8),
            Text('Version 0.0.1', style: TextStyle(color: isDark ? Colors.white70 : Colors.grey.shade600)),
            const SizedBox(height: 40),
            Text(
              'This is a placeholder for the About section. Describe your app here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: isDark ? Colors.white70 : Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}