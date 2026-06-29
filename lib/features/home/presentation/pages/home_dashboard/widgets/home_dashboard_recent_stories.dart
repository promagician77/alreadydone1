import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/features/home/presentation/pages/home_dashboard/home_dashboard_colors.dart';
import '/features/home/presentation/pages/home_dashboard/home_dashboard_story_utils.dart';
import '/shared/widgets/pressable.dart';

class HomeDashboardRecentStories extends StatelessWidget {
  const HomeDashboardRecentStories({
    super.key,
    required this.stories,
    required this.durationCache,
    required this.onStoryTap,
  });

  final List<Map<String, dynamic>> stories;
  final Map<int, int> durationCache;
  final void Function(Map<String, dynamic> story) onStoryTap;

  static final List<Color> _iconBackgrounds = [
    HomeDashboardColors.blushLight,
    HomeDashboardColors.goldPale,
    HomeDashboardColors.tealLight,
  ];

  @override
  Widget build(BuildContext context) {
    if (stories.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'No recent stories yet.',
          style: GoogleFonts.outfit(
            fontSize: 13,
            color: HomeDashboardColors.inkSoft,
          ),
        ),
      );
    }

    return Column(
      children: List.generate(stories.length, (i) {
        final story = stories[i];
        final name = (story['theme'] ??
                story['title'] ??
                story['desire_name'] ??
                'Story')
            .toString();
        final duration = HomeDashboardStoryUtils.durationFromStory(
          story,
          durationCache,
        );
        final meta = '· $duration';
        final iconBg = _iconBackgrounds[i % _iconBackgrounds.length];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Pressable(
            onTap: () => onStoryTap(story),
            borderRadius: BorderRadius.circular(12),
            child: HomeDashboardStoryListItem(
              name: name,
              meta: meta,
              iconBg: iconBg,
            ),
          ),
        );
      }),
    );
  }
}

class HomeDashboardStoryListItem extends StatelessWidget {
  const HomeDashboardStoryListItem({
    super.key,
    required this.name,
    required this.meta,
    required this.iconBg,
  });

  final String name;
  final String meta;
  final Color iconBg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: HomeDashboardColors.surface,
        border: Border.all(color: HomeDashboardColors.stone),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                '✓',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: HomeDashboardColors.ink,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: HomeDashboardColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  meta,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: HomeDashboardColors.inkSoft,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: HomeDashboardColors.warmWhite,
              border: Border.all(color: HomeDashboardColors.stone),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.play_arrow,
              size: 16,
              color: HomeDashboardColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}
