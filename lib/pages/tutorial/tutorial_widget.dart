import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/flutter_flow/nav/nav.dart';
import '/pages/auth/auth_theme.dart';
import '/pages/onboarding/onboarding_personalize_widget.dart';
import '/pages/onboarding/recording_circle.dart';
import '/services/ai_consent_service.dart';
import '/services/app_toast.dart';
import '/services/onboarding_service.dart';
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
            _TutorialHeader(
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
              onNext: () => _next(),
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
                'Tutorial Walkthrough',
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
                _InstructionCard(
                  step: step,
                  stepIndex: stepIndex,
                  totalSteps: totalSteps,
                ),
                SizedBox(height: isCompact ? 18 : 28),
                _PreviewCard(step: step),
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
        if (label.trim().isNotEmpty) ...[
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
        ] else
          const Spacer(),
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
      case TutorialVisualType.personalize:
        return const _PersonalizePreview();
      case TutorialVisualType.category:
        return const _CategoryPreview();
      case TutorialVisualType.desire:
        return const _DesirePreview();
      case TutorialVisualType.createStory:
        return const _CreateStoryPreview();
      case TutorialVisualType.paywall:
        return const _PaywallPreview();
      case TutorialVisualType.voiceSelect:
        return const _VoiceSelectPreview();
      case TutorialVisualType.voiceRecord:
        return const _VoiceRecordPreview();
      case TutorialVisualType.voiceClone:
        return const _VoiceClonePreview();
      case TutorialVisualType.voiceReady:
        return const _VoiceReadyPreview();
    }
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

class _PaywallPreview extends StatelessWidget {
  const _PaywallPreview();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: GoogleFonts.cormorantGaramond(
              fontSize: 27,
              fontWeight: FontWeight.w500,
              color: AuthTheme.ink,
              height: 1.08,
            ),
            children: [
              const TextSpan(text: 'Your dream life.\n'),
              TextSpan(
                text: 'Already done.',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 27,
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
          'Unlimited stories in your voice',
          style: GoogleFonts.outfit(fontSize: 13, color: AuthTheme.inkSoft),
        ),
        const SizedBox(height: 16),
        const _PaywallStatsCard(),
        const SizedBox(height: 14),
        const _PulsingButton(label: 'Start your 3-day free trial today'),
        const SizedBox(height: 14),
        const _PlanCard(
          title: 'Monthly',
          price: r'$29.99',
          period: '/month',
          selected: true,
          note: 'Save 30% vs weekly plan',
        ),
        const SizedBox(height: 10),
        const _PlanCard(
          title: 'Weekly',
          price: r'$9.99',
          period: '/week',
        ),
      ],
    );
  }
}

class _VoiceSelectPreview extends StatelessWidget {
  const _VoiceSelectPreview();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PreviewTitle(
          title: 'Choose your\nnarration voice',
          subtitle: 'Your own voice is recommended for manifestation.',
        ),
        SizedBox(height: 16),
        _HighlightedBox(
          child: _VoiceOption(
            name: 'My Voice',
            description: 'Your own cloned voice, the most powerful option',
            selected: true,
            badge: 'RECOMMENDED',
            isMyVoice: true,
          ),
        ),
        SizedBox(height: 14),
        _SectionDivider(label: 'OR CHOOSE A PRE-MADE VOICE'),
        SizedBox(height: 12),
        _VoiceOption(name: 'Matt', description: 'Warm & Soothing'),
        SizedBox(height: 8),
        _VoiceOption(name: 'David', description: 'Confident & Powerful'),
        SizedBox(height: 8),
        _VoiceOption(name: 'Sarah', description: 'Warm & Nurturing'),
      ],
    );
  }
}

