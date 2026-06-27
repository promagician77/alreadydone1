import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/shared/theme/auth_theme.dart';
import 'tutorial_step.dart';
import 'tutorial_visual.dart';

class TutorialPreviewCard extends StatelessWidget {
  const TutorialPreviewCard({super.key, required this.step});

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
          TutorialMockStatusBar(label: step.focusLabel),
          const SizedBox(height: 18),
          TutorialVisual(step: step),
        ],
      ),
    );
  }
}

class TutorialMockStatusBar extends StatelessWidget {
  const TutorialMockStatusBar({super.key, required this.label});

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
