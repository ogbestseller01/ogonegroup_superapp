import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'auth_provider.dart';

/// Creates a fresh [T] whenever AuthProvider.sessionEpoch changes.
/// Old instances are intentionally NOT disposed: late in-flight requests from
/// the previous user then land on an orphan instead of crashing or leaking
/// into the new session.
SingleChildWidget perSession<T extends ChangeNotifier>(T Function() build) {
  int? epoch;
  return ListenableProxyProvider<AuthProvider, T>(
    update: (_, auth, previous) {
      if (previous == null || epoch != auth.sessionEpoch) {
        epoch = auth.sessionEpoch;
        return build();
      }
      return previous;
    },
  );
}