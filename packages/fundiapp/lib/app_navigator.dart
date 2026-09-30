// lib/app_navigator.dart
//
// Shared navigator key used by:
//   * MaterialApp (main.dart / FundiAppMiniApp / NearbyFundiMiniApp)
//   * AuthProvider (for redirects on 401)
//   * NotificationProvider / FcmService (for tapping a push)
//
// NOTE: a GlobalKey can only be attached to ONE Navigator at a time.
// The host app owns this key. The mini-apps must use their own private
// keys — otherwise whichever MaterialApp mounts second steals the key
// and the first one's Navigator becomes unreachable.

import 'package:flutter/material.dart';

/// Global navigator key — owned by the *host* MaterialApp only.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();