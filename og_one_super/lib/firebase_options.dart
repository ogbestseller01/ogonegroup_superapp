// lib/firebase_options.dart

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  // ── MAIN APP (OG SuperApp) ──
  // These are used by default when Firebase.initializeApp() is called.
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

  // ── OG SuperApp project (og-superapp) ──
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCXju2lF-9vzal6zBINGQdSCxvTzWPEFXY',
    appId: '1:92116320070:android:2e13c51a4b65fb5d746f47',
    messagingSenderId: '92116320070',
    projectId: 'og-superapp',
    storageBucket: 'og-superapp.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyD2liteW-MXwbcLWtKdumK0BAp2ow3AGV4',
    appId: '1:92116320070:ios:981110df03690f86746f47',
    messagingSenderId: '92116320070',
    projectId: 'og-superapp',
    storageBucket: 'og-superapp.firebasestorage.app',
    iosBundleId: 'com.ogonegroup.ogsuperapp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyD2liteW-MXwbcLWtKdumK0BAp2ow3AGV4',
    appId: '1:92116320070:ios:981110df03690f86746f47',
    messagingSenderId: '92116320070',
    projectId: 'og-superapp',
    storageBucket: 'og-superapp.firebasestorage.app',
    iosBundleId: 'com.ogonegroup.ogsuperapp',
  );

  // ── MINI APP PROJECT (Nearby Fundi / Fundi App) ──
  // Use these if a mini-app needs to initialize its own secondary Firebase instance.
  static const FirebaseOptions fundiAndroid = FirebaseOptions(
    apiKey: 'AIzaSyCuamKYH11O-_DMpyyOuuI6DDTRSoy49i0',
    appId: '1:217153819583:android:3aa5b2b0654f73bb11c70a',
    messagingSenderId: '217153819583',
    projectId: 'nearbyfundi-8032f',
    storageBucket: 'nearbyfundi-8032f.firebasestorage.app',
  );

  static const FirebaseOptions fundiIos = FirebaseOptions(
    apiKey: 'AIzaSyCuamKYH11O-_DMpyyOuuI6DDTRSoy49i0',
    appId: '1:217153819583:ios:3aa5b2b0654f73bb11c70a',
    messagingSenderId: '217153819583',
    projectId: 'nearbyfundi-8032f',
    storageBucket: 'nearbyfundi-8032f.firebasestorage.app',
    iosClientId:
    '217153819583-7jv5l9jai0vu02euuldqkdodssqkqfrl.apps.googleusercontent.com',
    iosBundleId: 'com.fundiapp',
  );

  static const FirebaseOptions fundiMacos = FirebaseOptions(
    apiKey: 'AIzaSyCuamKYH11O-_DMpyyOuuI6DDTRSoy49i0',
    appId: '1:217153819583:ios:3aa5b2b0654f73bb11c70a',
    messagingSenderId: '217153819583',
    projectId: 'nearbyfundi-8032f',
    storageBucket: 'nearbyfundi-8032f.firebasestorage.app',
    iosClientId:
    '217153819583-7jv5l9jai0vu02euuldqkdodssqkqfrl.apps.googleusercontent.com',
    iosBundleId: 'com.fundiapp',
  );
}