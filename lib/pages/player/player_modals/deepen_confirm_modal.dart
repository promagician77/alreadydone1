import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design tokens matching the HTML "Deepen Your Manifestation" modal.
class _DeepenConfirmColors {
  static const gold = Color(0xFFD4AF37);
  static const goldLight = Color(0xFFF4E4C1);
  static const goldDark = Color(0xFFB8941F);
  static const navy = Color(0xFF1A1A2E);
  static const navyLight = Color(0xFF2A2A3E);
  static const offWhite = Color(0xFFF8F6F0);
  static const textDark = Color(0xFF2C2C2C);
  static const textLight = Color(0xFF6B6B6B);
}

/// Shows the "Deepen Your Manifestation" confirmation modal.
/// [onContinue] is called when the user taps "Continue to Deepen" (modal is popped first).
void showDeepenConfirmModal(
  BuildContext context, {
  required VoidCallback onContinue,
}) {
  showDialog<void>(
    context: context,
    barrierColor: _DeepenConfirmColors.navy.withValues(alpha: 0.85),
    builder: (ctx) => _DeepenConfirmDialog(onContinue: onContinue),
  );
}

class _DeepenConfirmDialog extends StatefulWidget {
  const _DeepenConfirmDialog({required this.onContinue});

  final VoidCallback onContinue;

  @override
  State<_DeepenConfirmDialog> createState() => _DeepenConfirmDialogState();
}

