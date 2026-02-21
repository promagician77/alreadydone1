import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ALREADY auth design tokens — matches HTML design (pixel-perfect).
abstract class AuthTheme {
  static const Color warmWhite = Color(0xFFF9F7F4);
  static const Color offWhite = Color(0xFFF2F0ED);
  static const Color surface = Color(0xFFFEFDFB);
  static const Color ink = Color(0xFF1C1917);
  static const Color inkMid = Color(0xFF44403C);
  static const Color inkSoft = Color(0xFF78716C);
  static const Color stone = Color(0xFFE8E2DA);
  static const Color stoneMid = Color(0xFFD6D0C8);
  static const Color gold = Color(0xFFB8861E);
  static const Color goldDark = Color(0xFF8B6914);
  static const Color goldLight = Color(0xFFD4A574);
  static const Color goldPale = Color(0xFFFBF4E6);
  static const Color goldHover = Color(0xFF9A7018);

  static TextStyle get labelStyle => GoogleFonts.outfit(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: inkMid,
        letterSpacing: 0.2,
      );

  static TextStyle get bodyStyle => GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: ink,
      );

  static TextStyle get placeholderStyle => GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: Color.lerp(AuthTheme.inkSoft, Colors.white, 0.4)!,
      );

  static TextStyle get welcomeTitleStyle => GoogleFonts.cormorantGaramond(
        fontSize: 26,
        fontWeight: FontWeight.w400,
        color: ink,
        height: 1.25,
      );

  static TextStyle get welcomeTitleItalicStyle => GoogleFonts.cormorantGaramond(
        fontSize: 26,
        fontWeight: FontWeight.w400,
        fontStyle: FontStyle.italic,
        color: gold,
        height: 1.25,
      );

  static TextStyle get welcomeSubStyle => GoogleFonts.outfit(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: inkSoft,
        height: 1.5,
      );

  static TextStyle get primaryButtonStyle => GoogleFonts.outfit(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: surface,
      );

  static TextStyle get footerStyle => GoogleFonts.outfit(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: inkSoft,
      );

  static TextStyle get footerLinkStyle => GoogleFonts.outfit(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: gold,
      );

  static TextStyle get dividerTextStyle => GoogleFonts.outfit(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: inkSoft,
        letterSpacing: 0.5,
      );

  static TextStyle get checkboxLabelStyle => GoogleFonts.outfit(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: inkMid,
        height: 1.5,
      );

  static TextStyle get forgotLinkStyle => GoogleFonts.outfit(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: gold,
      );

  static TextStyle get statusBarStyle => GoogleFonts.outfit(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: inkSoft,
      );
}

class AuthStatusBar extends StatelessWidget {
  const AuthStatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 34, 18, 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('9:41', style: AuthTheme.statusBarStyle),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('●●●', style: AuthTheme.statusBarStyle),
              const SizedBox(width: 4),
              Text('WiFi', style: AuthTheme.statusBarStyle),
              const SizedBox(width: 4),
              Text('▮', style: AuthTheme.statusBarStyle),
            ],
          ),
        ],
      ),
    );
  }
}

class WaveformIcon extends StatelessWidget {
  const WaveformIcon({super.key});

  static const List<double> _heights = [8, 12, 18, 24, 32, 36, 32, 24, 18, 12, 8];
  static const List<double> _opacities = [0.3, 0.45, 0.6, 0.75, 0.9, 1, 0.9, 0.75, 0.6, 0.45, 0.3];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: AuthTheme.warmWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AuthTheme.stone),
        boxShadow: [
          BoxShadow(
            color: AuthTheme.ink.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(11, (i) {
            return Container(
              width: 3,
              height: _heights[i],
              margin: EdgeInsets.only(left: i == 0 ? 0 : 1.5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AuthTheme.goldLight.withValues(alpha: _opacities[i]),
                    AuthTheme.gold.withValues(alpha: _opacities[i]),
                    AuthTheme.goldDark.withValues(alpha: _opacities[i]),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class KeyIcon extends StatelessWidget {
  const KeyIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: AuthTheme.warmWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AuthTheme.stone),
        boxShadow: [
          BoxShadow(
            color: AuthTheme.ink.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Center(
        child: Text('🔑', style: TextStyle(fontSize: 32), textAlign: TextAlign.center),
      ),
    );
  }
}
