import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/features/home/presentation/pages/home_dashboard/home_dashboard_colors.dart';
import '/features/home/presentation/pages/home_dashboard/widgets/home_dashboard_progress_waveform.dart';
import '/widgets/pressable.dart';

class HomeDashboardStoryCardLoading extends StatelessWidget {
  const HomeDashboardStoryCardLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: HomeDashboardColors.surface,
        border: Border.all(color: HomeDashboardColors.stone),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: HomeDashboardColors.gold),
      ),
    );
  }
}

class HomeDashboardStoryCard extends StatelessWidget {
  const HomeDashboardStoryCard({
    super.key,
    required this.categoryLabel,
    required this.title,
    required this.durationLabel,
    required this.isPlaying,
    required this.onTap,
    required this.waveController,
    this.story,
    this.isPlayingStory = false,
    this.playbackPosition = Duration.zero,
    this.playbackDuration = Duration.zero,
  });

  final Map<String, dynamic>? story;
  final String categoryLabel;
  final String title;
  final String durationLabel;
  final bool isPlaying;
  final VoidCallback onTap;
  final bool isPlayingStory;
  final Duration playbackPosition;
  final Duration playbackDuration;
  final AnimationController waveController;

  @override
  Widget build(BuildContext context) {
    final pos = playbackPosition.inMilliseconds;
    final dur = playbackDuration.inMilliseconds;
    const totalBars = HomeDashboardProgressWaveform.defaultTotalBars;
    final visibleBars = (dur > 0 && isPlayingStory)
        ? ((pos / dur) * totalBars).round().clamp(0, totalBars)
        : 0;

    return Container(
      decoration: BoxDecoration(
        color: HomeDashboardColors.surface,
        border: Border.all(color: HomeDashboardColors.stone),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: HomeDashboardColors.ink.withOpacity(0.06),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              categoryLabel.toUpperCase(),
              style: GoogleFonts.outfit(
                fontSize: 10,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w600,
                color: HomeDashboardColors.blush,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.cormorantGaramond(
                fontSize: 20,
                fontWeight: FontWeight.w400,
                color: HomeDashboardColors.ink,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: HomeDashboardColors.warmWhite,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: HomeDashboardProgressWaveform(
                      visibleCount: visibleBars,
                      totalBars: totalBars,
                      waveController: waveController,
                      isAnimated: !isPlayingStory,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Pressable(
              onTap: story != null ? onTap : null,
              borderRadius: BorderRadius.circular(10),
              splashColor: Colors.white.withValues(alpha: 0.3),
              highlightColor: Colors.white.withValues(alpha: 0.15),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: HomeDashboardColors.gold,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isPlaying ? Icons.pause : Icons.play_arrow,
                      color: HomeDashboardColors.surface,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isPlaying ? 'Pause' : 'Play Story · $durationLabel',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: HomeDashboardColors.surface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
