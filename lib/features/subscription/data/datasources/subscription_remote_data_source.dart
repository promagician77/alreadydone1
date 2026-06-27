import '/services/backend_client.dart';

/// Remote data source for subscription ops — thin wrapper over the
/// subscription slice of the shared [BackendClient].
abstract class SubscriptionRemoteDataSource {
  Future<Map<String, dynamic>> updateUserRevenueCatSubscription(
    int userId, {
    required String rcCustomerId,
    required String rcSubscriptionStatus,
    required String rcSubscriptionPlan,
    required String subscriptionProvider,
  });
}

class SubscriptionRemoteDataSourceImpl implements SubscriptionRemoteDataSource {
  const SubscriptionRemoteDataSourceImpl();

  @override
  Future<Map<String, dynamic>> updateUserRevenueCatSubscription(
    int userId, {
    required String rcCustomerId,
    required String rcSubscriptionStatus,
    required String rcSubscriptionPlan,
    required String subscriptionProvider,
  }) =>
      BackendClient.updateUserRevenueCatSubscription(
        userId,
        rcCustomerId: rcCustomerId,
        rcSubscriptionStatus: rcSubscriptionStatus,
        rcSubscriptionPlan: rcSubscriptionPlan,
        subscriptionProvider: subscriptionProvider,
      );
}
