import '../../features/subscription/data/datasources/subscription_remote_data_source.dart';
import '../../features/subscription/data/repositories/subscription_repository_impl.dart';
import '../../features/subscription/domain/repositories/subscription_repository.dart';

/// Interim manual DI for the subscription feature (see `core/di/auth_locator.dart`).
SubscriptionRepository subscriptionRepository = SubscriptionRepositoryImpl(
  const SubscriptionRemoteDataSourceImpl(),
);
