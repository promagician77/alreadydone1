import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design tokens matching the HTML "Deepen Your Manifestation" modal.
class _DeepenModalColors {
  static const gold = Color(0xFFD4AF37);
  static const goldLight = Color(0xFFF4E4C1);
  static const goldDark = Color(0xFFB8941F);
  static const navy = Color(0xFF1A1A2E);
  static const navyLight = Color(0xFF2A2A3E);
  static const white = Color(0xFFFFFFFF);
  static const offWhite = Color(0xFFF8F6F0);
  static const textDark = Color(0xFF2C2C2C);
  static const textLight = Color(0xFF6B6B6B);
}

/// Shows the "Deepen Your Manifestation" modal. On "Continue to Deepen", calls
/// [onContinue] and closes the modal. "Go Back" just closes.
void showDeepenManifestationModal(
  BuildContext context, {
  required VoidCallback onContinue,
}) {
  showDialog<void>(
    context: context,
    barrierColor: Colors.transparent,
    builder: (ctx) => _DeepenManifestationDialog(onContinue: onContinue),
  );
}

class _DeepenManifestationDialog extends StatefulWidget {
  final VoidCallback onContinue;

  const _DeepenManifestationDialog({required this.onContinue});

  @override
  State<_DeepenManifestationDialog> createState() =>
      _DeepenManifestationDialogState();
}

