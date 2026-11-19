// lib/firebase_options.dart

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
            'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
              'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
              'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB6YCImgt00-zk9F6Nr1b3kfHUDCdsHxJI',
    appId: '1:911035937686:android:4ccf2e4bb5502581faa3b7',
    messagingSenderId: '911035937686',
    projectId: 'og-plus-515119',
    storageBucket: 'og-plus-515119.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAUTJ7rruTIu8aVCjVISRzLk-hTMg_7lNA',
    appId: '1:911035937686:ios:af239c28439b0acdfaa3b7',
    messagingSenderId: '911035937686',
    projectId: 'og-plus-515119',
    storageBucket: 'og-plus-515119.firebasestorage.app',
    androidClientId:
    '911035937686-71vp8hnmc6sn2ggmgu1ipvo46p416tlm.apps.googleusercontent.com',
    iosBundleId: 'com.ogonegroup.ogplusapp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAUTJ7rruTIu8aVCjVISRzLk-hTMg_7lNA',
    appId: '1:911035937686:ios:af239c28439b0acdfaa3b7',
    messagingSenderId: '911035937686',
    projectId: 'og-plus-515119',
    storageBucket: 'og-plus-515119.firebasestorage.app',
    androidClientId:
    '911035937686-71vp8hnmc6sn2ggmgu1ipvo46p416tlm.apps.googleusercontent.com',
    iosBundleId: 'com.ogonegroup.ogplusapp',
  );
}