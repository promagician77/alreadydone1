/// Contract for the desires feature's own backend operations: listing the
/// user's desires and deleting stories from their library.
///
/// Wraps the relevant slice of the shared `BackendClient`. Playback reads
/// (getStories/getStoryPlayUrl/voiceGenerateAudio) are NOT here — consistent
/// with `home`, those stay on `BackendClient` until a dedicated `story`
/// feature is extracted. `getUserProfile` is reused from `profileRepository`.
abstract class DesiresRepository {
  Future<List<Map<String, dynamic>>> getDesires();

  Future<void> deleteStory(int storyId);
}
