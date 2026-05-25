import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/pages/profile/profile_colors.dart';
import '/widgets/pressable.dart';

class ProfileSettingToggle extends StatelessWidget {
  const ProfileSettingToggle({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: ProfileColors.gold,
            activeThumbColor: Colors.white,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: ProfileColors.stoneMid,
          ),
        ],
      ),
    );
  }
}

class ProfileSettingItem extends StatelessWidget {
  const ProfileSettingItem({
    super.key,
    required this.label,
    required this.value,
    this.subtitle,
    this.onTap,
  });

  final String label;
  final String value;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: ProfileColors.ink,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle!,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: ProfileColors.inkSoft,
                ),
              ),
            ],
          ],
        ),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 12,
            color: ProfileColors.inkSoft,
          ),
        ),
      ],
    );
    final child = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ProfileColors.surface,
        border: Border.all(color: ProfileColors.stone),
        borderRadius: BorderRadius.circular(12),
      ),
      child: content,
    );
    if (onTap != null) {
      return Pressable(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: child,
      );
    }
    return child;
  }
}
