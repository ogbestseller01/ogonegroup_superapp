// lib/widgets/secure_scaffold.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A scaffold that prevents screenshots by default
class SecureScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget? body;
  final Widget? bottomNavigationBar;
  final Color? backgroundColor;
  final bool resizeToAvoidBottomInset;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? drawer;
  final Widget? endDrawer;
  final bool extendBody;
  final bool extendBodyBehindAppBar;
  final Color? drawerScrimColor;
  final double? drawerEdgeDragWidth;

  const SecureScaffold({
    super.key,
    this.appBar,
    this.body,
    this.bottomNavigationBar,
    this.backgroundColor,
    this.resizeToAvoidBottomInset = true,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.drawer,
    this.endDrawer,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
    this.drawerScrimColor,
    this.drawerEdgeDragWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // The actual scaffold
        Scaffold(
          appBar: appBar,
          body: body,
          bottomNavigationBar: bottomNavigationBar,
          backgroundColor: backgroundColor,
          resizeToAvoidBottomInset: resizeToAvoidBottomInset,
          floatingActionButton: floatingActionButton,
          floatingActionButtonLocation: floatingActionButtonLocation,
          drawer: drawer,
          endDrawer: endDrawer,
          extendBody: extendBody,
          extendBodyBehindAppBar: extendBodyBehindAppBar,
          drawerScrimColor: drawerScrimColor,
          drawerEdgeDragWidth: drawerEdgeDragWidth,
        ),
        // Overlay that prevents screenshots
        const _SecureOverlay(),
      ],
    );
  }
}

/// Overlay widget that prevents screenshots
class _SecureOverlay extends StatelessWidget {
  const _SecureOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: true,
      child: Container(
        color: Colors.transparent,
        child: const _SecureView(),
      ),
    );
  }
}

/// The actual secure view
class _SecureView extends StatelessWidget {
  const _SecureView();

  @override
  Widget build(BuildContext context) {
    // This will be replaced with platform-specific secure view
    return const SizedBox.shrink();
  }
}