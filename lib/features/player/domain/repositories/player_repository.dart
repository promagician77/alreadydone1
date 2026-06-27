/// Contract for the player feature's playback + story-library operations.
///
/// Wraps the story slice of the shared `BackendClient` (remote) and
/// `LastPlayedService` (local persistence). Returns raw backend maps during the
/// migration; typed `Story` entity modeling is deferred until a dedicated
/// `story` feature is extracted (player, home and onboarding all read stories).
///
/// NOT here: `getUserProfile` (player reuses `profileRepository`) and
/// cross-cutting identity helpers like `getCurrentUserTableId` (stay on
/// `SupabaseService`).
abstract class PlayerRepository {
  Future<Map<String, dynamic>> getStories(int userId);

  Future<Map<String, dynamic>> getStoryPlayUrl(int storyId);

  Future<Map<String, dynamic>> voiceGenerateAudio({
    required String voiceId,
    required int storyId,
    String modelId = 'eleven_multilingual_v2',
    String narrationSpeed = 'normal',
  });

  Future<Map<String, dynamic>> deepenStory({
    required int userId,
    required int storyId,
    String name = '',
    String location = '',
    String energyWord = '',
    String lovedOne = '',
    String dreamLocation = '',
  });

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
