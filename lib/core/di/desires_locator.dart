import '../../features/desires/data/datasources/desires_remote_data_source.dart';
import '../../features/desires/data/repositories/desires_repository_impl.dart';
import '../../features/desires/domain/repositories/desires_repository.dart';

/// Interim manual DI for the desires feature (see `core/di/auth_locator.dart`).
DesiresRepository desiresRepository = DesiresRepositoryImpl(
  const DesiresRemoteDataSourceImpl(),
);
