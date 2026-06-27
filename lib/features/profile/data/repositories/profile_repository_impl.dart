import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_data_source.dart';

/// Default [ProfileRepository] backed by [ProfileRemoteDataSource].
/// Pass-through during migration (see the note on [ProfileRepository]).
class ProfileRepositoryImpl implements ProfileRepository {
  const ProfileRepositoryImpl(this._remote);

  final ProfileRemoteDataSource _remote;

  @override
  Future<Map<String, dynamic>> getUserProfile(int userId) =>
      _remote.getUserProfile(userId);

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
      _remote.updateUserProfile(
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
      _remote.closeAccount(
        userId: userId,
        authUserId: authUserId,
        supabaseAccessToken: supabaseAccessToken,
      );
}
