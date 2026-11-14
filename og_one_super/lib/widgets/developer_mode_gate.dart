import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/developer_mode_service.dart';

class DeveloperModeGate extends StatefulWidget {
  const DeveloperModeGate({super.key, required this.child});

  final Widget child;

  @override
  State<DeveloperModeGate> createState() => _DeveloperModeGateState();
}

class _DeveloperModeGateState extends State<DeveloperModeGate>
    with WidgetsBindingObserver {
  bool _blocked = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _check();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _check();
  }

  Future<void> _check() async {
    final blocked = await DeveloperModeService.shouldBlock();
    if (!mounted) return;

    if (blocked != _blocked) setState(() => _blocked = blocked);

    _timer?.cancel();
    if (blocked) {
      _timer = Timer.periodic(const Duration(seconds: 2), (_) => _check());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_blocked)
          Positioned.fill(
            child: PopScope(
              canPop: false,
              child: _DeveloperModeBlockedScreen(onRecheck: _check),
            ),
          ),
      ],
    );
  }
}

class _DeveloperModeBlockedScreen extends StatelessWidget {
  const _DeveloperModeBlockedScreen({required this.onRecheck});

  final VoidCallback onRecheck;

  @override
  Widget build(BuildContext context) {
    final isSw = Localizations.localeOf(context).languageCode == 'sw';
    final scheme = Theme.of(context).colorScheme;

    final title = isSw ? 'Hali ya Msanidi Imewashwa' : 'Developer Mode Is On';
    final body = isSw
        ? 'Kwa usalama wako, programu hii haiwezi kufunguka wakati '
        '"Developer options" au "USB debugging" imewashwa. '
        'Tafadhali izime kisha urudi kwenye programu.'
        : 'For your security, this app cannot run while "Developer options" '
        'or "USB debugging" is enabled. Please turn it off, then return to the app.';
    final openLabel = isSw ? 'Fungua Mipangilio' : 'Open Settings';
    final retryLabel = isSw ? 'Nimezima, jaribu tena' : "I've turned it off, retry";
    final closeLabel = isSw ? 'Funga programu' : 'Close app';

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.security, size: 72, color: scheme.error),
              const SizedBox(height: 24),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(body, textAlign: TextAlign.center),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: DeveloperModeService.openDeveloperSettings,
                  child: Text(openLabel),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onRecheck,
                  child: Text(retryLabel),
                ),
              ),
              TextButton(
                onPressed: () => SystemNavigator.pop(),
                child: Text(closeLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}