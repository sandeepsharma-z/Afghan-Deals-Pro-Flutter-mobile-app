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
    apiKey: 'AIzaSyCWPbpaK30KfelMNyPzKbOfHx66Od0JQL4',
    appId: '1:253988662059:android:b0a2c3c02588f4dbe8b36e',
    messagingSenderId: '253988662059',
    projectId: 'afghan-deals-pro-2',
    storageBucket: 'afghan-deals-pro-2.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyA-qjwj9cuPpxqPsuaViKABE_PKIr61qP0',
    appId: '1:253988662059:ios:e83b8c28fec986f7e8b36e',
    messagingSenderId: '253988662059',
    projectId: 'afghan-deals-pro-2',
    storageBucket: 'afghan-deals-pro-2.firebasestorage.app',
    iosBundleId: 'com.afghandeals.afghanDealsPro',
  );
}
