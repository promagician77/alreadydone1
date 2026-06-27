import 'package:supabase_flutter/supabase_flutter.dart' show AuthResponse;

import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/auth_user_model.dart';

/// Default [AuthRepository] backed by [AuthRemoteDataSource].
///
/// Delegates to the data source (which wraps Supabase). Maps the Supabase
/// `User` to the domain [AuthUser] for [currentUser]; the response-returning
/// methods pass [AuthResponse] through unchanged for now (see the migration
/// note on [AuthRepository]).
class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._remote);

  final AuthRemoteDataSource _remote;

  @override
  bool get isAuthenticated => _remote.isAuthenticated;

  @override
  AuthUser? get currentUser {
    final user = _remote.currentUser;
    return user == null ? null : AuthUserModel.fromSupabase(user);
  }

  @override
  Future<AuthResponse> signIn({required String email, required String password}) =>
      _remote.signIn(email: email, password: password);

  @override
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? fullName,
    Map<String, dynamic>? metadata,
  }) =>
      _remote.signUp(
        email: email,
        password: password,
        fullName: fullName,
        metadata: metadata,
      );

  @override
  Future<void> signOut() => _remote.signOut();

  @override
  Future<void> sendEmailOtp({required String email, String? redirectTo}) =>
      _remote.sendEmailOtp(email: email, redirectTo: redirectTo);

  @override
  Future<AuthResponse> verifyEmailOtp({required String email, required String token}) =>
      _remote.verifyEmailOtp(email: email, token: token);

  @override
  Future<AuthResponse> verifyEmailChangeOtp({required String email, required String token}) =>
      _remote.verifyEmailChangeOtp(email: email, token: token);

  @override
  Future<void> updateUserEmail(String newEmail, {String? emailRedirectTo}) =>
      _remote.updateUserEmail(newEmail, emailRedirectTo: emailRedirectTo);

  @override
  Future<void> resetPasswordForEmail(String email) =>
      _remote.resetPasswordForEmail(email);

  @override
  Future<AuthResponse> verifyRecoveryOtp({required String email, required String token}) =>
      _remote.verifyRecoveryOtp(email: email, token: token);

  @override
  Future<void> completePasswordRecovery({required String newPassword}) =>
      _remote.completePasswordRecovery(newPassword: newPassword);

  @override
  Future<void> signInWithApple() => _remote.signInWithApple();

  @override
  Future<void> signInWithGoogle() => _remote.signInWithGoogle();

  @override
  bool isEmailAlreadyRegisteredError(Object e) =>
      _remote.isEmailAlreadyRegisteredError(e);
}
