import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '/constants/legal_urls.dart';
import '/shared/theme/auth_theme.dart';
import '/shared/services/app_toast.dart';

class LegalTermsWidget extends StatelessWidget {
  const LegalTermsWidget({super.key});

  static const String routeName = 'LegalTerms';
  static const String routePath = '/legal/terms';

  static final Uri _appleStandardEula = Uri.parse(
    'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/',
  );

  Future<void> _openUri(BuildContext context, Uri uri) async {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      AppToast.info(context, 'Could not open link.');
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
          'Terms of Service',
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
                'Terms of Service',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AuthTheme.ink,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Read our full Terms of Service on our website.',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  height: 1.6,
                  color: AuthTheme.inkMid,
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () => _openUri(context, kTermsOfServiceUri),
                child: Text(
                  kTermsOfServiceUri.toString(),
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: AuthTheme.goldDark,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Apple subscriptions',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AuthTheme.ink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'If you subscribed on iOS, Apple’s standard terms may also apply.',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  height: 1.6,
                  color: AuthTheme.inkMid,
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () => _openUri(context, _appleStandardEula),
                child: Text(
                  _appleStandardEula.toString(),
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
