import '/features/player/presentation/pages/player/player_story_utils.dart';
import '/core/di/player_locator.dart';
import '/core/di/profile_locator.dart';
import '/services/supabase_service.dart';

/// Loads story metadata and play URLs for the player screen.
abstract final class PlayerStoryLoader {
  static Future<String?> getUserVoiceId() async {
    final userId = await SupabaseService.getCurrentUserTableId();
    if (userId == null) return null;
    try {
      final profile = await profileRepository.getUserProfile(userId);
      final id = profile['voice_id']?.toString().trim() ??
          profile['voice_Id']?.toString().trim();
      return id?.isNotEmpty == true ? id : null;
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> loadLastCreatedStory() async {
    final userId = await SupabaseService.getCurrentUserTableId();
    if (userId == null) return null;
    try {
      final profile = await profileRepository.getUserProfile(userId);
      final voiceId = profile['voice_id']?.toString().trim() ??
          profile['voice_Id']?.toString().trim();
      if (voiceId == null || voiceId.isEmpty) return null;

      final res = await playerRepository.getStories(userId);
      final list = (res['stories'] as List<dynamic>?)
              ?.map((e) =>
                  e is Map<String, dynamic> ? e : <String, dynamic>{})
              .toList() ??
          [];
      if (list.isEmpty) return null;

      list.sort((a, b) {
        final aAt = a['created_at'] ?? a['id'] ?? 0;
        final bAt = b['created_at'] ?? b['id'] ?? 0;
        if (aAt == bAt) return 0;
        return bAt.toString().compareTo(aAt.toString());
      });
      final story = list.first;
      final storyId = story['id'] is int
          ? story['id'] as int
          : int.tryParse(story['id']?.toString() ?? '');
      if (storyId == null) return null;

      String? playUrl;
      try {
        final urlRes = await playerRepository.getStoryPlayUrl(storyId);
        playUrl = urlRes['playUrl']?.toString().trim();
      } catch (_) {
        final genRes = await playerRepository.voiceGenerateAudio(
          voiceId: voiceId,
          storyId: storyId,
        );
        playUrl = genRes['url']?.toString().trim();
      }
      if (playUrl == null || playUrl.isEmpty) return null;

      final content =
          (story['story'] ?? story['content'])?.toString().trim();
      final preview = content != null && content.isNotEmpty ? content : null;
      final storyVoiceId =
          (story['voice_id'] ?? story['voice_Id'])?.toString().trim();

      return {
        'playUrl': playUrl,
        'storyId': storyId,
        'title': (story['theme'] ??
                story['title'] ??
                story['desire_name'] ??
                'Story')
            .toString(),
        'categoryLabel':
            (story['desire_name'] ?? story['category'] ?? 'Love').toString(),
        'durationLabel': PlayerStoryUtils.durationLabelFromStory(story),
        'storyPreview': preview,
        'storyContent': content,
        if (storyVoiceId != null && storyVoiceId.isNotEmpty)
          'voiceId': storyVoiceId,
      };
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> loadFirstAvailableFromList(
    List<dynamic> list,
  ) async {
    final mapped = list
        .map((e) => e is Map<String, dynamic> ? e : <String, dynamic>{})
        .toList();
    if (mapped.isEmpty) return null;
    mapped.sort((a, b) {
      final aAt = a['created_at'] ?? a['id'] ?? 0;
      final bAt = b['created_at'] ?? b['id'] ?? 0;
      if (aAt == bAt) return 0;
      return bAt.toString().compareTo(aAt.toString());
    });
    for (final story in mapped) {
      final storyId = story['id'] is int
          ? story['id'] as int
          : int.tryParse(story['id']?.toString() ?? '');
      if (storyId == null) continue;
      try {
        final res = await playerRepository.getStoryPlayUrl(storyId);
        final playUrl = res['playUrl']?.toString().trim();
        if (playUrl == null || playUrl.isEmpty) continue;
        final content =
            (story['story'] ?? story['content'])?.toString().trim();
        final preview = content != null && content.isNotEmpty ? content : null;
        final storyVoiceId =
            (story['voice_id'] ?? story['voice_Id'])?.toString().trim();
        return {
          'playUrl': playUrl,
          'storyId': storyId,
          'title': (story['theme'] ??
                  story['title'] ??
                  story['desire_name'] ??
                  'Story')
              .toString(),
          'categoryLabel':
              (story['desire_name'] ?? story['category'] ?? 'Love').toString(),
          'durationLabel': PlayerStoryUtils.durationLabelFromStory(story),
          'storyPreview': preview,
          'storyContent': content,
          if (storyVoiceId != null && storyVoiceId.isNotEmpty)
            'voiceId': storyVoiceId,
        };
      } catch (_) {
        continue;
      }
    }
    return null;
  }
}
