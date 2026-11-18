// lib/widgets/user_avatar.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../config/app_theme.dart';


class UserAvatar extends StatelessWidget {
  final String name;
  final String? url;
  final double radius;
  final bool hasStatus; // gold ring = unseen post
  final bool showOnline;
  final VoidCallback? onTap;       // tap on the picture
  final VoidCallback? onStatusTap; // tap when the ring is shown (wins over onTap)

  const UserAvatar({
    super.key,
    required this.name,
    this.url,
    this.radius = 26,
    this.hasStatus = false,
    this.showOnline = false,
    this.onTap,
    this.onStatusTap,
  });

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  Widget _fallback(bool dark) => Container(
    color: AppTheme.primary.withOpacity(dark ? 0.35 : 0.14),
    alignment: Alignment.center,
    child: Text(
      _initials,
      style: TextStyle(
        fontSize: radius * 0.72,
        fontWeight: FontWeight.w600,
        color: dark ? Colors.white : AppTheme.primary,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final d = radius * 2;
    final hasUrl = url != null && url!.isNotEmpty;

    Widget pic = ClipOval(
      child: SizedBox(
        width: d,
        height: d,
        child: hasUrl
            ? CachedNetworkImage(
          imageUrl: url!,
          fit: BoxFit.cover,
          memCacheWidth: (d * 3).toInt(),
          placeholder: (_, __) => _fallback(dark),
          errorWidget: (_, __, ___) => _fallback(dark),
        )
            : _fallback(dark),
      ),
    );

    if (hasStatus) {
      pic = Container(
        padding: const EdgeInsets.all(2.5),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: SweepGradient(colors: [AppTheme.secondary, Color(0xFF25D366), AppTheme.secondary]),
        ),
        child: Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: dark ? AppTheme.darkBackground : Colors.white,
          ),
          child: pic,
        ),
      );
    }

    if (showOnline) {
      pic = Stack(clipBehavior: Clip.none, children: [
        pic,
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: 13,
            height: 13,
            decoration: BoxDecoration(
              color: const Color(0xFF25D366), // online green
              shape: BoxShape.circle,
              border: Border.all(color: dark ? AppTheme.darkBackground : Colors.white, width: 2),
            ),
          ),
        ),
      ]);
    }

    final handler = hasStatus ? (onStatusTap ?? onTap) : onTap;
    return handler == null ? pic : GestureDetector(onTap: handler, child: pic);
  }
}