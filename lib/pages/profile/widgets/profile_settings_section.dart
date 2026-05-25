import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/pages/profile/profile_colors.dart';
import '/widgets/pressable.dart';

typedef ProfileSettingItem = (String label, String value, VoidCallback? onTap);

class ProfileSettingsSection extends StatelessWidget {
  const ProfileSettingsSection({
    super.key,
    required this.title,
    required this.items,
  });

  final String title;
  final List<ProfileSettingItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: ProfileColors.inkMid,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 14),
        ...items.asMap().entries.map((e) {
          final (label, value, onTap) = e.value;
          final isLast = e.key == items.length - 1;
          return Column(
            children: [
              Pressable(
                onTap: onTap,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: ProfileColors.surface,
                    border: Border.all(color: ProfileColors.stone),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        label,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: ProfileColors.ink,
                        ),
                      ),
                      Text(
                        value,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: ProfileColors.inkSoft,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (!isLast) const SizedBox(height: 8),
            ],
          );
        }),
      ],
    );
  }
}
