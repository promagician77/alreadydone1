import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/pages/player/coachmark/player_settings_coachmark.dart';
import '/pages/player/player_colors.dart';
import '/pages/player/widgets/player_duration_voice_row.dart';
import '/widgets/pressable.dart';

class PlayerHeader extends StatelessWidget {
  const PlayerHeader({
    super.key,
    required this.settingsButtonKey,
    required this.sleepModeActive,
    required this.categoryHeaderLine,
    required this.title,
    required this.durationText,
    required this.voiceLabel,
    required this.durationLabel,
    required this.subtitle,
    required this.isGeneratingVoice,
    required this.showSettingsCoachmark,
    required this.waveformController,
    required this.onSettingsTap,
  });

  final GlobalKey settingsButtonKey;
  final bool sleepModeActive;
  final String categoryHeaderLine;
  final String title;
  final String durationText;
  final String voiceLabel;
  final String? durationLabel;
  final String? subtitle;
  final bool isGeneratingVoice;
  final bool showSettingsCoachmark;
  final AnimationController waveformController;
  final VoidCallback onSettingsTap;

  @override
  Widget build(BuildContext context) {
    const settingsIconSize = 44.0;

    return Padding(
      padding: EdgeInsets.only(top: 24, bottom: sleepModeActive ? 16 : 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: sleepModeActive
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
              children: [
                if (sleepModeActive) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: PlayerColors.sleepPurple.withValues(alpha: 0.3),
                      border: Border.all(
                        color: PlayerColors.sleepPurple.withValues(alpha: 0.5),
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.nightlight_round,
                          size: 14,
                          color: PlayerColors.goldLight,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Sleep Mode Active',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Text(
                  categoryHeaderLine,
                  textAlign: sleepModeActive ? TextAlign.center : null,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w600,
                    color: sleepModeActive
                        ? Colors.white.withValues(alpha: 0.5)
                        : PlayerColors.blush,
                  ),
                ),
                SizedBox(height: sleepModeActive ? 8 : 12),
                Text(
                  title,
                  textAlign: sleepModeActive ? TextAlign.center : null,
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: sleepModeActive ? 20 : 32,
                    fontWeight: FontWeight.w400,
                    color: sleepModeActive
                        ? Colors.white.withValues(alpha: 0.9)
                        : PlayerColors.ink,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                if (sleepModeActive)
                  Text(
                    durationText.isNotEmpty
                        ? '$durationText · $voiceLabel'
                        : (durationLabel ??
                            subtitle ??
                            '$voiceLabel · Generated today'),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  )
                else
                  PlayerDurationVoiceRow(
                    durationText: durationText,
                    voiceLabel: voiceLabel,
                    isGeneratingVoice: isGeneratingVoice,
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4, right: 20),
            child: SizedBox(
              key: settingsButtonKey,
              width: settingsIconSize,
              height: settingsIconSize,
              child: Center(
                child: AnimatedBuilder(
                  animation: waveformController,
                  builder: (context, child) {
                    final isHighlighted =
                        showSettingsCoachmark && !sleepModeActive;
                    final t = waveformController.value * math.pi * 2;
                    final pulse = (math.sin(t) + 1) / 2;
                    final glowAlpha =
                        isHighlighted ? (0.22 + pulse * 0.18) : 0.0;
                    return Container(
                      decoration: BoxDecoration(
                        color: isHighlighted
                            ? PlayerSettingsCoachmarkTokens.bgCard
                            : Colors.transparent,
                        shape: BoxShape.circle,
                        boxShadow: isHighlighted
                            ? [
                                BoxShadow(
                                  color: PlayerColors.ink
                                      .withValues(alpha: 0.14),
                                  blurRadius: 18,
                                  offset: const Offset(0, 5),
                                ),
                                BoxShadow(
                                  color: PlayerColors.ink
                                      .withValues(alpha: 0.06),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                                BoxShadow(
                                  color: PlayerColors.gold
                                      .withValues(alpha: glowAlpha),
                                  blurRadius: 32,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                      child: child,
                    );
                  },
                  child: Pressable(
                    onTap: onSettingsTap,
                    borderRadius: BorderRadius.circular(999),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Icon(
                        Icons.settings,
                        size: 24,
                        color: sleepModeActive
                            ? Colors.white.withValues(alpha: 0.7)
                            : PlayerColors.ink,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
