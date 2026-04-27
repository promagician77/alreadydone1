import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '/services/backend_client.dart';
import '/services/supabase_service.dart';

class TimezoneSyncService {
  TimezoneSyncService._();

  static const String _keyPrefix = 'timezone_synced_v1_';

  static String _offsetFallbackTimezone() {
    final offset = DateTime.now().timeZoneOffset;
    final sign = offset.isNegative ? '-' : '+';
    final hours = offset.inHours.abs().toString().padLeft(2, '0');
    final minutes = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
    return 'UTC$sign$hours:$minutes';
  }

  static Future<String?> getDeviceTimezone() async {
    try {
      final dynamic tz = await FlutterTimezone.getLocalTimezone();

      if (tz is String) {
        final s = tz.trim();
        if (s.isNotEmpty) {
          debugPrint('[TimezoneSync] device timezone string=$s');
          return s;
        }
      }

      final identifier = (tz?.identifier as String?)?.trim();
      if (identifier != null && identifier.isNotEmpty) {
        debugPrint('[TimezoneSync] device timezone identifier=$identifier');
        return identifier;
      }

      final fallback = _offsetFallbackTimezone();
      debugPrint('[TimezoneSync] missing plugin timezone; fallback=$fallback raw=$tz');
      return fallback;
    } catch (e) {
      final fallback = _offsetFallbackTimezone();
      debugPrint('[TimezoneSync] failed to read plugin timezone: $e; fallback=$fallback');
      return fallback;
    }
  }

  static Future<void> syncIfNeeded() async {
    final userId = await SupabaseService.getCurrentUserTableId();
    if (userId == null) {
      debugPrint('[TimezoneSync] skipped: no user');
      return;
    }

    final timezone = await getDeviceTimezone();
    if (timezone == null || timezone.isEmpty) {
      debugPrint('[TimezoneSync] skipped: empty timezone userId=$userId');
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_keyPrefix$userId';
      final last = prefs.getString(key)?.trim();
      if (last == timezone) {
        debugPrint('[TimezoneSync] already synced userId=$userId tz=$timezone');
        return;
      }

      await BackendClient.updateUserProfile(userId, timezone: timezone);
      await prefs.setString(key, timezone);
      debugPrint('[TimezoneSync] synced userId=$userId tz=$timezone');
    } catch (e) {
      debugPrint('[TimezoneSync] sync failed userId=$userId tz=$timezone error=$e');
      // Best-effort; do not block app start / login.
    }
  }

  static void syncInBackground() {
    // Fire-and-forget wrapper so callers don't need to await.
    Future<void>(() => syncIfNeeded());
  }
}

