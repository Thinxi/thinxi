// MOCK FILE FOR DEMO PURPOSES ONLY
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    throw UnsupportedError(
      'DefaultFirebaseOptions are not supported for this platform.',
    );
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyD-MOCK-KEY-FOR-TESTING",
    appId: "1:1234567890:web:mockappid",
    messagingSenderId: "1234567890",
    projectId: "thinxi-demo-project",
    authDomain: "thinxi-demo.firebaseapp.com",
    storageBucket: "thinxi-demo.appspot.com",
    measurementId: "G-MOCKMEASURE",
  );
}
