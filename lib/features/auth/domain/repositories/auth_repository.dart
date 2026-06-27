import 'package:supabase_flutter/supabase_flutter.dart' show AuthResponse;

import '../entities/auth_user.dart';

/// Contract for all authentication operations used by the auth feature.
///
/// MIGRATION NOTE: the email/password/OTP methods currently return Supabase's
/// [AuthResponse] to preserve exact behavior during the feature-first
/// migration (the presentation layer still reads the Supabase response). A
/// later pass can map these to pure domain types so this interface no longer
/// imports `supabase_flutter`.
///
/// The cross-cutting profile/device operations that used to live on
/// `SupabaseService` (e.g. `ensureUserProfileFromAuth`,
/// `upsertDeviceInfoForCurrentUser`, `getDeviceId`) intentionally do NOT belong
/// here. They are separate concerns and should move to future `profile` /
/// `device` features rather than be absorbed into auth.
abstract class AuthRepository {
  /// Whether a user session currently exists.
  bool get isAuthenticated;

  /// The currently signed-in user mapped to the domain entity, or null.
  AuthUser? get currentUser;

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  });

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? fullName,
    Map<String, dynamic>? metadata,
  });

  Future<void> signOut();

  Future<void> sendEmailOtp({required String email, String? redirectTo});

  Future<AuthResponse> verifyEmailOtp({
    required String email,
    required String token,
  });

  Future<AuthResponse> verifyEmailChangeOtp({
    required String email,
    required String token,
  });

  Future<void> updateUserEmail(String newEmail, {String? emailRedirectTo});

  Future<void> resetPasswordForEmail(String email);

  Future<AuthResponse> verifyRecoveryOtp({
    required String email,
    required String token,
  });

  Future<void> completePasswordRecovery({required String newPassword});

  Future<void> signInWithApple();

  Future<void> signInWithGoogle();

  /// True if [e] indicates the email is already registered.
  bool isEmailAlreadyRegisteredError(Object e);
}
