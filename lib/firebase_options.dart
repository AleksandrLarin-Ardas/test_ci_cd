// File generated by FlutterFire CLI.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCEtk60cWrjgD477UTszN9cf9u2YfBMw_A',
    appId: '1:448343196077:web:102834c70170fcd1c02124',
    messagingSenderId: '448343196077',
    projectId: 'testanalytics-89461',
    authDomain: 'testanalytics-89461.firebaseapp.com',
    storageBucket: 'testanalytics-89461.appspot.com',
    measurementId: 'G-36TGQHTVB6',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDjByQn1IYB9eh0rC3BSIj1R8NN_hnBAM4',
    appId: '1:448343196077:android:a18fe0bd6ab105cdc02124',
    messagingSenderId: '448343196077',
    projectId: 'testanalytics-89461',
    storageBucket: 'testanalytics-89461.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDdNtKXnzp5qEtpPJYx38fRa3VkUE1VuRQ',
    appId: '1:448343196077:ios:04c04f7eb4de4415c02124',
    messagingSenderId: '448343196077',
    projectId: 'testanalytics-89461',
    storageBucket: 'testanalytics-89461.appspot.com',
    iosClientId: '448343196077-822dskk82qcbrc18bgnc1834kndm6kcu.apps.googleusercontent.com',
    iosBundleId: 'com.example.testCiCd',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDdNtKXnzp5qEtpPJYx38fRa3VkUE1VuRQ',
    appId: '1:448343196077:ios:100f63b56ccc4eddc02124',
    messagingSenderId: '448343196077',
    projectId: 'testanalytics-89461',
    storageBucket: 'testanalytics-89461.appspot.com',
    iosClientId: '448343196077-f40q9trhmtsrh88qakc9rr240st1u4pv.apps.googleusercontent.com',
    iosBundleId: 'com.example.testCiCd.RunnerTests',
  );
}