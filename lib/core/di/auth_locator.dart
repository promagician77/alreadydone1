import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';

/// Minimal, dependency-free dependency injection for the auth feature.
///
/// This keeps the feature-first migration additive — no new packages, no
/// changes to the app's widget tree. As more features migrate, consider
/// replacing this with `get_it`/`injectable` or Provider/Riverpod injection so
/// dependencies are wired in one place and overridden per scope.
///
/// Tests can replace [authRepository] with a fake implementation:
/// ```dart
/// authRepository = FakeAuthRepository();
/// ```
AuthRepository authRepository = AuthRepositoryImpl(
  const AuthRemoteDataSourceImpl(),
);
