import 'dart:math' as math;
import 'package:flutter/material.dart';
import '/pages/auth/auth_theme.dart';

/// Shared animated waveform icon — bars gently oscillate in height.
/// Used across auth, onboarding splash, subscription, etc.
enum AnimatedWaveformSize {
  /// Auth (login, sign up, email verification): 72×72 boxed
  auth,
  /// Onboarding splash: larger, 120×85
  splash,
  /// Subscription paywall: compact, 64×48
  paywall,
}

class AnimatedWaveformIcon extends StatefulWidget {
  final AnimatedWaveformSize size;
  /// Show bordered container (auth style). Only used when size is [AnimatedWaveformSize.auth].
  final bool wrapped;

  const AnimatedWaveformIcon({
    super.key,
    this.size = AnimatedWaveformSize.auth,
    this.wrapped = true,
  });

  @override
  State<AnimatedWaveformIcon> createState() => _AnimatedWaveformIconState();
}

class _AnimatedWaveformIconState extends State<AnimatedWaveformIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  static const _authHeights = [8.0, 12.0, 18.0, 24.0, 32.0, 36.0, 32.0, 24.0, 18.0, 12.0, 8.0];
  static const _splashHeights = [14.0, 22.0, 32.0, 42.0, 54.0, 62.0, 54.0, 42.0, 32.0, 22.0, 14.0];
  static const _paywallHeights = [8.0, 14.0, 22.0, 28.0, 36.0, 30.0, 24.0, 18.0, 12.0, 6.0];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<double> get _baseHeights {
    switch (widget.size) {
      case AnimatedWaveformSize.auth:
        return _authHeights;
      case AnimatedWaveformSize.splash:
        return _splashHeights;
      case AnimatedWaveformSize.paywall:
        return _paywallHeights;
    }
  }

  int get _barCount => _baseHeights.length;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value * 2 * math.pi;
        final content = _buildBars(t);
        if (widget.size == AnimatedWaveformSize.auth && widget.wrapped) {
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
            child: Center(child: content),
          );
        }
        return content;
      },
    );
  }

  Widget _buildBars(double t) {
    final (barWidth, spacing, childSize, opacityFn) = switch (widget.size) {
      AnimatedWaveformSize.auth => (3.0, 1.5, const Size(72, 72), _authOpacity),
      AnimatedWaveformSize.splash => (6.0, 3.0, const Size(120, 85), _constantOpacity),
      AnimatedWaveformSize.paywall => (4.0, 2.0, const Size(64, 48), _constantOpacity),
    };

    return SizedBox(
      width: childSize.width,
      height: childSize.height,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(_barCount, (i) {
          final baseH = _baseHeights[i];
          // Oscillate height: slight variation (0.85–1.15 of base), phase-staggered per bar
          final phase = i * 0.5;
          final factor = 0.92 + 0.16 * math.sin(t + phase);
          final h = (baseH * factor).clamp(baseH * 0.7, baseH * 1.2);

          final opacity = opacityFn(i);

          return Container(
            width: barWidth,
            height: h,
            margin: EdgeInsets.only(left: i == 0 ? 0 : spacing),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(barWidth * 0.6),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AuthTheme.goldLight.withValues(alpha: opacity),
                  AuthTheme.gold.withValues(alpha: opacity),
                  AuthTheme.goldDark.withValues(alpha: opacity),
                ],
              ),
              boxShadow: widget.size == AnimatedWaveformSize.splash ||
                      widget.size == AnimatedWaveformSize.paywall
                  ? [
                      BoxShadow(
                        color: AuthTheme.gold.withValues(
                            alpha: widget.size == AnimatedWaveformSize.splash ? 0.25 : 0.2),
                        blurRadius: widget.size == AnimatedWaveformSize.splash ? 12 : 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
          );
        }),
      ),
    );
  }

  static double _authOpacity(int i) {
    const opacities = <double>[0.3, 0.45, 0.6, 0.75, 0.9, 1.0, 0.9, 0.75, 0.6, 0.45, 0.3];
    return opacities[i];
  }

  static double _constantOpacity(int _) => 1.0;
}
