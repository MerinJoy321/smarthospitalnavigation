# Firebase Setup Guide

This app uses Firebase Authentication for Google Sign-In. Follow these steps to configure Firebase:

## 1. Create a Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project" or select an existing project
3. Follow the setup wizard

## 2. Add Firebase to Your Flutter App

### For Web:

1. In Firebase Console, click the web icon (`</>`) to add a web app
2. Register your app with a nickname
3. Copy the Firebase configuration object

### For Android:

1. In Firebase Console, click the Android icon to add an Android app
2. Register your app with package name: `com.example.smart_hospital_navigator` (or your package name)
3. Download `google-services.json`
4. Place it in `android/app/`

### For iOS:

1. In Firebase Console, click the iOS icon to add an iOS app
2. Register your app with bundle ID
3. Download `GoogleService-Info.plist`
4. Place it in `ios/Runner/`

## 3. Enable Google Sign-In

1. In Firebase Console, go to **Authentication** → **Sign-in method**
2. Enable **Google** as a sign-in provider
3. Add your project's support email
4. Save

## 4. Configure OAuth Consent Screen (for Web)

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your Firebase project
3. Go to **APIs & Services** → **OAuth consent screen**
4. Configure the consent screen:
   - User Type: External (or Internal if using Google Workspace)
   - App name: Smart Hospital Navigator
   - User support email: your email
   - Developer contact: your email
5. Add scopes: `email`, `profile`
6. Add test users (if in testing mode)

## 5. Add Firebase Configuration (Optional - for Web)

If you want to configure Firebase manually for web, create `lib/firebase_options.dart`:

```dart
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'YOUR_API_KEY',
    appId: 'YOUR_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    authDomain: 'YOUR_PROJECT_ID.firebaseapp.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'YOUR_API_KEY',
    appId: 'YOUR_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_API_KEY',
    appId: 'YOUR_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    iosBundleId: 'com.example.smartHospitalNavigator',
  );
}
```

Then update `main.dart`:

```dart
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // ... rest of code
}
```

## 6. Run FlutterFire CLI (Recommended)

Alternatively, use FlutterFire CLI for automatic configuration:

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase
flutterfire configure
```

This will automatically generate `firebase_options.dart` for all platforms.

## 7. Test the App

1. Run `flutter pub get`
2. Run the app: `flutter run`
3. The auth screen should appear
4. Click "Continue with Google" to test sign-in

## Troubleshooting

- **"Firebase not initialized"**: Make sure you've completed Firebase setup
- **"Google Sign-In failed"**: Check that Google Sign-In is enabled in Firebase Console
- **Web errors**: Ensure OAuth consent screen is configured and published (or add test users)
- **Android errors**: Verify `google-services.json` is in `android/app/`
- **iOS errors**: Verify `GoogleService-Info.plist` is in `ios/Runner/`

## Notes

- The app will work without Firebase configuration, but authentication will fail gracefully
- For production, always configure Firebase properly
- Keep your Firebase configuration files secure and never commit sensitive keys to public repositories
