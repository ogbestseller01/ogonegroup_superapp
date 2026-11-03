// lib/widgets/swipe_to_reply.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// WhatsApp-style "swipe right to reply".
class SwipeToReply extends StatefulWidget {
  final Widget child;
  final VoidCallback onReply;
  final bool enabled;

  const SwipeToReply({
    super.key,
    required this.child,
    required this.onReply,
    this.enabled = true,
  });

  @override
  State<SwipeToReply> createState() => _SwipeToReplyState();
}

class _SwipeToReplyState extends State<SwipeToReply> {
  static const double _trigger = 56;
  static const double _max = 72;

  double _dx = 0;
  bool _armed = false;
  bool _dragging = false;

  void _reset() => setState(() {
    _dx = 0;
    _armed = false;
    _dragging = false;
  });

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    final primary = Theme.of(context).colorScheme.primary;
    final t = (_dx / _trigger).clamp(0.0, 1.0).toDouble();

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragStart: (_) => setState(() => _dragging = true),
      onHorizontalDragUpdate: (d) {
        final next = (_dx + d.delta.dx).clamp(0.0, _max).toDouble();
        if (next != _dx) setState(() => _dx = next);
        if (_dx >= _trigger && !_armed) {
          _armed = true;
          HapticFeedback.mediumImpact();
        }
      },
      onHorizontalDragEnd: (_) {
        final fire = _armed;
        _reset();
        if (fire) widget.onReply();
      },
      onHorizontalDragCancel: _reset,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          Positioned(
            left: 12,
            child: Opacity(
              opacity: t,
              child: Transform.scale(
                scale: 0.6 + 0.4 * t,
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: primary.withValues(alpha: 0.15),
                  child: Icon(Icons.reply_rounded, size: 18, color: primary),
                ),
              ),
            ),
          ),
          AnimatedContainer(
            duration: _dragging ? Duration.zero : const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            transform: Matrix4.translationValues(_dx, 0, 0),
            child: widget.child,
          ),
        ],
      ),
    );
  }
}