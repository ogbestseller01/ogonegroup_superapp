import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../config/app_theme.dart';
import '../screens/dashboard/core/dash_theme.dart';

/// Search field with the QR scan button inside it.
/// This is now the ONLY place where scanning starts.
class DashSearchBox extends StatelessWidget {
  static const double height = 50;

  final TextEditingController controller;
  final String hint;
  final bool hasText;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onScan;

  const DashSearchBox({
    super.key,
    required this.controller,
    required this.hint,
    required this.hasText,
    required this.onChanged,
    required this.onClear,
    required this.onScan,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = dashInk(isDark);

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: dashSurface(isDark),
        borderRadius: BorderRadius.circular(25),
        border: isDark
            ? Border.all(color: Colors.white.withValues(alpha: 0.08))
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.38 : 0.12),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        cursorColor: isDark ? AppTheme.secondary : AppTheme.primary,
        style: TextStyle(
          color: textColor,
          fontSize: 14.5,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              TextStyle(color: dashMuted(isDark), fontWeight: FontWeight.w500),
          prefixIcon: Icon(Icons.search_rounded, color: textColor, size: 21),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasText)
                IconButton(
                  onPressed: onClear,
                  icon: Icon(Icons.close_rounded, color: textColor, size: 19),
                  splashRadius: 18,
                ),
              Padding(
                padding: const EdgeInsets.only(right: 7),
                child: Material(
                  color: kGold.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onScan();
                    },
                    child: SizedBox(
                      width: 36,
                      height: 36,
                      child: Icon(Icons.qr_code_scanner_rounded,
                          color: dashAccent(isDark), size: 19),
                    ),
                  ),
                ),
              ),
            ],
          ),
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }
}
