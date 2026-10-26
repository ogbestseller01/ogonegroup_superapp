// lib/widgets/app_gates.dart
// ============================================================
//  App-level gates wrapped around the whole MaterialApp:
//
//    SecurityGate      → blocks the app while USB / developer debugging is ON
//    ConnectivityGate  → blocks interaction (but keeps app state alive) while
//                        the device is offline or the backend is unreachable
//
//  Usage (in MaterialApp.builder):
//    SecurityGate(checker: ..., child: child)
//  ConnectivityGate is applied automatically inside SecurityGate.
// ============================================================

import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/internet_checker.dart';
import '../services/security_service.dart';

// ── Shared palette ───────────────────────────────────────────
const Color _kNavy = Color(0xFF0F1A2E);
const Color _kInk = Color(0xFF1A2B4A);
const Color _kMuted = Color(0xFF5B6B82);
const Color _kAmber = Color(0xFFFFB300);
const Color _kDanger = Color(0xFFE5484D);

// ── Connectivity tuning ──────────────────────────────────────
/// Consecutive failed checks needed before flipping online → blocked.
/// Prevents a single slow check from flashing the dialog.
const int _kOfflineThreshold = 2;

/// How often to re-check while online / blocked.
const Duration _kOnlineInterval = Duration(seconds: 10);
const Duration _kBlockedInterval = Duration(seconds: 3);

/// true  → show a blocking dialog when internet works but our backend
///         does not answer.
/// false → let the user in and treat that case as online.
const bool _kBlockWhenServerUnreachable = true;

// ============================================================
//  SECURITY GATE
// ============================================================
class SecurityGate extends StatefulWidget {
  const SecurityGate({
    super.key,
    required this.child,
    this.enforce = true,
    this.checker = const InternetChecker(),
  });

  final Widget child;

  /// Set false to skip the debug-mode block (e.g. local development).
  final bool enforce;

  /// Connection probe handed to the ConnectivityGate.
  final InternetChecker checker;

  @override
  State<SecurityGate> createState() => _SecurityGateState();
}

class _SecurityGateState extends State<SecurityGate>
    with WidgetsBindingObserver {
  bool? _blocked; // null = first check still running

  @override
  void initState() {
    super.initState();
    if (widget.enforce) {
      WidgetsBinding.instance.addObserver(this);
      _check();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Re-check when the user returns (e.g. after turning debugging off).
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _check();
  }

  Future<void> _check() async {
    bool isDebugOn;
    try {
      isDebugOn = await SecurityService.instance.isDebugModeEnabled();
    } catch (e, st) {
      // Fail-open: a broken check must not lock every user out.
      // Set `isDebugOn = true` here if you prefer fail-closed behaviour.
      dev.log('Security check failed', error: e, stackTrace: st);
      isDebugOn = false;
    }
    if (!mounted) return;
    if (_blocked != isDebugOn) setState(() => _blocked = isDebugOn);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enforce) {
      return ConnectivityGate(checker: widget.checker, child: widget.child);
    }

    if (_blocked == null) return const _GateLoading();
    if (_blocked == true) return const _DebugBlockerScreen();

    return ConnectivityGate(checker: widget.checker, child: widget.child);
  }
}

// ============================================================
//  CONNECTIVITY GATE
// ============================================================
class ConnectivityGate extends StatefulWidget {
  const ConnectivityGate({
    super.key,
    required this.child,
    this.checker = const InternetChecker(),
  });

  final Widget child;
  final InternetChecker checker;

  @override
  State<ConnectivityGate> createState() => _ConnectivityGateState();
}

