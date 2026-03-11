import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '/widgets/animated_waveform_icon.dart';

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

/// Animated waveform icon for auth screens (login, sign up, email verification).
class WaveformIcon extends StatelessWidget {
  const WaveformIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return const AnimatedWaveformIcon(
      size: AnimatedWaveformSize.auth,
      wrapped: true,
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

/// Multi-colored Google "G" logo for social login button (matches design SVG).
class GoogleLogoIcon extends StatelessWidget {
  const GoogleLogoIcon({super.key, this.size = 20});

  final double size;

  static const String _svg = r'''
<svg viewBox="0 0 16 16" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M15.545 8.182C15.545 7.655 15.5 7.127 15.418 6.609H8V9.564H12.309C12.127 10.509 11.591 11.345 10.8 11.873V13.818H13.291C14.782 12.436 15.545 10.436 15.545 8.182Z" fill="#4285F4"/>
  <path d="M8 15.636C10.018 15.636 11.709 14.973 13.291 13.818L10.8 11.873C10.127 12.327 9.236 12.591 8 12.591C6.055 12.591 4.418 11.2 3.836 9.364H1.255V11.382C2.855 14.564 5.273 15.636 8 15.636Z" fill="#34A853"/>
  <path d="M3.836 9.364C3.491 8.418 3.491 7.391 3.836 6.445V4.427H1.255C0.073 6.782 0.073 9.027 1.255 11.382L3.836 9.364Z" fill="#FBBC04"/>
  <path d="M8 3.218C9.309 3.2 10.564 3.691 11.527 4.582L13.745 2.364C11.636 0.382 8.8 -0.618 6.073 0.236C4.618 0.691 3.309 1.564 2.291 2.745C1.273 3.927 0.582 5.364 0.291 6.918L2.873 8.936C3.418 6.927 5.527 3.218 8 3.218Z" fill="#EA4335"/>
</svg>
''';

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: SvgPicture.string(
        _svg,
        width: size,
        height: size,
        fit: BoxFit.contain,
      ),
    );
  }
}
