import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/flutter_flow/nav/nav.dart';
import '/pages/auth/auth_theme.dart';
import '/pages/onboarding/onboarding_origin_splash_widget.dart';
import '/widgets/pressable.dart';
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

  void _goToOnboarding() {
    context.go(OnboardingOriginSplashWidget.routePath);
  }

  void _next() {
    if (_isLastStep) {
      _goToOnboarding();
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
            _TutorialHeader(
              stepIndex: _stepIndex,
              totalSteps: tutorialSteps.length,
              onSkip: _goToOnboarding,
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
                child: _TutorialBody(
                  key: ValueKey(_stepIndex),
                  step: _currentStep,
                  stepIndex: _stepIndex,
                  totalSteps: tutorialSteps.length,
                ),
              ),
            ),
            _TutorialActions(
              isFirstStep: _isFirstStep,
              isLastStep: _isLastStep,
              onBack: _back,
              onNext: _next,
            ),
          ],
        ),
      ),
    );
  }
}

class _TutorialHeader extends StatelessWidget {
  const _TutorialHeader({
    required this.stepIndex,
    required this.totalSteps,
    required this.onSkip,
  });

  final int stepIndex;
  final int totalSteps;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 8),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Quick Tour',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AuthTheme.gold,
                  letterSpacing: 1.6,
                ),
              ),
              const Spacer(),
              Pressable(
                onTap: onSkip,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Text(
                    'Skip',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AuthTheme.inkSoft,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: List.generate(totalSteps, (index) {
              final isActive = index <= stepIndex;
              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  height: 3,
                  margin:
                      EdgeInsets.only(right: index == totalSteps - 1 ? 0 : 5),
                  decoration: BoxDecoration(
                    color: isActive ? AuthTheme.gold : AuthTheme.stone,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _TutorialBody extends StatelessWidget {
  const _TutorialBody({
    super.key,
    required this.step,
    required this.stepIndex,
    required this.totalSteps,
  });

  final TutorialStep step;
  final int stepIndex;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxHeight < 560;
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24, isCompact ? 8 : 18, 24, 18),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 36),
            child: Column(
              mainAxisAlignment: isCompact
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.center,
              children: [
                _PreviewCard(step: step),
                SizedBox(height: isCompact ? 18 : 28),
                _InstructionCard(
                  step: step,
                  stepIndex: stepIndex,
                  totalSteps: totalSteps,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.step});

  final TutorialStep step;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 420),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AuthTheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AuthTheme.stone),
        boxShadow: [
          BoxShadow(
            color: AuthTheme.ink.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MockStatusBar(label: step.focusLabel),
          const SizedBox(height: 18),
          _TutorialVisual(step: step),
        ],
      ),
    );
  }
}

class _MockStatusBar extends StatelessWidget {
  const _MockStatusBar({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AuthTheme.goldPale,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AuthTheme.gold.withValues(alpha: 0.24)),
          ),
          child: const Icon(
            Icons.auto_awesome_rounded,
            size: 17,
            color: AuthTheme.gold,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AuthTheme.ink,
            ),
          ),
        ),
        Container(
          width: 44,
          height: 18,
          decoration: BoxDecoration(
            color: AuthTheme.offWhite,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ],
    );
  }
}

class _TutorialVisual extends StatelessWidget {
  const _TutorialVisual({required this.step});

  final TutorialStep step;

  @override
  Widget build(BuildContext context) {
    switch (step.visualType) {
      case TutorialVisualType.welcome:
        return const _WelcomePreview();
      case TutorialVisualType.personalize:
        return const _PersonalizePreview();
      case TutorialVisualType.category:
        return const _CategoryPreview();
      case TutorialVisualType.desire:
        return const _DesirePreview();
      case TutorialVisualType.createStory:
        return const _CreateStoryPreview();
    }
  }
}

class _WelcomePreview extends StatelessWidget {
  const _WelcomePreview();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8),
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: AuthTheme.gold.withValues(alpha: 0.18),
                blurRadius: 22,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Image.asset(
              'assets/icon/app_icon.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 18),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: GoogleFonts.cormorantGaramond(
              fontSize: 28,
              fontWeight: FontWeight.w400,
              color: AuthTheme.ink,
              height: 1.08,
            ),
            children: [
              const TextSpan(text: 'Your dream life.\n'),
              TextSpan(
                text: 'Already done.',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 28,
                  fontWeight: FontWeight.w400,
                  fontStyle: FontStyle.italic,
                  color: AuthTheme.gold,
                  height: 1.08,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'In your voice.',
          style: GoogleFonts.outfit(
            fontSize: 13,
            color: AuthTheme.inkSoft,
          ),
        ),
      ],
    );
  }
}

