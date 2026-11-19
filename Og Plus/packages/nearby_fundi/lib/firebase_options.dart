// lib/firebase_options.dart

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Web not configured yet');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB6YCImgt00-zk9F6Nr1b3kfHUDCdsHxJI',
    appId: '1:911035937686:android:6e3194663eae1cd8faa3b7',
    messagingSenderId: '911035937686',
    projectId: 'og-plus-515119',
    storageBucket: 'og-plus-515119.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAUTJ7rruTIu8aVCjVISRzLk-hTMg_7lNA',
    appId: '1:911035937686:ios:bc52f1e5ad4d5810faa3b7',
    messagingSenderId: '911035937686',
    projectId: 'og-plus-515119',
    storageBucket: 'og-plus-515119.firebasestorage.app',
    androidClientId:
    '911035937686-71vp8hnmc6sn2ggmgu1ipvo46p416tlm.apps.googleusercontent.com',
    iosBundleId: 'com.ogonegroup.fundiapp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAUTJ7rruTIu8aVCjVISRzLk-hTMg_7lNA',
    appId: '1:911035937686:ios:bc52f1e5ad4d5810faa3b7',
    messagingSenderId: '911035937686',
    projectId: 'og-plus-515119',
    storageBucket: 'og-plus-515119.firebasestorage.app',
    androidClientId:
    '911035937686-71vp8hnmc6sn2ggmgu1ipvo46p416tlm.apps.googleusercontent.com',
    iosBundleId: 'com.ogonegroup.fundiapp',
  );
}