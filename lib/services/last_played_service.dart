import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import '/services/supabase_service.dart';

/// Persists and retrieves the last played story so the Player can resume it
/// when opened from the navbar (no route params).
class LastPlayedService {
  static const _keyPrefix = 'last_played_';

  static String _storageKey() {
    final userId = SupabaseService.currentUser?.id;
    return '$_keyPrefix${userId?.toString() ?? 'guest'}';
  }

  /// Save the currently playing story so it can be restored when opening Player from navbar.
  /// [storyContent] is the full story text, used when re-recording voice from profile.
  static Future<void> saveLastPlayed({
    required int? storyId,
    required String? playUrl,
    String? title,
    String? categoryLabel,
    String? durationLabel,
    String? storyPreview,
    String? storyContent,
  }) async {
    if (playUrl == null || playUrl.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _storageKey();
      final data = <String, dynamic>{
        'playUrl': playUrl,
        if (storyId != null) 'storyId': storyId,
        if (title != null) 'title': title,
        if (categoryLabel != null) 'categoryLabel': categoryLabel,
        if (durationLabel != null) 'durationLabel': durationLabel,
        if (storyPreview != null) 'storyPreview': storyPreview,
        if (storyContent != null && storyContent.isNotEmpty) 'storyContent': storyContent,
      };
      await prefs.setString(key, jsonEncode(data));
    } catch (_) {}
  }

  /// Load the last played story for the current user, or null if none.
  static Future<Map<String, dynamic>?> loadLastPlayed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _storageKey();
      final raw = prefs.getString(key);
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final map = Map<String, dynamic>.from(decoded);
      if (map['playUrl'] == null || map['playUrl'].toString().isEmpty) return null;
      return map;
    } catch (_) {
      return null;
    }
  }
}
