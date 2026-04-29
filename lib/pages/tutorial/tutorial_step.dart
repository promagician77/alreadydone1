enum TutorialVisualType {
  welcome,
  personalize,
  category,
  desire,
  createStory,
}

class TutorialStep {
  const TutorialStep({
    required this.title,
    required this.body,
    required this.visualType,
    required this.focusLabel,
  });

  final String title;
  final String body;
  final TutorialVisualType visualType;
  final String focusLabel;
}

const tutorialSteps = <TutorialStep>[
  TutorialStep(
    title: 'Your dream life. Already done.',
    body:
        'Start with a few details, then create a manifestation story that feels personal and already complete.',
    visualType: TutorialVisualType.welcome,
    focusLabel: 'Getting Started',
  ),
  TutorialStep(
    title: 'Personalize Your Experience',
    body:
        'Add your name, dream location, energy word, and someone you love so every story feels like yours.',
    visualType: TutorialVisualType.personalize,
    focusLabel: 'Personal Details',
  ),
  TutorialStep(
    title: 'Choose a Category',
    body:
        'Pick the area of life you want to manifest first, like Love, Money, Career, Health, or Home.',
    visualType: TutorialVisualType.category,
    focusLabel: 'Your Focus',
  ),
  TutorialStep(
    title: "Describe What's Already Yours",
    body:
        'Write your desire as if it already happened. Be specific, emotional, and clear.',
    visualType: TutorialVisualType.desire,
    focusLabel: 'Your Desire',
  ),
  TutorialStep(
    title: 'Tap Create My Story',
    body:
        'When your desire feels right, create the first story and continue into your voice-led onboarding.',
    visualType: TutorialVisualType.createStory,
    focusLabel: 'Create Story',
  ),
];
