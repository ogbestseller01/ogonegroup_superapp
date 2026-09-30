import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final Color? backgroundColor;
  final Color? textColor;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final Color bgColor = backgroundColor ??
        (isOutlined ? Colors.transparent : theme.primaryColor);
    final Color txtColor = textColor ??
        (isOutlined ? theme.primaryColor : theme.colorScheme.onPrimary);

    final buttonStyle = isOutlined
        ? OutlinedButton.styleFrom(
      foregroundColor: txtColor,
      side: BorderSide(
        color: bgColor == Colors.transparent
            ? theme.primaryColor
            : bgColor,
      ),
      minimumSize: const Size(double.infinity, 50),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    )
        : ElevatedButton.styleFrom(
      backgroundColor: bgColor,
      foregroundColor: txtColor,
      minimumSize: const Size(double.infinity, 50),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );

    final Widget child = isLoading
        ? SpinKitThreeBounce(
      color: theme.colorScheme.onPrimary,
      size: 20,
    )
        : Text(
      text,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: txtColor,
      ),
    );

    return isOutlined
        ? OutlinedButton(
      onPressed: (isLoading || onPressed == null) ? null : onPressed,
      style: buttonStyle,
      child: child,
    )
        : ElevatedButton(
      onPressed: (isLoading || onPressed == null) ? null : onPressed,
      style: buttonStyle,
      child: child,
    );
  }
}