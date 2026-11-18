// lib/services/internet_checker.dart
// ============================================================
//  Connection probe that answers the question the app really has:
//  "Can this device reach MY backend?"
//
//  Result:
//    online             → backend answered (or, with no backend URL
//                         configured, the public internet is reachable)
//    serverUnreachable  → public internet works, backend does not answer
//    offline            → nothing reachable
//
//  How it works:
//    1. Backend health URL      (the one that matters, if configured)
//    2. Public probes, run in parallel, any success counts:
//         - DNS lookup of a well-known host
//         - raw TCP to well-known public IPs on 443 (works without DNS)
//
//  Backend health endpoint requirements:
//    * Plain GET, no auth, tiny response (204 No Content is perfect).
//    * Must NOT redirect: a redirect is treated as a captive portal
//      (hotel / airport Wi-Fi login page), i.e. "not really online".
// ============================================================

import 'dart:async';
import 'dart:io';

enum ConnectionStatus { online, serverUnreachable, offline }

class InternetChecker {
  const InternetChecker({
    this.apiHealthUrl,
    this.apiTimeout = const Duration(seconds: 5),
    this.dnsHost = 'google.com',
    this.dnsTimeout = const Duration(seconds: 4),
    this.socketTimeout = const Duration(seconds: 3),
    this.socketTargets = const [
      ('1.1.1.1', 443), // Cloudflare
      ('8.8.8.8', 443), // Google
      ('9.9.9.9', 443), // Quad9
    ],
  });

  /// Full URL of your backend health endpoint,
  /// e.g. https://api.yourdomain.com/health
  /// Leave null/empty to rely on public probes only.
  final String? apiHealthUrl;

  final Duration apiTimeout;
  final String dnsHost;
  final Duration dnsTimeout;
  final Duration socketTimeout;

  /// (ip, port) pairs reachable without DNS.
  final List<(String, int)> socketTargets;

  bool get _hasApiUrl => apiHealthUrl != null && apiHealthUrl!.isNotEmpty;

  /// Never throws.
  Future<ConnectionStatus> check() async {
    // Start public probes immediately; they run while the API is tried.
    final publicFuture = _hasPublicInternet();

    if (!_hasApiUrl) {
      return await publicFuture
          ? ConnectionStatus.online
          : ConnectionStatus.offline;
    }

    if (await _apiReachable()) return ConnectionStatus.online;

    return await publicFuture
        ? ConnectionStatus.serverUnreachable
        : ConnectionStatus.offline;
  }

  // ── Backend ────────────────────────────────────────────────
  Future<bool> _apiReachable() async {
    final uri = Uri.tryParse(apiHealthUrl!);
    if (uri == null) return false;

    final client = HttpClient()..connectionTimeout = apiTimeout;
    try {
      final request = await client.getUrl(uri);
      request.followRedirects = false; // redirect ⇒ likely captive portal
      final response = await request.close().timeout(apiTimeout);
      await response.drain<void>();

      final code = response.statusCode;
      // 2xx = healthy. 4xx = server answered (e.g. 404/401) ⇒ reachable.
      // 3xx = possible captive portal. 5xx = backend problem.
      return code < 300 || (code >= 400 && code < 500);
    } catch (_) {
      return false;
    } finally {
      client.close(force: true);
    }
  }

  // ── Public internet (any probe succeeding is enough) ───────
  Future<bool> _hasPublicInternet() {
    final probes = <Future<bool>>[
      _dnsProbe(),
      for (final t in socketTargets) _socketProbe(t.$1, t.$2),
    ];

    final completer = Completer<bool>();
    var pending = probes.length;

    for (final probe in probes) {
      probe.then((ok) {
        if (ok && !completer.isCompleted) completer.complete(true);
        pending--;
        if (pending == 0 && !completer.isCompleted) completer.complete(false);
      });
    }

    return completer.future;
  }

  Future<bool> _dnsProbe() async {
    try {
      final result = await InternetAddress.lookup(dnsHost).timeout(dnsTimeout);
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _socketProbe(String host, int port) async {
    try {
      final socket = await Socket.connect(host, port, timeout: socketTimeout);
      socket.destroy();
      return true;
    } catch (_) {
      return false;
    }
  }
}