class _DeepenConfirmDialogState extends State<_DeepenConfirmDialog>
    with TickerProviderStateMixin {
  late AnimationController _ac;
  late Animation<double> _scale;
  late Animation<double> _opacity;

  /// Sparkle (side star) animation: opacity 0→1→0, scale 0.8→1.2→0.8, rotate.
  late AnimationController _sparkleAc;
  late Animation<double> _sparkleValue;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _scale = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _ac, curve: Curves.easeOutCubic),
    );
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ac, curve: Curves.easeOut),
    );
    _ac.forward();

    _sparkleAc = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _sparkleValue = CurvedAnimation(
      parent: _sparkleAc,
      curve: Curves.easeInOut,
    );
    _sparkleAc.repeat();
  }

  @override
  void dispose() {
    _ac.dispose();
    _sparkleAc.dispose();
    super.dispose();
  }

  void _handleContinue() {
    Navigator.of(context).pop();
    widget.onContinue();
  }

  void _handleBack() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ac,
      builder: (context, child) {
        return Opacity(
          opacity: _opacity.value,
          child: Transform.scale(
            scale: _scale.value,
            child: child,
          ),
        );
      },
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: _buildCard(context),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 40, 28, 40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.95),
            _DeepenConfirmColors.offWhite.withValues(alpha: 0.95),
          ],
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 60,
            offset: const Offset(0, 20),
          ),
          BoxShadow(
            color: _DeepenConfirmColors.gold.withValues(alpha: 0.2),
            blurRadius: 80,
            offset: Offset.zero,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Gold accent line at top (clear of icon to avoid blur/streak)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 80,
                  height: 4,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        _DeepenConfirmColors.gold,
                        Colors.transparent,
                      ],
                    ),
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                _buildIcon(),
                    const SizedBox(height: 24),
                    _buildTitle(),
                    const SizedBox(height: 12),
                    _buildSubtitle(),
                    const SizedBox(height: 24),
                    _buildExplanation(),
                    const SizedBox(height: 24),
                    _buildFeatures(),
                    const SizedBox(height: 24),
                    _buildInfoBox(),
                    const SizedBox(height: 28),
                    _buildButtons(),
                  ],
                ),
              ],
            ),
        ),
    );
  }

  Widget _buildIcon() {
  const double circleSize = 70;
  return Center(
    child: Padding(
      padding: const EdgeInsets.only(top: 4),
      child: SizedBox(
        width: circleSize,
        height: circleSize,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: circleSize,
              height: circleSize,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _DeepenConfirmColors.goldLight,
                    _DeepenConfirmColors.gold,
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _DeepenConfirmColors.gold.withValues(alpha: 0.3),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  '🌟',
                  style: TextStyle(
                    fontSize: 36,
                    decoration: TextDecoration.none,
                    decorationColor: null,
                  ),
                ),
              ),
            ),
            // Sparkle at top-right edge of the circle
            Positioned(
              right: -8,
              top: -8,
              child: AnimatedBuilder(
                animation: _sparkleValue,
                builder: (context, child) {
                  final t = _sparkleValue.value;
                  final opacity = math.sin(math.pi * t);
                  final scale = 0.8 + 0.4 * math.sin(math.pi * t);
                  final rotation = t * math.pi;
                  return Opacity(
                    opacity: opacity.clamp(0.0, 1.0),
                    child: Transform.rotate(
                      angle: rotation,
                      child: Transform.scale(
                        scale: scale,
                        child: child,
                      ),
                    ),
                  );
                },
                child: const Text(
                  '✨',
                  style: TextStyle(
                    fontSize: 20,
                    decoration: TextDecoration.none,
                    decorationColor: null,
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

  Widget _buildTitle() {
    return Text(
      'Deepen Your\nManifestation',
      textAlign: TextAlign.center,
      style: GoogleFonts.cormorantGaramond(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: _DeepenConfirmColors.textDark,
        height: 1.2,
        letterSpacing: -0.5,
        decoration: TextDecoration.none,
        decorationColor: null,
      ),
    );
  }

  Widget _buildSubtitle() {
    return Text(
      'NEXT CHAPTER',
      textAlign: TextAlign.center,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: _DeepenConfirmColors.goldDark,
        letterSpacing: 2,
        decoration: TextDecoration.none,
        decorationColor: null,
      ),
    );
  }

  Widget _buildExplanation() {
    return RichText(
      textAlign: TextAlign.left,
      text: TextSpan(
        style: GoogleFonts.inter(
          fontSize: 15,
          height: 1.6,
          color: _DeepenConfirmColors.textDark,
        ),
        children: [
          const TextSpan(text: 'To deepen your manifestation, click the '),
          TextSpan(
            text: 'Continue',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              color: _DeepenConfirmColors.goldDark,
            ),
          ),
          const TextSpan(
            text: ' button below, and the next part of your story will be created.',
          ),
        ],
      ),
    );
  }

  Widget _buildFeatures() {
    final features = [
      ('✨', 'The continuation will include ', 'new specific details', ' about your manifestation'),
      ('🎯', 'You can keep creating subsequent parts, each with ', 'more vivid details', ''),
      ('🔄', 'Each deepening builds on the previous story, taking you ', 'further into your future', ''),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: features.map((f) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _DeepenConfirmColors.gold.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  f.$1,
                  style: const TextStyle(
                    fontSize: 20,
                    decoration: TextDecoration.none,
                    decorationColor: null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        height: 1.5,
                        color: _DeepenConfirmColors.textDark,
                      ),
                      children: [
                        TextSpan(text: f.$2),
                        TextSpan(
                          text: f.$3,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            color: _DeepenConfirmColors.textDark,
                          ),
                        ),
                        TextSpan(text: f.$4),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInfoBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _DeepenConfirmColors.gold.withValues(alpha: 0.08),
            _DeepenConfirmColors.gold.withValues(alpha: 0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: _DeepenConfirmColors.gold, width: 4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ℹ️',
            style: TextStyle(
              fontSize: 24,
              decoration: TextDecoration.none,
              decorationColor: null,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.inter(
                  fontSize: 14,
                  height: 1.6,
                  color: _DeepenConfirmColors.textDark,
                ),
                children: [
                  TextSpan(
                    text: 'Please note: ',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: _DeepenConfirmColors.goldDark,
                    ),
                  ),
                  const TextSpan(
                    text:
                        'Using this feature counts as one of your daily manifestation stories, '
                        'which means you won\'t be able to create a new manifestation story until tomorrow.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _handleContinue,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 28),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _DeepenConfirmColors.gold,
                    _DeepenConfirmColors.goldDark,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: _DeepenConfirmColors.gold.withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  'Continue to Deepen',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _handleBack,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 28),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _DeepenConfirmColors.textLight.withValues(alpha: 0.2),
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  'Go Back',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: _DeepenConfirmColors.textLight,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
