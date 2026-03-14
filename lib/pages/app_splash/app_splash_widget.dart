import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'app_splash_model.dart';
export 'app_splash_model.dart';

/// App-branded splash shown ~2s after install before login.
/// Navy gradient, gold particles, app logo, "Already Done", loading dots.
class AppSplashWidget extends StatefulWidget {
  const AppSplashWidget({super.key});

  static String routeName = 'AppSplash';
  static String routePath = '/app_splash';

  @override
  State<AppSplashWidget> createState() => _AppSplashWidgetState();
}

class _AppSplashWidgetState extends State<AppSplashWidget>
    with TickerProviderStateMixin {
  late AppSplashModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  static const _splashDuration = Duration(seconds: 2);
  late final AnimationController _particleController;

  // Splash design tokens (match HTML)
  static const _gold = Color(0xFFD4AF37);
  static const _navy = Color(0xFF1A1A2E);
  static const _navyLight = Color(0xFF2A2A3E);
  static const _surface = Color(0xFFFEFDFB);

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AppSplashModel());
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    _scheduleNavigation();
  }

  void _scheduleNavigation() {
    Future.delayed(_splashDuration, () {
      if (!mounted) return;
      context.go('/');
    });
  }

  @override
  void dispose() {
    _particleController.dispose();
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_navy, _navyLight],
          ),
        ),
        child: Stack(
          children: [
            _buildParticles(),
            _buildContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildParticles() {
    final positions = [
      const Offset(0.1, 0.2),
      const Offset(0.2, 0.8),
      const Offset(0.3, 0.4),
      const Offset(0.4, 0.6),
      const Offset(0.5, 0.3),
      const Offset(0.6, 0.7),
      const Offset(0.7, 0.5),
      const Offset(0.8, 0.25),
      const Offset(0.9, 0.85),
      const Offset(0.15, 0.55),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        return AnimatedBuilder(
          animation: _particleController,
          builder: (context, _) {
            return IgnorePointer(
              child: CustomPaint(
                size: Size(constraints.maxWidth, constraints.maxHeight),
                painter: _ParticlesPainter(
                  positions: positions,
                  time: _particleController.value * 8 * math.pi,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildContent() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 40),
            _buildLogo(),
            const SizedBox(height: 40),
            _buildTitle(),
            const SizedBox(height: 12),
            _buildTagline(),
            const SizedBox(height: 60),
            _buildLoadingDots(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + 0.2 * value,
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Glow behind logo
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _gold.withValues(alpha: 0.4),
                  blurRadius: 60,
                  spreadRadius: 0,
                ),
              ],
            ),
          ),
          // App icon (Already Done logo)
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: _gold.withValues(alpha: 0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Image.asset(
                'assets/icon/app_icon.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - value)),
            child: child,
          ),
        );
      },
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: GoogleFonts.cormorantGaramond(
            fontSize: _titleFontSize,
            fontWeight: FontWeight.w300,
            color: _surface,
            letterSpacing: -1,
            height: 1.2,
          ),
          children: [
            const TextSpan(text: 'Already '),
            TextSpan(
              text: 'Done',
              style: GoogleFonts.cormorantGaramond(
                fontSize: _titleFontSize,
                fontWeight: FontWeight.w400,
                fontStyle: FontStyle.italic,
                color: _gold,
                letterSpacing: -1,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  double get _titleFontSize {
    final width = MediaQuery.sizeOf(context).width;
    return width <= 480 ? 42 : 52;
  }

  Widget _buildTagline() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(opacity: value, child: child);
      },
      child: Text(
        'Your dream life. In your voice.',
        style: GoogleFonts.outfit(
          fontSize: 15,
          fontWeight: FontWeight.w300,
          color: Colors.white.withValues(alpha: 0.7),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildLoadingDots() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(opacity: value, child: child);
      },
      child: const _LoadingDots(),
    );
  }
}

/// Floating gold particles (match HTML animation).
class _ParticlesPainter extends CustomPainter {
  _ParticlesPainter({required this.positions, required this.time});

  final List<Offset> positions;
  final double time;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    for (var i = 0; i < positions.length; i++) {
      final pos = positions[i];
      final x = size.width * pos.dx;
      final y = size.height * pos.dy;
      final phase = i * 0.5 + time * 0.5;
      final opacity = (0.3 + 0.3 * math.sin(phase)).clamp(0.0, 0.6);
      final dy = -20 * math.sin(phase);
      final dx = 15 * math.sin(phase * 0.7);
      paint.color = const Color(0xFFD4AF37).withValues(alpha: opacity);
      canvas.drawCircle(Offset(x + dx, y + dy), 1.5, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlesPainter oldDelegate) =>
      oldDelegate.time != time;
}

/// Bouncing loading dots.
class _LoadingDots extends StatefulWidget {
  const _LoadingDots();

  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final delay = i * 0.2;
            final t = ((_controller.value - delay) % 1.0).clamp(0.0, 1.0);
            final scale = t < 0.4
                ? 1.0 + 0.3 * (t / 0.4)
                : t < 0.8
                    ? 1.3 - 0.3 * ((t - 0.4) / 0.4)
                    : 1.0;
            final opacity = 0.5 + 0.5 * math.sin(t * math.pi);
            return Transform.scale(
              scale: scale,
              child: Container(
                margin: EdgeInsets.only(left: i == 0 ? 0 : 8),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37).withValues(alpha: opacity),
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
