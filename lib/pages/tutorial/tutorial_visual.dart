import 'package:flutter/material.dart';

import 'pages/tutorial_desire_preview.dart';
import 'pages/tutorial_paywall_preview.dart';
import 'pages/tutorial_personalize_preview.dart';
import 'pages/tutorial_voice_clone_preview.dart';
import 'pages/tutorial_voice_ready_preview.dart';
import 'pages/tutorial_voice_record_preview.dart';
import 'pages/tutorial_voice_select_preview.dart';
import 'tutorial_step.dart';

class TutorialVisual extends StatelessWidget {
  const TutorialVisual({super.key, required this.step});

  final TutorialStep step;

  @override
  Widget build(BuildContext context) {
    switch (step.visualType) {
      case TutorialVisualType.personalize:
        return const TutorialPersonalizePreview();
      case TutorialVisualType.category:
        return const TutorialDesirePreview(
          highlight: TutorialDesirePreviewHighlight.categories,
        );
      case TutorialVisualType.desire:
        return const TutorialDesirePreview(
          highlight: TutorialDesirePreviewHighlight.describe,
        );
      case TutorialVisualType.createStory:
        return const TutorialDesirePreview(
          highlight: TutorialDesirePreviewHighlight.button,
        );
      case TutorialVisualType.paywall:
        return const TutorialPaywallPreview();
      case TutorialVisualType.voiceSelect:
        return const TutorialVoiceSelectPreview();
      case TutorialVisualType.voiceRecord:
        return const TutorialVoiceRecordPreview();
      case TutorialVisualType.voiceClone:
        return const TutorialVoiceClonePreview();
      case TutorialVisualType.voiceReady:
        return const TutorialVoiceReadyPreview();
    }
  }
}
