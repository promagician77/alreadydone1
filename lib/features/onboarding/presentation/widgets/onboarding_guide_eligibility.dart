import '/core/network/backend_client.dart';
import '/shared/services/supabase_service.dart';

/// Decides whether onboarding tutorial guide modals should appear.
///
/// Guides are for first-time signup users only: if the user already has at
/// least one generated story with a non-empty [voice_id], skip all guides.
class OnboardingGuideEligibility {
  OnboardingGuideEligibility._();

  static bool? _cachedShouldShow;

  /// Marks that guides should no longer show (e.g. after a voiced story exists).
  static void markHasVoicedStory() {
    _cachedShouldShow = false;
  }

  /// Clears the in-memory cache (e.g. after sign-out).
  static void clearCache() {
    _cachedShouldShow = null;
  }

  /// Returns true when guide modals should be shown (no voiced story yet).
  static Future<bool> shouldShowGuides() async {
    if (_cachedShouldShow != null) return _cachedShouldShow!;

    final userId = await SupabaseService.getCurrentUserTableId();
    if (userId == null) {
      _cachedShouldShow = true;
      return true;
    }

    try {
      final res = await BackendClient.getStories(userId);
      final list = (res['stories'] as List<dynamic>?) ?? const [];
      for (final item in list) {
        if (item is! Map) continue;
        final voiceId =
            (item['voice_id'] ?? item['voice_Id'])?.toString().trim();
        if (voiceId != null && voiceId.isNotEmpty) {
          _cachedShouldShow = false;
          return false;
        }
      }
      _cachedShouldShow = true;
      return true;
    } catch (_) {
      // Fail open for first-time users if the check fails mid-onboarding.
      _cachedShouldShow = true;
      return true;
    }
  }
}
