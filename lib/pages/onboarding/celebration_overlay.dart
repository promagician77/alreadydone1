import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/shared/theme/auth_theme.dart';

/// Full-screen celebratory overlay with fireworks and a message.
/// Calls [onComplete] after [duration] then removes itself.
void showCelebrationOverlay(
  BuildContext context, {
  required String message,
  required VoidCallback onComplete,
  Duration duration = const Duration(milliseconds: 2500),
}) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (ctx) => _CelebrationOverlay(
      message: message,
      onComplete: () {
        entry.remove();
        onComplete();
      },
      duration: duration,
    ),
  );
  overlay.insert(entry);
}

class _CelebrationOverlay extends StatefulWidget {
  const _CelebrationOverlay({
    required this.message,
    required this.onComplete,
    required this.duration,
  });

  final String message;
  final VoidCallback onComplete;
  final Duration duration;

  @override
  State<_CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<_CelebrationOverlay>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late Animation<double> _fadeIn;
  late Animation<double> _scaleIn;

  @override
  void initState() {
    super.initState();
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeIn = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.easeOut),
    );
    _scaleIn = Tween<double>(begin: 0.7, end: 1).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.elasticOut),
    );
    _mainController.forward();
    Future.delayed(widget.duration, () {
      if (mounted) widget.onComplete();
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        fit: StackFit.expand,
        children: [
          FadeTransition(
            opacity: _fadeIn,
            child: Container(
              color: AuthTheme.ink.withValues(alpha: 0.35),
            ),
          ),
          Center(
            child: ScaleTransition(
              scale: _scaleIn,
              child: FadeTransition(
                opacity: _fadeIn,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const _Fireworks(),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 20,
                        ),
                        decoration: BoxDecoration(
                          color: AuthTheme.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AuthTheme.goldLight,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AuthTheme.gold.withValues(alpha: 0.25),
                              blurRadius: 24,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              size: 48,
                              color: AuthTheme.gold,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              widget.message,
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AuthTheme.ink,
                                height: 1.35,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Fireworks extends StatefulWidget {
  const _Fireworks();

  @override
  State<_Fireworks> createState() => _FireworksState();
}

class _FireworksState extends State<_Fireworks>
    with SingleTickerProviderStateMixin {
  static const int _particleCount = 60;
  late AnimationController _controller;
  final List<_Particle> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < _particleCount; i++) {
      final angle = (i / _particleCount) * 2 * math.pi + _random.nextDouble();
      _particles.add(_Particle(
        angle: angle,
        distance: 0,
        size: 4 + _random.nextDouble() * 6,
        colorIndex: _random.nextInt(4),
      ));
    }
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static const List<Color> _colors = [
    AuthTheme.gold,
    AuthTheme.goldLight,
    Color(0xFFFFD700),
    AuthTheme.goldPale,
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 200,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _FireworksPainter(
              progress: _controller.value,
              particles: _particles,
              colors: _colors,
            ),
          );
        },
      ),
    );
  }
}

class _Particle {
  _Particle({
    required this.angle,
    required this.distance,
    required this.size,
    required this.colorIndex,
  });
  final double angle;
  final double distance;
  final double size;
  final int colorIndex;
}

class _FireworksPainter extends CustomPainter {
  _FireworksPainter({
    required this.progress,
    required this.particles,
    required this.colors,
  });

  final double progress;
  final List<_Particle> particles;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    for (final p in particles) {
      final dist = 15 + progress * 85;
      final x = center.dx + math.cos(p.angle) * dist;
      final y = center.dy + math.sin(p.angle) * dist;
      final opacity = (1 - progress).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = colors[p.colorIndex % colors.length]
            .withValues(alpha: opacity * 0.9)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x, y), p.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _FireworksPainter old) =>
      old.progress != progress;
}
