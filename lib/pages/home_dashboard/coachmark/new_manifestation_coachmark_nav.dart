import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '/services/supabase_service.dart';

/// Shown with [newManifestationCoachmarkVisible] while the home "new manifestation" tip is up.
final GlobalKey newManifestationCoachmarkHomeTabKey = GlobalKey();

final ValueNotifier<bool> newManifestationCoachmarkVisible = ValueNotifier(false);

/// [HomeDashboardWidget] registers: dismiss prefs when user taps Home during the coachmark.
Future<void> Function()? newManifestationCoachmarkOnHomeTabDuringCoachmark;

class NewManifestationCoachmarkPrefs {
  static const _seenPrefix = 'home_new_manifestation_coachmark_v1_';
  static const _pendingPrefix = 'pending_home_new_manifestation_coachmark_v1_';

  static String _userKey() =>
      SupabaseService.currentUser?.id.toLowerCase() ?? 'guest';

  static Future<void> setPendingAfterOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_pendingPrefix${_userKey()}', true);
  }

  static Future<bool> takePendingShowCoachmark() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('$_seenPrefix${_userKey()}') ?? false;
    if (seen) {
      await prefs.setBool('$_pendingPrefix${_userKey()}', false);
      return false;
    }
    final pending = prefs.getBool('$_pendingPrefix${_userKey()}') ?? false;
    if (!pending) return false;
    await prefs.setBool('$_pendingPrefix${_userKey()}', false);
    return true;
  }

  static Future<void> markSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_seenPrefix${_userKey()}', true);
  }
}
