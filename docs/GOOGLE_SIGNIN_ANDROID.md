# Google Sign-In with Supabase (Android)

You use **two** Google OAuth 2.0 client IDs:

| Use | Where it goes | Purpose |
|-----|----------------|---------|
| **Web client ID** | Supabase Dashboard + `.env` | Supabase uses it for the OAuth callback and to verify the ID token from your app. |
| **Android client ID** | Google Cloud Console only (no value in app code) | Identifies your Android app (package name + SHA-1). The `google_sign_in` plugin uses it automatically. |

So: **Web client ID is for Supabase**; **Android client ID is for the native sign-in** on the device. The app sends the **Web** client ID to `GoogleSignIn(serverClientId: webClientId)` so the ID token is valid for Supabase’s backend.

---

## 1. Google Cloud Console

1. Open [Google Cloud Console](https://console.cloud.google.com/) → your project (or create one).
2. **APIs & Services** → **Credentials** → **Create Credentials** → **OAuth client ID**.
3. If asked, configure the **OAuth consent screen** (User type, app name, support email).

### Create the Web client (for Supabase)

- Application type: **Web application**.
- Name: e.g. `Already Done Web`.
- **Authorized redirect URIs**: add the Supabase callback URL, e.g.  
  `https://<YOUR_PROJECT_REF>.supabase.co/auth/v1/callback`
- Create → copy the **Client ID** and **Client secret**. You’ll use these in Supabase and (client ID only) in `.env`.

### Create the Android client (for the app)

- Application type: **Android**.
- Name: e.g. `Already Done Android`.
- **Package name**: `com.alreadydone.myapp` (must match `applicationId` in `android/app/build.gradle`).
- **SHA-1**: from your keystore (debug or release).
  - Debug (local):  
    `cd android && ./gradlew signingReport`  
    or from Android Studio: **Gradle** → **android** → **Tasks** → **android** → **signingReport**  
    Use the **SHA-1** under `Variant: debug`.
  - Release: use the SHA-1 of the keystore you use to build the release APK/App Bundle.
- Create. You do **not** put this Android client ID in your Flutter code or `.env`; the plugin uses it via package name + SHA-1.

---

## 2. Supabase Dashboard

1. **Authentication** → **Providers** → **Google** → Enable.
2. Paste the **Client ID** and **Client secret** from the **Web** OAuth client (from step 1).
3. Save.

The redirect URL Supabase uses is the one you added in the Web client’s “Authorized redirect URIs”.

---

## 3. App config (`.env`)

In your project root `.env`:

```env
GOOGLE_WEB_CLIENT_ID=<paste the Web client ID from Google Cloud>
```

- This must be the **Web** client ID (same as in Supabase).
- The app uses it in `SupabaseService.signInWithGoogle()` as `serverClientId` for `GoogleSignIn`, so the returned ID token works with Supabase.

(Optional: for iOS you can add `GOOGLE_IOS_CLIENT_ID`; for Android you don’t need an extra env var for the Android client ID.)

---

## 4. Summary

- **Web client ID** → Supabase Dashboard (Google provider) + `.env` as `GOOGLE_WEB_CLIENT_ID` (Supabase callback / token verification).
- **Android client** → Google Cloud (Android OAuth client with package `com.alreadydone.myapp` and correct SHA-1); no ID in app code.
- If you see **ApiException: 10** or “sign_in_failed”, check that the Android client’s package name and SHA-1 match your app and that the Web client ID in Supabase and `.env` are the same.
