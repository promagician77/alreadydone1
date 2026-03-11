# Apple Sign-In setup guide

Your app **already has** Sign in with Apple implemented in code. This guide covers configuration so it works end-to-end.

---

## What’s already in the project

- **Package:** `sign_in_with_apple: ^6.1.0` in `pubspec.yaml`
- **Service:** `SupabaseService.signInWithApple()` in `lib/services/supabase_service.dart`
  - **iOS:** Native Sign in with Apple (Face ID / Touch ID) → gets credential → signs in with Supabase via `signInWithIdToken`
  - **Web / Android:** Falls back to Supabase OAuth (Apple redirect)
- **UI:** Apple button and `_handleAppleSignIn()` on:
  - `lib/pages/login/login_widget.dart`
  - `lib/pages/sign_up/sign_up_widget.dart`
- **iOS entitlement:** `ios/Runner/Runner.entitlements` has `com.apple.developer.applesignin` with `Default`

---

## 1. Apple Developer (developer.apple.com)

### 1.1 App ID – Sign in with Apple capability

1. Go to [Certificates, Identifiers & Profiles](https://developer.apple.com/account/resources/identifiers/list) → **Identifiers**.
2. Open your **App ID** (e.g. `com.alreadydone.app` or your bundle ID).
3. Enable **Sign in with Apple** (as “Default” or “Primary”).
4. Save.

### 1.2 (Optional) Services ID – for web/Android OAuth

Only needed if you want Apple Sign-In on **web** or **Android** (Supabase OAuth flow).

1. **Identifiers** → **+** → **Services IDs**.
2. Register a Services ID (e.g. `com.alreadydone.app.auth`).
3. Enable **Sign in with Apple**.
4. Configure **Domains and Subdomains** (your Supabase project URL, e.g. `xxxx.supabase.co`) and **Return URLs** (Supabase callback, e.g. `https://xxxx.supabase.co/auth/v1/callback`).
5. Save.

### 1.3 (Optional) Key for backend / Supabase

If Supabase or your backend needs to verify Apple tokens with a private key:

1. **Keys** → **+** → name it (e.g. “Sign in with Apple key”).
2. Enable **Sign in with Apple** and link your **Primary App ID**.
3. Register the key and **download the `.p8`** once (you can’t download it again).
4. Note **Key ID**, **Services ID**, **Team ID**, **Bundle ID**, and **Client ID** (Services ID or App ID depending on Supabase docs). Use the **Apple-provided private key** (`.p8`) in Supabase Dashboard → Authentication → Providers → Apple.

---

## 2. Supabase (supabase.com)

1. **Dashboard** → your project → **Authentication** → **Providers**.
2. Enable **Apple**.
3. Fill in:
   - **Services ID** (e.g. `com.alreadydone.app.auth`) if you use a Services ID; otherwise use your **App ID** (bundle ID) if Supabase allows it for native.
   - **Secret / Private Key:** For native iOS, Supabase often only needs the **Apple provider enabled**; for web/Android OAuth you’ll need the **Key ID**, **Team ID**, **Bundle ID**, **Services ID**, and the **.p8 private key** (see [Supabase Apple docs](https://supabase.com/docs/guides/auth/social-login/auth-apple)).
4. **Redirect URL:** Add the callback Supabase gives you (e.g. `https://xxxx.supabase.co/auth/v1/callback`) in the Apple Services ID return URLs (see 1.2).

---

## 3. Xcode (iOS)

1. Open `ios/Runner.xcworkspace` in Xcode.
2. Select the **Runner** target → **Signing & Capabilities**.
3. Ensure **Sign in with Apple** is in the list (it should be if `Runner.entitlements` has `com.apple.developer.applesignin`).
4. If not: **+ Capability** → add **Sign in with Apple**.
5. Use the same **Team** and **Bundle Identifier** as in Apple Developer.

---

## 4. Android (optional)

For **Android**, your code uses Supabase OAuth (`signInWithOAuth(provider: OAuthProvider.apple)`). You need:

- Apple **Services ID** configured with the Supabase callback URL (see 1.2).
- Supabase **Apple** provider configured with the **.p8** key and IDs (see 2).
- No extra Android-specific code for Apple; the flow is browser/redirect.

---

## 5. Test checklist

- **iOS (device):** Log in / Sign up → tap Apple → native sheet (Face ID / Touch ID or Apple ID) → after sign-in, you should be logged in and `SupabaseService.currentUser` non-null.
- **Web / Android:** Same buttons use OAuth; ensure Supabase callback URL is in Apple Services ID and Supabase Apple provider is set.

If something fails, check:  
- Console for “Apple sign in error” or Supabase errors.  
- Supabase **Authentication** → **Logs** for the attempt.  
- Apple Developer: App ID and (if used) Services ID and return URLs.
