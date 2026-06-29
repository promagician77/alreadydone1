import 'package:flutter/material.dart';

import '/flutter_flow/nav/nav.dart';
import '/shared/theme/auth_theme.dart';
import '/features/onboarding/presentation/pages/onboarding/onboarding_personalize_widget.dart';
import '/shared/services/ai_consent_service.dart';
import '/shared/services/app_toast.dart';
import '/shared/services/onboarding_service.dart';
import 'tutorial_actions.dart';
import 'tutorial_body.dart';
import 'tutorial_header.dart';
import 'tutorial_step.dart';

export 'tutorial_step.dart';

class OnboardingTutorialWidget extends StatefulWidget {
  const OnboardingTutorialWidget({super.key});

  static String routeName = 'OnboardingTutorial';
  static String routePath = '/onboarding/tutorial';

  @override
  State<OnboardingTutorialWidget> createState() =>
      _OnboardingTutorialWidgetState();
}

class _OnboardingTutorialWidgetState extends State<OnboardingTutorialWidget> {
  int _stepIndex = 0;

  TutorialStep get _currentStep => tutorialSteps[_stepIndex];
  bool get _isFirstStep => _stepIndex == 0;
  bool get _isLastStep => _stepIndex == tutorialSteps.length - 1;

  Future<void> _goToOnboarding() async {
    await OnboardingService.setTutorialSeen();
    if (!mounted) return;
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
    if (!mounted) return;
    context.go(OnboardingPersonalizeWidget.routePath);
  }

  Future<void> _next() async {
    if (_isLastStep) {
      await _goToOnboarding();
      return;
    }
    setState(() => _stepIndex += 1);
  }

  void _back() {
    if (_isFirstStep) return;
    setState(() => _stepIndex -= 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuthTheme.warmWhite,
      body: SafeArea(
        child: Column(
          children: [
            TutorialHeader(
              stepIndex: _stepIndex,
              totalSteps: tutorialSteps.length,
              onSkip: () => _goToOnboarding(),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.04, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: TutorialBody(
                  key: ValueKey(_stepIndex),
                  step: _currentStep,
                  stepIndex: _stepIndex,
                  totalSteps: tutorialSteps.length,
                ),
              ),
            ),
            TutorialActions(
              isFirstStep: _isFirstStep,
              isLastStep: _isLastStep,
              onBack: _back,
              onNext: () => _next(),
            ),
          ],
        ),
      ),
    );
  }
}
