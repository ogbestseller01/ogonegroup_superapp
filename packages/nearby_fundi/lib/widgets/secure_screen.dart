// lib/widgets/secure_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A wrapper widget that prevents screenshots and screen recording
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

class _SecureScreenState extends State<SecureScreen> with WidgetsBindingObserver {
  static const MethodChannel _securityChannel = MethodChannel('com.nearbyfundi/security');

  @override
  void initState() {
    super.initState();
    if (widget.preventScreenshot) {
      _enableSecureScreen();
    }
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    if (widget.preventScreenshot) {
      _disableSecureScreen();
    }
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && widget.preventScreenshot) {
      _enableSecureScreen();
    }
  }

  Future<void> _enableSecureScreen() async {
    try {
      await _securityChannel.invokeMethod('enableSecureScreen');
    } catch (e) {
      // Fallback - use system channel
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  Future<void> _disableSecureScreen() async {
    try {
      await _securityChannel.invokeMethod('disableSecureScreen');
    } catch (e) {
      // Fallback
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}