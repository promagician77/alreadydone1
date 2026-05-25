import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/pages/auth/auth_theme.dart';

class TutorialSectionDivider extends StatelessWidget {
  const TutorialSectionDivider({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: AuthTheme.stone,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
              color: AuthTheme.inkSoft,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: AuthTheme.stone,
          ),
        ),
      ],
    );
  }
}

class TutorialVoiceOption extends StatelessWidget {
  const TutorialVoiceOption({
    super.key,
    required this.name,
    required this.description,
    this.selected = false,
    this.badge,
    this.isMyVoice = false,
  });

  final String name;
  final String description;
  final bool selected;
  final String? badge;
  final bool isMyVoice;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        gradient: isMyVoice
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AuthTheme.goldPale, AuthTheme.warmWhite],
              )
            : null,
        color: isMyVoice
            ? null
            : (selected ? AuthTheme.goldPale : AuthTheme.surface),
        borderRadius: BorderRadius.circular(isMyVoice ? 16 : 12),
        border: Border.all(
          color: selected
              ? AuthTheme.gold
              : (isMyVoice ? AuthTheme.goldLight : AuthTheme.stone),
          width: isMyVoice ? 2 : 1.5,
        ),
        boxShadow: selected && isMyVoice
            ? [
                BoxShadow(
                  color: AuthTheme.ink.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? AuthTheme.gold : AuthTheme.stoneMid,
                width: 1.6,
              ),
            ),
            child: selected
                ? Center(
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AuthTheme.gold,
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.outfit(
                        fontSize: isMyVoice ? 16 : 14,
                        fontWeight: FontWeight.w600,
                        color: AuthTheme.ink,
                      ),
                    ),
                    if (badge != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AuthTheme.gold,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badge!,
                          style: GoogleFonts.outfit(
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.7,
                            color: AuthTheme.surface,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: GoogleFonts.outfit(
                    fontSize: isMyVoice ? 12 : 11,
                    height: 1.35,
                    color: AuthTheme.inkSoft,
                  ),
                ),
              ],
            ),
          ),
          if (!selected) ...[
            const SizedBox(width: 8),
            const Icon(Icons.play_arrow_rounded,
                size: 20, color: AuthTheme.ink),
          ],
        ],
      ),
    );
  }
}

class TutorialInfoBanner extends StatelessWidget {
  const TutorialInfoBanner({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F0E0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x805A8A4A)),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          height: 1.4,
          color: const Color(0xFF5A8A4A),
        ),
      ),
    );
  }
}

class TutorialNextStepCard extends StatelessWidget {
  const TutorialNextStepCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AuthTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AuthTheme.stone),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                color: AuthTheme.gold,
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                'What happens next?',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AuthTheme.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            "Tap 'Create Clone Voice' to generate your manifestation story. Takes 30 to 45 seconds.",
            style: GoogleFonts.outfit(
              fontSize: 11,
              height: 1.4,
              color: AuthTheme.inkSoft,
            ),
          ),
        ],
      ),
    );
  }
}

class TutorialSmallActionButton extends StatelessWidget {
  const TutorialSmallActionButton({
    super.key,
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
      decoration: BoxDecoration(
        color: AuthTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AuthTheme.stone),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: AuthTheme.ink),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AuthTheme.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
