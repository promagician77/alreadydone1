import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '/shared/theme/auth_theme.dart';
import '/shared/widgets/pressable.dart';
import 'onboarding_guide_content.dart';

/// Bottom-sheet guide shown on top of onboarding screens (matches design reference).
class OnboardingGuideModal {
  OnboardingGuideModal._();

  static Future<void> show(
    BuildContext context,
    OnboardingGuideContent content,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x801C1917),
      isDismissible: true,
      enableDrag: true,
      builder: (context) => _OnboardingGuideSheet(content: content),
    );
  }
}

class _OnboardingGuideSheet extends StatelessWidget {
  const _OnboardingGuideSheet({required this.content});

  final OnboardingGuideContent content;

  static const _goldSoft = Color(0xFFF7EFDC);
  static const _navy = Color(0xFF1E2A4A);

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Color(0x261C1917),
                blurRadius: 40,
                offset: Offset(0, -12),
              ),
            ],
          ),
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(24, 20, 24, 32 + bottomInset),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: AuthTheme.ink.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    _buildIcon(),
                    const SizedBox(height: 14),
                    Text(
                      content.title,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 26,
                        fontWeight: FontWeight.w500,
                        color: AuthTheme.ink,
                        height: 1.15,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      content.body,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: AuthTheme.inkSoft,
                        height: 1.55,
                      ),
                    ),
                    if (content.bullets != null && content.bullets!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildBullets(content.bullets!),
                    ],
                    if (content.footer != null) ...[
                      const SizedBox(height: 20),
                      _buildFooter(content.footer!),
                    ],
                    SizedBox(height: content.footer != null ? 20 : 24),
                    _buildButton(context),
                  ],
                ),
              ),
              Positioned(
                top: 16,
                right: 16,
                child: Pressable(
                  onTap: () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AuthTheme.offWhite,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close,
                      size: 16,
                      color: AuthTheme.inkSoft,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: _goldSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AuthTheme.goldLight),
      ),
      child: Icon(
        content.icon,
        size: 24,
        color: AuthTheme.gold,
      ),
    );
  }

  Widget _buildBullets(List<String> bullets) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AuthTheme.goldPale,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AuthTheme.goldLight),
      ),
      child: Column(
        children: [
          for (var i = 0; i < bullets.length; i++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(top: 6),
                  decoration: const BoxDecoration(
                    color: AuthTheme.gold,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    bullets[i],
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AuthTheme.ink,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
            if (i < bullets.length - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildFooter(String footer) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _navy,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            margin: const EdgeInsets.only(top: 1),
            decoration: const BoxDecoration(
              color: AuthTheme.gold,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: SvgPicture.string(
                _sparklesIconSvg,
                width: 11,
                height: 11,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'WHAT HAPPENS NEXT',
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    color: AuthTheme.goldLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  footer,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(BuildContext context) {
    return Pressable(
      onTap: () => Navigator.of(context).pop(),
      borderRadius: BorderRadius.circular(14),
      scaleDownTo: 0.98,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: AuthTheme.gold,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AuthTheme.gold.withValues(alpha: 0.25),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          content.buttonText,
          style: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }

  static const _sparklesIconSvg = '''
<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M9.937 15.5A2 2 0 0 0 8.5 14.063l-6.135-1.582a.5.5 0 0 1 0-.962L8.5 9.936A2 2 0 0 0 9.937 8.5l1.582-6.135a.5.5 0 0 1 .962 0L14.063 8.5A2 2 0 0 0 15.5 9.937l6.135 1.581a.5.5 0 0 1 0 .964L15.5 14.063a2 2 0 0 0-1.437 1.437l-1.582 6.135a.5.5 0 0 1-.962 0z" fill="#FFFFFF" stroke="#FFFFFF" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M20 3v4" stroke="#FFFFFF" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M22 5h-4" stroke="#FFFFFF" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M4 17v2" stroke="#FFFFFF" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M5 18H3" stroke="#FFFFFF" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
</svg>
''';
}
