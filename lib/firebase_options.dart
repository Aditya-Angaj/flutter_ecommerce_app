import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    // When targeting web, defaultTargetPlatform can still report the
    // underlying platform (e.g. TargetPlatform.windows). Use kIsWeb
    // to reliably detect web and return the web options.
    if (kIsWeb) return web;

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
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAFyAAcaIQ2vRLM3OYUU_vItSBquKpnyck',
    appId: '1:69505171248:web:d51cc353d67a9f2e8bd2f5',
    messagingSenderId: '69505171248',
    projectId: 'ecommerce-2d482',
    authDomain: 'ecommerce-2d482.firebaseapp.com',
    storageBucket: 'ecommerce-2d482.appspot.com',
    measurementId: 'G-PK4PB74MCB',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'dummy-api-key',
    appId: '1:000000000000:android:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'dummy-project-id',
    storageBucket: 'dummy-app.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'dummy-api-key',
    appId: '1:000000000000:ios:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'dummy-project-id',
    storageBucket: 'dummy-app.appspot.com',
    iosClientId: 'dummy-ios-client-id.apps.googleusercontent.com',
    iosBundleId: 'com.example.flutterEcommerceApp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'dummy-api-key',
    appId: '1:000000000000:macos:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'dummy-project-id',
    storageBucket: 'dummy-app.appspot.com',
    iosClientId: 'dummy-macos-client-id.apps.googleusercontent.com',
    iosBundleId: 'com.example.flutterEcommerceApp',
  );
}