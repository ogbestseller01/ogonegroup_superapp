import 'package:flutter/foundation.dart';

/// Lets any screen ask HomeScreen to switch tab.
///
///   homeTabRequest.value = HomeTabs.jobs;
///
/// HomeScreen listens, switches, and resets the value to null.
class HomeTabs {
  static const int home = 0;
  static const int blog = 1;
  static const int requests = 2;
  static const int jobs = 3;
  static const int profile = 4;
}

final ValueNotifier<int?> homeTabRequest = ValueNotifier<int?>(null);
