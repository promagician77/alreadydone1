/// Domain entity representing an authenticated user.
///
/// Pure Dart: no dependency on Supabase or Flutter. This is the shape the
/// presentation layer should depend on. Mapping from the Supabase `User` lives
/// in `data/models/auth_user_model.dart`.
class AuthUser {
  const AuthUser({
    required this.id,
    this.email,
    this.fullName,
    this.isEmailConfirmed = false,
  });

  final String id;
  final String? email;
  final String? fullName;
  final bool isEmailConfirmed;
}
