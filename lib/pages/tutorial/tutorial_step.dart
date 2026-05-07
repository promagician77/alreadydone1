enum TutorialVisualType {
  personalize,
  category,
  desire,
  createStory,
  paywall,
  voiceSelect,
  voiceRecord,
  voiceClone,
  voiceReady,
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
    title: 'Quick Tutorial First',
    body:
        "Just follow along, no need to fill anything in yet. On this screen, you'll enter your name, dream location, energy word, and someone you love. These details make every story unique to you. You'll set everything up when the tutorial ends.",
    visualType: TutorialVisualType.personalize,
    focusLabel: 'Personalize Form',
  ),
  TutorialStep(
    title: 'Choose a Category',
    body:
        'Pick the area of life you want to manifest. Love, Money, Career/Business, Health, or Home.',
    visualType: TutorialVisualType.category,
    focusLabel: 'Categories',
  ),
  TutorialStep(
    title: "Describe What's Already Yours",
    body:
        'Write your desired manifestation. Write it like it already happened. Be specific. Be emotional.',
    visualType: TutorialVisualType.desire,
    focusLabel: 'Desire Input',
  ),
  TutorialStep(
    title: 'Tap "Create My Story"',
    body:
        "Once you've described your manifestation, tap the gold button to continue building your story.",
    visualType: TutorialVisualType.createStory,
    focusLabel: 'Create Button',
  ),
  TutorialStep(
    title: 'Unlock Your Voice',
    body:
        'Start your 3-day free trial. Tap the gold button to unlock unlimited stories in your own voice.',
    visualType: TutorialVisualType.paywall,
    focusLabel: '',
  ),
  TutorialStep(
    title: "You're In",
    body:
        'Now choose the voice that will narrate your manifestations. Your own voice is most powerful.',
    visualType: TutorialVisualType.voiceSelect,
    focusLabel: 'Voice Setup',
  ),
  TutorialStep(
    title: 'Pick "My Voice"',
    body:
        'Select My Voice to clone yours, or pick from our pre-made voices to start instantly.',
    visualType: TutorialVisualType.voiceSelect,
    focusLabel: 'Voice Options',
  ),
  TutorialStep(
    title: 'Tap "Start Recording"',
    body:
        'Read the passage aloud 3 times, slowly and clearly. Recording auto-completes at 30 seconds.',
    visualType: TutorialVisualType.voiceRecord,
    focusLabel: 'Start Recording',
  ),
  TutorialStep(
    title: 'Tap "Create Clone Voice"',
    body:
        'Your recording is ready. Tap the gold button to create your custom voice. Takes 30 to 45 seconds.',
    visualType: TutorialVisualType.voiceClone,
    focusLabel: 'Clone Button',
  ),
  TutorialStep(
    title: "It's Already Done",
    body:
        'Your voice is ready. Every manifestation will now be narrated in your own voice. Welcome home.',
    visualType: TutorialVisualType.voiceReady,
    focusLabel: 'Voice Ready',
  ),
];
