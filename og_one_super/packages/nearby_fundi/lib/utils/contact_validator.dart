// lib/utils/contact_validator.dart
import 'package:flutter/material.dart';

class ContactValidator {
  /// Returns `null` if the text is safe (no contact info).
  /// Returns an error message string if contact info is found.
  static String? validate(String? value) {
    if (value == null || value.trim().isEmpty) return null;

    final text = value.toLowerCase();

    // 1. Check for Email Addresses (gmail, yahoo, outlook, custom, etc.)
    final emailRegex = RegExp(
      r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}',
      caseSensitive: false,
    );
    if (emailRegex.hasMatch(text)) {
      return 'Please remove any email addresses from your description.';
    }

    // 2. Check for Phone Numbers
    // Matches 10+ digits, allowing spaces, dashes, parentheses, and plus signs.
    final phoneRegex = RegExp(
      r'(\+?\d[\d\s\-\(\)]{8,}\d)',
      caseSensitive: false,
    );
    if (phoneRegex.hasMatch(text)) {
      return 'Please remove any phone numbers from your description.';
    }

    // 3. Check for written numbers (zero, one, two...)
    final wordNumbers = RegExp(
      r'\b(zero|one|two|three|four|five|six|seven|eight|nine)\b',
      caseSensitive: false,
    );
    if (wordNumbers.hasMatch(text)) {
      return 'Please do not write out phone numbers in words.';
    }

    // 4. Check for social handles / links
    final socialRegex = RegExp(
      r'(@[a-zA-Z0-9_]{3,})|(wa\.me)|(t\.me)|(instagram\.com)|(facebook\.com)|(twitter\.com)|(tiktok\.com)',
      caseSensitive: false,
    );
    if (socialRegex.hasMatch(text)) {
      return 'Please remove social media handles or links.';
    }

    // 5. Check for common contact intent keywords
    final keywords = [
      'call me', 'call my', 'text me', 'whatsapp', 'whats app',
      'email me', 'contact me', 'nipigie', 'nifuate', 'sms'
    ];
    for (final keyword in keywords) {
      if (text.contains(keyword)) {
        return 'Please use the app chat/call features instead of sharing contact info.';
      }
    }

    return null;
  }
}