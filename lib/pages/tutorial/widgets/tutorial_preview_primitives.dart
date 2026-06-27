import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/shared/theme/auth_theme.dart';

class TutorialPreviewTitle extends StatelessWidget {
  const TutorialPreviewTitle({
    super.key,
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

class TutorialHighlightedBox extends StatelessWidget {
  const TutorialHighlightedBox({super.key, required this.child});

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

class TutorialMockInput extends StatelessWidget {
  const TutorialMockInput({
    super.key,
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

class TutorialMockChips extends StatelessWidget {
  const TutorialMockChips({
    super.key,
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

class TutorialPulsingButton extends StatelessWidget {
  const TutorialPulsingButton({super.key, required this.label});

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
