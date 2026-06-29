import 'package:supabase_flutter/supabase_flutter.dart' show AuthResponse, User;
import '/shared/services/supabase_service.dart';

abstract class AuthRemoteDataSource {
  bool get isAuthenticated;
  User? get currentUser;

  Future<AuthResponse> signIn({required String email, required String password});
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? fullName,
    Map<String, dynamic>? metadata,
  });
  Future<void> signOut();
  Future<void> sendEmailOtp({required String email, String? redirectTo});
  Future<AuthResponse> verifyEmailOtp({required String email, required String token});
  Future<AuthResponse> verifyEmailChangeOtp({required String email, required String token});
  Future<void> updateUserEmail(String newEmail, {String? emailRedirectTo});
  Future<void> resetPasswordForEmail(String email);
  Future<AuthResponse> verifyRecoveryOtp({required String email, required String token});
  Future<void> completePasswordRecovery({required String newPassword});
  Future<void> updatePassword({required String currentPassword, required String newPassword});
  Future<void> signInWithApple();
  Future<void> signInWithGoogle();
  bool isEmailAlreadyRegisteredError(Object e);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  const AuthRemoteDataSourceImpl();

  @override
  bool get isAuthenticated => SupabaseService.isAuthenticated;

  @override
  User? get currentUser => SupabaseService.currentUser;

  @override
  Future<AuthResponse> signIn({required String email, required String password}) =>
      SupabaseService.signIn(email: email, password: password);

  @override
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? fullName,
    Map<String, dynamic>? metadata,
  }) =>
      SupabaseService.signUp(
        email: email,
        password: password,
        fullName: fullName,
        metadata: metadata,
      );

  @override
  Future<void> signOut() => SupabaseService.signOut();

  @override
  Future<void> sendEmailOtp({required String email, String? redirectTo}) =>
      SupabaseService.sendEmailOtp(email: email, redirectTo: redirectTo);

  @override
  Future<AuthResponse> verifyEmailOtp({required String email, required String token}) =>
      SupabaseService.verifyEmailOtp(email: email, token: token);

  @override
  Future<AuthResponse> verifyEmailChangeOtp({required String email, required String token}) =>
      SupabaseService.verifyEmailChangeOtp(email: email, token: token);

  @override
  Future<void> updateUserEmail(String newEmail, {String? emailRedirectTo}) =>
      SupabaseService.updateUserEmail(newEmail, emailRedirectTo: emailRedirectTo);

  @override
  Future<void> resetPasswordForEmail(String email) =>
      SupabaseService.resetPasswordForEmail(email);

  @override
  Future<AuthResponse> verifyRecoveryOtp({required String email, required String token}) =>
      SupabaseService.verifyRecoveryOtp(email: email, token: token);

  @override
  Future<void> completePasswordRecovery({required String newPassword}) =>
      SupabaseService.completePasswordRecovery(newPassword: newPassword);

  @override
  Future<void> updatePassword({required String currentPassword, required String newPassword}) =>
      SupabaseService.updatePassword(currentPassword: currentPassword, newPassword: newPassword);

  @override
  Future<void> signInWithApple() => SupabaseService.signInWithApple();

  @override
  Future<void> signInWithGoogle() => SupabaseService.signInWithGoogle();

  @override
  bool isEmailAlreadyRegisteredError(Object e) =>
      SupabaseService.isEmailAlreadyRegisteredError(e);
}
