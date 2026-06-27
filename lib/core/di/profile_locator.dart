import '../../features/profile/data/datasources/profile_remote_data_source.dart';
import '../../features/profile/data/repositories/profile_repository_impl.dart';
import '../../features/profile/domain/repositories/profile_repository.dart';

/// Interim manual DI for the profile feature (see `core/di/auth_locator.dart`
/// for the rationale). Override in tests with a fake implementation.
ProfileRepository profileRepository = ProfileRepositoryImpl(
  const ProfileRemoteDataSourceImpl(),
);
