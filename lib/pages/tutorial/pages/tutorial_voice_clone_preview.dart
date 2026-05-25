import 'package:flutter/material.dart';

import '/pages/onboarding/recording_circle.dart';
import '../widgets/tutorial_preview_primitives.dart';
import '../widgets/tutorial_voice_widgets.dart';

class TutorialVoiceClonePreview extends StatelessWidget {
  const TutorialVoiceClonePreview({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        TutorialPreviewTitle(
          title: 'Great Recording!',
          subtitle: 'Your voice clone is ready to create.',
        ),
        SizedBox(height: 16),
        RecordingCircle(
          progress: 1,
          timerText: '00:00',
          label: '',
          showCheckmark: true,
          size: 126,
        ),
        SizedBox(height: 14),
        TutorialInfoBanner(
          text:
              "Perfect! 30 seconds recorded.\nTap 'Create Clone Voice' below to continue.",
        ),
        SizedBox(height: 12),
        TutorialNextStepCard(),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TutorialSmallActionButton(
                icon: Icons.headphones,
                label: 'Listen',
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: TutorialSmallActionButton(
                icon: Icons.refresh,
                label: 'Re-record',
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        TutorialPulsingButton(label: 'Create Clone Voice'),
      ],
    );
  }
}
