import '../../domain/repositories/subscription_repository.dart';
import '../datasources/subscription_remote_data_source.dart';

/// Default [SubscriptionRepository] backed by [SubscriptionRemoteDataSource].
class SubscriptionRepositoryImpl implements SubscriptionRepository {
  const SubscriptionRepositoryImpl(this._remote);

  final SubscriptionRemoteDataSource _remote;

  @override
  Future<Map<String, dynamic>> updateUserRevenueCatSubscription(
    int userId, {
    required String rcCustomerId,
    required String rcSubscriptionStatus,
    required String rcSubscriptionPlan,
    required String subscriptionProvider,
  }) =>
      _remote.updateUserRevenueCatSubscription(
        userId,
        rcCustomerId: rcCustomerId,
        rcSubscriptionStatus: rcSubscriptionStatus,
        rcSubscriptionPlan: rcSubscriptionPlan,
        subscriptionProvider: subscriptionProvider,
      );
}
