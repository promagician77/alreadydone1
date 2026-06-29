import 'package:shared_preferences/shared_preferences.dart';

import '/shared/services/supabase_service.dart';

enum RatingPromptVariant { day7, day30, day90 }

/// Persistent state for the milestone rating prompts (per Supabase auth user).
class RatingPromptPrefs {
  RatingPromptPrefs._();

  static const _prefix = 'rating_prompt_v1_';
  static const _globalMinSpacing = Duration(hours: 48);

  static String _userSuffix() {
    final id = SupabaseService.currentUser?.id;
    return id?.toString().toLowerCase() ?? 'guest';
  }

  static String _kDeclined() => '${_prefix}declined_${_userSuffix()}';
  static String _kShownCountTotal() => '${_prefix}shown_count_total_${_userSuffix()}';
  static String _kLastShownAtMs() => '${_prefix}last_shown_at_ms_${_userSuffix()}';
  static String _kSnoozeUntilMs() => '${_prefix}snooze_until_ms_${_userSuffix()}';
  static String _kT1() => '${_prefix}t1_${_userSuffix()}';
  static String _kT2() => '${_prefix}t2_${_userSuffix()}';
  static String _kT3() => '${_prefix}t3_${_userSuffix()}';

  static Future<bool> loadDeclinedPermanent() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kDeclined()) ?? false;
  }

  static Future<void> setDeclinedPermanent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kDeclined(), true);
  }

  static Future<int> loadShownCountTotal() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kShownCountTotal()) ?? 0;
  }

  static Future<void> incrementShownCountTotal() async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_kShownCountTotal()) ?? 0;
    await prefs.setInt(_kShownCountTotal(), current + 1);
  }

  static Future<DateTime?> loadLastShownAt() async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(_kLastShownAtMs());
    if (ms == null || ms <= 0) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
  }

  static Future<void> setLastShownNow() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _kLastShownAtMs(),
      DateTime.now().toUtc().millisecondsSinceEpoch,
    );
  }

  static Future<DateTime?> loadSnoozeUntil() async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(_kSnoozeUntilMs());
    if (ms == null || ms <= 0) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
  }

  static Duration snoozeDurationForVariant(RatingPromptVariant v) {
    return switch (v) {
      RatingPromptVariant.day7 => const Duration(days: 3),
      RatingPromptVariant.day30 => const Duration(days: 7),
      RatingPromptVariant.day90 => const Duration(days: 14),
    };
  }

  static Future<void> snoozeFromNow(RatingPromptVariant v) async {
    final prefs = await SharedPreferences.getInstance();
    final until = DateTime.now()
        .toUtc()
        .add(snoozeDurationForVariant(v))
        .millisecondsSinceEpoch;
    await prefs.setInt(_kSnoozeUntilMs(), until);
  }

  static Future<void> clearSnooze() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kSnoozeUntilMs());
  }

  /// Safety net to prevent rapid re-prompts from edge cases.
  static Future<bool> isGloballyRateLimitedNow() async {
    final last = await loadLastShownAt();
    if (last == null) return false;
    final delta = DateTime.now().toUtc().difference(last);
    return delta < _globalMinSpacing;
  }

  static Future<({bool t1, bool t2, bool t3})> loadTierFlags() async {
    final prefs = await SharedPreferences.getInstance();
    return (
      t1: prefs.getBool(_kT1()) ?? false,
      t2: prefs.getBool(_kT2()) ?? false,
      t3: prefs.getBool(_kT3()) ?? false,
    );
  }

  /// When tier 2+ is completed, lower tiers must count as done (catch-up / no Day 7 after Day 30).
  static Future<void> _setTier1(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kT1(), v);
  }

  static Future<void> _setTier2(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kT2(), v);
    if (v) await _setTier1(true);
  }

  static Future<void> _setTier3(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kT3(), v);
    if (v) {
      await _setTier2(true);
      await _setTier1(true);
    }
  }

  /// Mark a tier as resolved (we only do this when the user actually taps "Rate").
  static Future<void> markVariantResolved(RatingPromptVariant v) async {
    switch (v) {
      case RatingPromptVariant.day7:
        await _setTier1(true);
        break;
      case RatingPromptVariant.day30:
        await _setTier2(true);
        break;
      case RatingPromptVariant.day90:
        await _setTier3(true);
        break;
    }
  }

  static Future<bool> allTiersResolved() async {
    final t = await loadTierFlags();
    return t.t1 && t.t2 && t.t3;
  }

  /// Picks which modal to show, if any, based on days-since-start and resolved tiers.
  static RatingPromptVariant? pickVariant(int daysSinceStart, bool t1, bool t2, bool t3) {
    if (daysSinceStart < 7) return null;
    if (daysSinceStart >= 90 && !t3) return RatingPromptVariant.day90;
    if (daysSinceStart >= 30 && !t2) return RatingPromptVariant.day30;
    if (daysSinceStart >= 7 && !t1) return RatingPromptVariant.day7;
    return null;
  }

  /// Debug-only helper for quickly exercising flows during development.
  static Future<void> resetForTesting() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kDeclined());
    await prefs.remove(_kShownCountTotal());
    await prefs.remove(_kLastShownAtMs());
    await prefs.remove(_kSnoozeUntilMs());
    await prefs.remove(_kT1());
    await prefs.remove(_kT2());
    await prefs.remove(_kT3());
  }
}
