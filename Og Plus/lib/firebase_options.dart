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

  // ============================================================
  // ANDROID — matches google-services.json (project nearbyfundi-8032f)
  // ============================================================
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAI8DIC73GaDmuLhyMa-V9LKUV9JowpTXc',
    appId: '1:217153819583:android:e805e315e875010811c70a',
    messagingSenderId: '217153819583',
    projectId: 'nearbyfundi-8032f',
    storageBucket: 'nearbyfundi-8032f.firebasestorage.app',
  );

  // ============================================================
  // iOS — matches GoogleService-Info.plist (project nearbyfundi-8032f)
  // ============================================================
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCuamKYH11O-_DMpyyOuuI6DDTRSoy49i0',
    appId: '1:217153819583:ios:5bdbce08eb57f8ae11c70a',
    messagingSenderId: '217153819583',
    projectId: 'nearbyfundi-8032f',
    storageBucket: 'nearbyfundi-8032f.firebasestorage.app',
    iosClientId:
    '217153819583-i53f9rsb46uiid53ikuiv6r68o93qe4s.apps.googleusercontent.com',
    iosBundleId: 'com.example.ogonesuperapp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCuamKYH11O-_DMpyyOuuI6DDTRSoy49i0',
    appId: '1:217153819583:ios:5bdbce08eb57f8ae11c70a',
    messagingSenderId: '217153819583',
    projectId: 'nearbyfundi-8032f',
    storageBucket: 'nearbyfundi-8032f.firebasestorage.app',
    iosClientId:
    '217153819583-i53f9rsb46uiid53ikuiv6r68o93qe4s.apps.googleusercontent.com',
    iosBundleId: 'com.example.ogonesuperapp',
  );
}