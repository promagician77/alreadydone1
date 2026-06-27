import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/features/player/presentation/pages/player/player_colors.dart';

class PlayerSleepInfo extends StatelessWidget {
  const PlayerSleepInfo({
    super.key,
    required this.speedLabel,
    required this.timerText,
  });

  final String speedLabel;
  final String timerText;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: PlayerColors.sleepPurple.withValues(alpha: 0.2),
        border: Border.all(
          color: PlayerColors.sleepPurple.withValues(alpha: 0.3),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _SleepInfoItem(label: 'Speed', value: speedLabel, valueIsGold: false),
          const _SleepInfoItem(label: 'Loop', value: 'On', valueIsGold: false),
          _SleepInfoItem(label: 'Timer', value: timerText, valueIsGold: true),
        ],
      ),
    );
  }
}

class _SleepInfoItem extends StatelessWidget {
  const _SleepInfoItem({
    required this.label,
    required this.value,
    required this.valueIsGold,
  });

  final String label;
  final String value;
  final bool valueIsGold;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.outfit(
            fontSize: 10,
            color: Colors.white.withValues(alpha: 0.5),
            fontWeight: FontWeight.w500,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: valueIsGold
                ? PlayerColors.goldLight
                : Colors.white.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }
}
