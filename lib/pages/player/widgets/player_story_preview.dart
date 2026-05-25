import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/pages/player/player_colors.dart';

class PlayerStoryPreview extends StatelessWidget {
  const PlayerStoryPreview({
    super.key,
    required this.storyText,
  });

  final String storyText;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: PlayerColors.warmWhite,
        border: Border.all(color: PlayerColors.stone),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'STORY PREVIEW',
            style: GoogleFonts.outfit(
              fontSize: 10,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w600,
              color: PlayerColors.blush,
            ),
          ),
          const SizedBox(height: 10),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.45,
            ),
            child: SingleChildScrollView(
              child: Text(
                storyText,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: PlayerColors.inkMid,
                  height: 1.6,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
