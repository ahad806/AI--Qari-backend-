import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDvs4BkHyhP2Z-TQQ2zGWUMMI-QlEPx_ZM',
    appId: '1:827310573080:android:cca8760464b9298b2a256d',
    messagingSenderId: '827310573080',
    projectId: 'al-qari-2567f',
    storageBucket: 'al-qari-2567f.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCl81fjdhIypMr-iAyen0ZjhIxygbJUv4k',
    appId: '1:827310573080:ios:43ddd66b2068d04a2a256d',
    messagingSenderId: '827310573080',
    projectId: 'al-qari-2567f',
    storageBucket: 'al-qari-2567f.firebasestorage.app',
    iosBundleId: 'com.example.alqari',
  );
}