class _VoiceRecordPreview extends StatelessWidget {
  const _VoiceRecordPreview();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Column(
          children: [
            Text(
              'Clone Your Voice',
              textAlign: TextAlign.center,
              style: GoogleFonts.cormorantGaramond(
                fontSize: 25,
                height: 1.08,
                fontWeight: FontWeight.w500,
                color: AuthTheme.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Record yourself reading the words below.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: AuthTheme.inkSoft,
                height: 1.35,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const RecordingCircle(
          progress: 0,
          timerText: '00:30',
          label: '',
          size: 126,
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AuthTheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AuthTheme.gold, width: 1.5),
          ),
          child: Column(
            children: [
              Text(
                'READ THIS ALOUD 3 TIMES',
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  color: AuthTheme.gold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Three months later, I stood on the private terrace of my Newport Coast estate, watching the sunrise paint the Pacific in liquid gold...',
                textAlign: TextAlign.center,
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 15,
                  height: 1.35,
                  color: AuthTheme.ink,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const _PulsingButton(label: 'Start Recording'),
      ],
    );
  }
}

class _VoiceClonePreview extends StatelessWidget {
  const _VoiceClonePreview();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _PreviewTitle(
          title: 'Great Recording!',
          subtitle: 'Your voice clone is ready to create.',
        ),
        SizedBox(height: 16),
        RecordingCircle(
          progress: 1,
          timerText: '00:00',
          label: '',
          showCheckmark: true,
          size: 126,
        ),
        SizedBox(height: 14),
        _InfoBanner(
          text:
              "Perfect! 30 seconds recorded.\nTap 'Create Clone Voice' below to continue.",
        ),
        SizedBox(height: 12),
        _NextStepCard(),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
                child: _SmallActionButton(
                    icon: Icons.headphones, label: 'Listen')),
            SizedBox(width: 8),
            Expanded(
                child: _SmallActionButton(
                    icon: Icons.refresh, label: 'Re-record')),
          ],
        ),
        SizedBox(height: 12),
        _PulsingButton(label: 'Create Clone Voice'),
      ],
    );
  }
}

class _VoiceReadyPreview extends StatelessWidget {
  const _VoiceReadyPreview();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: AuthTheme.goldPale,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AuthTheme.gold.withValues(alpha: 0.45)),
            boxShadow: [
              BoxShadow(
                color: AuthTheme.gold.withValues(alpha: 0.18),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.auto_awesome_rounded,
            color: AuthTheme.gold,
            size: 34,
          ),
        ),
        const SizedBox(height: 18),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: GoogleFonts.cormorantGaramond(
              fontSize: 28,
              fontWeight: FontWeight.w500,
              color: AuthTheme.ink,
              height: 1.08,
            ),
            children: [
              const TextSpan(text: "It's already done.\n"),
              TextSpan(
                text: 'Welcome home.',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 28,
                  fontStyle: FontStyle.italic,
                  color: AuthTheme.gold,
                  height: 1.08,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Every manifestation can now be narrated in your own voice.',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 13,
            height: 1.45,
            color: AuthTheme.inkSoft,
          ),
        ),
      ],
    );
  }
}

class _PaywallStatsCard extends StatelessWidget {
  const _PaywallStatsCard();

  @override
  Widget build(BuildContext context) {
    const stats = [
      ('4.8*', 'RATING'),
      ('50K+', 'STORIES'),
      ('12K+', 'USERS'),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AuthTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AuthTheme.stone),
      ),
      child: Column(
        children: [
          Text(
            'TRUSTED BY THOUSANDS',
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
              color: AuthTheme.ink,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: stats.map((stat) {
              return Column(
                children: [
                  Text(
                    stat.$1,
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AuthTheme.gold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    stat.$2,
                    style: GoogleFonts.outfit(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                      color: AuthTheme.inkSoft,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.title,
    required this.price,
    required this.period,
    this.selected = false,
    this.note,
  });

  final String title;
  final String price;
  final String period;
  final bool selected;
  final String? note;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFE3F0E0) : AuthTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected ? const Color(0xFF5A8A4A) : AuthTheme.stone,
          width: selected ? 1.6 : 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AuthTheme.ink,
                  ),
                ),
                const SizedBox(height: 2),
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AuthTheme.ink,
                    ),
                    children: [
                      TextSpan(text: price),
                      TextSpan(
                        text: ' $period',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AuthTheme.inkSoft,
                        ),
                      ),
                    ],
                  ),
                ),
                if (note != null) ...[
                  const SizedBox(height: 7),
                  Text(
                    note!,
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF5A8A4A),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? const Color(0xFF5A8A4A) : AuthTheme.stoneMid,
                width: 1.5,
              ),
            ),
            child: selected
                ? Center(
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF5A8A4A),
                      ),
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: AuthTheme.stone,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
              color: AuthTheme.inkSoft,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: AuthTheme.stone,
          ),
        ),
      ],
    );
  }
}

