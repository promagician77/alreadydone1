import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show debugPrint, defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

export 'package:supabase_flutter/supabase_flutter.dart' show OAuthProvider;

const String oauthRedirectUrl = 'alreadydone://alreadydone.app/auth/callback';

/// Thrown when sign-up is attempted with an email that is already registered.
class EmailAlreadyRegisteredException implements Exception {
  const EmailAlreadyRegisteredException();
  @override
  String toString() =>
      'This email is already registered. Please sign in instead.';
}

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize({
    required String url,
    required String anonKey,
  }) async {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
      debug: false, 
    );
  }

  static User? get currentUser => client.auth.currentUser;
  static bool get isAuthenticated => currentUser != null;

  static Future<int?> getCurrentUserTableId() async {
    final email = currentUser?.email;
    if (email == null || email.isEmpty) return null;
    try {
      final result = await client.from('Users').select('id').eq('email', email) as dynamic;
      final rows = result is List ? List<dynamic>.from(result) : <dynamic>[];
      if (rows.isEmpty) return null;
      final first = rows.first;
      final rawId = first is Map ? first['id'] : first;
      if (rawId == null) return null;
      if (rawId is int) return rawId;
      if (rawId is num) return rawId.toInt();
      if (rawId is String) return int.tryParse(rawId);
    } catch (_) {}
    return null;
  }

  /// Thrown when signUp is called with an email that is already registered.
  /// UI can catch this and show "Please sign in" instead of a generic error.
  static bool isEmailAlreadyRegisteredError(Object e) {
    return e is EmailAlreadyRegisteredException ||
        (e.toString().contains('already registered') ||
            e.toString().toLowerCase().contains('already been registered'));
  }

  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? fullName,
    Map<String, dynamic>? metadata,
  }) async {
    final response = await client.auth.signUp(
      email: email,
      password: password,
      data: {
        if (fullName != null) 'full_name': fullName,
        if (metadata != null) ...metadata,
      },
    );
    // Double signup: when email confirmation is enabled, Supabase returns a user
    // but with empty identities when the email already exists.
    if (response.user != null &&
        (response.user!.identities == null ||
            response.user!.identities!.isEmpty)) {
      throw const EmailAlreadyRegisteredException();
    }
    return response;
  }

  static Future<void> sendEmailOtp({
    required String email,
    String? redirectTo,
  }) async {
    await client.auth.signInWithOtp(
      email: email,
      emailRedirectTo: redirectTo,
    );
  }

  static Future<AuthResponse> verifyEmailOtp({
    required String email,
    required String token,
  }) async {
    return await client.auth.verifyOTP(
      email: email,
      token: token,
      type: OtpType.email,
    );
  }

  /// Request email change. Supabase sends a magic link to the new email.
  /// User taps the link to confirm; it deep-links back to the app.
  /// [emailRedirectTo] should include userId, e.g. alreadydone://.../auth/callback?userId=123
  static Future<void> updateUserEmail(
    String newEmail, {
    String? emailRedirectTo,
  }) async {
    await client.auth.updateUser(
      UserAttributes(email: newEmail.trim()),
      emailRedirectTo: emailRedirectTo,
    );
  }

  /// Verify OTP for email change. Call after updateUserEmail.
  static Future<AuthResponse> verifyEmailChangeOtp({
    required String email,
    required String token,
  }) async {
    return await client.auth.verifyOTP(
      email: email,
      token: token,
      type: OtpType.emailChange,
    );
  }

  static Future<void> insertUserProfile({
    required String name,
    required String email,
  }) async {
    await client.from('Users').insert({
      'name': name,
      'email': email,
    });
  }

  static Future<void> ensureUserProfileFromAuth() async {
    final user = currentUser;
    if (user == null) return;
    final email = user.email?.trim();
    if (email == null || email.isEmpty) return;
    final name = (user.userMetadata?['full_name'] as String?)?.trim() ??
        (user.userMetadata?['name'] as String?)?.trim() ??
        user.email?.split('@').first ??
        '';
    try {
      final existing = await client.from('Users').select('id').eq('email', email).maybeSingle();
      if (existing != null && existing is Map) {
        await client.from('Users').update({'name': name}).eq('email', email);
      } else {
        await client.from('Users').insert({'name': name, 'email': email});
      }
    } catch (_) {}
  }

  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  static Future<void> resetPasswordForEmail(String email) async {
    await client.auth.resetPasswordForEmail(
      email,
      redirectTo: null, 
    );
  }

  /// Change password: verifies current password, then updates to new one.
  /// Throws if not signed in, current password wrong, or update fails.
  static Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final email = currentUser?.email;
    if (email == null || email.isEmpty) {
      throw Exception('You must be signed in to change your password');
    }
    await client.auth.signInWithPassword(
      email: email,
      password: currentPassword,
    );
    await client.auth.updateUser(UserAttributes(password: newPassword));
  }

  static Future<bool> signInWithOAuth({
    required OAuthProvider provider,
    String? redirectTo,
  }) async {
    final redirect = redirectTo ?? (kIsWeb ? null : oauthRedirectUrl);
    return await client.auth.signInWithOAuth(
      provider,
      redirectTo: redirect,
    );
  }

  /// Apple sign-in: native Sign in with Apple on iOS (Face ID / Touch ID), OAuth redirect on web/Android.
  static Future<void> signInWithApple() async {
    final isIOS = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
    if (!isIOS) {
      await client.auth.signInWithOAuth(
        OAuthProvider.apple,
        redirectTo: oauthRedirectUrl,
        authScreenLaunchMode: LaunchMode.externalApplication,
      );
      return;
    }
    try {
      final rawNonce = _generateSecureNonce();
      final hashedNonce = _sha256ofString(rawNonce);
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );
      final idToken = credential.identityToken;
      if (idToken == null || idToken.isEmpty) {
        throw Exception('Apple Sign-In: no identity token');
      }
      await client.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
        nonce: rawNonce,
      );
      final user = client.auth.currentUser;
      if (user != null &&
          credential.givenName != null &&
          (credential.givenName!.isNotEmpty || credential.familyName != null)) {
        final fullName = [credential.givenName, credential.familyName]
            .whereType<String>()
            .where((s) => s.isNotEmpty)
            .join(' ')
            .trim();
        if (fullName.isNotEmpty) {
          await client.auth.updateUser(
            UserAttributes(data: {'full_name': fullName}),
          );
        }
      }
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) return;
      throw Exception(e.message);
    } on PlatformException catch (e) {
      throw Exception(e.message ?? 'Apple Sign-In failed');
    }
  }

  static String _generateSecureNonce() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64Url.encode(bytes);
  }

  static String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.bytes.map((e) => e.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Google sign-in: native account picker on mobile (no browser), OAuth redirect on web.
  /// Uses GOOGLE_WEB_CLIENT_ID (Supabase/server) and GOOGLE_ANDROID_CLIENT_ID or GOOGLE_IOS_CLIENT_ID (app).
  static Future<void> signInWithGoogle() async {
    const _tag = '[GoogleOAuth]';
    debugPrint('$_tag signInWithGoogle() started. kIsWeb=$kIsWeb, platform=${defaultTargetPlatform.name}');

    if (kIsWeb) {
      debugPrint('$_tag Web: using signInWithOAuth redirect.');
      await signInWithOAuth(provider: OAuthProvider.google);
      return;
    }

    final isAndroid = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    final isIOS = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
    debugPrint('$_tag Native: isAndroid=$isAndroid, isIOS=$isIOS');

    final webClientId = dotenv.env['GOOGLE_WEB_CLIENT_ID']?.trim();
    debugPrint('$_tag GOOGLE_WEB_CLIENT_ID: ${webClientId == null || webClientId.isEmpty ? "MISSING" : "set (length ${webClientId.length})"}');
    if (webClientId == null || webClientId.isEmpty) {
      throw Exception(
        'GOOGLE_WEB_CLIENT_ID is not set in .env. '
        'Add your Google Cloud web client ID (same as in Supabase Dashboard → Auth → Google).',
      );
    }

    final androidClientId = dotenv.env['GOOGLE_ANDROID_CLIENT_ID']?.trim();
    final iosClientId = dotenv.env['GOOGLE_IOS_CLIENT_ID']?.trim();
    debugPrint('$_tag GOOGLE_ANDROID_CLIENT_ID: ${androidClientId == null || androidClientId.isEmpty ? "MISSING" : "set (length ${androidClientId.length})"}');
    debugPrint('$_tag GOOGLE_IOS_CLIENT_ID: ${iosClientId == null || iosClientId.isEmpty ? "MISSING" : "set (length ${iosClientId.length})"}');

    if (isAndroid && (androidClientId == null || androidClientId.isEmpty)) {
      throw Exception(
        'GOOGLE_ANDROID_CLIENT_ID is not set in .env. '
        'Add your Google Cloud Android OAuth client ID (package com.alreadydone.app + SHA-1).',
      );
    }
    if (isIOS && (iosClientId == null || iosClientId.isEmpty)) {
      throw Exception(
        'GOOGLE_IOS_CLIENT_ID is not set in .env. '
        'Add your Google Cloud iOS OAuth client ID (bundle id com.mycompany.alreadyapp). '
        'Also add the reversed client ID as a URL scheme in ios/Runner/Info.plist.',
      );
    }

    final clientIdForSignIn = isIOS && (iosClientId != null && iosClientId.isNotEmpty) ? iosClientId : null;
    debugPrint('$_tag GoogleSignIn config: serverClientId length=${webClientId.length}, clientId (native)=${clientIdForSignIn != null ? "set" : "null"}');
    final googleSignIn = GoogleSignIn(
      serverClientId: webClientId,
      clientId: clientIdForSignIn,
    );

    try {
      debugPrint('$_tag Calling GoogleSignIn.signIn()...');
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint('$_tag GoogleSignIn.signIn() returned null (user cancelled or error).');
        return;
      }
      debugPrint('$_tag Got GoogleUser: email=${googleUser.email ?? "null"}, id=${googleUser.id ?? "null"}');

      debugPrint('$_tag Requesting googleUser.authentication...');
      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;
      debugPrint('$_tag authentication: idToken=${idToken != null ? "present (length ${idToken.length})" : "NULL"}, accessToken=${accessToken != null ? "present (length ${accessToken.length})" : "NULL"}');

      if (idToken == null) {
        debugPrint('$_tag FAIL: idToken is null.');
        throw Exception('Google Sign-In: no ID token');
      }
      if (accessToken == null) {
        debugPrint('$_tag FAIL: accessToken is null.');
        throw Exception('Google Sign-In: no access token');
      }

      debugPrint('$_tag Calling Supabase client.auth.signInWithIdToken(provider: google)...');
      await client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
      debugPrint('$_tag Supabase signInWithIdToken SUCCESS. Session: ${client.auth.currentSession != null}');
    } on PlatformException catch (e, st) {
      debugPrint('$_tag PlatformException: code=${e.code}, message=${e.message}, details=${e.details}');
      debugPrint('$_tag PlatformException stackTrace: $st');
      if (e.code == 'sign_in_failed' &&
          (e.message?.contains('ApiException: 10') ?? false)) {
        debugPrint('$_tag ApiException: 10 → SHA-1 / package name mismatch in Google Cloud Console (Android OAuth client).');
        throw Exception(
          isAndroid
              ? 'Google Sign-In setup error: add your app\'s SHA-1 and package name '
                '(com.alreadydone.app) in Google Cloud Console → Credentials → '
                'Create OAuth 2.0 Client ID → Android. Use Web client ID in Supabase and .env.'
              : 'Google Sign-In setup error: add iOS OAuth client ID (bundle id com.mycompany.alreadyapp) '
                'in Google Cloud Console, set GOOGLE_IOS_CLIENT_ID in .env, and add the reversed '
                'client ID URL scheme in ios/Runner/Info.plist.',
        );
      }
      rethrow;
    } catch (e, st) {
      debugPrint('$_tag Exception: $e');
      debugPrint('$_tag StackTrace: $st');
      rethrow;
    }
  }

  static Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;

  /// Handle auth callback from magic link (e.g. email change confirmation).
  /// Parses refresh_token from URL and sets session.
  /// Returns the new email if successful, else null.
  static Future<String?> handleAuthCallbackUrl(String url) async {
    final uri = Uri.parse(url);
    if (!uri.toString().contains('auth/callback')) return null;

    String? refreshToken;
    final fragment = uri.fragment;
    if (fragment.isNotEmpty) {
      final params = Uri.splitQueryString(fragment);
      refreshToken = params['refresh_token'];
    }
    if (refreshToken == null || refreshToken.isEmpty) return null;

    await client.auth.setSession(refreshToken);
    return client.auth.currentUser?.email;
  }
}
