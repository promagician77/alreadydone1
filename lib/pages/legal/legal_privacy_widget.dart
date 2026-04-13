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
            'Effective date: 2026-04-13\n\n'
            'Already Done collects and uses personal data to provide manifestation features in the app.\n\n'
            'Data we collect:\n'
            '- Account information (such as email and user id) for authentication and account access.\n'
            '- Profile and manifestation inputs you provide (such as name, location, desire text, and energy word).\n'
            '- Voice data you choose to record for voice clone and narration features.\n'
            '- Device/app data for notifications, subscriptions, and app reliability.\n\n'
            'How data is collected:\n'
            '- Directly from your in-app inputs and recordings.\n'
            '- From app integrations required to run account, billing, and notification features.\n\n'
            'How data is used:\n'
            '- To create and deliver your personalized manifestations and voice playback.\n'
            '- To manage subscriptions, restore purchases, and support account features.\n'
            '- To maintain app security, reliability, and customer support.\n\n'
            'Third-party AI data sharing:\n'
            'When you use AI-powered manifestation or voice features, we share the minimum required data with third-party AI vendors, including ElevenLabs and Anthropic, solely to provide those features inside Already Done. We do not sell your personal data.\n\n'
            'User permission:\n'
            'Before the app sends personal data to third-party AI services, the app requests your permission in-app. If you do not agree, AI-powered features will not run.\n\n'
            'Data protection:\n'
            'We require third-party processors we use to provide data protections that are the same as or stronger than the protections described in this policy.\n\n'
            'Retention and deletion:\n'
            'We retain data only as needed to provide services, meet legal requirements, and secure the app. You can request account closure and data deletion through app support/account tools where available.\n\n'
            'Contact:\n'
            'For privacy questions, contact support through the Already Done support channel listed in the app and App Store listing.\n',
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

