import '/core/network/backend_client.dart';

/// Remote data source for profile data — a thin wrapper over the profile slice
/// of the shared [BackendClient]. `BackendClient` stays shared (it also serves
/// stories and other features); this isolates the profile feature from it.
abstract class ProfileRemoteDataSource {
  Future<Map<String, dynamic>> getUserProfile(int userId);
  Future<Map<String, dynamic>> updateUserProfile(
    int userId, {
    String? speed,
    bool? isMorningReminder,
    bool? isBedtimeReminder,
    String? morningTimeReminder,
    String? bedtimeReminder,
    String? timezone,
    String? name,
    String? email,
    String? dreamPlace,
    String? location,
    String? energyWord,
    String? someoneYouLove,
    String? fcmToken,
  });
  Future<Map<String, dynamic>> closeAccount({
    required int userId,
    required String authUserId,
    required String supabaseAccessToken,
  });
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  const ProfileRemoteDataSourceImpl();

  @override
  Future<Map<String, dynamic>> getUserProfile(int userId) =>
      BackendClient.getUserProfile(userId);

  @override
  Future<Map<String, dynamic>> updateUserProfile(
    int userId, {
    String? speed,
    bool? isMorningReminder,
    bool? isBedtimeReminder,
    String? morningTimeReminder,
    String? bedtimeReminder,
    String? timezone,
    String? name,
    String? email,
    String? dreamPlace,
    String? location,
    String? energyWord,
    String? someoneYouLove,
    String? fcmToken,
  }) =>
      BackendClient.updateUserProfile(
        userId,
        speed: speed,
        isMorningReminder: isMorningReminder,
        isBedtimeReminder: isBedtimeReminder,
        morningTimeReminder: morningTimeReminder,
        bedtimeReminder: bedtimeReminder,
        timezone: timezone,
        name: name,
        email: email,
        dreamPlace: dreamPlace,
        location: location,
        energyWord: energyWord,
        someoneYouLove: someoneYouLove,
        fcmToken: fcmToken,
      );

  @override
  Future<Map<String, dynamic>> closeAccount({
    required int userId,
    required String authUserId,
    required String supabaseAccessToken,
  }) =>
      BackendClient.closeAccount(
        userId: userId,
        authUserId: authUserId,
        supabaseAccessToken: supabaseAccessToken,
      );
}
