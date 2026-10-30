import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';

/// Web values come from the registered Firebase web app, never Android appId.
Future<void> initializeDliniiFirebase() async {
  if (Firebase.apps.isNotEmpty) return;
  try {
    if (kIsWeb) {
      const apiKey = String.fromEnvironment(
        'FIREBASE_API_KEY',
        defaultValue: 'AIzaSyBO6gILa5BtSBKdagi7FxRu00FZ4MchPvI',
      );
      const appId = String.fromEnvironment(
        'FIREBASE_APP_ID',
        defaultValue: '1:343805973795:web:86a2155c8ab30c7ef1a896',
      );
      if (apiKey.isEmpty || appId.isEmpty) return;
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: apiKey,
          appId: appId,
          messagingSenderId: String.fromEnvironment(
            'FIREBASE_SENDER_ID',
            defaultValue: '343805973795',
          ),
          projectId: 'dlinii',
          authDomain: 'dlinii.firebaseapp.com',
          storageBucket: 'dlinii.firebasestorage.app',
        ),
      );
    } else if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      await Firebase.initializeApp();
    }
  } catch (e) {
    debugPrint('Firebase initialization unavailable: $e');
  }
}
