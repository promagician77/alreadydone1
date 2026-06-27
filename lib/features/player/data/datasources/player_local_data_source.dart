import '/services/last_played_service.dart';

/// Local data source for "last played" persistence — thin wrapper over the
/// shared [LastPlayedService] (SharedPreferences-backed).
abstract class PlayerLocalDataSource {
  Future<void> saveLastPlayed({
    required int? storyId,
    required String? playUrl,
    String? title,
    String? categoryLabel,
    String? durationLabel,
    String? storyPreview,
    String? storyContent,
    String? voiceId,
  });
  Future<Map<String, dynamic>?> loadLastPlayed();
  Future<void> clearLastPlayed();
}

class PlayerLocalDataSourceImpl implements PlayerLocalDataSource {
  const PlayerLocalDataSourceImpl();

  @override
  Future<void> saveLastPlayed({
    required int? storyId,
    required String? playUrl,
    String? title,
    String? categoryLabel,
    String? durationLabel,
    String? storyPreview,
    String? storyContent,
    String? voiceId,
  }) =>
      LastPlayedService.saveLastPlayed(
        storyId: storyId,
        playUrl: playUrl,
        title: title,
        categoryLabel: categoryLabel,
        durationLabel: durationLabel,
        storyPreview: storyPreview,
        storyContent: storyContent,
        voiceId: voiceId,
      );

  @override
  Future<Map<String, dynamic>?> loadLastPlayed() =>
      LastPlayedService.loadLastPlayed();

  @override
  Future<void> clearLastPlayed() => LastPlayedService.clearLastPlayed();
}
