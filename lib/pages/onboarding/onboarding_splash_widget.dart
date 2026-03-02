import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/auth/auth_theme.dart';
import '/widgets/animated_waveform_icon.dart';
import 'onboarding_personalize_widget.dart';

class OnboardingSplashWidget extends StatelessWidget {
  const OnboardingSplashWidget({super.key});

  static String routeName = 'OnboardingSplash';
  static String routePath = '/onboarding';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuthTheme.warmWhite,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const AnimatedWaveformIcon(size: AnimatedWaveformSize.splash, wrapped: false),
                      const SizedBox(height: 28),
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: AuthTheme.welcomeTitleStyle.copyWith(
                            fontSize: 32,
                            height: 1.2,
                          ),
                          children: [
                            const TextSpan(text: 'Your dream life.\n'),
                            TextSpan(
                              text: 'Already done.',
                              style: AuthTheme.welcomeTitleItalicStyle.copyWith(
                                fontSize: 32,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'In your voice.',
                        style: AuthTheme.welcomeSubStyle.copyWith(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 240),
                      child: _buildButton(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Free to start · No card required',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: AuthTheme.inkSoft,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(BuildContext context) {
    return Material(
      color: AuthTheme.gold,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => context.go(OnboardingPersonalizeWidget.routePath),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          alignment: Alignment.center,
          child: Text('Start Manifesting', style: AuthTheme.primaryButtonStyle),
        ),
      ),
    );
  }
}
