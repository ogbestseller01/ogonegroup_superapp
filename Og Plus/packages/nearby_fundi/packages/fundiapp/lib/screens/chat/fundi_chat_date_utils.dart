// lib/screens/fundi/chat/fundi_chat_date_utils.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

String fundiChatDayLabel(BuildContext context, DateTime t) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final date = DateTime(t.year, t.month, t.day);
  final diff = today.difference(date).inDays;

  final locale = Localizations.localeOf(context).languageCode;

  if (diff == 0) return locale == 'sw' ? 'Leo' : 'Today';
  if (diff == 1) return locale == 'sw' ? 'Jana' : 'Yesterday';

  if (diff < 7) return DateFormat('EEEE', locale).format(t);
  return DateFormat('MMM d, yyyy', locale).format(t);
}