import '../../features/player/data/datasources/player_local_data_source.dart';
import '../../features/player/data/datasources/player_remote_data_source.dart';
import '../../features/player/data/repositories/player_repository_impl.dart';
import '../../features/player/domain/repositories/player_repository.dart';

/// Interim manual DI for the player feature (see `core/di/auth_locator.dart`
/// for the rationale). Override in tests with a fake implementation.
PlayerRepository playerRepository = PlayerRepositoryImpl(
  const PlayerRemoteDataSourceImpl(),
  const PlayerLocalDataSourceImpl(),
);
