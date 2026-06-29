import 'package:supabase_flutter/supabase_flutter.dart' show User;

import '../../domain/entities/auth_user.dart';

class AuthUserModel {
  const AuthUserModel._();

  static AuthUser fromSupabase(User user) => AuthUser(
        id: user.id,
        email: user.email,
        fullName: user.userMetadata?['full_name'] as String?,
        isEmailConfirmed: user.emailConfirmedAt != null,
      );
}
