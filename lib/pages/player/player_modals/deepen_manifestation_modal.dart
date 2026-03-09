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
  AnimationController? _featureController;
  List<Animation<double>>? _featureAnimations;

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
      curve: Curves.easeOutCubic,
    );
    _slideController.forward();

    final featureController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _featureController = featureController;
    _featureAnimations = [
      CurvedAnimation(
        parent: featureController,
        curve: const Interval(0.0, 0.33, curve: Curves.easeOut),
      ),
      CurvedAnimation(
        parent: featureController,
        curve: const Interval(0.33, 0.66, curve: Curves.easeOut),
      ),
      CurvedAnimation(
        parent: featureController,
        curve: const Interval(0.66, 1.0, curve: Curves.easeOut),
      ),
    ];
    Future<void>.delayed(const Duration(milliseconds: 350), () {
      if (mounted) _featureController?.forward();
    });
  }

  @override
  void dispose() {
    _twinkleController.dispose();
    _glowController.dispose();
    _floatController.dispose();
    _sparkleController.dispose();
    _slideController.dispose();
    _featureController?.dispose();
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
                    begin: const Offset(0, 0.25),
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
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
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
              AnimatedBuilder(
                animation: _glowController,
                builder: (context, child) {
                  final t = _glowController.value;
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
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              _buildIconSection(isSmall),
              const SizedBox(height: 24),
              _buildTitleSection(isSmall),
              const SizedBox(height: 24),
              _fadeIn(0.4, _buildExplanation(isSmall)),
              const SizedBox(height: 24),
              _buildFeatures(isSmall),
              const SizedBox(height: 24),
              _fadeIn(0.5, _buildInfoBox(isSmall)),
              const SizedBox(height: 28),
              _fadeIn(0.6, _buildButtons(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconSection(bool isSmall) {
    final size = isSmall ? 60.0 : 70.0;
    final iconSize = isSmall ? 30.0 : 36.0;

    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, child) {
        final dy = -8.0 * (0.5 - (_floatController.value - 0.5).abs());
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
              // First sparkle (top-right)
              Positioned(
                top: -10,
                right: -10,
                child: AnimatedBuilder(
                  animation: _sparkleController,
                  builder: (context, child) {
                    final t = _sparkleController.value;
                    final opacity = t < 0.5 ? t * 2 : 2 - t * 2;
                    final scale = 0.8 + 0.4 * opacity;
                    return Opacity(
                      opacity: opacity,
                      child: Transform.scale(
                        scale: scale,
                        child: const Text('✨', style: TextStyle(fontSize: 24)),
                      ),
                    );
                  },
                ),
              ),
              // Second flying star (further out, trailing)
              Positioned(
                top: -22,
                right: -18,
                child: AnimatedBuilder(
                  animation: _sparkleController,
                  builder: (context, child) {
                    final t = _sparkleController.value;
                    final opacity = (t > 0.3 && t < 0.7) ? (t - 0.3) * 2.5 : 0.0;
                    final translate = Offset(4 * (1 - t), -6 * (1 - t));
                    return Opacity(
                      opacity: opacity.clamp(0.0, 1.0),
                      child: Transform.translate(
                        offset: translate,
                        child: Transform.scale(
                          scale: 0.7,
                          child: const Text('✨', style: TextStyle(fontSize: 18)),
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Third flying star (smallest, trailing upward-right)
              Positioned(
                top: -28,
                right: -8,
                child: AnimatedBuilder(
                  animation: _sparkleController,
                  builder: (context, child) {
                    final t = _sparkleController.value;
                    final opacity = (t > 0.5 && t < 0.9) ? (t - 0.5) * 2.5 : 0.0;
                    final translate = Offset(6 * t, -8 * t);
                    return Opacity(
                      opacity: opacity.clamp(0.0, 1.0),
                      child: Transform.translate(
                        offset: translate,
                        child: Transform.scale(
                          scale: 0.5,
                          child: const Text('✨', style: TextStyle(fontSize: 14)),
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
        const SizedBox(height: 12),
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
              text: ' button below, and the next part of your story will be created.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatures(bool isSmall) {
    final features = [
      ('✨', 'The continuation will include ', 'new specific details', ' about your manifestation'),
      ('🎯', 'You can keep creating subsequent parts, each with ', 'more vivid details', ''),
      ('🔄', 'Each deepening builds on the previous story, taking you ', 'further into your future', ''),
    ];

    final animations = _featureAnimations;
    final useAnimation = animations != null && animations.length >= features.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: List.generate(features.length, (index) {
        final f = features[index];
        final anim = useAnimation ? animations![index] : null;
        final content = Container(
          padding: EdgeInsets.all(isSmall ? 12 : 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _DeepenModalColors.gold.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(f.$1, style: TextStyle(fontSize: isSmall ? 18 : 20)),
              const SizedBox(width: 12),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: GoogleFonts.inter(
                      fontSize: isSmall ? 13 : 14,
                      height: 1.5,
                      color: _DeepenModalColors.textDark,
                    ),
                    children: [
                      TextSpan(text: f.$2),
                      TextSpan(
                        text: f.$3,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _DeepenModalColors.goldDark,
                        ),
                      ),
                      TextSpan(text: f.$4),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: anim != null
              ? FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.04, 0),
                      end: Offset.zero,
                    ).animate(anim),
                    child: content,
                  ),
                )
              : content,
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
          const Text('ℹ️', style: TextStyle(fontSize: 24)),
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
                    text: ' Using this feature counts as one of your daily manifestation stories, which means you won\'t be able to create a new manifestation story until tomorrow.',
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

  Widget _fadeIn(double delay, Widget child) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOut,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: child,
      ),
      child: child,
    );
  }
}

/// Backdrop: navy gradient + twinkling star dots.
class _DeepenBackdropPainter extends CustomPainter {
  final double twinkleValue;

  _DeepenBackdropPainter({required this.twinkleValue});

  @override
  void paint(Canvas canvas, Size size) {
    final gradient = LinearGradient(
      begin: Alignment.bottomLeft,
      end: Alignment.topRight,
      colors: const [
        _DeepenModalColors.navy,
        _DeepenModalColors.navyLight,
      ],
    );
    canvas.drawRect(
      Offset.zero & size,
      Paint()..shader = gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    final opacity = 0.6 + 0.4 * twinkleValue;
    final starPositions = [
      const Offset(0.2, 0.3),
      const Offset(0.6, 0.7),
      const Offset(0.5, 0.5),
      const Offset(0.8, 0.1),
      const Offset(0.9, 0.6),
      const Offset(0.33, 0.9),
    ];
    for (final pos in starPositions) {
      final center = Offset(pos.dx * size.width, pos.dy * size.height);
      final starPaint = Paint()
        ..color = _DeepenModalColors.gold.withValues(alpha: 0.2 * opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
      canvas.drawCircle(center, 2, starPaint);
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

  Future<void> _handleContinue() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    Navigator.of(context).pop();
    widget.onContinue();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Continue to Deepen (primary)
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _isLoading ? null : _handleContinue,
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
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
                    color: _DeepenModalColors.gold.withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.3),
                    blurRadius: 0,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Center(
                child: _isLoading
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Creating your deepening...',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      )
                    : Text(
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
        // Go Back (secondary)
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onBack,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 28),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _DeepenModalColors.textLight.withValues(alpha: 0.2),
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  'Go Back',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: _DeepenModalColors.textLight,
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
