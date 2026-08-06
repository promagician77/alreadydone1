import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '/core/network/backend_client.dart';
import '/features/onboarding/presentation/widgets/onboarding_guide_eligibility.dart';
import '/features/player/data/datasources/last_played_service.dart';
import '/shared/services/supabase_service.dart';

class OnboardingService {
  static const _keyPrefix = 'onboarding_completed_';
  static const _stepPrefix = 'onboarding_step_';
  static const _dataPrefix = 'onboarding_data_';
  static const _firstStoryPrefix = 'first_story_generated_';
  static const _listenedPrefix = 'first_story_listened_';

  /// In-memory cache so redirect checks don't hit the network repeatedly.
  static bool? _completedCache;
  static String? _completedCacheUserId;
  static bool? _createdAndListenedCache;
  static String? _createdAndListenedCacheUserId;

  static String _storageKey() {
    final userId = SupabaseService.currentUser?.id;
    return '$_keyPrefix${userId?.toLowerCase() ?? 'guest'}';
  }

  static String _stepKey() {
    final userId = SupabaseService.currentUser?.id;
    return '$_stepPrefix${userId?.toLowerCase() ?? 'guest'}';
  }

  static String _dataKey() {
    final userId = SupabaseService.currentUser?.id;
    return '$_dataPrefix${userId?.toLowerCase() ?? 'guest'}';
  }

  static String _firstStoryKey() {
    final userId = SupabaseService.currentUser?.id;
    return '$_firstStoryPrefix${userId?.toLowerCase() ?? 'guest'}';
  }

  static String _listenedKey() {
    final userId = SupabaseService.currentUser?.id;
    return '$_listenedPrefix${userId?.toLowerCase() ?? 'guest'}';
  }

  static void _clearCompletedCache() {
    _completedCache = null;
    _completedCacheUserId = null;
    _createdAndListenedCache = null;
    _createdAndListenedCacheUserId = null;
  }

  static void _setCompletedCache(bool value) {
    _completedCache = value;
    _completedCacheUserId = SupabaseService.currentUser?.id;
  }

