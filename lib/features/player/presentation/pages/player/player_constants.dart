/// Shared constants for the player screen.
abstract final class PlayerConstants {
  static const settingsCoachmarkKeyPrefix = 'player_settings_coachmark_v1_';
  static const doneLibraryCoachmarkKeyPrefix =
      'player_done_library_coachmark_v1_';

  static const voiceDropdownMyVoice = 'my_voice';

  static const presetVoices = [
    ('QuCIJW2VbXkVSkVMP2V9', 'Chris'),
    ('8yh4Wuya1OlwcUp0epGF', 'David'),
    ('tJHJUEHzOkMoPmJJ5jo2', 'Alex'),
    ('KGZeK6FsnWQdrkDHnDNA', 'Sarah'),
    ('NXqsj0QYxuanzBw3KwjB', 'Maya'),
    ('VlQRLHkc5IdFj7o0atT1', 'Luna'),
  ];

  static const thetaTracks = [
    ('Healing Therapy', 'audios/theta/Healing Therapy.mp3'),
    ('The City in Dreams', 'audios/theta/The City in Dreams.mp3'),
    ('Solar Drift', 'audios/theta/Solar Drift.mp3'),
    ('Boyar', 'audios/theta/Boyar.mp3'),
    ('Mantle', 'audios/theta/Mantle.mp3'),
    ('Reflection', 'audios/theta/Reflection.mp3'),
    ('Healing Spheres', 'audios/theta/Healing Spheres.mp3'),
    ('Neptune', 'audios/theta/Neptune.mp3'),
  ];

  static const speedOptions = [0.5, 0.75, 1.0];

  static const totalWaveBars = 32;
  static const skipSeconds = 10;

  static const sleepVolumeTarget = 0.7;
  static const thetaVolumeTarget = 0.2;
  static const sleepVolumeFadeInSeconds = 120;
  static const sleepFadeOutSeconds = 60;
  static const sleepBrightness = 0.4;

  static const sleepModeAllowedStatuses = ['trial', 'active'];
  static const sleepModeAllowedPlans = ['monthly', 'weekly', 'annual'];

  static const barHeights = [
    12.0, 24.0, 36.0, 20.0, 44.0, 32.0, 16.0, 28.0, 36.0, 24.0, 40.0,
    28.0, 16.0, 32.0, 20.0, 12.0,
  ];

  static const sleepBarHeights = [
    10.0, 18.0, 28.0, 36.0, 40.0, 36.0, 24.0, 16.0, 8.0,
  ];
}
