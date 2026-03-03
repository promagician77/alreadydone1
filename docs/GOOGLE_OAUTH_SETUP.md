# Google OAuth Setup Guide

Your app already uses **Supabase** for auth and **google_sign_in** for native Google Sign-In. This guide walks you through configuring Google Cloud and Supabase so "Sign in with Google" works on **Web**, **Android**, and **iOS**.

---

## 1. Google Cloud Console

### 1.1 Create or select a project

1. Go to [Google Cloud Console](https://console.cloud.google.com/).
2. Create a new project or select your existing one (e.g. the one used for Firebase: `already-done-app-a3e9a`).

### 1.2 Enable required APIs

1. **APIs & Services** → **Library**.
2. Search for **Google+ API** or ensure **Google Identity** is available (often enabled with Firebase).
3. If you use Firebase, the project may already have the right APIs.

### 1.3 Configure OAuth consent screen

1. **APIs & Services** → **OAuth consent screen**.
2. Choose **External** (or **Internal** for workspace-only).
3. Fill in:
   - **App name**: e.g. "Already Done"
   - **User support email**: your email
   - **Developer contact**: your email
4. **Scopes**: Add `email`, `profile`, `openid` (Supabase/Google usually need these).
5. Save and continue. Add test users if the app is in "Testing" mode.

---

## 2. Create OAuth 2.0 Client IDs

Go to **APIs & Services** → **Credentials** → **Create Credentials** → **OAuth client ID**.

### 2.1 Web client (required for all platforms)

1. Application type: **Web application**.
2. Name: e.g. "Already App – Web".
3. **Authorized redirect URIs**: add your Supabase auth callback:
   - `https://<YOUR_SUPABASE_PROJECT_REF>.supabase.co/auth/v1/callback`
   - Find the exact URL in: Supabase Dashboard → **Project Settings** → **API** → **URL**; then append `/auth/v1/callback`.
4. Create and copy the **Client ID** (and optionally Client Secret).  
   This is your **GOOGLE_WEB_CLIENT_ID** (you already have one in `.env`).

### 2.2 Android client

1. Application type: **Android**.
2. Name: e.g. "Already App – Android".
3. **Package name**: `com.alreadydone.app` (must match `applicationId` in `android/app/build.gradle`).
4. **SHA-1**:
   - **Debug**: run in project root:
     ```bash
     cd android && ./gradlew signingReport
     ```
     Copy the SHA-1 under `Variant: debug` (or from `keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android`).
   - **Release**: use the SHA-1 of your release keystore (from `keytool -list -v -keystore <path-to-keystore> -alias <alias>`).
5. Add both SHA-1 fingerprints if you test with debug and release.
6. Create and note the Android Client ID. You do **not** put this in `.env`; Google Sign-In on Android uses the Web Client ID as `serverClientId` and the Android client is matched by package name + SHA-1.

### 2.3 iOS client (for native Google Sign-In on iOS)

1. Application type: **iOS**.
2. Name: e.g. "Already App – iOS".
3. **Bundle ID**: `com.mycompany.alreadyapp` (must match Xcode `PRODUCT_BUNDLE_IDENTIFIER`).
4. Optional: App Store ID, team ID, etc.
5. Create and copy the **Client ID**.  
   This is your **GOOGLE_IOS_CLIENT_ID** for native sign-in.

**iOS URL scheme (for Google Sign-In):**

- Google Sign-In for iOS can use a reversed client ID as URL scheme (e.g. `com.googleusercontent.apps.XXXX-YYYY`).
- In Xcode, open **Runner** → **Info** → **URL Types** and add a URL scheme equal to the **reversed iOS client ID** (e.g. if client ID is `123456-abc.apps.googleusercontent.com`, the scheme is `com.googleusercontent.apps.123456-abc`).  
- Your current `Info.plist` has a custom scheme `alreadyapp`; if you use native Google Sign-In, add the reversed iOS client ID as an additional URL type so Google can open the app after sign-in.

---

## 3. Environment variables (`.env`)

In your project root `.env` (and never commit secrets to git):

```env
# Required for native Android/iOS and for Supabase Google provider
GOOGLE_WEB_CLIENT_ID=<your-web-client-id>.apps.googleusercontent.com

# Optional but recommended for native iOS Google Sign-In
GOOGLE_IOS_CLIENT_ID=<your-ios-client-id>.apps.googleusercontent.com
```

- **Web**: Supabase uses the Web Client ID (and secret) configured in the Supabase Dashboard; the app uses the same Web Client ID for redirect flow.
- **Android**: Uses `GOOGLE_WEB_CLIENT_ID` as `serverClientId`; Android OAuth client is matched by package name + SHA-1.
- **iOS**: Use `GOOGLE_IOS_CLIENT_ID` so the app uses the iOS OAuth client for native sign-in.

---

## 4. Supabase Dashboard

1. **Authentication** → **Providers** → **Google**.
2. Enable Google.
3. **Client ID**: paste your **Web** OAuth client ID.
4. **Client Secret**: paste the Web client secret from Google Cloud.
5. Save.

Supabase will use this for the web OAuth redirect; native Android/iOS use the same Web Client ID (and on iOS the optional iOS Client ID) with `signInWithIdToken`.

---

## 5. Platform-specific checks

### Android

- **Package name** in Google Cloud Android client: `com.alreadydone.app`.
- **SHA-1**: debug and release keystores must be added to the Android OAuth client; otherwise you get `ApiException: 10` / "sign_in_failed".
- Deep link `alreadydone://alreadydone.app` in `AndroidManifest.xml` is used for Supabase magic links / email confirmation; Google Sign-In on Android does not use this redirect.

### iOS

- **Bundle ID** in Google Cloud iOS client: `com.mycompany.alreadyapp`.
- Add URL scheme with the **reversed iOS client ID** in `Info.plist` / Xcode URL Types for native Google Sign-In.
- Set `GOOGLE_IOS_CLIENT_ID` in `.env` so `SupabaseService.signInWithGoogle()` uses the iOS client.

### Web

- Authorized redirect URI in Google Cloud must be exactly:  
  `https://<YOUR_SUPABASE_PROJECT_REF>.supabase.co/auth/v1/callback`
- No `.env` is needed in the browser for Google; Supabase handles the OAuth redirect.

---

## 6. Quick checklist

- [ ] OAuth consent screen configured in Google Cloud.
- [ ] **Web** OAuth client created; redirect URI = Supabase `/auth/v1/callback`.
- [ ] **Android** OAuth client: package `com.alreadydone.app`, debug (and release) SHA-1 added.
- [ ] **iOS** OAuth client: bundle ID `com.mycompany.alreadyapp`; reversed client ID as URL scheme in Xcode.
- [ ] `.env`: `GOOGLE_WEB_CLIENT_ID` set; `GOOGLE_IOS_CLIENT_ID` set for iOS.
- [ ] Supabase Dashboard → Auth → Google: same Web Client ID and Client Secret.
- [ ] Run the app and test "Sign in with Google" on Web, Android, and iOS.

---

## 7. Troubleshooting

| Issue | What to check |
|-------|----------------|
| "GOOGLE_WEB_CLIENT_ID is not set" | Add Web Client ID to `.env` and ensure the app loads `.env` (e.g. `flutter_dotenv`). |
| Android: "ApiException: 10" / "sign_in_failed" | Package name `com.alreadydone.app` and SHA-1 (debug/release) in Google Cloud Android client. |
| iOS: Sign-in opens browser and doesn’t return | Add reversed iOS Client ID as URL scheme; set `GOOGLE_IOS_CLIENT_ID`. |
| Web: Redirect fails | Redirect URI in Google Cloud must exactly match Supabase callback URL. |
| Supabase "Invalid OAuth credentials" | Use the **Web** Client ID and Secret in Supabase; ensure Google provider is enabled. |

Your implementation in `lib/services/supabase_service.dart` already uses:

- **Web**: `signInWithOAuth(provider: OAuthProvider.google)` (redirect).
- **Android / iOS**: `GoogleSignIn` with `serverClientId: GOOGLE_WEB_CLIENT_ID`, optional `clientId: GOOGLE_IOS_CLIENT_ID`, then `signInWithIdToken`. No code changes are required once the above configuration is correct.
