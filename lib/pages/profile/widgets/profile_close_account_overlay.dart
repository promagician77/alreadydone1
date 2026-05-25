import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/pages/profile/profile_colors.dart';

class ProfileCloseAccountOverlay extends StatelessWidget {
  const ProfileCloseAccountOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: AbsorbPointer(
        child: Material(
          color: Colors.black.withValues(alpha: 0.45),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: ProfileColors.gold),
                const SizedBox(height: 16),
                Text(
                  'Closing your account…',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
