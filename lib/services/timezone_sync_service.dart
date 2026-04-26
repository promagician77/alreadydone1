import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '/services/backend_client.dart';
import '/services/supabase_service.dart';

class TimezoneSyncService {
  TimezoneSyncService._();

  static const String _keyPrefix = 'timezone_synced_v1_';

  static Future<String?> _getDeviceTimezone() async {
    try {
      final tz = await FlutterTimezone.getLocalTimezone();

      // v5+ returns TimezoneInfo; some platforms/versions may return String.
      if (tz is String) {
        final s = tz.trim();
        return s.isEmpty ? null : s;
      }

      final dynamic d = tz;
      final identifier = (d?.identifier as String?)?.trim();
      if (identifier != null && identifier.isNotEmpty) return identifier;

      // Final fallback: allow toString() if it looks usable.
      final asString = tz.toString().trim();
      return asString.isEmpty ? null : asString;
    } catch (_) {
      return null;
    }
  }

  static Future<void> syncIfNeeded() async {
    final userId = await SupabaseService.getCurrentUserTableId();
    if (userId == null) return;

    final timezone = await _getDeviceTimezone();
    if (timezone == null || timezone.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_keyPrefix$userId';
      final last = prefs.getString(key)?.trim();
      if (last == timezone) return;

      await BackendClient.updateUserProfile(userId, timezone: timezone);
      await prefs.setString(key, timezone);
      debugPrint('[TimezoneSync] synced userId=$userId tz=$timezone');
    } catch (_) {
      // Best-effort; do not block app start / login.
    }
  }

  static void syncInBackground() {
    // Fire-and-forget wrapper so callers don't need to await.
    Future<void>(() => syncIfNeeded());
  }
}

