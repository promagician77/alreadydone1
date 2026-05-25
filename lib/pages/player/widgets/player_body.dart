import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '/pages/player/player_constants.dart';
import '/pages/player/player_story_utils.dart';
import '/pages/player/widgets/player_controls.dart';
import '/pages/player/widgets/player_deepen_button.dart';
import '/pages/player/widgets/player_header.dart';
import '/pages/player/widgets/player_progress_section.dart';
import '/pages/player/widgets/player_sleep_info.dart';
import '/pages/player/widgets/player_story_preview.dart';
import '/pages/player/widgets/player_waveform.dart';

/// Scrollable player content: header, waveform, progress, controls, deepen, preview.
class PlayerBody extends StatelessWidget {
  const PlayerBody({
    super.key,
    required this.settingsButtonKey,
    required this.sleepModeActive,
    required this.categoryHeaderLine,
    required this.title,
    required this.durationLabel,
    required this.subtitle,
    required this.voiceLabel,
    required this.isGeneratingVoice,
    required this.showSettingsCoachmark,
    required this.waveformController,
    required this.onSettingsTap,
    required this.position,
    required this.effectiveDuration,
    required this.isPlaying,
    required this.hasUrl,
    required this.canSkipStory,
    required this.audioPlayer,
    required this.onTogglePlayPause,
    required this.onSkipBackward,
    required this.onSkipForward,
    required this.onSkipToPreviousStory,
    required this.onSkipToNextStory,
    required this.sleepSpeedLabel,
    required this.sleepTimerText,
    required this.isDeepening,
    required this.onDeepenTap,
    required this.storyPreviewText,
  });

  final GlobalKey settingsButtonKey;
  final bool sleepModeActive;
  final String categoryHeaderLine;
  final String title;
  final String? durationLabel;
  final String? subtitle;
  final String voiceLabel;
  final bool isGeneratingVoice;
  final bool showSettingsCoachmark;
  final AnimationController waveformController;
  final VoidCallback onSettingsTap;
  final Duration position;
  final Duration effectiveDuration;
  final bool isPlaying;
  final bool hasUrl;
  final bool canSkipStory;
  final AudioPlayer audioPlayer;
  final VoidCallback? onTogglePlayPause;
  final VoidCallback? onSkipBackward;
  final VoidCallback? onSkipForward;
  final VoidCallback? onSkipToPreviousStory;
  final VoidCallback? onSkipToNextStory;
  final String sleepSpeedLabel;
  final String sleepTimerText;
  final bool isDeepening;
  final VoidCallback? onDeepenTap;
  final String storyPreviewText;

  @override
  Widget build(BuildContext context) {
    final durationText = effectiveDuration.inSeconds > 0
        ? PlayerStoryUtils.formatDuration(effectiveDuration.inSeconds)
        : (durationLabel ?? '0:00');

    final visibleBars = sleepModeActive
        ? (effectiveDuration.inMilliseconds > 0
            ? ((position.inMilliseconds /
                        effectiveDuration.inMilliseconds) *
                    9)
                .round()
                .clamp(0, 9)
            : 0)
        : PlayerStoryUtils.visibleWaveBars(
            position: position,
            effectiveDuration: effectiveDuration,
            totalBars: PlayerConstants.totalWaveBars,
          );

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 80),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PlayerHeader(
            settingsButtonKey: settingsButtonKey,
            sleepModeActive: sleepModeActive,
            categoryHeaderLine: categoryHeaderLine,
            title: title,
            durationText: durationText,
            voiceLabel: voiceLabel,
            durationLabel: durationLabel,
            subtitle: subtitle,
            isGeneratingVoice: isGeneratingVoice,
            showSettingsCoachmark: showSettingsCoachmark,
            waveformController: waveformController,
            onSettingsTap: onSettingsTap,
          ),
          PlayerWaveform(
            sleepModeActive: sleepModeActive,
            visibleBars: visibleBars,
            waveformController: waveformController,
          ),
          if (sleepModeActive)
            PlayerSleepInfo(
              speedLabel: sleepSpeedLabel,
              timerText: sleepTimerText,
            ),
          PlayerProgressSection(
            sleepModeActive: sleepModeActive,
            position: position,
            effectiveDuration: effectiveDuration,
            formatDuration: PlayerStoryUtils.formatDuration,
            audioPlayer: audioPlayer,
          ),
          PlayerControls(
            sleepModeActive: sleepModeActive,
            isPlaying: isPlaying,
            hasUrl: hasUrl,
            canSkipStory: canSkipStory,
            onTogglePlayPause: onTogglePlayPause,
            onSkipBackward: onSkipBackward,
            onSkipForward: onSkipForward,
            onSkipToPreviousStory: onSkipToPreviousStory,
            onSkipToNextStory: onSkipToNextStory,
          ),
          SizedBox(height: sleepModeActive ? 0 : 28),
          if (!sleepModeActive)
            PlayerDeepenButton(
              isDisabled: isDeepening,
              onTap: onDeepenTap,
            ),
          if (!sleepModeActive) PlayerStoryPreview(storyText: storyPreviewText),
        ],
      ),
    );
  }
}
