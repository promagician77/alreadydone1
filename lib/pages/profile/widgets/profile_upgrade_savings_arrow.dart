import 'package:flutter/material.dart';

class ProfileUpgradeSavingsArrow extends StatelessWidget {
  const ProfileUpgradeSavingsArrow({super.key, required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: CustomPaint(
        size: const Size(20, 12),
        painter: _ProfileUpgradeSavingsArrowPainter(
          color: color.withValues(alpha: 0.92),
        ),
      ),
    );
  }
}

class _ProfileUpgradeSavingsArrowPainter extends CustomPainter {
  const _ProfileUpgradeSavingsArrowPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final centerY = size.height / 2;
    canvas.drawLine(Offset(0, centerY), Offset(size.width - 5, centerY), paint);

    final arrowHead = Path()
      ..moveTo(size.width - 9, centerY - 4)
      ..lineTo(size.width - 1.5, centerY)
      ..lineTo(size.width - 9, centerY + 4);
    canvas.drawPath(arrowHead, paint);
  }

  @override
  bool shouldRepaint(covariant _ProfileUpgradeSavingsArrowPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
