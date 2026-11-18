// lib/widgets/custom_button.dart
import 'dart:async';
import 'package:flutter/material.dart';

class CustomButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isDisabled;
  final Color? backgroundColor;
  final Color? textColor;
  final double height;
  final double borderRadius;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
    this.backgroundColor,
    this.textColor,
    this.height = 52,
    this.borderRadius = 12,
  });

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..addListener(() {
      setState(() {
        _progress = _controller.value;
      });
    });
  }

  @override
  void didUpdateWidget(CustomButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading && !oldWidget.isLoading) {
      _controller.repeat(reverse: false);
    } else if (!widget.isLoading && oldWidget.isLoading) {
      _controller.stop();
      _controller.reset();
      setState(() => _progress = 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEnabled = widget.onPressed != null && !widget.isDisabled && !widget.isLoading;

    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isEnabled ? widget.onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: widget.backgroundColor ?? theme.primaryColor,
          foregroundColor: widget.textColor ?? Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
          elevation: 0,
        ),
        child: widget.isLoading
            ? _buildLoadingIndicator()
            : Text(
          widget.text,
          style: theme.textTheme.titleMedium?.copyWith(
            color: widget.textColor ?? Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    final percentage = (_progress * 100).round();
    return SizedBox(
      height: 36,
      width: 36,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: _progress,
            strokeWidth: 3.5,
            backgroundColor: Colors.white.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(
              widget.textColor ?? Colors.white,
            ),
          ),
          Text(
            '$percentage%',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: widget.textColor ?? Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}