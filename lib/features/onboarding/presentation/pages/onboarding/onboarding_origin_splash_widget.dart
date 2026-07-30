import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/nav/nav.dart';
import '/shared/theme/auth_theme.dart';
import '/shared/services/ai_consent_service.dart';
import '/shared/services/app_toast.dart';
import '/shared/widgets/pressable.dart';
import 'onboarding_origin_splash_model.dart';
import 'onboarding_personalize_widget.dart';

export 'onboarding_origin_splash_model.dart';

/// First screen of onboarding: welcome message and Continue to personalization.
class OnboardingOriginSplashWidget extends StatefulWidget {
  const OnboardingOriginSplashWidget({super.key});

  static String routeName = 'OnboardingOriginSplash';
  static String routePath = '/onboarding/welcome';

  @override
  State<OnboardingOriginSplashWidget> createState() =>
      _OnboardingOriginSplashWidgetState();
}

class _OnboardingOriginSplashWidgetState
    extends State<OnboardingOriginSplashWidget>
    with TickerProviderStateMixin {
  late OnboardingOriginSplashModel _model;
  late AnimationController _fadeController;
  late AnimationController _shimmerController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => OnboardingOriginSplashModel());

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _scaleAnimation = Tween<double>(begin: 0.98, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _fadeController.forward();

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _shimmerController.dispose();
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuthTheme.offWhite,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _fadeAnimation,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: child,
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSparkleIcon(),
                const SizedBox(height: 32),
                _buildTitle(),
                const SizedBox(height: 14),
                _buildSubhead(),
                const SizedBox(height: 48),
                _buildPrimaryButton(),
                const SizedBox(height: 20),
                _buildFooterNote(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSparkleIcon() {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        final t = _shimmerController.value;
        final scale = 1.0 + 0.05 * math.sin(math.pi * t);
        final opacity = 0.85 + 0.15 * math.sin(math.pi * t);
        return Opacity(
          opacity: opacity,
          child: Transform.scale(
            scale: scale,
            child: child,
          ),
        );
      },
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AuthTheme.goldLight, AuthTheme.gold],
          ),
          boxShadow: [
            BoxShadow(
              color: AuthTheme.gold.withValues(alpha: 0.25),
              blurRadius: 32,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: const Icon(
          Icons.auto_awesome,
          size: 36,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: GoogleFonts.cormorantGaramond(
          fontSize: 36,
          fontWeight: FontWeight.w500,
          color: AuthTheme.ink,
          height: 1.1,
          letterSpacing: -0.5,
        ),
        children: [
          const TextSpan(text: 'Welcome to '),
          TextSpan(
            text: 'Already Done',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 36,
              fontWeight: FontWeight.w500,
              fontStyle: FontStyle.italic,
              color: AuthTheme.gold,
              height: 1.1,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubhead() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: Text(
        "Let's create your first manifestation story.",
        textAlign: TextAlign.center,
        style: GoogleFonts.outfit(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: AuthTheme.inkSoft,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildPrimaryButton() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: Pressable(
          onTap: () async {
            final hasConsent = await AIConsentService.ensureConsent(context);
            if (!hasConsent) {
              if (mounted) {
                AppToast.info(
                  context,
                  'You need to agree to AI data sharing to start onboarding.',
                );
              }
              return;
            }
            if (mounted) context.go(OnboardingPersonalizeWidget.routePath);
          },
          borderRadius: BorderRadius.circular(16),
          scaleDownTo: 0.98,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: AuthTheme.gold,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AuthTheme.gold.withValues(alpha: 0.25),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              'Continue',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooterNote() {
    return Text(
      'Takes about 2 minutes',
      textAlign: TextAlign.center,
      style: GoogleFonts.outfit(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AuthTheme.inkSoft,
      ),
    );
  }
}
