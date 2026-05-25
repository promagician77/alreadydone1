import 'package:flutter/material.dart';

import 'tutorial_instruction_card.dart';
import 'tutorial_preview_card.dart';
import 'tutorial_step.dart';

class TutorialBody extends StatelessWidget {
  const TutorialBody({
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxHeight < 560;
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24, isCompact ? 8 : 18, 24, 18),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 36),
            child: Column(
              mainAxisAlignment: isCompact
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.center,
              children: [
                TutorialInstructionCard(
                  step: step,
                  stepIndex: stepIndex,
                  totalSteps: totalSteps,
                ),
                SizedBox(height: isCompact ? 18 : 28),
                TutorialPreviewCard(step: step),
              ],
            ),
          ),
        );
      },
    );
  }
}
