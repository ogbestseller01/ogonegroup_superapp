// lib/screens/chat/widgets/typing_indicator.dart

import 'package:flutter/material.dart';

class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Typing',
            style: TextStyle(
              color: theme.textTheme.bodyMedium?.color,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 6),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Row(
                children: List.generate(3, (index) {
                  final delay = index * 0.15;
                  final value = (_controller.value - delay) % 1.0;
                  final size = 4 + (value * 4);

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1.5),
                    child: Container(
                      width: size.clamp(4.0, 8.0),
                      height: size.clamp(4.0, 8.0),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withOpacity(
                          0.3 + (value * 0.7),
                        ),
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                }),
              );
            },
          ),
        ],
      ),
    );
  }
}