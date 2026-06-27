/// Contract for subscription-domain backend operations.
///
/// Wraps the subscription slice of the shared `BackendClient`. The RevenueCat
/// SDK access (`RevenueCatService`) stays a shared payments service — like
/// `SupabaseService`/`BackendClient` — and is not wrapped here. `getUserProfile`
/// is not here either: the subscription UI reuses `profileRepository`.
abstract class SubscriptionRepository {
  Future<Map<String, dynamic>> updateUserRevenueCatSubscription(
    int userId, {
    required String rcCustomerId,
    required String rcSubscriptionStatus,
    required String rcSubscriptionPlan,
    required String subscriptionProvider,
  });
}