class _VoiceOption extends StatelessWidget {
  const _VoiceOption({
    required this.name,
    required this.description,
    this.selected = false,
    this.badge,
    this.isMyVoice = false,
  });

  final String name;
  final String description;
  final bool selected;
  final String? badge;
  final bool isMyVoice;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        gradient: isMyVoice
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AuthTheme.goldPale, AuthTheme.warmWhite],
              )
            : null,
        color: isMyVoice
            ? null
            : (selected ? AuthTheme.goldPale : AuthTheme.surface),
        borderRadius: BorderRadius.circular(isMyVoice ? 16 : 12),
        border: Border.all(
          color: selected
              ? AuthTheme.gold
              : (isMyVoice ? AuthTheme.goldLight : AuthTheme.stone),
          width: isMyVoice ? 2 : 1.5,
        ),
        boxShadow: selected && isMyVoice
            ? [
                BoxShadow(
                  color: AuthTheme.ink.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? AuthTheme.gold : AuthTheme.stoneMid,
                width: 1.6,
              ),
            ),
            child: selected
                ? Center(
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AuthTheme.gold,
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.outfit(
                        fontSize: isMyVoice ? 16 : 14,
                        fontWeight: FontWeight.w600,
                        color: AuthTheme.ink,
                      ),
                    ),
                    if (badge != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AuthTheme.gold,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badge!,
                          style: GoogleFonts.outfit(
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.7,
                            color: AuthTheme.surface,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: GoogleFonts.outfit(
                    fontSize: isMyVoice ? 12 : 11,
                    height: 1.35,
                    color: AuthTheme.inkSoft,
                  ),
                ),
              ],
            ),
          ),
          if (!selected) ...[
            const SizedBox(width: 8),
            const Icon(Icons.play_arrow_rounded,
                size: 20, color: AuthTheme.ink),
          ],
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F0E0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x805A8A4A)),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          height: 1.4,
          color: const Color(0xFF5A8A4A),
        ),
      ),
    );
  }
}

class _NextStepCard extends StatelessWidget {
  const _NextStepCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AuthTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AuthTheme.stone),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                color: AuthTheme.gold,
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                'What happens next?',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AuthTheme.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            "Tap 'Create Clone Voice' to generate your manifestation story. Takes 30 to 45 seconds.",
            style: GoogleFonts.outfit(
              fontSize: 11,
              height: 1.4,
              color: AuthTheme.inkSoft,
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallActionButton extends StatelessWidget {
  const _SmallActionButton({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
      decoration: BoxDecoration(
        color: AuthTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AuthTheme.stone),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: AuthTheme.ink),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AuthTheme.ink,
              ),
            ),
          ),
        ],
      ),
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
        color: AuthTheme.goldPale,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AuthTheme.gold.withValues(alpha: 0.9)),
        boxShadow: [
          BoxShadow(
            color: AuthTheme.gold.withValues(alpha: 0.20),
            blurRadius: 32,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: AuthTheme.ink.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Step ${stepIndex + 1} of $totalSteps',
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  color: AuthTheme.gold,
                ),
              ),
              if (step.isPaywall) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AuthTheme.goldPale,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: AuthTheme.gold.withValues(alpha: 0.32),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.lock_rounded,
                        size: 10,
                        color: AuthTheme.gold,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'PAYWALL',
                        style: GoogleFonts.outfit(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: AuthTheme.gold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
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
