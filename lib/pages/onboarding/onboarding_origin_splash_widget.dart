import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/auth/auth_theme.dart';
import '/widgets/pressable.dart';
import 'onboarding_origin_splash_model.dart';
import 'onboarding_personalize_widget.dart';

export 'onboarding_origin_splash_model.dart';

/// First screen of onboarding flow: app avatar, "Your dream life. Already done.", "Start Manifesting".
/// Shown before the paywall/onboarding_splash; tap goes to personalization.
class OnboardingOriginSplashWidget extends StatefulWidget {
  const OnboardingOriginSplashWidget({super.key});

  static String routeName = 'OnboardingOriginSplash';
  static String routePath = '/onboarding/welcome';

  @override
  State<OnboardingOriginSplashWidget> createState() =>
      _OnboardingOriginSplashWidgetState();
}

class _OnboardingOriginSplashWidgetState
    extends State<OnboardingOriginSplashWidget> {
  late OnboardingOriginSplashModel _model;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => OnboardingOriginSplashModel());
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuthTheme.warmWhite,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 32),
                    _buildLogo(),
                    const SizedBox(height: 28),
                    _buildTitle(),
                    const SizedBox(height: 12),
                    _buildTagline(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildPrimaryButton(),
                  const SizedBox(height: 8),
                  _buildSubtext(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Center(
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AuthTheme.ink.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: AuthTheme.gold.withValues(alpha: 0.2),
              blurRadius: 24,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Image.asset(
            'assets/icon/app_icon.png',
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: GoogleFonts.cormorantGaramond(
          fontSize: 32,
          fontWeight: FontWeight.w400,
          color: AuthTheme.ink,
          height: 1.2,
        ),
        children: [
          const TextSpan(text: 'Your dream life.\n'),
          TextSpan(
            text: 'Already done.',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 32,
              fontWeight: FontWeight.w400,
              fontStyle: FontStyle.italic,
              color: AuthTheme.gold,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagline() {
    return Text(
      'In your voice.',
      style: GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AuthTheme.inkSoft,
      ),
    );
  }

  Widget _buildPrimaryButton() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 240),
        child: Pressable(
          onTap: () => context.go(OnboardingPersonalizeWidget.routePath),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            decoration: BoxDecoration(
              color: AuthTheme.gold,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AuthTheme.ink.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              'Start Manifesting',
              style: AuthTheme.primaryButtonStyle,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubtext() {
    return Text(
      'Free to start · No card required',
      style: GoogleFonts.outfit(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: AuthTheme.inkSoft,
      ),
    );
  }
}
