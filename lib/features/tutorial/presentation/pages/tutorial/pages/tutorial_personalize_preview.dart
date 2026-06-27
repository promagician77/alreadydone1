import 'package:flutter/material.dart';

import '../widgets/tutorial_preview_primitives.dart';

class TutorialPersonalizePreview extends StatelessWidget {
  const TutorialPersonalizePreview({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TutorialPreviewTitle(
          title: "First, let's personalize\nyour experience",
          subtitle: 'These details make every story unique to you.',
        ),
        SizedBox(height: 16),
        TutorialHighlightedBox(
          child: Column(
            children: [
              TutorialMockInput(label: 'Your First Name', value: 'Jordan'),
              SizedBox(height: 12),
              TutorialMockInput(label: 'Dream Location', value: 'Bali'),
              SizedBox(height: 12),
              TutorialMockChips(
                label: 'Choose Your Energy Word',
                chips: ['Powerful', 'Peaceful', 'Abundant'],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
