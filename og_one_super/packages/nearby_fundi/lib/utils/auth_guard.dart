// lib/utils/auth_guard.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/app_routes.dart';
import '../config/app_theme.dart';
import '../providers/auth_provider.dart';

const Color _gold = Color(0xFFF2B93B);

class AuthGuard {
  AuthGuard._();

  static bool isLoggedIn(BuildContext context) {
    return context.read<AuthProvider>().isLoggedIn;
  }

  /// Returns true if logged in, false if the modal was shown.
  static bool ensure(BuildContext context, {String? message}) {
    if (isLoggedIn(context)) return true;
    showLoginRequired(context, message: message);
    return false;
  }

  static Future<void> showLoginRequired(
      BuildContext context, {
        String? message,
      }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final ink = isDark ? Colors.white : AppTheme.primary;

    // Capture the root navigator (same as LoginScreen back arrow)
    final rootNavigator = Navigator.of(context, rootNavigator: true);

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: theme.colorScheme.surface,
      constraints: const BoxConstraints(maxWidth: 520),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle + Close (X)
                Row(
                  children: [
                    const Spacer(),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.dividerColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      icon: Icon(Icons.close_rounded, color: theme.hintColor),
                      tooltip: 'Close',
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Lock icon
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.30),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.lock_person_rounded,
                    size: 40,
                    color: _gold,
                  ),
                ),

                const SizedBox(height: 18),

                Text(
                  'Please create an account',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: ink,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  message ??
                      'Sign in or create a free account to search for '
                          'fundis, request services and chat.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: theme.hintColor,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 28),

                // Login
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      rootNavigator.pushNamed(AppRoutes.login);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Login',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Create account
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      rootNavigator.pushNamed(AppRoutes.register);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ink,
                      side: BorderSide(color: theme.dividerColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Create account',
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ========== GO HOME (same as Login back arrow) ==========
                TextButton(
                  onPressed: () {
                    // 1. Close the modal first
                    Navigator.pop(sheetContext);

                    // 2. Exactly the same as LoginScreen top-left arrow
                    rootNavigator.maybePop();
                  },
                  child: Text(
                    'Go Home',
                    style: TextStyle(
                      color: theme.hintColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 14.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}