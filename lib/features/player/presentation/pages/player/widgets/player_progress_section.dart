import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/features/player/presentation/pages/player/player_colors.dart';

class PlayerProgressSection extends StatelessWidget {
  const PlayerProgressSection({
    super.key,
    required this.sleepModeActive,
    required this.position,
    required this.effectiveDuration,
    required this.formatDuration,
    required this.audioPlayer,
  });

  final bool sleepModeActive;
  final Duration position;
  final Duration effectiveDuration;
  final String Function(int seconds) formatDuration;
  final AudioPlayer audioPlayer;

  @override
  Widget build(BuildContext context) {
    final durMs = effectiveDuration.inMilliseconds;
    final posMs = position.inMilliseconds;
    final progress = durMs > 0 ? (posMs / durMs).clamp(0.0, 1.0) : 0.0;
    final textColor = sleepModeActive
        ? Colors.white.withValues(alpha: 0.6)
        : PlayerColors.inkSoft;
    final trackColor = sleepModeActive
        ? Colors.white.withValues(alpha: 0.2)
        : PlayerColors.stone;

    return Padding(
      padding: EdgeInsets.only(bottom: sleepModeActive ? 20 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formatDuration(position.inSeconds),
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                Text(
                  formatDuration(effectiveDuration.inSeconds),
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          LayoutBuilder(
            builder: (_, constraints) {
              final barWidth = constraints.maxWidth;
              return GestureDetector(
                onTapDown: durMs > 0 && barWidth > 0
                    ? (d) {
                        final rel = (d.localPosition.dx / barWidth)
                            .clamp(0.0, 1.0);
                        audioPlayer.seek(
                          Duration(milliseconds: (rel * durMs).round()),
                        );
                      }
                    : null,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: trackColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: progress,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: sleepModeActive
                              ? const LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                    PlayerColors.goldLight,
                                    PlayerColors.gold,
                                    PlayerColors.sleepPurple,
                                  ],
                                  stops: [0.0, 0.5, 1.0],
                                )
                              : null,
                          color: sleepModeActive ? null : PlayerColors.gold,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
