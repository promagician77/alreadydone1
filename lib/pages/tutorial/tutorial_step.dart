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
    required this.phaseLabel,
    this.isPaywall = false,
  });

  final String title;
  final String body;
  final TutorialVisualType visualType;
  final String focusLabel;
  final String phaseLabel;
  final bool isPaywall;
}

const tutorialSteps = <TutorialStep>[
  TutorialStep(
    title: 'Personalize Your Experience',
    body:
        'Enter your name, your dream location, your energy word, and someone you love. Then tap Continue. These details make every story unique to you.',
    visualType: TutorialVisualType.personalize,
    focusLabel: 'Personalize Form',
    phaseLabel: 'Pre-Paywall',
  ),
  TutorialStep(
    title: 'Choose a Category',
    body:
        'Pick the area of life you want to manifest. Love, Money, Career, Health, or Home.',
    visualType: TutorialVisualType.category,
    focusLabel: 'Categories',
    phaseLabel: 'Pre-Paywall',
  ),
  TutorialStep(
    title: "Describe What's Already Yours",
    body:
        'Write your desired manifestation. Write it like it already happened. Be specific. Be emotional.',
    visualType: TutorialVisualType.desire,
    focusLabel: 'Desire Input',
    phaseLabel: 'Pre-Paywall',
  ),
  TutorialStep(
    title: 'Tap "Create My Story"',
    body:
        "Once you've described your manifestation, tap the gold button to continue building your story.",
    visualType: TutorialVisualType.createStory,
    focusLabel: 'Create Button',
    phaseLabel: 'Pre-Paywall',
  ),
  TutorialStep(
    title: 'Unlock Your Voice',
    body:
        'Start your 3-day free trial. Tap the gold button to unlock unlimited stories in your own voice.',
    visualType: TutorialVisualType.paywall,
    focusLabel: 'Paywall CTA',
    phaseLabel: 'Pre-Paywall',
    isPaywall: true,
  ),
  TutorialStep(
    title: "You're In",
    body:
        'Now choose the voice that will narrate your manifestations. Your own voice is most powerful.',
    visualType: TutorialVisualType.voiceSelect,
    focusLabel: 'Voice Setup',
    phaseLabel: 'Post-Paywall',
  ),
  TutorialStep(
    title: 'Pick "My Voice"',
    body:
        'Select My Voice to clone yours, or pick from our pre-made voices to start instantly.',
    visualType: TutorialVisualType.voiceSelect,
    focusLabel: 'Voice Options',
    phaseLabel: 'Post-Paywall',
  ),
  TutorialStep(
    title: 'Tap "Start Recording"',
    body:
        'Read the passage aloud 3 times, slowly and clearly. Recording auto-completes at 30 seconds.',
    visualType: TutorialVisualType.voiceRecord,
    focusLabel: 'Start Recording',
    phaseLabel: 'Post-Paywall',
  ),
  TutorialStep(
    title: 'Tap "Create Clone Voice"',
    body:
        'Your recording is ready. Tap the gold button to create your custom voice. Takes 30 to 45 seconds.',
    visualType: TutorialVisualType.voiceClone,
    focusLabel: 'Clone Button',
    phaseLabel: 'Post-Paywall',
  ),
  TutorialStep(
    title: "It's Already Done",
    body:
        'Your voice is ready. Every manifestation will now be narrated in your own voice. Welcome home.',
    visualType: TutorialVisualType.voiceReady,
    focusLabel: 'Voice Ready',
    phaseLabel: 'Post-Paywall',
  ),
];
