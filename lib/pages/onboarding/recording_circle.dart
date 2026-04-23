import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/pages/auth/auth_theme.dart';

/// Circular progress ring. [progress] 0..1.
/// [size] defaults to 180; use 126 for compact voice recording screen.
/// Mic icon has a subtle breathing/pulsing scale animation when not complete.
class RecordingCircle extends StatefulWidget {
  const RecordingCircle({
    super.key,
    required this.progress,
    required this.timerText,
    required this.label,
    this.showCheckmark = false,
    this.size = 180,
  });

  final double progress;
  final String timerText;
  final String label;
  final bool showCheckmark;
  /// Circle diameter. Use 126 for design-matched compact layout.
  final double size;

  @override
  State<RecordingCircle> createState() => _RecordingCircleState();
}

class _RecordingCircleState extends State<RecordingCircle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final strokeWidth = size <= 130 ? 4.0 : 6.0;
    final r = (size / 2) - strokeWidth / 2;
    final circumference = 2 * 3.141592 * r;
    final iconSize = size <= 130 ? 43.0 : 48.0;
    final timeFontSize = size <= 130 ? 16.0 : 24.0;
    final checkSize = size <= 130 ? 36.0 : 56.0;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: CircleRingPainter(
              progress: widget.progress,
              strokeWidth: strokeWidth,
              radius: r,
              circumference: circumference,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.showCheckmark)
                Text(
                  '✓',
                  style: GoogleFonts.outfit(
                    fontSize: checkSize,
                    fontWeight: FontWeight.w600,
                    color: AuthTheme.gold,
                  ),
                )
              else
                AnimatedBuilder(
                  animation: _scale,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scale.value,
                      child: child,
                    );
                  },
                  child: Text('🎙️', style: TextStyle(fontSize: iconSize)),
                ),
              SizedBox(height: size <= 130 ? 6 : 8),
              Text(
                widget.timerText,
                style: GoogleFonts.outfit(
                  fontSize: timeFontSize,
                  fontWeight: FontWeight.w600,
                  color: AuthTheme.ink,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              if (widget.label.isNotEmpty) ...[
                SizedBox(height: size <= 130 ? 2 : 4),
                Text(
                  widget.label,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: AuthTheme.inkSoft,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class CircleRingPainter extends CustomPainter {
  CircleRingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.radius,
    required this.circumference,
  });

  final double progress;
  final double strokeWidth;
  final double radius;
  final double circumference;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: center, radius: radius);
    final bgPaint = Paint()
      ..color = AuthTheme.stone
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);
    if (progress > 0) {
      final progressPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AuthTheme.goldLight, AuthTheme.gold, AuthTheme.goldDark],
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      const startAngle = -3.141592 / 2;
      final sweepAngle = 2 * 3.141592 * progress;
      canvas.drawArc(rect, startAngle, sweepAngle, false, progressPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CircleRingPainter old) => old.progress != progress;
}
