/// Domain entity for a user's profile/settings.
///
/// Pure Dart. MIGRATION NOTE: the presentation layer currently consumes the
/// raw `Map<String, dynamic>` returned by the backend, so [ProfileRepository]
/// still returns maps for now. This entity + `ProfileModel.fromJson` document
/// the target shape; wire them in once the UI reads typed fields.
class Profile {
  const Profile({
    this.name,
    this.email,
    this.narrationSpeed,
    this.dreamPlace,
    this.location,
    this.energyWord,
    this.someoneYouLove,
    this.isMorningReminder = false,
    this.isBedtimeReminder = false,
    this.morningTimeReminder,
    this.bedtimeReminder,
    this.timezone,
  });

  final String? name;
  final String? email;
  final String? narrationSpeed;
  final String? dreamPlace;
  final String? location;
  final String? energyWord;
  final String? someoneYouLove;
  final bool isMorningReminder;
  final bool isBedtimeReminder;
  final String? morningTimeReminder;
  final String? bedtimeReminder;
  final String? timezone;
}
