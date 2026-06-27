import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/shared/theme/auth_theme.dart';
import '/widgets/pressable.dart';

class TutorialActions extends StatelessWidget {
  const TutorialActions({
    super.key,
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
