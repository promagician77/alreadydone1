import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '/constants/legal_urls.dart';
import '/shared/theme/auth_theme.dart';
import '/shared/services/app_toast.dart';

class LegalPrivacyWidget extends StatelessWidget {
  const LegalPrivacyWidget({super.key});

  static const String routeName = 'LegalPrivacy';
  static const String routePath = '/legal/privacy';

  Future<void> _openPrivacyPolicy(BuildContext context) async {
    final ok = await launchUrl(
      kPrivacyPolicyUri,
      mode: LaunchMode.externalApplication,
    );
    if (!ok && context.mounted) {
      AppToast.info(context, 'Could not open Privacy Policy link.');
    }
  }

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Privacy Policy',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AuthTheme.ink,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Read our full Privacy Policy on our website.',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  height: 1.6,
                  color: AuthTheme.inkMid,
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () => _openPrivacyPolicy(context),
                child: Text(
                  kPrivacyPolicyUri.toString(),
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: AuthTheme.goldDark,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
