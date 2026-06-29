import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '/shared/services/supabase_service.dart';

/// Shown with [newManifestationCoachmarkVisible] while the home "new manifestation" tip is up.
final GlobalKey newManifestationCoachmarkHomeTabKey = GlobalKey();

final ValueNotifier<bool> newManifestationCoachmarkVisible = ValueNotifier(false);

/// [HomeDashboardWidget] registers: dismiss prefs when user taps Home during the coachmark.
Future<void> Function()? newManifestationCoachmarkOnHomeTabDuringCoachmark;

class NewManifestationCoachmarkPrefs {
  static const _seenPrefix = 'home_new_manifestation_coachmark_v1_';
  static const _pendingPrefix = 'pending_home_new_manifestation_coachmark_v1_';

  /// Never use `'guest'` — that breaks one-shot tutorials when the session appears late.
  static String? _userKeyOrNull() {
    final id = SupabaseService.currentUser?.id;
    if (id == null || id.isEmpty) return null;
    return id.toLowerCase();
  }

  static Future<void> setPendingAfterOnboardingComplete() async {
    final key = _userKeyOrNull();
    if (key == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_pendingPrefix$key', true);
  }

  static Future<bool> takePendingShowCoachmark() async {
    final key = _userKeyOrNull();
    if (key == null) return false;
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('$_seenPrefix$key') ?? false;
    if (seen) {
      await prefs.setBool('$_pendingPrefix$key', false);
      return false;
    }
    final pending = prefs.getBool('$_pendingPrefix$key') ?? false;
    if (!pending) return false;
    await prefs.setBool('$_pendingPrefix$key', false);
    return true;
  }

  static Future<void> markSeen() async {
    final key = _userKeyOrNull();
    if (key == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_seenPrefix$key', true);
  }
}
