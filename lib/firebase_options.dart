// Generated for the ALBYATE Firebase Android app.
// Keep this file aligned with the Firebase Android app registered for:
// com.albyate.solarinverter
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('ALBYATE currently supports Android only.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'Firebase is configured for Android only in this ALBYATE build.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAvz3RMJQ4UzxcV6g0DXPAwKMHrzU5kXy8',
    appId: '1:424242379675:android:b07418a1196eec0903ff3e',
    messagingSenderId: '424242379675',
    projectId: 'albyate-solar-inverter',
    storageBucket: 'albyate-solar-inverter.firebasestorage.app',
  );
}
