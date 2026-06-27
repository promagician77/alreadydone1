import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/features/player/presentation/pages/player/player_colors.dart';

class PlayerDeepenButton extends StatelessWidget {
  const PlayerDeepenButton({
    super.key,
    required this.isDisabled,
    required this.onTap,
  });

  final bool isDisabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isDisabled ? null : onTap,
          borderRadius: BorderRadius.circular(14),
          child: Opacity(
            opacity: isDisabled ? 0.7 : 1,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    PlayerColors.goldPale,
                    PlayerColors.surface,
                  ],
                ),
                border: Border.all(
                  color: PlayerColors.goldLight,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A1C1917),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '✨',
                    style: GoogleFonts.outfit(fontSize: 14),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Deepen This Manifestation',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: PlayerColors.goldDark,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '→',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: PlayerColors.goldDark,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
