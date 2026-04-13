import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '/pages/auth/auth_theme.dart';
import '/services/app_toast.dart';

class LegalTermsWidget extends StatelessWidget {
  const LegalTermsWidget({super.key});

  static const String routeName = 'LegalTerms';
  static const String routePath = '/legal/terms';

  static final Uri _appleStandardEula = Uri.parse(
    'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/',
  );

  Future<void> _openAppleEula(BuildContext context) async {
    final ok = await launchUrl(
      _appleStandardEula,
      mode: LaunchMode.externalApplication,
    );
    if (!ok && context.mounted) {
      AppToast.info(context, 'Could not open Terms of Use link.');
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
          'Terms of Use',
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
                'Terms of Use (EULA)\n',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AuthTheme.ink,
                ),
              ),
              Text(
                'This app uses the Apple Standard EULA for iOS subscriptions.\n',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  height: 1.6,
                  color: AuthTheme.inkMid,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _openAppleEula(context),
                child: Text(
                  _appleStandardEula.toString(),
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: AuthTheme.goldDark,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Before submitting, ensure your App Store Connect metadata also includes a functional link to the Terms of Use (EULA).\n',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  height: 1.6,
                  color: AuthTheme.inkSoft,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

