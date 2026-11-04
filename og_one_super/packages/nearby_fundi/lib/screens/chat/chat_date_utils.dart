// lib/screens/chat/chat_date_utils.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Returns a localized string representing the day (Today, Yesterday, Day Name, or Date).
/// Uses the phone's current locale by default.
String chatDayLabel(BuildContext context, DateTime t) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final date = DateTime(t.year, t.month, t.day);
  final diff = today.difference(date).inDays;

  // Get the current locale from the app (e.g., 'en', 'sw')
  final locale = Localizations.localeOf(context).languageCode;

  if (diff == 0) {
    return locale == 'sw' ? 'Leo' : 'Today';
  }
  if (diff == 1) {
    return locale == 'sw' ? 'Jana' : 'Yesterday';
  }

  if (diff < 7) {
    // Returns localized day name (e.g. "Monday" / "Jumatatu")
    return DateFormat('EEEE', locale).format(t);
  }

  // Returns localized date (e.g. "Oct 24, 2026" / "24 Okt, 2026")
  return DateFormat('MMM d, yyyy', locale).format(t);
}