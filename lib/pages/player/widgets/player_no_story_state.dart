import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/flutter_flow/nav/nav.dart';
import '/index.dart';
import '/pages/player/player_colors.dart';

class PlayerNoStoryState extends StatelessWidget {
  const PlayerNoStoryState({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.headset_outlined,
              size: 64,
              color: PlayerColors.inkSoft.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 20),
            Text(
              'No story',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 26,
                fontWeight: FontWeight.w500,
                color: PlayerColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a story from Desires or Home\nto listen here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: PlayerColors.inkSoft,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            TextButton(
              onPressed: () => context.go(DesiresWidget.routePath),
              style: TextButton.styleFrom(
                backgroundColor: PlayerColors.gold,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Go to Desires',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
