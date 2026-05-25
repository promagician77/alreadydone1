import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/pages/home_dashboard/home_dashboard_colors.dart';
import '/pages/home_dashboard/home_dashboard_story_utils.dart';
import '/widgets/pressable.dart';

class HomeDashboardDesireChips extends StatelessWidget {
  const HomeDashboardDesireChips({
    super.key,
    required this.desires,
    required this.stories,
    required this.selectedDesireFilter,
    required this.onFilterChanged,
  });

  final List<Map<String, dynamic>> desires;
  final List<Map<String, dynamic>> stories;
  final String? selectedDesireFilter;
  final ValueChanged<String?> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    final selected = selectedDesireFilter;
    final chips = <(String, String?)>[
      ('All Stories', null),
      ...desires.map((d) {
        final name = (d['desireCategory'] ?? d['name'] ?? '').toString();
        return (name, name.isEmpty ? null : name);
      }),
    ].where((c) => c.$1.isNotEmpty).toList();

    if (chips.isEmpty) {
      chips.add(('All Stories', null));
    }

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final (label, desireName) = chips[i];
          final count = HomeDashboardStoryUtils.countByDesire(
            stories: stories,
            desireName: desireName,
          );
          final isSelected = selected == desireName;
          return Pressable(
            onTap: () => onFilterChanged(desireName),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? HomeDashboardColors.goldPale
                    : HomeDashboardColors.surface,
                border: Border.all(
                  color: isSelected
                      ? HomeDashboardColors.gold
                      : HomeDashboardColors.stone,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  '$label ($count)',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isSelected
                        ? HomeDashboardColors.gold
                        : HomeDashboardColors.inkSoft,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
