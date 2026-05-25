/// Story duration, filtering, and URL helpers for the home dashboard.
abstract final class HomeDashboardStoryUtils {
  static String cacheBustUrlIfSafe(String url) {
    final u = url.trim();
    if (u.isEmpty) return u;
    final lower = u.toLowerCase();
    if (lower.contains('x-amz-signature') ||
        lower.contains('x-amz-credential') ||
        lower.contains('x-amz-algorithm') ||
        lower.contains('x-amz-date') ||
        lower.contains('x-amz-security-token') ||
        lower.contains('signature=') ||
        lower.contains('token=')) {
      return u;
    }
    final uri = Uri.tryParse(u);
    if (uri == null) return u;
    final qp = <String, String>{...uri.queryParameters};
    qp['_cb'] = DateTime.now().millisecondsSinceEpoch.toString();
    return uri.replace(queryParameters: qp).toString();
  }

  static int? parseDurationSeconds(dynamic raw) {
    if (raw == null) return null;
    if (raw is int) return raw;
    if (raw is num) return raw.round();
    final text = raw.toString().trim();
    if (text.isEmpty) return null;
    final clock = RegExp(r'^(\d+):(\d{2})$').firstMatch(text);
    if (clock != null) {
      final minutes = int.tryParse(clock.group(1)!);
      final seconds = int.tryParse(clock.group(2)!);
      if (minutes != null && seconds != null) {
        return minutes * 60 + seconds;
      }
    }
    return num.tryParse(text)?.round();
  }

  static int? storyDurationSeconds(Map<String, dynamic>? story) {
    if (story == null) return null;
    return parseDurationSeconds(
      story['play_length'] ?? story['playLength'] ?? story['duration'],
    );
  }

  static int? storyDurationSecondsById(
    int? storyId,
    List<Map<String, dynamic>> stories,
  ) {
    if (storyId == null) return null;
    final story = stories.where((s) {
      final id = s['id'] is int
          ? s['id'] as int
          : int.tryParse(s['id']?.toString() ?? '');
      return id == storyId;
    }).cast<Map<String, dynamic>?>().firstWhere(
          (_) => true,
          orElse: () => null,
        );
    return storyDurationSeconds(story);
  }

  static int? storyIdFromMap(Map<String, dynamic> story) {
    return story['id'] is int
        ? story['id'] as int
        : int.tryParse(story['id']?.toString() ?? '');
  }

  static String durationFromStory(
    Map<String, dynamic> story,
    Map<int, int> durationCache,
  ) {
    final storyId = storyIdFromMap(story);
    final cached = storyId != null ? durationCache[storyId] : null;
    final storySeconds = storyDurationSeconds(story);
    final d = cached != null && storySeconds != null
        ? (cached > storySeconds ? cached : storySeconds)
        : (cached ?? storySeconds);
    if (d == null) return '--:--';
    final secs = d;
    final m = secs ~/ 60;
    final s = secs % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  static List<Map<String, dynamic>> filteredStories({
    required List<Map<String, dynamic>> stories,
    required String? selectedDesireFilter,
  }) {
    final selected = selectedDesireFilter;
    if (selected == null || selected.isEmpty) return stories;
    return stories
        .where(
          (s) =>
              (s['desire_name'] ?? s['category'] ?? '').toString() == selected,
        )
        .toList();
  }

  static int countByDesire({
    required List<Map<String, dynamic>> stories,
    required String? desireName,
  }) {
    if (desireName == null || desireName.isEmpty) return stories.length;
    return stories
        .where(
          (s) =>
              (s['desire_name'] ?? s['category'] ?? '').toString() ==
              desireName,
        )
        .length;
  }

  static String greetingForHour(int hour) {
    if (hour < 12) return 'GOOD MORNING';
    if (hour < 17) return 'GOOD AFTERNOON';
    return 'GOOD EVENING';
  }
}