class _PersonalizePreview extends StatelessWidget {
  const _PersonalizePreview();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PreviewTitle(
          title: "First, let's personalize\nyour experience",
          subtitle: 'These details make every story unique to you.',
        ),
        SizedBox(height: 16),
        _HighlightedBox(
          child: Column(
            children: [
              _MockInput(label: 'Your First Name', value: 'Jordan'),
              SizedBox(height: 12),
              _MockInput(label: 'Dream Location', value: 'Bali'),
              SizedBox(height: 12),
              _MockChips(
                label: 'Choose Your Energy Word',
                chips: ['Powerful', 'Peaceful', 'Abundant'],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CategoryPreview extends StatelessWidget {
  const _CategoryPreview();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _PreviewTitle(
          title: "What's already done\nfor you?",
          subtitle: 'Choose a category to begin.',
        ),
        const SizedBox(height: 16),
        _HighlightedBox(
          child: GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1.75,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: const [
              _CategoryTile(
                  icon: Icons.favorite_rounded, label: 'Love', active: true),
              _CategoryTile(icon: Icons.attach_money_rounded, label: 'Money'),
              _CategoryTile(icon: Icons.work_rounded, label: 'Career'),
              _CategoryTile(icon: Icons.spa_rounded, label: 'Health'),
            ],
          ),
        ),
      ],
    );
  }
}

class _DesirePreview extends StatelessWidget {
  const _DesirePreview();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _PreviewTitle(
          title: "Describe what's\nalready yours",
          subtitle: 'Write it like it already happened.',
        ),
        const SizedBox(height: 16),
        _HighlightedBox(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AuthTheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AuthTheme.stone),
            ),
            child: Text(
              'I am in the deeply loving relationship where I feel seen, valued, and cherished every day...',
              style: GoogleFonts.outfit(
                fontSize: 13,
                height: 1.45,
                color: AuthTheme.inkSoft,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CreateStoryPreview extends StatelessWidget {
  const _CreateStoryPreview();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DesirePreview(),
        SizedBox(height: 16),
        _PulsingButton(label: 'Create My Story'),
      ],
    );
  }
}

class _PreviewTitle extends StatelessWidget {
  const _PreviewTitle({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.cormorantGaramond(
            fontSize: 25,
            height: 1.08,
            fontWeight: FontWeight.w500,
            color: AuthTheme.ink,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: GoogleFonts.outfit(
            fontSize: 13,
            color: AuthTheme.inkSoft,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _HighlightedBox extends StatelessWidget {
  const _HighlightedBox({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        final glow = math.sin(value * math.pi);
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AuthTheme.goldPale.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AuthTheme.gold.withValues(alpha: 0.42 + glow * 0.18),
            ),
            boxShadow: [
              BoxShadow(
                color: AuthTheme.gold.withValues(alpha: 0.14 + glow * 0.10),
                blurRadius: 18 + glow * 8,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        );
      },
      child: child,
    );
  }
}

class _MockInput extends StatelessWidget {
  const _MockInput({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AuthTheme.ink,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AuthTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AuthTheme.stone),
          ),
          child: Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: AuthTheme.inkSoft,
            ),
          ),
        ),
      ],
    );
  }
}

class _MockChips extends StatelessWidget {
  const _MockChips({
    required this.label,
    required this.chips,
  });

  final String label;
  final List<String> chips;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AuthTheme.ink,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: chips.asMap().entries.map((entry) {
            final active = entry.key == 0;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: active ? AuthTheme.goldPale : AuthTheme.surface,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: active ? AuthTheme.gold : AuthTheme.stone,
                ),
              ),
              child: Text(
                entry.value,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: active ? AuthTheme.goldDark : AuthTheme.inkSoft,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.icon,
    required this.label,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: active ? AuthTheme.goldPale : AuthTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: active ? AuthTheme.gold : AuthTheme.stone,
          width: active ? 1.5 : 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 18,
            color: active ? AuthTheme.gold : AuthTheme.inkSoft,
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AuthTheme.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _PulsingButton extends StatelessWidget {
  const _PulsingButton({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        final glow = math.sin(value * math.pi);
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          decoration: BoxDecoration(
            color: AuthTheme.gold,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AuthTheme.gold.withValues(alpha: 0.28 + glow * 0.18),
                blurRadius: 14 + glow * 16,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: child,
        );
      },
      child: Text(label, style: AuthTheme.primaryButtonStyle),
    );
  }
}

class _InstructionCard extends StatelessWidget {
  const _InstructionCard({
    required this.step,
    required this.stepIndex,
    required this.totalSteps,
  });

  final TutorialStep step;
  final int stepIndex;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 420),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        color: AuthTheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AuthTheme.gold.withValues(alpha: 0.72)),
        boxShadow: [
          BoxShadow(
            color: AuthTheme.ink.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: AuthTheme.gold.withValues(alpha: 0.14),
            blurRadius: 36,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step ${stepIndex + 1} of $totalSteps',
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.7,
              color: AuthTheme.gold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            step.title,
            style: GoogleFonts.cormorantGaramond(
              fontSize: 25,
              fontWeight: FontWeight.w500,
              color: AuthTheme.ink,
              height: 1.12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            step.body,
            style: GoogleFonts.outfit(
              fontSize: 14,
              height: 1.48,
              color: AuthTheme.inkSoft,
            ),
          ),
        ],
      ),
    );
  }
}

class _TutorialActions extends StatelessWidget {
  const _TutorialActions({
    required this.isFirstStep,
    required this.isLastStep,
    required this.onBack,
    required this.onNext,
  });

  final bool isFirstStep;
  final bool isLastStep;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: Row(
        children: [
          Expanded(
            child: Opacity(
              opacity: isFirstStep ? 0.35 : 1,
              child: Pressable(
                onTap: isFirstStep ? null : onBack,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AuthTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AuthTheme.stone),
                  ),
                  child: Text(
                    'Back',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AuthTheme.inkSoft,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Pressable(
              onTap: onNext,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 15),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AuthTheme.gold,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AuthTheme.gold.withValues(alpha: 0.24),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Text(
                  isLastStep ? 'Start onboarding' : 'Next',
                  style: AuthTheme.primaryButtonStyle,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
