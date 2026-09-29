import 'package:flutter/material.dart';
import '../../../config/app_theme.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : const Color(0xFFF4F7FC),
      appBar: AppBar(
        title: const Text('Terms & Conditions', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
        backgroundColor: AppTheme.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Text(
          'Your Terms and Conditions text goes here...\n\n1. Acceptable Use\n2. Privacy Policy\n3. etc.',
          style: TextStyle(fontSize: 16, height: 1.5, color: isDark ? Colors.white70 : Colors.grey.shade800),
        ),
      ),
    );
  }
}