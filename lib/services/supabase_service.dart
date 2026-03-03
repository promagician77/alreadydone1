import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

export 'package:supabase_flutter/supabase_flutter.dart' show OAuthProvider;

const String oauthRedirectUrl = 'alreadydone://alreadydone.app';

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

  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? fullName,
    Map<String, dynamic>? metadata,
  }) async {
    return await client.auth.signUp(
      email: email,
      password: password,
      data: {
        if (fullName != null) 'full_name': fullName,
        if (metadata != null) ...metadata,
      },
    );
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

  /// Google sign-in: native account picker on mobile (no browser), OAuth redirect on web.
  static Future<void> signInWithGoogle() async {
    if (kIsWeb) {
      await signInWithOAuth(provider: OAuthProvider.google);
      return;
    }
    final webClientId = dotenv.env['GOOGLE_WEB_CLIENT_ID']?.trim();
    if (webClientId == null || webClientId.isEmpty) {
      throw Exception(
        'GOOGLE_WEB_CLIENT_ID is not set in .env. '
        'Add your Google Cloud web client ID (same as in Supabase Dashboard → Auth → Google).',
      );
    }
    final iosClientId = dotenv.env['GOOGLE_IOS_CLIENT_ID']?.trim();
    final googleSignIn = GoogleSignIn(
      serverClientId: webClientId,
      clientId: (iosClientId != null && iosClientId.isNotEmpty) ? iosClientId : null,
    );
    try {
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) return;
      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;
      if (idToken == null) throw Exception('Google Sign-In: no ID token');
      if (accessToken == null) throw Exception('Google Sign-In: no access token');
      await client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
    } on PlatformException catch (e) {
      if (e.code == 'sign_in_failed' &&
          (e.message?.contains('ApiException: 10') ?? false)) {
        throw Exception(
          'Google Sign-In setup error: add your app\'s SHA-1 and package name '
          '(com.alreadydone.app) in Google Cloud Console → Credentials → '
          'Create OAuth 2.0 Client ID → Android.',
        );
      }
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
