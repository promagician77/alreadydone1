import 'package:flutter/material.dart';

/// Copy and icons for onboarding guide bottom sheets (matches design reference).
class OnboardingGuideContent {
  const OnboardingGuideContent({
    required this.icon,
    required this.title,
    required this.body,
    this.bullets,
    this.footer,
    this.buttonText = 'Got it',
  });

  final IconData icon;
  final String title;
  final String body;
  final List<String>? bullets;
  final String? footer;
  final String buttonText;

  static const personalize = OnboardingGuideContent(
    icon: Icons.person_outline_rounded,
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
}
