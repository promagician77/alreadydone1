import 'package:flutter/material.dart';

enum OnboardingGuideIconKind {
  person,
  grid3x3,
  mic,
}

/// Copy and icons for onboarding guide bottom sheets (matches design reference).
class OnboardingGuideContent {
  const OnboardingGuideContent({
    required this.iconKind,
    required this.title,
    required this.body,
    this.bullets,
    this.footer,
    this.buttonText = 'Got it',
  });

  final OnboardingGuideIconKind iconKind;
  final String title;
  final String body;
  final List<String>? bullets;
  final String? footer;
  final String buttonText;

  static const personalize = OnboardingGuideContent(
    iconKind: OnboardingGuideIconKind.person,
    title: 'Make it yours',
    body:
        'Fill in your name, dream location, energy word, and someone you love. '
        'These details make every story unique to you.',
    bullets: [
      'Your name - how you want to be addressed',
      'Dream location - where you want to be',
      'Energy word - how you want to feel',
      'Someone you love - a romantic interest',
    ],
  );

  static const category = OnboardingGuideContent(
    iconKind: OnboardingGuideIconKind.grid3x3,
    title: "What's already yours?",
    body:
        'Pick a category, then describe your manifestation. Write it like it '
        'already happened, or tap the navy mic to speak it.',
    bullets: [
      'Choose Love, Money, Career, Health, Home, or Personal Growth',
      'Describe it in present tense',
      'Be specific and emotional',
    ],
  );

  static const voiceSelect = OnboardingGuideContent(
    iconKind: OnboardingGuideIconKind.mic,
    title: 'Choose your voice',
    body:
        'Clone your own voice for the most personal experience, or pick from '
        'our pre-made voices to start instantly.',
    bullets: [
      'My Voice - clone yours in 30 seconds',
      'Pre-made voices - start instantly',
    ],
  );
}
