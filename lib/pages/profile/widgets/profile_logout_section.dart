import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/pages/profile/profile_colors.dart';
import '/widgets/pressable.dart';

class ProfileLogoutSection extends StatelessWidget {
  const ProfileLogoutSection({
    super.key,
    required this.isClosingAccount,
    required this.onCloseAccount,
    required this.onLogout,
  });

  final bool isClosingAccount;
  final VoidCallback? onCloseAccount;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: ProfileColors.stone)),
            ),
            padding: const EdgeInsets.only(top: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Pressable(
                  onTap: isClosingAccount ? null : onCloseAccount,
                  borderRadius: BorderRadius.circular(12),
                  splashColor: ProfileColors.logoutRed.withValues(alpha: 0.12),
                  highlightColor:
                      ProfileColors.logoutRed.withValues(alpha: 0.06),
                  backgroundColor: ProfileColors.dangerSurface,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 15,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: ProfileColors.dangerSurface,
                      border: Border.all(
                        color: ProfileColors.dangerBorder,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_off_outlined,
                          size: 20,
                          color: ProfileColors.logoutRed.withValues(
                            alpha: isClosingAccount ? 0.45 : 1,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Close My Account',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                            color: ProfileColors.logoutRed.withValues(
                              alpha: isClosingAccount ? 0.45 : 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Pressable(
                  onTap: onLogout,
                  borderRadius: BorderRadius.circular(12),
                  splashColor: ProfileColors.stoneMid.withValues(alpha: 0.65),
                  highlightColor: ProfileColors.stone.withValues(alpha: 0.95),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 15,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: ProfileColors.surface,
                      border: Border.all(color: ProfileColors.stone),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.logout_rounded,
                          size: 20,
                          color: ProfileColors.inkMid,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Log Out',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                            color: ProfileColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              'Version 1.0.0',
              style: GoogleFonts.outfit(
                fontSize: 10,
                color: ProfileColors.inkSoft,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
