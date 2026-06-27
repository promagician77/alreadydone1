import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/shared/theme/auth_theme.dart';
import '../widgets/tutorial_paywall_widgets.dart';
import '../widgets/tutorial_preview_primitives.dart';

class TutorialPaywallPreview extends StatelessWidget {
  const TutorialPaywallPreview({super.key});

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
        const SizedBox(height: 22),
        const TutorialPulsingButton(label: 'Start your 3-day free trial today'),
        const SizedBox(height: 14),
        const TutorialPlanCard(
          title: 'Monthly',
          price: r'$14.99',
          period: '/month',
          selected: true,
        ),
        const SizedBox(height: 10),
        const TutorialPlanCard(
          title: 'Annual',
          price: r'$99.99',
          period: '/year',
          note: r'[SAVE 44%] -> only $8.33/month',
        ),
      ],
    );
  }
}
