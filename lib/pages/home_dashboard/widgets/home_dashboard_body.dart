import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/pages/home_dashboard/home_dashboard_colors.dart';
import '/pages/home_dashboard/widgets/home_dashboard_add_manifestation_button.dart';
import '/pages/home_dashboard/widgets/home_dashboard_desire_chips.dart';
import '/pages/home_dashboard/widgets/home_dashboard_recent_stories.dart';
import '/pages/home_dashboard/widgets/home_dashboard_sleep_card.dart';
import '/pages/home_dashboard/widgets/home_dashboard_story_card.dart';

/// Scrollable home dashboard content below the hero.
class HomeDashboardBody extends StatelessWidget {
  const HomeDashboardBody({
    super.key,
    required this.storiesLoading,
    required this.lastPlayedStory,
    required this.lastPlayedCategoryLabel,
    required this.lastPlayedTitle,
    required this.lastPlayedDurationLabel,
    required this.lastPlayedIsPlaying,
    required this.lastPlayedIsPlayingStory,
    required this.onLastPlayedTap,
    required this.profileSubscriptionReady,
    required this.subscriptionStatusLoaded,
    required this.isSubscribed,
    required this.rcSubscriptionStatus,
    required this.onUnlockSleepMode,
    required this.desires,
    required this.stories,
    required this.selectedDesireFilter,
    required this.onDesireFilterChanged,
    required this.addManifestationButtonKey,
    required this.onAddManifestation,
    required this.showNewManifestationCoachmark,
    required this.manifestCoachPulseController,
    required this.recentStories,
    required this.onRecentStoryTap,
    required this.durationCache,
    required this.playbackPosition,
    required this.playbackDuration,
    required this.idleWaveController,
  });

  final bool storiesLoading;
  final Map<String, dynamic>? lastPlayedStory;
  final String lastPlayedCategoryLabel;
  final String lastPlayedTitle;
  final String lastPlayedDurationLabel;
  final bool lastPlayedIsPlaying;
  final bool lastPlayedIsPlayingStory;
  final VoidCallback onLastPlayedTap;
  final bool profileSubscriptionReady;
  final bool subscriptionStatusLoaded;
  final bool isSubscribed;
  final String? rcSubscriptionStatus;
  final VoidCallback onUnlockSleepMode;
  final List<Map<String, dynamic>> desires;
  final List<Map<String, dynamic>> stories;
  final String? selectedDesireFilter;
  final ValueChanged<String?> onDesireFilterChanged;
  final GlobalKey addManifestationButtonKey;
  final VoidCallback onAddManifestation;
  final bool showNewManifestationCoachmark;
  final AnimationController manifestCoachPulseController;
  final List<Map<String, dynamic>> recentStories;
  final void Function(Map<String, dynamic> story) onRecentStoryTap;
  final Map<int, int> durationCache;
  final Duration playbackPosition;
  final Duration playbackDuration;
  final AnimationController idleWaveController;

  bool get _showSleepCard {
    return profileSubscriptionReady &&
        subscriptionStatusLoaded &&
        !isSubscribed &&
        rcSubscriptionStatus != 'active' &&
        rcSubscriptionStatus != 'trial';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 24, 20, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (storiesLoading)
            const HomeDashboardStoryCardLoading()
          else
            HomeDashboardStoryCard(
              story: lastPlayedStory,
              categoryLabel: lastPlayedCategoryLabel,
              title: lastPlayedTitle,
              durationLabel: lastPlayedDurationLabel,
              isPlaying: lastPlayedIsPlaying,
              isPlayingStory: lastPlayedIsPlayingStory,
              onTap: onLastPlayedTap,
              playbackPosition: playbackPosition,
              playbackDuration: playbackDuration,
              waveController: idleWaveController,
            ),
          const SizedBox(height: 16),
          if (!profileSubscriptionReady || !subscriptionStatusLoaded)
            const HomeDashboardSleepCardLoading()
          else if (_showSleepCard) ...[
            HomeDashboardSleepCard(onUnlockTap: onUnlockSleepMode),
            const SizedBox(height: 20),
          ],
          Text(
            'Your Manifestations',
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: HomeDashboardColors.inkMid,
            ),
          ),
          const SizedBox(height: 12),
          HomeDashboardDesireChips(
            desires: desires,
            stories: stories,
            selectedDesireFilter: selectedDesireFilter,
            onFilterChanged: onDesireFilterChanged,
          ),
          const SizedBox(height: 20),
          HomeDashboardAddManifestationButton(
            buttonKey: addManifestationButtonKey,
            onTap: onAddManifestation,
            showCoachmark: showNewManifestationCoachmark,
            pulseController: manifestCoachPulseController,
          ),
          const SizedBox(height: 20),
          Text(
            'Recent Stories',
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: HomeDashboardColors.inkMid,
            ),
          ),
          const SizedBox(height: 12),
          HomeDashboardRecentStories(
            stories: recentStories,
            durationCache: durationCache,
            onStoryTap: onRecentStoryTap,
          ),
        ],
      ),
    );
  }
}
