import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/pages/player/player_colors.dart';

class PlayerBlockingOverlay extends StatelessWidget {
  const PlayerBlockingOverlay({
    super.key,
    required this.message,
    required this.hint,
  });

  final String message;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: PlayerColors.surface.withValues(alpha: 0.85),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: PlayerColors.gold),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  message,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: PlayerColors.ink,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Text(
                  hint,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: PlayerColors.ink,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
