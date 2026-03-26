import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/pages/auth/auth_theme.dart';

class LegalPrivacyWidget extends StatelessWidget {
  const LegalPrivacyWidget({super.key});

  static const String routeName = 'LegalPrivacy';
  static const String routePath = '/legal/privacy';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuthTheme.warmWhite,
      appBar: AppBar(
        backgroundColor: AuthTheme.warmWhite,
        elevation: 0,
        foregroundColor: AuthTheme.gold,
        title: Text(
          'Privacy Policy',
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AuthTheme.ink,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Text(
            'Privacy Policy\n\n'
            'This is a placeholder privacy policy screen.\n\n'
            'Before submitting to the App Store / Play Store, replace this text with your real privacy policy '
            '(or load it from your website URL).\n\n'
            'At minimum, cover:\n'
            '- Account/login (Supabase)\n'
            '- Push notifications (FCM)\n'
            '- Subscriptions (RevenueCat)\n'
            '- Microphone/audio recording usage\n'
            '- Data retention and deletion\n',
            style: GoogleFonts.outfit(
              fontSize: 13,
              height: 1.6,
              color: AuthTheme.inkMid,
            ),
          ),
        ),
      ),
    );
  }
}

