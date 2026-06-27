import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/features/home/presentation/pages/home_dashboard/home_dashboard_colors.dart';
import '/features/home/presentation/pages/home_dashboard/home_dashboard_story_utils.dart';

class HomeDashboardHero extends StatelessWidget {
  const HomeDashboardHero({
    super.key,
    required this.userName,
    required this.dayStreak,
  });

  final String? userName;
  final int dayStreak;

  @override
  Widget build(BuildContext context) {
    final displayName = (userName ?? '').trim().isNotEmpty
        ? (userName ?? '').trim()
        : 'there';

    return Container(
      width: double.infinity,
      padding: const EdgeInsetsDirectional.fromSTEB(20, 28, 20, 28),
      decoration: const BoxDecoration(color: HomeDashboardColors.ink),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            HomeDashboardStoryUtils.greetingForHour(DateTime.now().hour),
            style: GoogleFonts.outfit(
              fontSize: 12,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w500,
              color: HomeDashboardColors.stone,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            displayName,
            style: GoogleFonts.cormorantGaramond(
              fontSize: 32,
              fontWeight: FontWeight.w300,
              color: HomeDashboardColors.warmWhite,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '✓',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: HomeDashboardColors.goldLight,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '$dayStreak-day streak',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: HomeDashboardColors.goldLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
