import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/features/profile/presentation/pages/profile/profile_colors.dart';
import '/features/profile/presentation/pages/profile/widgets/profile_setting_item.dart';

class ProfileRemindersSection extends StatelessWidget {
  const ProfileRemindersSection({
    super.key,
    required this.morningEnabled,
    required this.bedtimeEnabled,
    required this.morningTimeLabel,
    required this.bedtimeTimeLabel,
    required this.onMorningChanged,
    required this.onBedtimeChanged,
    required this.onMorningTimeTap,
    required this.onBedtimeTimeTap,
  });

  final bool morningEnabled;
  final bool bedtimeEnabled;
  final String morningTimeLabel;
  final String bedtimeTimeLabel;
  final ValueChanged<bool> onMorningChanged;
  final ValueChanged<bool> onBedtimeChanged;
  final VoidCallback onMorningTimeTap;
  final VoidCallback onBedtimeTimeTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'REMINDERS',
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: ProfileColors.inkMid,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 10),
        ProfileSettingToggle(
          label: 'Morning Reminder',
          value: morningEnabled,
          onChanged: onMorningChanged,
        ),
        if (morningEnabled) ...[
          const SizedBox(height: 8),
          ProfileSettingItem(
            label: 'Morning Time',
            value: morningTimeLabel,
            subtitle: 'Daily story notification',
            onTap: onMorningTimeTap,
          ),
        ],
        const SizedBox(height: 8),
        ProfileSettingToggle(
          label: 'Bedtime Reminder',
          value: bedtimeEnabled,
          onChanged: onBedtimeChanged,
        ),
        if (bedtimeEnabled) ...[
          const SizedBox(height: 8),
          ProfileSettingItem(
            label: 'Bedtime Time',
            value: bedtimeTimeLabel,
            subtitle: 'Evening reflection prompt',
            onTap: onBedtimeTimeTap,
          ),
        ],
      ],
    );
  }
}
