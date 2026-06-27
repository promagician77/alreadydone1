import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '/shared/theme/auth_theme.dart';
import '/services/supabase_service.dart';

class AIConsentService {
  AIConsentService._();

  /// Bump when in-app disclosure text changes materially (users may see prompt again).
  static const String _consentVersion = 'v2';
  static const String _consentKeyPrefix = 'ai_data_consent_';

  static String _storageKeyForCurrentUser() {
    final user = SupabaseService.currentUser;
    final userKey = user?.id.toLowerCase() ?? 'guest';
    return '$_consentKeyPrefix$_consentVersion\_$userKey';
  }

  static Future<bool> hasConsent() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_storageKeyForCurrentUser()) ?? false;
  }

  static Future<void> setConsent(bool agreed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_storageKeyForCurrentUser(), agreed);
  }

  static Future<void> resetConsentForTesting() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKeyForCurrentUser());
  }

  static Future<bool> ensureConsent(BuildContext context) async {
    if (await hasConsent()) return true;
    if (!context.mounted) return false;

    debugPrint('[AIConsent] prompt_shown');
    final agreed = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => const _AIConsentDialog(),
        ) ??
        false;

    if (agreed) {
      await setConsent(true);
      debugPrint('[AIConsent] user_agreed');
      return true;
    }

    debugPrint('[AIConsent] user_declined');
    return false;
  }
}

class _AIConsentDialog extends StatelessWidget {
  const _AIConsentDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AuthTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Data Sharing Permission',
        style: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AuthTheme.ink,
        ),
      ),
      content: Text(
        'To create your manifestations, we send your data to trusted third-party AI vendors (including ElevenLabs and Anthropic). '
        'This may include your profile inputs (such as name, location, and manifestation text) and voice recordings/audio when you use voice features. '
        'We only use this data to generate features inside the Already Done app. We never sell your data.\n\n'
        'We work with these vendors under agreements that require them to provide the same or equal protection of your personal data as we describe in our Privacy Policy.\n\n'
        'Tap "Agree" to proceed.',
        style: GoogleFonts.outfit(
          fontSize: 13,
          height: 1.5,
          color: AuthTheme.inkSoft,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            'Not now',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w600,
              color: AuthTheme.inkSoft,
            ),
          ),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AuthTheme.gold,
            foregroundColor: Colors.white,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(
            'Agree',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
