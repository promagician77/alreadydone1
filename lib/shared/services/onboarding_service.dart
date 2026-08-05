import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '/core/network/backend_client.dart';
import '/features/onboarding/presentation/widgets/onboarding_guide_eligibility.dart';
import '/shared/services/supabase_service.dart';

class OnboardingService {
  static const _keyPrefix = 'onboarding_completed_';
  static const _stepPrefix = 'onboarding_step_';
  static const _dataPrefix = 'onboarding_data_';
  static const _firstStoryPrefix = 'first_story_generated_';

  /// In-memory cache so redirect checks don't hit the network repeatedly.
  static bool? _completedCache;
  static String? _completedCacheUserId;

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

  static void _clearCompletedCache() {
    _completedCache = null;
    _completedCacheUserId = null;
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

  /// Check if user has completed onboarding. Uses Supabase Users table as source
  /// of truth (persists across devices), with SharedPreferences as local cache.
  /// Returning users who already have stories are treated as completed even if
  /// the flag was never set / local prefs were wiped on reinstall.
  static Future<bool> hasCompletedOnboarding() async {
    final user = SupabaseService.currentUser;
    if (user == null) return false;

    if (_completedCache != null && _completedCacheUserId == user.id) {
      return _completedCache!;
    }

    // 1. Check Supabase Users table (source of truth across devices/sessions)
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
          if (completed == true) {
            _setCompletedCache(true);
            return true;
          }
        }
      }
    } catch (_) {}

    // 2. Fallback to local SharedPreferences (e.g. before Users table has column)
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_storageKey()) ?? false) {
      _setCompletedCache(true);
      return true;
    }

    // 3. Returning users: any existing story means onboarding is done.
    // Backfill flag so later launches (and other devices after sync) skip onboarding.
    if (await _hasExistingStories()) {
      await setOnboardingCompleted();
      await setFirstStoryGenerated();
      return true;
    }

    _setCompletedCache(false);
    return false;
  }

  /// True when the current user already has at least one story on the server.
  static Future<bool> _hasExistingStories() async {
    try {
      final userId = await SupabaseService.getCurrentUserTableId();
      if (userId == null) return false;
      final res = await BackendClient.getStories(userId);
      final list = (res['stories'] as List<dynamic>?) ?? const [];
      return list.isNotEmpty;
    } catch (_) {
      return false;
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
