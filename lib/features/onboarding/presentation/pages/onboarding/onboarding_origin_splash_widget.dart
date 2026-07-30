import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _model = createModel(context, () => OnboardingOriginSplashModel());
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
          animation: _fadeController,
          builder: (context, child) {
            final progress = Curves.easeOut.transform(_fadeController.value);
            return Opacity(
              opacity: progress,
              child: Transform.scale(
                scale: 0.98 + 0.02 * progress,
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
      child: SizedBox(
        width: 128,
        height: 128,
        child: Stack(
          alignment: Alignment.center,
          children: [
            for (var i = 3; i >= 1; i--)
              Container(
                width: 80 + i * 22.0,
                height: 80 + i * 22.0,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AuthTheme.gold.withValues(alpha: 0.06 + i * 0.04),
                  ),
                ),
              ),
            Container(
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
              child: Center(
                child: SvgPicture.string(
                  _sparklesIconSvg,
                  width: 36,
                  height: 36,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Lucide Sparkles icon (matches design reference), not Material auto_awesome.
  static const _sparklesIconSvg = '''
<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M9.937 15.5A2 2 0 0 0 8.5 14.063l-6.135-1.582a.5.5 0 0 1 0-.962L8.5 9.936A2 2 0 0 0 9.937 8.5l1.582-6.135a.5.5 0 0 1 .962 0L14.063 8.5A2 2 0 0 0 15.5 9.937l6.135 1.581a.5.5 0 0 1 0 .964L15.5 14.063a2 2 0 0 0-1.437 1.437l-1.582 6.135a.5.5 0 0 1-.962 0z" fill="#FFFFFF" stroke="#FFFFFF" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M20 3v4" stroke="#FFFFFF" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M22 5h-4" stroke="#FFFFFF" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M4 17v2" stroke="#FFFFFF" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M5 18H3" stroke="#FFFFFF" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
</svg>
''';

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
            if (mounted) {
              context.go(
                '${OnboardingPersonalizeWidget.routePath}?guide=personalize',
              );
            }
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
