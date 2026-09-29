import 'package:flutter/material.dart';
import '../../../config/app_theme.dart';

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : const Color(0xFFF4F7FC),
      appBar: AppBar(
        title: const Text('Contact Us', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
        backgroundColor: AppTheme.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.email, color: AppTheme.primary),
              title: Text('Email', style: TextStyle(color: isDark ? Colors.white : AppTheme.primary)),
              subtitle: Text('support@yourapp.com', style: TextStyle(color: isDark ? Colors.white70 : Colors.grey.shade600)),
            ),
            ListTile(
              leading: Icon(Icons.phone, color: AppTheme.primary),
              title: Text('Phone', style: TextStyle(color: isDark ? Colors.white : AppTheme.primary)),
              subtitle: Text('+1 234 567 890', style: TextStyle(color: isDark ? Colors.white70 : Colors.grey.shade600)),
            ),
            ListTile(
              leading: Icon(Icons.language, color: AppTheme.primary),
              title: Text('Website', style: TextStyle(color: isDark ? Colors.white : AppTheme.primary)),
              subtitle: Text('www.yourapp.com', style: TextStyle(color: isDark ? Colors.white70 : Colors.grey.shade600)),
            ),
          ],
        ),
      ),
    );
  }
}