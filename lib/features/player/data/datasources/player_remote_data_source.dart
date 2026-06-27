import '/services/backend_client.dart';

/// Remote data source for playback/story operations — thin wrapper over the
/// story slice of the shared [BackendClient].
abstract class PlayerRemoteDataSource {
  Future<Map<String, dynamic>> getStories(int userId);
  Future<Map<String, dynamic>> getStoryPlayUrl(int storyId);
  Future<Map<String, dynamic>> voiceGenerateAudio({
    required String voiceId,
    required int storyId,
    String modelId,
    String narrationSpeed,
  });
  Future<Map<String, dynamic>> deepenStory({
    required int userId,
    required int storyId,
    String name,
    String location,
    String energyWord,
    String lovedOne,
    String dreamLocation,
  });
}

class PlayerRemoteDataSourceImpl implements PlayerRemoteDataSource {
  const PlayerRemoteDataSourceImpl();

  @override
  Future<Map<String, dynamic>> getStories(int userId) =>
      BackendClient.getStories(userId);

  @override
  Future<Map<String, dynamic>> getStoryPlayUrl(int storyId) =>
      BackendClient.getStoryPlayUrl(storyId);

  @override
  Future<Map<String, dynamic>> voiceGenerateAudio({
    required String voiceId,
    required int storyId,
    String modelId = 'eleven_multilingual_v2',
    String narrationSpeed = 'normal',
  }) =>
      BackendClient.voiceGenerateAudio(
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
      BackendClient.deepenStory(
        userId: userId,
        storyId: storyId,
        name: name,
        location: location,
        energyWord: energyWord,
        lovedOne: lovedOne,
        dreamLocation: dreamLocation,
      );
}
