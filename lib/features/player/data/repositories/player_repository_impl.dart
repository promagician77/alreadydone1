import '../../domain/repositories/player_repository.dart';
import '../datasources/player_local_data_source.dart';
import '../datasources/player_remote_data_source.dart';

/// Default [PlayerRepository] combining the remote (BackendClient) and local
/// (LastPlayedService) data sources. Pass-through during migration.
class PlayerRepositoryImpl implements PlayerRepository {
  const PlayerRepositoryImpl(this._remote, this._local);

  final PlayerRemoteDataSource _remote;
  final PlayerLocalDataSource _local;

  @override
  Future<Map<String, dynamic>> getStories(int userId) =>
      _remote.getStories(userId);

  @override
  Future<Map<String, dynamic>> getStoryPlayUrl(int storyId) =>
      _remote.getStoryPlayUrl(storyId);

  @override
  Future<Map<String, dynamic>> voiceGenerateAudio({
    required String voiceId,
    required int storyId,
    String modelId = 'eleven_multilingual_v2',
    String narrationSpeed = 'normal',
  }) =>
      _remote.voiceGenerateAudio(
        voiceId: voiceId,
        storyId: storyId,
        modelId: modelId,
        narrationSpeed: narrationSpeed,
      );

  @override
  Future<Map<String, dynamic>> deepenStory({
    required int userId,
    required int storyId,
    String name = '',
    String location = '',
    String energyWord = '',
    String lovedOne = '',
    String dreamLocation = '',
  }) =>
      _remote.deepenStory(
        userId: userId,
        storyId: storyId,
        name: name,
        location: location,
        energyWord: energyWord,
        lovedOne: lovedOne,
        dreamLocation: dreamLocation,
      );

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
      _local.saveLastPlayed(
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
  Future<Map<String, dynamic>?> loadLastPlayed() => _local.loadLastPlayed();

  @override
  Future<void> clearLastPlayed() => _local.clearLastPlayed();
}
