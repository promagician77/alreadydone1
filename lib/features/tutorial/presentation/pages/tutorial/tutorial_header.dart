import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/shared/theme/auth_theme.dart';
import '/widgets/pressable.dart';

class TutorialHeader extends StatelessWidget {
  const TutorialHeader({
    super.key,
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
