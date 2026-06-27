import 'dart:math' as math;

import 'package:flutter/material.dart';

import '/features/player/presentation/pages/player/player_colors.dart';
import '/features/player/presentation/pages/player/player_constants.dart';

class PlayerWaveform extends StatelessWidget {
  const PlayerWaveform({
    super.key,
    required this.sleepModeActive,
    required this.visibleBars,
    required this.waveformController,
  });

  final bool sleepModeActive;
  final int visibleBars;
  final AnimationController waveformController;

  @override
  Widget build(BuildContext context) {
    final barCount = sleepModeActive ? 9 : PlayerConstants.totalWaveBars;
    final heights = sleepModeActive
        ? PlayerConstants.sleepBarHeights
        : PlayerConstants.barHeights;

    Widget waveRow;
    if (sleepModeActive) {
      waveRow = AnimatedBuilder(
        animation: waveformController,
        builder: (context, _) {
          final t = waveformController.value * 2 * math.pi;
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(barCount, (i) {
              final isPlayed = i < visibleBars;
              final baseH = heights[i % heights.length];
              final h = baseH * (0.55 + 0.45 * math.sin(t + i * math.pi / 4));
              return Padding(
                padding: EdgeInsets.only(right: i < barCount - 1 ? 3 : 0),
                child: Container(
                  width: 6,
                  height: h,
                  decoration: BoxDecoration(
                    gradient: isPlayed
                        ? const LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              PlayerColors.goldLight,
                              PlayerColors.gold,
                              PlayerColors.sleepPurple,
                              PlayerColors.sleepBlue,
                            ],
                            stops: [0.0, 0.35, 0.7, 1.0],
                          )
                        : null,
                    color: isPlayed
                        ? null
                        : Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: isPlayed
                        ? [
                            BoxShadow(
                              color: PlayerColors.sleepPurple
                                  .withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                ),
              );
            }),
          );
        },
      );
    } else {
      waveRow = AnimatedBuilder(
        animation: waveformController,
        builder: (context, _) {
          final t = waveformController.value * 2 * math.pi;
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(barCount, (i) {
              final isPlayed = i < visibleBars;
              final baseH = heights[i % heights.length];
              final mult = (0.55 + 0.45 * math.sin(t + i * math.pi / 4))
                  .clamp(0.2, 1.0);
              final h = baseH * mult;
              return Padding(
                padding: EdgeInsets.only(right: i < barCount - 1 ? 3 : 0),
                child: Container(
                  width: 6,
                  height: h,
                  decoration: BoxDecoration(
                    gradient: isPlayed
                        ? const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              PlayerColors.goldLight,
                              PlayerColors.gold,
                              PlayerColors.goldDark,
                            ],
                            stops: [0.0, 0.5, 1.0],
                          )
                        : null,
                    color: isPlayed ? null : PlayerColors.stone,
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: isPlayed
                        ? [
                            BoxShadow(
                              color: PlayerColors.gold.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                ),
              );
            }),
          );
        },
      );
    }

    return Padding(
      padding: sleepModeActive
          ? const EdgeInsets.fromLTRB(0, 24, 0, 16)
          : const EdgeInsets.fromLTRB(0, 48, 0, 48 + 24),
      child: SizedBox(
        height: 56,
        child: Center(child: waveRow),
      ),
    );
  }
}
