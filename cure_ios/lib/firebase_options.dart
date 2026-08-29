import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Configured for Cure Healthcare App.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: String.fromEnvironment('FIREBASE_API_KEY', defaultValue: 'AIzaSyDwaCqJKY6c8B9XIqpYULREaNunFmzHFdQ'),
    appId: String.fromEnvironment('FIREBASE_APP_ID', defaultValue: '1:679705328915:ios:2f7fe69d61053506dd2ee6'),
    messagingSenderId: '679705328915',
    projectId: String.fromEnvironment('FIREBASE_PROJECT_ID', defaultValue: 'curaa-8ac6b'),
    authDomain: 'curaa-8ac6b.firebaseapp.com',
    storageBucket: 'curaa-8ac6b.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: String.fromEnvironment('FIREBASE_API_KEY', defaultValue: 'AIzaSyDwaCqJKY6c8B9XIqpYULREaNunFmzHFdQ'),
    appId: String.fromEnvironment('FIREBASE_APP_ID', defaultValue: '1:679705328915:ios:2f7fe69d61053506dd2ee6'),
    messagingSenderId: '679705328915',
    projectId: String.fromEnvironment('FIREBASE_PROJECT_ID', defaultValue: 'curaa-8ac6b'),
    storageBucket: 'curaa-8ac6b.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: String.fromEnvironment('FIREBASE_API_KEY', defaultValue: 'AIzaSyDwaCqJKY6c8B9XIqpYULREaNunFmzHFdQ'),
    appId: String.fromEnvironment('FIREBASE_APP_ID', defaultValue: '1:679705328915:ios:2f7fe69d61053506dd2ee6'),
    messagingSenderId: '679705328915',
    projectId: String.fromEnvironment('FIREBASE_PROJECT_ID', defaultValue: 'curaa-8ac6b'),
    storageBucket: 'curaa-8ac6b.firebasestorage.app',
    iosBundleId: 'com.example.cureApp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: String.fromEnvironment('FIREBASE_API_KEY', defaultValue: 'AIzaSyDwaCqJKY6c8B9XIqpYULREaNunFmzHFdQ'),
    appId: String.fromEnvironment('FIREBASE_APP_ID', defaultValue: '1:679705328915:ios:2f7fe69d61053506dd2ee6'),
    messagingSenderId: '679705328915',
    projectId: String.fromEnvironment('FIREBASE_PROJECT_ID', defaultValue: 'curaa-8ac6b'),
    storageBucket: 'curaa-8ac6b.firebasestorage.app',
    iosBundleId: 'com.example.cureApp',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: String.fromEnvironment('FIREBASE_API_KEY', defaultValue: 'AIzaSyDwaCqJKY6c8B9XIqpYULREaNunFmzHFdQ'),
    appId: String.fromEnvironment('FIREBASE_APP_ID', defaultValue: '1:679705328915:ios:2f7fe69d61053506dd2ee6'),
    messagingSenderId: '679705328915',
    projectId: String.fromEnvironment('FIREBASE_PROJECT_ID', defaultValue: 'curaa-8ac6b'),
    authDomain: 'curaa-8ac6b.firebaseapp.com',
    storageBucket: 'curaa-8ac6b.firebasestorage.app',
  );
}
