import 'package:flutter/material.dart';
import '../../../config/app_theme.dart';

class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : const Color(0xFFF4F7FC),
      appBar: AppBar(
        title: const Text('Others / Coming Soon', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
        backgroundColor: AppTheme.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.hourglass_empty_rounded, size: 80, color: AppTheme.primary),
            const SizedBox(height: 20),
            Text(
              'More features coming soon!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppTheme.primary),
            ),
            const SizedBox(height: 10),
            Text(
              'Stay tuned for updates.',
              style: TextStyle(fontSize: 16, color: isDark ? Colors.white70 : Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}