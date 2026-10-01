// lib/widgets/secure_screen.dart

import 'package:flutter/material.dart';

import '../services/security_service.dart';

/// Wraps any screen and optionally blocks screenshots / recording.
class SecureScreen extends StatefulWidget {
  final Widget child;
  final bool preventScreenshot;

  const SecureScreen({
    super.key,
    required this.child,
    this.preventScreenshot = true,
  });

  @override
  State<SecureScreen> createState() => _SecureScreenState();
}

class _SecureScreenState extends State<SecureScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.preventScreenshot) {
      SecurityService.enableSecureScreen();
    }
  }

  @override
  void dispose() {
    if (widget.preventScreenshot) {
      SecurityService.disableSecureScreen();
    }
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant SecureScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.preventScreenshot != widget.preventScreenshot) {
      if (widget.preventScreenshot) {
        SecurityService.enableSecureScreen();
      } else {
        SecurityService.disableSecureScreen();
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && widget.preventScreenshot) {
      // Re-apply after resume (some OEMs clear FLAG_SECURE)
      SecurityService.enableSecureScreen();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}