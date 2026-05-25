import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/pages/auth/auth_theme.dart';

class TutorialVoiceReadyPreview extends StatelessWidget {
  const TutorialVoiceReadyPreview({super.key});

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
