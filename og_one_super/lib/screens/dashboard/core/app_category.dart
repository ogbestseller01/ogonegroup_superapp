import 'package:flutter/material.dart';

import '../../../models/mini_app.dart';
import '../../../config/app_strings.dart';

/// Categories shown in the Apps tab (in this order).
enum AppCategory { services, food, cleaning, delivery, partners }

extension AppCategoryX on AppCategory {
  IconData get icon => switch (this) {
    AppCategory.services => Icons.handyman_rounded,
    AppCategory.food => Icons.restaurant_rounded,
    AppCategory.cleaning => Icons.local_laundry_service_rounded,
    AppCategory.delivery => Icons.local_shipping_rounded,
    AppCategory.partners => Icons.handshake_rounded,
  };

  String label(AppLocalizations t) => switch (this) {
    AppCategory.services => t.services,
    AppCategory.food => t.categoryFood,
    AppCategory.cleaning => t.categoryCleaning,
    AppCategory.delivery => t.categoryDelivery,
    AppCategory.partners => t.categoryPartners,
  };
}

/// Slugs of third-party partner apps (Niajir, etc.). Add new partners here.
const Set<String> kPartnerSlugs = {'niajir'};

/// Maps a mini app to its category using its slug.
/// Adjust the keywords if your slugs are different.
AppCategory categoryOf(MiniApp app) {
  final s = app.slug.toLowerCase();

  if (kPartnerSlugs.contains(s)) return AppCategory.partners;

  if (s.contains('msosi') || s.contains('food') || s.contains('chakula')) {
    return AppCategory.food;
  }
  if (s.contains('laundry') ||
      s.contains('osha') ||
      s.contains('wash') ||
      s.contains('clean') ||
      s.contains('wafua')) {
    return AppCategory.cleaning;
  }
  if (s.contains('duma') ||
      s.contains('hama') ||
      s.contains('delivery') ||
      s.contains('mizigo')) {
    return AppCategory.delivery;
  }
  // fundi, nearbyfundi, dalali, nimepoteza, ...
  return AppCategory.services;
}