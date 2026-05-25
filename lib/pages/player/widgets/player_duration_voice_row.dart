import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/pages/player/player_colors.dart';

class PlayerDurationVoiceRow extends StatelessWidget {
  const PlayerDurationVoiceRow({
    super.key,
    required this.durationText,
    required this.voiceLabel,
    required this.isGeneratingVoice,
  });

  final String durationText;
  final String voiceLabel;
  final bool isGeneratingVoice;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          '$durationText · $voiceLabel',
          style: GoogleFonts.outfit(
            fontSize: 12,
            color: PlayerColors.inkSoft,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (isGeneratingVoice) ...[
          const SizedBox(width: 8),
          const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: PlayerColors.gold,
            ),
          ),
        ],
      ],
    );
  }
}
