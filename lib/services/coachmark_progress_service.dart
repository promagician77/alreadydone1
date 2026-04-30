import 'package:shared_preferences/shared_preferences.dart';

import '/services/supabase_service.dart';

/// Stores ordered, one-time coachmark progress per user.
///
/// Stages:
/// 0 = not started (no coachmarks shown)
/// 1 = settings coachmark shown in Player
/// 2 = library coachmark shown (Done tab)
/// 3 = new manifestation coachmark shown (Home)
class CoachmarkProgressService {
  CoachmarkProgressService._();

  static const String _keyPrefix = 'coachmark_progress_v1_';

  static String _key() {
    final userKey = SupabaseService.currentUser?.id.toLowerCase() ?? 'guest';
    return '$_keyPrefix$userKey';
  }

  static Future<int> getStage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_key()) ?? 0;
  }

  static Future<void> setStage(int stage) async {
    final next = stage.clamp(0, 3);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key(), next);
  }

  static Future<bool> advanceToAtLeast(int stage) async {
    final current = await getStage();
    if (current >= stage) return false;
    await setStage(stage);
    return true;
  }
}

