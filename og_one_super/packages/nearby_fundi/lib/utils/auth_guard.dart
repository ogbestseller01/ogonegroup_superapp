// lib/utils/auth_guard.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/app_routes.dart';
import '../config/app_theme.dart';
import '../providers/auth_provider.dart';

const Color _gold = Color(0xFFF2B93B);

class AuthGuard {
  AuthGuard._();

  /// True when the user is logged in (read once, no rebuild).
  static bool isLoggedIn(BuildContext context) {
    return context.read<AuthProvider>().isLoggedIn;
  }

  /// Call before any action that needs an account:
  ///
  ///   if (!AuthGuard.ensure(context)) return;
  ///
  /// true  -> logged in, continue
  /// false -> modal shown, stop
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
    final navigator = Navigator.of(context);

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      constraints: const BoxConstraints(maxWidth: 520),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 24),
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
                  child: const Icon(Icons.lock_person_rounded,
                      size: 40, color: _gold),
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
                const SizedBox(height: 22),

                // Login button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      navigator.pushNamed(AppRoutes.login);
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
                const SizedBox(height: 6),

                // Create account
                TextButton(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    navigator.pushNamed(AppRoutes.register);
                  },
                  child: Text(
                    'Create account',
                    style: TextStyle(
                      color: ink,
                      fontWeight: FontWeight.w800,
                      fontSize: 14.5,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(sheetContext),
                  child: Text(
                    'Maybe later',
                    style: TextStyle(
                      color: theme.hintColor,
                      fontWeight: FontWeight.w600,
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