import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/features/profile/presentation/pages/profile/profile_colors.dart';

class ProfileTopSection extends StatelessWidget {
  const ProfileTopSection({
    super.key,
    required this.displayName,
    required this.dreamLocation,
    required this.energyWord,
    required this.complete,
    required this.dayStreak,
    required this.active,
  });

  final String displayName;
  final String dreamLocation;
  final String energyWord;
  final String complete;
  final String dayStreak;
  final String active;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: ProfileColors.gold.withValues(alpha: 0.22),
              blurRadius: 32,
              offset: const Offset(0, 12),
            ),
            BoxShadow(
              color: ProfileColors.ink.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFFFFF9F3),
                        ProfileColors.goldPale,
                        const Color(0xFFF7ECD8),
                        ProfileColors.warmWhite,
                      ],
                      stops: const [0.0, 0.35, 0.72, 1.0],
                    ),
                  ),
                ),
              ),
              Positioned(
                right: -36,
                top: -44,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ProfileColors.gold.withValues(alpha: 0.14),
                  ),
                ),
              ),
              Positioned(
                left: -48,
                bottom: -28,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ProfileColors.surface.withValues(alpha: 0.85),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: 3,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        ProfileColors.gold.withValues(alpha: 0),
                        ProfileColors.gold.withValues(alpha: 0.55),
                        ProfileColors.gold.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      displayName,
                      style: GoogleFonts.outfit(
                        fontSize: 23,
                        fontWeight: FontWeight.w700,
                        color: ProfileColors.ink,
                        height: 1.15,
                        letterSpacing: -0.35,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ProfileMetaChip(
                          text: dreamLocation,
                          icon: Icons.location_on_outlined,
                        ),
                        ProfileMetaChip(
                          text: energyWord,
                          icon: Icons.bolt_rounded,
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      child: Divider(
                        height: 1,
                        thickness: 1,
                        color: Colors.white.withValues(alpha: 0.65),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(child: ProfileStatTile(value: complete, label: 'COMPLETE')),
                        const SizedBox(width: 10),
                        Expanded(child: ProfileStatTile(value: dayStreak, label: 'DAY STREAK')),
                        const SizedBox(width: 10),
                        Expanded(child: ProfileStatTile(value: active, label: 'ACTIVE')),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileMetaChip extends StatelessWidget {
  const ProfileMetaChip({super.key, required this.text, required this.icon});

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final display = text.trim().isEmpty ? '—' : text;
    return Container(
      constraints: const BoxConstraints(maxWidth: 220),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.95)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 15, color: ProfileColors.gold),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              display,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: ProfileColors.inkMid,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileStatTile extends StatelessWidget {
  const ProfileStatTile({super.key, required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
      decoration: BoxDecoration(
        color: ProfileColors.warmWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: ProfileColors.ink.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 23,
              fontWeight: FontWeight.w800,
              color: ProfileColors.gold,
              height: 1,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: GoogleFonts.outfit(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: ProfileColors.inkSoft,
              letterSpacing: 0.6,
              height: 1.15,
            ),
          ),
        ],
      ),
    );
  }
}
