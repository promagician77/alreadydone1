import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/shared/theme/auth_theme.dart';
import '/shared/widgets/recording_circle.dart';
import '../widgets/tutorial_preview_primitives.dart';

class TutorialVoiceRecordPreview extends StatelessWidget {
  const TutorialVoiceRecordPreview({super.key});

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
        const TutorialPulsingButton(label: 'Start Recording'),
      ],
    );
  }
}
