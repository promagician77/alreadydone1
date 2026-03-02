import 'package:shared_preferences/shared_preferences.dart';
import '/services/supabase_service.dart';

class OnboardingService {
  static const _keyPrefix = 'onboarding_completed_';

  static String _storageKey() {
    final userId = SupabaseService.currentUser?.id;
    return '$_keyPrefix${userId?.toLowerCase() ?? 'guest'}';
  }

  /// Check if user has completed onboarding. Uses Supabase Users table as source
  /// of truth (persists across devices), with SharedPreferences as local cache.
  static Future<bool> hasCompletedOnboarding() async {
    final user = SupabaseService.currentUser;
    if (user == null) return false;

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
          if (completed == true) return true;
        }
      }
    } catch (_) {}

    // 2. Fallback to local SharedPreferences (e.g. before Users table has column)
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_storageKey()) ?? false;
  }

  static Future<void> setOnboardingCompleted() async {
    final user = SupabaseService.currentUser;
    if (user != null) {
      final email = user.email;
      if (email != null && email.isNotEmpty) {
        try {
          await SupabaseService.client
              .from('Users')
              .update({'onboarding_completed': true})
              .eq('email', email);
        } catch (_) {}
      }
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_storageKey(), true);
  }
}

