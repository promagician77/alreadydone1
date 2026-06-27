/// Contract for profile data operations.
///
/// Wraps the profile slice of the shared `BackendClient`. As with
/// `AuthRepository`, methods currently return the raw backend
/// `Map<String, dynamic>` to preserve behavior during migration; map to the
/// `Profile` entity in a later pass.
///
/// Auth-overlap actions (sign out, change email/password, OTP verification) do
/// NOT live here — the profile UI routes those through `authRepository`.
/// User-identity helpers like `getCurrentUserTableId` remain on the shared
/// `SupabaseService` as cross-cutting concerns.
abstract class ProfileRepository {
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
