import '../../domain/entities/profile.dart';

/// Maps the backend profile JSON (snake_case keys) to the domain [Profile].
///
/// Target mapping for the migration — not yet wired into the UI (which still
/// reads the raw map). Keys mirror `BackendClient.updateUserProfile`'s body.
class ProfileModel {
  const ProfileModel._();

  static Profile fromJson(Map<String, dynamic> json) => Profile(
        name: json['name'] as String?,
        email: json['email'] as String?,
        narrationSpeed: json['speed'] as String?,
        dreamPlace: json['dream_place'] as String?,
        location: json['location'] as String?,
        energyWord: json['energyWord'] as String?,
        someoneYouLove: json['lovedOne'] as String?,
        isMorningReminder: json['is_MorningTime_Reminder'] == true,
        isBedtimeReminder: json['is_BedTime_Reminder'] == true,
        morningTimeReminder: json['morningTime_Reminder'] as String?,
        bedtimeReminder: json['bedTime_Reminder'] as String?,
        timezone: json['timezone'] as String?,
      );
}
