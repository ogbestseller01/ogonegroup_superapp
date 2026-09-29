// lib/widgets/notification_bell_icon.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';

/// Drop-in replacement for the old inline `Consumer<NotificationProvider>`
/// bell block in app bars. Animates a bounce-scale "pop" on the badge
/// whenever the unread count increases live (new FCM push arrives),
/// the same feel as TikTok / Instagram / YouTube badges.
class NotificationBellIcon extends StatefulWidget {
  final VoidCallback onTap;
  final Color iconColor;

  const NotificationBellIcon({
    super.key,
    required this.onTap,
    this.iconColor = Colors.white,
  });

  @override
  State<NotificationBellIcon> createState() => _NotificationBellIconState();
}

class _NotificationBellIconState extends State<NotificationBellIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );

  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.45), weight: 40),
    TweenSequenceItem(tween: Tween(begin: 1.45, end: 0.9), weight: 30),
    TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.0), weight: 30),
  ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

  int _lastCount = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, provider, child) {
        final count = provider.unreadCount;

        if (count > _lastCount || provider.pulseBadge) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _controller.forward(from: 0);
            provider.consumePulse();
          });
        }
        _lastCount = count;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: Icon(
                Icons.notifications_outlined,
                color: widget.iconColor,
                size: 26,
              ),
              onPressed: widget.onTap,
            ),
            if (count > 0)
              Positioned(
                top: 6,
                right: 6,
                child: ScaleTransition(
                  scale: _scale,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      count > 9 ? '9+' : '$count',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}