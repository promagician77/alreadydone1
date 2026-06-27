import 'package:flutter/material.dart';

import '../widgets/tutorial_preview_primitives.dart';
import '../widgets/tutorial_voice_widgets.dart';

class TutorialVoiceSelectPreview extends StatelessWidget {
  const TutorialVoiceSelectPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TutorialPreviewTitle(
          title: 'Choose your\nnarration voice',
          subtitle: 'Your own voice is recommended for manifestation.',
        ),
        SizedBox(height: 16),
        TutorialHighlightedBox(
          child: TutorialVoiceOption(
            name: 'My Voice',
            description: 'Your own cloned voice, the most powerful option',
            selected: true,
            badge: 'RECOMMENDED',
            isMyVoice: true,
          ),
        ),
        SizedBox(height: 14),
        TutorialSectionDivider(label: 'OR CHOOSE A PRE-MADE VOICE'),
        SizedBox(height: 12),
        TutorialVoiceOption(name: 'Matt', description: 'Warm & Soothing'),
        SizedBox(height: 8),
        TutorialVoiceOption(name: 'David', description: 'Confident & Powerful'),
        SizedBox(height: 8),
        TutorialVoiceOption(name: 'Sarah', description: 'Warm & Nurturing'),
      ],
    );
  }
}
