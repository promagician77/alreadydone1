import 'package:supabase_flutter/supabase_flutter.dart';

export 'package:supabase_flutter/supabase_flutter.dart' show OAuthProvider;

/// Supabase service for authentication and database operations.
class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;

  /// Initialize Supabase with your project credentials.
  /// 
  /// Get these from your Supabase project dashboard:
  /// - Project URL: https://your-project.supabase.co
  /// - Anon Key: Your anon/public key from Settings > API
  static Future<void> initialize({
    required String url,
    required String anonKey,
  }) async {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
      debug: false, // Set to true for development debugging
    );
  }

  /// Get current user session
  static User? get currentUser => client.auth.currentUser;

  /// Check if user is authenticated
  static bool get isAuthenticated => currentUser != null;

  /// Sign up with email and password
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

  /// Sign in with email and password
  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Sign out
  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  /// Reset password (send reset email)
  static Future<void> resetPasswordForEmail(String email) async {
    await client.auth.resetPasswordForEmail(
      email,
      redirectTo: null, // You can set a custom redirect URL if needed
    );
  }

  /// Sign in with OAuth provider (Google, Apple, etc.)
  static Future<bool> signInWithOAuth({
    required OAuthProvider provider,
    String? redirectTo,
  }) async {
    return await client.auth.signInWithOAuth(
      provider,
      redirectTo: redirectTo,
    );
  }

  /// Listen to auth state changes
  static Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;
}