  /// Mark that the user has generated their first story (used for relaunch routing).
  static Future<void> setFirstStoryGenerated() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_firstStoryKey(), true);
    // User finished first story playback path — stop showing tutorial guides.
    OnboardingGuideEligibility.markHasVoicedStory();
  }

  /// Mark that the user has listened to (started/played) their first story.
  static Future<void> setFirstStoryListened() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_listenedKey(), true);
    final userId = SupabaseService.currentUser?.id;
    _createdAndListenedCache = null;
    _createdAndListenedCacheUserId = null;
    // Invalidate completed cache so next check can promote to completed.
    if (_completedCacheUserId == userId) {
      _completedCache = null;
      _completedCacheUserId = null;
    }
  }

  /// Returns true if the user has already generated their first story.
  static Future<bool> hasGeneratedFirstStory() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_firstStoryKey()) ?? false) return true;

    // Fresh install wipes prefs; derive from server stories for returning users.
    if (await _hasExistingStories()) {
      await setFirstStoryGenerated();
      return true;
    }
    return false;
  }

  /// Chris's warm-lead gate: user has both created and listened to a first story.
  ///
  /// Never-subscribed users who fail this check should enter the new onboarding
  /// flow and get a free first story.
  static Future<bool> hasCreatedAndListenedToFirstStory() async {
    final user = SupabaseService.currentUser;
    if (user == null) return false;

    if (_createdAndListenedCache != null &&
        _createdAndListenedCacheUserId == user.id) {
      return _createdAndListenedCache!;
    }

    final prefs = await SharedPreferences.getInstance();
    final localGenerated = prefs.getBool(_firstStoryKey()) ?? false;
    final localListened = prefs.getBool(_listenedKey()) ?? false;
    if (localGenerated && localListened) {
      _createdAndListenedCache = true;
      _createdAndListenedCacheUserId = user.id;
      return true;
    }

    final stories = await _fetchStories();
    final hasCreated = stories.isNotEmpty || localGenerated;
    if (!hasCreated) {
      _createdAndListenedCache = false;
      _createdAndListenedCacheUserId = user.id;
      return false;
    }

    if (localListened) {
      await setFirstStoryGenerated();
      _createdAndListenedCache = true;
      _createdAndListenedCacheUserId = user.id;
      return true;
    }

    for (final item in stories) {
      if (item is! Map) continue;
      final lastPlayed = item['last_played'] ?? item['last_played_at'];
      final raw = lastPlayed?.toString().trim();
      if (raw != null && raw.isNotEmpty) {
        await setFirstStoryGenerated();
        await setFirstStoryListened();
        _createdAndListenedCache = true;
        _createdAndListenedCacheUserId = user.id;
        return true;
      }
    }

    // Same-device returning users who played via the main player.
    final localLastPlayed = await LastPlayedService.loadLastPlayed();
    if (localLastPlayed != null) {
      await setFirstStoryGenerated();
      await setFirstStoryListened();
      _createdAndListenedCache = true;
      _createdAndListenedCacheUserId = user.id;
      return true;
    }

    if (stories.isNotEmpty) {
      await setFirstStoryGenerated();
    }
    _createdAndListenedCache = false;
    _createdAndListenedCacheUserId = user.id;
    return false;
  }

  /// Check if user has completed onboarding.
  ///
  /// Completion requires creating and listening to a first story (warm-lead
  /// criterion). A completed flag alone with existing stories but no listen
  /// does not count — those users re-enter the new onboarding for a free story.
  /// A completed flag with no stories still counts (e.g. subscribed on paywall).
  static Future<bool> hasCompletedOnboarding() async {
    final user = SupabaseService.currentUser;
    if (user == null) return false;

    if (_completedCache != null && _completedCacheUserId == user.id) {
      return _completedCache!;
    }

    // 1. Created + listened (source of truth for warm-lead / free-story routing)
    if (await hasCreatedAndListenedToFirstStory()) {
      await setOnboardingCompleted();
      return true;
    }

    final hasStories = await _hasExistingStories();

    // 2. Flag set without stories (e.g. subscribed during onboarding paywall)
    try {
      final email = user.email;
      if (email != null && email.isNotEmpty) {
        final result = await SupabaseService.client
            .from('Users')
            .select('onboarding_completed')
            .eq('email', email) as dynamic;
        final rows = result is List ? List<dynamic>.from(result) : <dynamic>[];
        if (rows.isNotEmpty) {
          final first = rows.first;
          final completed = first is Map ? first['onboarding_completed'] : null;
          if (completed == true && !hasStories) {
            _setCompletedCache(true);
            return true;
          }
        }
      }
    } catch (_) {}

    // 3. Local flag without stories
    final prefs = await SharedPreferences.getInstance();
    if ((prefs.getBool(_storageKey()) ?? false) && !hasStories) {
      _setCompletedCache(true);
      return true;
    }

    _setCompletedCache(false);
    return false;
  }

  /// True when the current user already has at least one story on the server.
  static Future<bool> _hasExistingStories() async {
    final stories = await _fetchStories();
    return stories.isNotEmpty;
  }

  static Future<List<dynamic>> _fetchStories() async {
    try {
      final userId = await SupabaseService.getCurrentUserTableId();
      if (userId == null) return const [];
      final res = await BackendClient.getStories(userId);
      return (res['stories'] as List<dynamic>?) ?? const [];
    } catch (_) {
      return const [];
    }
  }

  static Future<void> setOnboardingCompleted() async {
    final user = SupabaseService.currentUser;
    if (user != null) {
      final email = user.email;
      if (email != null && email.isNotEmpty) {
        try {
          await SupabaseService.client
              .from('Users')
              .update({'onboarding_completed': true}).eq('email', email);
        } catch (_) {}
      }
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_storageKey(), true);
    // Clear in-progress step/data on completion
    await prefs.remove(_stepKey());
    await prefs.remove(_dataKey());
    _setCompletedCache(true);
  }

  /// Save the current onboarding step route path and form data.
  /// Call this on each "Continue" tap so the user can resume after an app kill.
  static Future<void> saveProgress({
    required String stepPath,
    required Map<String, dynamic> data,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_stepKey(), stepPath);
    await prefs.setString(_dataKey(), jsonEncode(data));
  }

  /// Returns the saved step path (e.g. '/onboarding/desire'), or null if none saved.
  static Future<String?> getSavedStep() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_stepKey());
  }

  /// Returns the saved form data map, or empty map if none saved.
  static Future<Map<String, dynamic>> loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_dataKey());
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : {};
    } catch (_) {
      return {};
    }
  }

  /// Clear saved progress without marking onboarding complete (e.g. on sign-out).
  static Future<void> clearProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_stepKey());
    await prefs.remove(_dataKey());
    _clearCompletedCache();
    OnboardingGuideEligibility.clearCache();
  }
}
