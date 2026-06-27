import 'dart:math' as math;

import 'package:flutter/material.dart';

import '/features/home/presentation/pages/home_dashboard/home_dashboard_colors.dart';

/// Animated waveform bars; [visibleCount] bars render in gold (playback progress).
class HomeDashboardProgressWaveform extends StatelessWidget {
  const HomeDashboardProgressWaveform({
    super.key,
    required this.visibleCount,
    required this.totalBars,
    required this.waveController,
    this.isAnimated = false,
  });

  final int visibleCount;
  final int totalBars;
  final AnimationController waveController;
  final bool isAnimated;

  static const int defaultTotalBars = 56;

  @override
  Widget build(BuildContext context) {
    const heights = [8.0, 20.0, 32.0, 16.0, 36.0, 12.0, 28.0, 24.0, 14.0, 30.0];
    return AnimatedBuilder(
      animation: waveController,
      builder: (context, _) {
        final t = waveController.value * 2 * math.pi;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(totalBars, (i) {
            final isPlayed = i < visibleCount;
            final s1 = (math.sin(t + i * 0.4) + 1) / 2;
            final s2 = (math.sin(t * 1.3 + i * 0.6) + 1) / 2;
            final baseH = heights[i % heights.length];
            final h = baseH * 0.6 + baseH * 0.4 * s1 + 4.0 * s2;
            return Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 0.5),
                child: Container(
                  width: double.infinity,
                  height: h.clamp(6.0, 34.0),
                  decoration: BoxDecoration(
                    gradient: isPlayed
                        ? const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              HomeDashboardColors.goldLight,
                              HomeDashboardColors.gold,
                              HomeDashboardColors.goldDark,
                            ],
                            stops: [0.0, 0.55, 1.0],
                          )
                        : null,
                    color: isPlayed
                        ? null
                        : (isAnimated && visibleCount == 0
                            ? HomeDashboardColors.stone.withValues(alpha: 0.9)
                            : HomeDashboardColors.stone),
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: isPlayed
                        ? [
                            BoxShadow(
                              color: HomeDashboardColors.gold
                                  .withValues(alpha: 0.22),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