class _DeepenManifestationDialogState extends State<_DeepenManifestationDialog>
    with TickerProviderStateMixin {
  late AnimationController _twinkleController;
  late AnimationController _glowController;
  late AnimationController _floatController;
  late AnimationController _sparkleController;
  late AnimationController _slideController;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _twinkleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 8000),
    )..repeat(reverse: true);

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _slideAnimation = CurvedAnimation(
      parent: _slideController,
      curve: const Cubic(0.22, 1, 0.36, 1), // cubic-bezier(0.22, 1, 0.36, 1)
    );
    _slideController.forward();
  }

  @override
  void dispose() {
    _twinkleController.dispose();
    _glowController.dispose();
    _floatController.dispose();
    _sparkleController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Backdrop: gradient + twinkling stars (tap to close = Go Back)
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            behavior: HitTestBehavior.opaque,
            child: SizedBox.expand(
              child: AnimatedBuilder(
                animation: _twinkleController,
                builder: (context, _) => CustomPaint(
                  painter: _DeepenBackdropPainter(
                    twinkleValue: _twinkleController.value,
                  ),
                ),
              ),
            ),
          ),
          // Centered card
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: GestureDetector(
                onTap: () {}, // absorb tap so card doesn't close
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.15),
                    end: Offset.zero,
                  ).animate(_slideAnimation),
                  child: FadeTransition(
                    opacity: _slideAnimation,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.95, end: 1.0)
                          .animate(_slideAnimation),
                      child: _buildCard(context),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 480;
    final cardRadius = isSmall ? 24.0 : 32.0;
    final padding = isSmall
        ? const EdgeInsets.fromLTRB(20, 28, 20, 28)
        : const EdgeInsets.fromLTRB(28, 40, 28, 40);

    return Container(
      constraints: const BoxConstraints(maxWidth: 480),
      padding: padding,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment(-1, -1), // top-left
          end: Alignment(1, 1), // bottom-right (145deg approx)
          stops: [0.0, 1.0],
          colors: [
            Color(0xFFF2F2F2), // rgba(255,255,255,0.95)
            Color(0xFFEBE9E4), // rgba(248,246,240,0.95)
          ],
        ),
        borderRadius: BorderRadius.circular(cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 60,
            offset: const Offset(0, 20),
          ),
          BoxShadow(
            color: _DeepenModalColors.gold.withValues(alpha: 0.2),
            blurRadius: 80,
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.9),
            blurRadius: 0,
            offset: const Offset(0, 1),
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(cardRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Gold accent bar at top
              _buildGoldAccentBar(),
              _buildIconSection(isSmall),
              SizedBox(height: isSmall ? 20 : 24),
              _buildFadeInItem(
                delay: 0.2,
                child: _buildTitleSection(isSmall),
              ),
              SizedBox(height: isSmall ? 20 : 24),
              _buildFadeInItem(
                delay: 0.4,
                child: _buildExplanation(isSmall),
              ),
              SizedBox(height: isSmall ? 20 : 24),
              _buildFadeInItem(
                delay: 0.5,
                child: _buildFeatures(isSmall),
              ),
              SizedBox(height: isSmall ? 20 : 24),
              _buildFadeInItem(
                delay: 0.5,
                child: _buildInfoBox(isSmall),
              ),
              SizedBox(height: isSmall ? 24 : 28),
              _buildFadeInItem(
                delay: 0.6,
                child: _buildButtons(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoldAccentBar() {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        final t = _glowController.value;
        // HTML: 0% opacity:0.6 box-shadow:20px, 50% opacity:1 box-shadow:40px
        final opacity = 0.6 + 0.4 * (t < 0.5 ? t * 2 : 2 - t * 2);
        return Center(
          child: Container(
            width: 80,
            height: 4,
            margin: const EdgeInsets.only(bottom: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  _DeepenModalColors.gold.withValues(alpha: opacity),
                  Colors.transparent,
                ],
              ),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(4),
              ),
              boxShadow: [
                BoxShadow(
                  color: _DeepenModalColors.gold
                      .withValues(alpha: 0.3 * opacity),
                  blurRadius: 20 + 20 * opacity,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildIconSection(bool isSmall) {
    final size = isSmall ? 60.0 : 70.0;
    final iconSize = isSmall ? 30.0 : 36.0;

    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, child) {
        // HTML: 0%,100% translateY(0), 50% translateY(-8px)
        final t = _floatController.value;
        final dy = -8.0 * (t < 0.5 ? t * 2 : 2 - t * 2);
        return Transform.translate(
          offset: Offset(0, dy),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _DeepenModalColors.goldLight,
                      _DeepenModalColors.gold,
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _DeepenModalColors.gold.withValues(alpha: 0.3),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.5),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '🌟',
                    style: TextStyle(fontSize: iconSize),
                  ),
                ),
              ),
              // Single sparkle matching HTML ::after - top:-10px, right:-10px
              Positioned(
                top: -10,
                right: -10,
                child: AnimatedBuilder(
                  animation: _sparkleController,
                  builder: (context, child) {
                    // HTML: 0%,100% opacity:0 scale(0.8) rotate(0deg)
                    //       50% opacity:1 scale(1.2) rotate(180deg)
                    final t = _sparkleController.value;
                    final opacity = t < 0.5 ? t * 2 : 2 - t * 2;
                    final scale = 0.8 + 0.4 * opacity;
                    final rotation = t * 3.14159; // 0 to 180deg
                    return Opacity(
                      opacity: opacity,
                      child: Transform.scale(
                        scale: scale,
                        child: Transform.rotate(
                          angle: rotation,
                          child:
                              const Text('✨', style: TextStyle(fontSize: 24)),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTitleSection(bool isSmall) {
    final titleSize = isSmall ? 24.0 : 28.0;
    final subtitleSize = isSmall ? 11.0 : 13.0;

    return Column(
      children: [
        Text(
          'Deepen Your\nManifestation',
          textAlign: TextAlign.center,
          style: GoogleFonts.cormorantGaramond(
            fontSize: titleSize,
            fontWeight: FontWeight.w600,
            color: _DeepenModalColors.textDark,
            letterSpacing: -0.5,
            height: 1.2,
          ),
        ),
        SizedBox(height: isSmall ? 10 : 12),
        Text(
          'NEXT CHAPTER',
          style: GoogleFonts.inter(
            fontSize: subtitleSize,
            fontWeight: FontWeight.w500,
            letterSpacing: 2,
            color: _DeepenModalColors.goldDark,
          ),
        ),
      ],
    );
  }

  Widget _buildExplanation(bool isSmall) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: RichText(
        textAlign: TextAlign.left,
        text: TextSpan(
          style: GoogleFonts.inter(
            fontSize: isSmall ? 14 : 15,
            height: 1.6,
            color: _DeepenModalColors.textDark,
          ),
          children: const [
            TextSpan(text: 'To deepen your manifestation, click the '),
            TextSpan(
              text: 'Continue',
              style: TextStyle(
                color: _DeepenModalColors.goldDark,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextSpan(
              text:
                  ' button below, and the next part of your story will be created.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatures(bool isSmall) {
    final features = [
      (
        '✨',
        'The continuation will include ',
        'new specific details',
        ' about your manifestation'
      ),
      (
        '🎯',
        'You can keep creating subsequent parts, each with ',
        'more vivid details',
        ''
      ),
      (
        '🔄',
        'Each deepening builds on the previous story, taking you ',
        'further into your future',
        ''
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: List.generate(features.length, (index) {
        final f = features[index];
        return Padding(
          padding: EdgeInsets.only(bottom: isSmall ? 10 : 12),
          child: _FeatureItem(
            emoji: f.$1,
            prefix: f.$2,
            highlight: f.$3,
            suffix: f.$4,
            isSmall: isSmall,
          ),
        );
      }),
    );
  }

  Widget _buildInfoBox(bool isSmall) {
    return Container(
      padding: EdgeInsets.all(isSmall ? 14 : 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _DeepenModalColors.gold.withValues(alpha: 0.08),
            _DeepenModalColors.gold.withValues(alpha: 0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: const Border(
          left: BorderSide(color: _DeepenModalColors.gold, width: 4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Text('ℹ️', style: TextStyle(fontSize: 24)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.inter(
                  fontSize: isSmall ? 13 : 14,
                  height: 1.6,
                  color: _DeepenModalColors.textDark,
                ),
                children: const [
                  TextSpan(
                    text: 'Please note:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _DeepenModalColors.goldDark,
                    ),
                  ),
                  TextSpan(
                    text:
                        ' Using this feature counts as one of your daily manifestation stories, which means you won\'t be able to create a new manifestation story until tomorrow.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtons(BuildContext context) {
    return _DeepenModalButtons(
      onContinue: widget.onContinue,
      onBack: () => Navigator.of(context).pop(),
    );
  }

  /// Wraps [child] in a fadeIn + translateY(10) animation matching the HTML
  /// `fadeIn 0.8s ease-out <delay>s both`.
  Widget _buildFadeInItem({required double delay, required Widget child}) {
    final delayMs = (delay * 1000).round();
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        // Delay: hold at 0 until after the slide-up entry (600ms) + per-item delay
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

/// Individual feature item with hover-like interaction matching HTML
/// `.feature-item:hover { background: rgba(255,255,255,0.9); border-color: rgba(212,175,55,0.3); transform: translateX(4px); }`
class _FeatureItem extends StatefulWidget {
  final String emoji;
  final String prefix;
  final String highlight;
  final String suffix;
  final bool isSmall;

  const _FeatureItem({
    required this.emoji,
    required this.prefix,
    required this.highlight,
    required this.suffix,
    required this.isSmall,
  });

  @override
  State<_FeatureItem> createState() => _FeatureItemState();
}

class _FeatureItemState extends State<_FeatureItem> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: EdgeInsets.all(widget.isSmall ? 12 : 14),
        transform: Matrix4.translationValues(_hovering ? 4 : 0, 0, 0),
        decoration: BoxDecoration(
          color: _hovering
              ? Colors.white.withValues(alpha: 0.9)
              : Colors.white.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _hovering
                ? _DeepenModalColors.gold.withValues(alpha: 0.3)
                : _DeepenModalColors.gold.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                widget.emoji,
                style: TextStyle(fontSize: widget.isSmall ? 18 : 20),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: GoogleFonts.inter(
                    fontSize: widget.isSmall ? 13 : 14,
                    height: 1.5,
                    color: _DeepenModalColors.textDark,
                  ),
                  children: [
                    TextSpan(text: widget.prefix),
                    TextSpan(
                      text: widget.highlight,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _DeepenModalColors.goldDark,
                      ),
                    ),
                    TextSpan(text: widget.suffix),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Backdrop: navy gradient + twinkling star dots.
class _DeepenBackdropPainter extends CustomPainter {
  final double twinkleValue;

  _DeepenBackdropPainter({required this.twinkleValue});

  @override
  void paint(Canvas canvas, Size size) {
    // HTML: linear-gradient(135deg, #1A1A2E 0%, #2A2A3E 100%)
    final gradient = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        _DeepenModalColors.navy,
        _DeepenModalColors.navyLight,
      ],
    );
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader =
            gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    // HTML twinkle: 0%,100% opacity:1 → 50% opacity:0.6
    // twinkleValue goes 0→1→0 (reverse), so at 0.5 it's peak
    final opacity = 0.6 + 0.4 * (1 - (twinkleValue - 0.5).abs() * 2);

    // Star positions and sizes matching the HTML radial-gradients
    final stars = [
      (const Offset(0.2, 0.3), 2.0, 0.3),
      (const Offset(0.6, 0.7), 2.0, 0.2),
      (const Offset(0.5, 0.5), 1.0, 0.4),
      (const Offset(0.8, 0.1), 1.0, 0.2),
      (const Offset(0.9, 0.6), 2.0, 0.3),
      (const Offset(0.33, 0.9), 1.0, 0.2),
    ];

    for (final (pos, radius, baseAlpha) in stars) {
      final center = Offset(pos.dx * size.width, pos.dy * size.height);
      final starPaint = Paint()
        ..color =
            _DeepenModalColors.gold.withValues(alpha: baseAlpha * opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
      canvas.drawCircle(center, radius, starPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _DeepenBackdropPainter old) =>
      old.twinkleValue != twinkleValue;
}

class _DeepenModalButtons extends StatefulWidget {
  final VoidCallback onContinue;
  final VoidCallback onBack;

  const _DeepenModalButtons({
    required this.onContinue,
    required this.onBack,
  });

  @override
  State<_DeepenModalButtons> createState() => _DeepenModalButtonsState();
}

class _DeepenModalButtonsState extends State<_DeepenModalButtons> {
  bool _isLoading = false;
  bool _hovering = false;

  Future<void> _handleContinue() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    // HTML: setTimeout 1000ms
    await Future<void>.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;
    Navigator.of(context).pop();
    widget.onContinue();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Continue to Deepen (primary) — matches HTML .continue-button
        MouseRegion(
          onEnter: (_) => setState(() => _hovering = true),
          onExit: (_) => setState(() => _hovering = false),
          child: GestureDetector(
            onTapDown: (_) {},
            onTapUp: (_) => _handleContinue(),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: const Cubic(0.22, 1, 0.36, 1),
              transform: Matrix4.translationValues(
                  0, _hovering && !_isLoading ? -2 : 0, 0),
              padding:
                  const EdgeInsets.symmetric(vertical: 16, horizontal: 28),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _DeepenModalColors.gold,
                    _DeepenModalColors.goldDark,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: _DeepenModalColors.gold.withValues(
                        alpha: _hovering ? 0.5 : 0.4),
                    blurRadius: _hovering ? 24 : 16,
                    offset: Offset(0, _hovering ? 8 : 4),
                  ),
                  BoxShadow(
                    color: Colors.white
                        .withValues(alpha: _hovering ? 0.4 : 0.3),
                    blurRadius: 0,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _isLoading ? 0.7 : 1.0,
                child: Center(
                  child: Text(
                    _isLoading
                        ? 'Creating your deepening...'
                        : 'Continue to Deepen',
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
        ),
        const SizedBox(height: 12),
        // Go Back (secondary) — matches HTML .back-button
        _BackButton(onTap: widget.onBack),
      ],
    );
  }
}

class _BackButton extends StatefulWidget {
  final VoidCallback onTap;

  const _BackButton({required this.onTap});

  @override
  State<_BackButton> createState() => _BackButtonState();
}

class _BackButtonState extends State<_BackButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 28),
          decoration: BoxDecoration(
            color: _hovering
                ? _DeepenModalColors.textLight.withValues(alpha: 0.05)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _DeepenModalColors.textLight
                  .withValues(alpha: _hovering ? 0.3 : 0.2),
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              'Go Back',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: _hovering
                    ? _DeepenModalColors.textDark
                    : _DeepenModalColors.textLight,
              ),
            ),
          ),
        ),
      ),
    );
  }
}