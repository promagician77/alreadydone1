import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show debugPrint, defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '/pages/onboarding/onboarding_state.dart';

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

  /// Serializes [ensureUserProfileFromAuth] so concurrent calls (e.g. OAuth +
  /// auth state listener) cannot both observe "no row" and insert duplicates.
  static Future<void> _ensureUserProfileChain = Future<void>.value();

  static Future<void> _runEnsureUserProfileSerialized(
    Future<void> Function() work,
  ) async {
    final previous = _ensureUserProfileChain;
    final completer = Completer<void>();
    _ensureUserProfileChain = completer.future;
    try {
      await previous;
      await work();
    } finally {
      if (!completer.isCompleted) completer.complete();
    }
  }

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

  static Future<void> updateUserEmail(
    String newEmail, {
    String? emailRedirectTo,
  }) async {
    await client.auth.updateUser(
      UserAttributes(email: newEmail.trim()),
      emailRedirectTo: emailRedirectTo,
    );
  }

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

  static Future<void> ensureUserProfileFromAuth({String? overrideName}) async {
    await _runEnsureUserProfileSerialized(() async {
      final user = currentUser;
      if (user == null) return;
      final email = user.email?.trim();
      if (email == null || email.isEmpty) return;

      // Build the best name we have right now.
      // Priority: overrideName → full_name metadata → name metadata → email prefix (last resort)
      final String resolvedName = _pickBestName(
        override: overrideName,
        fullNameMeta: user.userMetadata?['full_name'] as String?,
        nameMeta: user.userMetadata?['name'] as String?,
        emailPrefix: user.email?.split('@').first,
      );

      try {
        // Avoid maybeSingle() — duplicate legacy rows would throw; limit(1) is safe.
        final result = await client
            .from('Users')
            .select('id, name')
            .eq('email', email)
            .limit(1);
        final rows = List<dynamic>.from(result as List<dynamic>);
        final Map<String, dynamic>? existing = rows.isEmpty
            ? null
            : Map<String, dynamic>.from(rows.first as Map);

        if (existing != null) {
          // Only overwrite if the stored name is blank or an email-prefix placeholder.
          final storedName = (existing['name'] as String?)?.trim() ?? '';
          if (_isPlaceholderName(storedName)) {
            await client
                .from('Users')
                .update({'name': resolvedName})
                .eq('email', email);
          }
        } else {
          await client.from('Users').insert({
            'name': resolvedName,
            'email': email,
          });
        }
      } catch (_) {}
    });
  }

  /// Returns true when [name] looks like an auto-generated placeholder
  /// (empty, or an email-prefix: no spaces, only letters/digits/dots/underscores/hyphens).
  static bool _isPlaceholderName(String name) {
    if (name.isEmpty) return true;
    // A real display name almost always contains a space or mixed-case letters.
    // An email prefix never contains spaces and is typically all-lowercase + digits.
    final emailPrefixPattern = RegExp(r'^[a-zA-Z0-9._\-]+$');
    return emailPrefixPattern.hasMatch(name) && !name.contains(' ');
  }

  /// Picks the best available name from the provided candidates.
  static String _pickBestName({
    String? override,
    String? fullNameMeta,
    String? nameMeta,
    String? emailPrefix,
  }) {
    final candidates = [override, fullNameMeta, nameMeta, emailPrefix];
    for (final c in candidates) {
      final trimmed = c?.trim() ?? '';
      if (trimmed.isNotEmpty) return trimmed;
    }
    return '';
  }

  static String? _extractFirstName(String? fullNameOrName) {
    final s = (fullNameOrName ?? '').trim();
    if (s.isEmpty) return null;
    final parts = s.split(RegExp(r'\s+')).where((p) => p.trim().isNotEmpty).toList();
    if (parts.isEmpty) return null;
    return parts.first.trim();
  }

  static void _prefillOnboardingFirstName({String? firstName, String? fullName}) {
    final state = OnboardingState.instance;
    if (state.firstNameController.text.trim().isNotEmpty) return;
    final candidate = _extractFirstName(firstName) ?? _extractFirstName(fullName);
    if (candidate == null || candidate.isEmpty) return;
    state.firstNameController.text = candidate;
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

  /// Apple sign-in: native Sign in with Apple on iOS, OAuth redirect on web/Android.
  ///
  /// FIX: The real display name (from Apple credential) is now passed directly
  /// into [ensureUserProfileFromAuth] *before* the metadata update completes,
  /// preventing the race condition that wrote the email-prefix as the username.
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

      // Step 1 — authenticate with Supabase.
      await client.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
        nonce: rawNonce,
      );

      // Step 2 — build the full name from the Apple credential.
      // Apple only returns givenName / familyName on the FIRST sign-in.
      // On subsequent logins both will be null — ensureUserProfileFromAuth
      // will then skip overwriting an already-valid stored name.
      String? fullName;
      if ((credential.givenName?.isNotEmpty ?? false) ||
          (credential.familyName?.isNotEmpty ?? false)) {
        fullName = [credential.givenName, credential.familyName]
            .whereType<String>()
            .where((s) => s.isNotEmpty)
            .join(' ')
            .trim();
        if (fullName.isEmpty) fullName = null;
      }

      // Step 3 — update Supabase auth metadata (best-effort, non-blocking for DB write).
      if (fullName != null) {
        await client.auth.updateUser(
          UserAttributes(data: {'full_name': fullName}),
        );
      }

      // Step 4 — upsert the Users table row with the real name, not the email prefix.
      // We pass fullName as overrideName so the DB write uses it directly,
      // independent of whether the metadata update above has propagated yet.
      await ensureUserProfileFromAuth(overrideName: fullName);

      // Step 5 — prefill onboarding first name.
      _prefillOnboardingFirstName(
        firstName: credential.givenName,
        fullName: fullName ??
            (client.auth.currentUser?.userMetadata?['full_name'] as String?) ??
            (client.auth.currentUser?.userMetadata?['name'] as String?),
      );
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

      // Upsert Users table with the real Google display name as override,
      // avoiding any race condition with metadata propagation.
      final displayName = googleUser.displayName?.trim();
      await ensureUserProfileFromAuth(
        overrideName: (displayName != null && displayName.isNotEmpty) ? displayName : null,
      );

      // Prefill onboarding first name from Google display name / user metadata.
      _prefillOnboardingFirstName(
        fullName: googleUser.displayName ??
            (client.auth.currentUser?.userMetadata?['full_name'] as String?) ??
            (client.auth.currentUser?.userMetadata?['name'] as String?),
      );
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