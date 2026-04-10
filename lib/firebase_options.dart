// File generated from google-services.json & GoogleService-Info.plist
// Do not edit manually.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) throw UnsupportedError('Web not supported');
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError('Unsupported platform: $defaultTargetPlatform');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAaEk_cEsWhc2cAiEvpGXJ_wqVdCxtQZVc',
    appId: '1:7761798024:android:f11d7964e2e5d2c3f3503d',
    messagingSenderId: '7761798024',
    projectId: 'afghan-deals-pro',
    storageBucket: 'afghan-deals-pro.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBO6JeWEaBCzRQuFZK64ydZpecIOPal5Fo',
    appId: '1:7761798024:ios:37c9ef7a384422bbf3503d',
    messagingSenderId: '7761798024',
    projectId: 'afghan-deals-pro',
    storageBucket: 'afghan-deals-pro.firebasestorage.app',
    iosBundleId: 'com.afghandeals.afghanDealsPro',
  );
}
