import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/shared/theme/auth_theme.dart';
import 'tutorial_step.dart';

class TutorialInstructionCard extends StatelessWidget {
  const TutorialInstructionCard({
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
          Text(
            'Step ${stepIndex + 1} of $totalSteps',
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
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
