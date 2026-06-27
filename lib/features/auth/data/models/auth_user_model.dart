import 'package:supabase_flutter/supabase_flutter.dart' show User;

import '../../domain/entities/auth_user.dart';

/// Maps the Supabase [User] (data layer) to the domain [AuthUser] entity.
///
/// Keeping this mapping here means the domain and presentation layers never
/// need to know about Supabase's `User` shape.
class AuthUserModel {
  const AuthUserModel._();

  static AuthUser fromSupabase(User user) => AuthUser(
        id: user.id,
        email: user.email,
        fullName: user.userMetadata?['full_name'] as String?,
        isEmailConfirmed: user.emailConfirmedAt != null,
      );
}