class _ConnectivityGateState extends State<ConnectivityGate>
    with WidgetsBindingObserver {
  ConnectionStatus? _status; // null = first check still running
  bool _checking = false;
  bool _paused = false;
  int _failures = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _check();
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      // Stop polling in the background (saves battery / data).
        _paused = true;
        _timer?.cancel();
      case AppLifecycleState.resumed:
        _paused = false;
        _failures = 0; // fresh start after coming back
        _check();
      default:
        break;
    }
  }

  void _scheduleNext() {
    _timer?.cancel();
    if (!mounted || _paused) return;
    final delay =
    _status == ConnectionStatus.online ? _kOnlineInterval : _kBlockedInterval;
    _timer = Timer(delay, _check);
  }

  Future<void> _check() async {
    if (_checking) return;
    _checking = true;

    ConnectionStatus raw;
    try {
      raw = await widget.checker.check();
    } catch (_) {
      raw = ConnectionStatus.offline;
    } finally {
      _checking = false;
    }

    if (!mounted) return;

    if (raw == ConnectionStatus.serverUnreachable &&
        !_kBlockWhenServerUnreachable) {
      raw = ConnectionStatus.online;
    }

    final ConnectionStatus next;
    if (raw == ConnectionStatus.online) {
      _failures = 0;
      next = ConnectionStatus.online;
    } else {
      _failures++;
      // Already online → tolerate brief blips before blocking.
      // First check / already blocked → report right away.
      next = (_status == ConnectionStatus.online &&
          _failures < _kOfflineThreshold)
          ? ConnectionStatus.online
          : raw;
    }

    if (_status != next) setState(() => _status = next);
    _scheduleNext();
  }

  @override
  Widget build(BuildContext context) {
    // First check still running → don't open the app yet.
    if (_status == null) return const _GateLoading();

    final blocked = _status != ConnectionStatus.online;

    // The app stays mounted underneath so navigation stack and in-memory
    // state survive a connection drop; the overlay just blocks it.
    return PopScope(
      canPop: !blocked,
      child: Stack(
        fit: StackFit.expand,
        children: [
          widget.child,
          if (blocked) ...[
            const ModalBarrier(color: Colors.black54, dismissible: false),
            _ConnectionDialog(
              serverIssue: _status == ConnectionStatus.serverUnreachable,
              onRetry: _check,
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================
//  UI
// ============================================================
class _GateLoading extends StatelessWidget {
  const _GateLoading();

  @override
  Widget build(BuildContext context) => const ColoredBox(color: _kNavy);
}

// TODO(l10n): move these texts into your ARB files (English + Kiswahili).
class _ConnectionDialog extends StatelessWidget {
  const _ConnectionDialog({
    required this.serverIssue,
    required this.onRetry,
  });

  /// true  → internet works but our servers don't answer
  /// false → no internet at all
  final bool serverIssue;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final icon = serverIssue ? Icons.cloud_off_rounded : Icons.wifi_off_rounded;
    final title =
    serverIssue ? "Can't Reach Our Servers" : 'No Internet Connection';
    final message = serverIssue
        ? 'Your internet works, but we could not reach our servers. '
        'Please try again in a moment.'
        : 'Please connect to the internet.';

    return Material(
      type: MaterialType.transparency,
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 28),
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
          constraints: const BoxConstraints(maxWidth: 380),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _kAmber.withValues(alpha: 0.16),
                ),
                child: Icon(icon, size: 44, color: _kInk),
              ),
              const SizedBox(height: 22),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _kInk,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _kMuted,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: _kInk,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: onRetry,
                  child: const Text(
                    'Try again',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: _kAmber,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Waiting for connection…',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _kMuted,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full screen that stays until debug mode is turned off.
class _DebugBlockerScreen extends StatelessWidget {
  const _DebugBlockerScreen();

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Material(
        color: _kNavy,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.security_rounded,
                  size: 72,
                  color: _kDanger,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Security Alert',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Please turn off your phone debug mode.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 36),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: _kDanger,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: SystemNavigator.pop,
                    child: const Text(
                      'Close App',
                      style:
                      TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Turn off Developer Options / USB Debugging\nthen reopen the app.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white38, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}