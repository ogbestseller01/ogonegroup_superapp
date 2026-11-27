// lib/screens/chat/chat_date_utils.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';

/// Returns a localized string representing the day (Today, Yesterday, Day Name, or Date).
String chatDayLabel(BuildContext context, DateTime t) {
  final l10n = AppLocalizations.of(context)!;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final date = DateTime(t.year, t.month, t.day);
  final diff = today.difference(date).inDays;
  final locale = Localizations.localeOf(context).languageCode;

  if (diff == 0) return l10n.today;
  if (diff == 1) return l10n.yesterday;
  if (diff < 7) return DateFormat('EEEE', locale).format(t);
  return DateFormat('MMM d, yyyy', locale).format(t);
}

/// Short relative time like "5 min ago", "2 h ago", "Yesterday".
String chatRelativeTime(BuildContext context, DateTime? d) {
  if (d == null) return '';
  final l10n = AppLocalizations.of(context)!;
  final diff = DateTime.now().difference(d);
  if (diff.inMinutes < 1) return l10n.justNow;
  if (diff.inHours < 1) return l10n.minAgo(diff.inMinutes);
  if (diff.inDays < 1) return l10n.hAgo(diff.inHours);
  if (diff.inDays == 1) return l10n.yesterday;
  return l10n.daysAgo(diff.inDays);
}

/// Full date+time used in the message-info sheet.
String chatFullDateTime(BuildContext context, DateTime t) {
  final l10n = AppLocalizations.of(context)!;
  final local = t.toLocal();
  final locale = Localizations.localeOf(context).languageCode;
  final timeStr = DateFormat.Hm(locale).format(local);
  final now = DateTime.now();

  if (local.year == now.year && local.month == now.month && local.day == now.day) {
    return timeStr;
  }
  final yesterday = now.subtract(const Duration(days: 1));
  if (local.year == yesterday.year &&
      local.month == yesterday.month &&
      local.day == yesterday.day) {
    return '${l10n.yesterday} $timeStr';
  }
  return '${DateFormat.yMd(locale).format(local)} $timeStr';
}