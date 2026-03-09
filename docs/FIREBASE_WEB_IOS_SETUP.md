# Firebase setup for Web and iOS

The app runs on **Android** without extra steps because Firebase is configured there. On **Web** and **iOS** you need to add Firebase config so the app doesn’t show a white screen.

## Why the white screen happened

1. **Firebase** – `Firebase.initializeApp()` was failing on web (no Firebase JS in `index.html`) and on iOS (no `GoogleService-Info.plist` / options), so startup never reached `runApp()`.
2. **FCM / dart:io** – FCM service used `dart:io` (e.g. `Platform.isAndroid`), which isn’t available on web and could crash. FCM is now skipped on web and the service no longer uses `dart:io`.

The code now catches Firebase init errors and still runs the app (without push on that platform). To get Firebase (and push on iOS) working, follow the steps below.

---

## Web

1. Open [Firebase Console](https://console.firebase.google.com) → your project → **Project settings** (gear) → **Your apps**.
2. If you don’t have a web app, click **Add app** → **Web** and register it.
3. Copy the `firebaseConfig` object from the SDK setup.
4. In this project, open **`web/index.html`** and replace the placeholder `firebaseConfig` with your real config:

   ```js
   var firebaseConfig = {
     apiKey: "AIza...",
     authDomain: "your-project.firebaseapp.com",
     projectId: "your-project-id",
     storageBucket: "your-project.appspot.com",
     messagingSenderId: "123456789",
     appId: "1:123456789:web:..."
   };
   firebase.initializeApp(firebaseConfig);
   ```

5. Remove or adjust the `if (firebaseConfig.apiKey !== "YOUR_API_KEY")` check if you want init to always run.

After this, `Firebase.initializeApp()` in Dart can use the default app and the web build should no longer show a white screen due to Firebase.

---

## iOS

1. In Firebase Console → **Project settings** → **Your apps**, add an **iOS** app if needed (use your iOS bundle ID).
2. Download **GoogleService-Info.plist** and add it to the Xcode project:
   - Open `ios/Runner.xcworkspace` in Xcode.
   - Drag `GoogleService-Info.plist` into the **Runner** target (ensure “Copy items if needed” and Runner target are checked).
3. Rebuild and run on the iOS simulator or device.

Alternatively, you can use **FlutterFire CLI** so that one config works for all platforms:

- Run `dart pub global activate flutterfire_cli` then `flutterfire configure`.
- This generates `lib/firebase_options.dart` and configures Android/iOS/Web.
- Then in `lib/main.dart` you can switch to:

  ```dart
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  ```

  (and add `import 'firebase_options.dart';`).

---

## Summary

- **Web**: Add your Firebase web config in `web/index.html` so the JS SDK is loaded and the default app is created before Dart runs.
- **iOS**: Add `GoogleService-Info.plist` to the Runner target (or use `flutterfire configure` and `DefaultFirebaseOptions`).
- **FCM**: Initialization is skipped on web; no code change needed. On iOS, after adding `GoogleService-Info.plist`, FCM will initialize from Dart as before.

If Firebase init still fails (e.g. wrong or missing config), the app will now show an error screen with the exception message instead of a white screen, so you can debug more easily.
