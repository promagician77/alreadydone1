import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/widgets/pressable.dart';

abstract final class PlayerSettingsCoachmarkTokens {
  static const Color bgCard = Color(0xFFFFFDF7);
  static const Color gold = Color(0xFFB8862F);
  static const Color text = Color(0xFF1A1612);
  static const Color textMuted = Color(0xFF7A6F5E);
  static const Color dim = Color.fromRGBO(20, 15, 10, 0.55);
}

class PlayerSettingsCoachmarkOverlay extends StatefulWidget {
  const PlayerSettingsCoachmarkOverlay({
    super.key,
    required this.stackKey,
    required this.settingsTargetKey,
    required this.onGotIt,
    required this.onSettingsTap,
  });

  final GlobalKey stackKey;

  final GlobalKey settingsTargetKey;

  final VoidCallback onGotIt;

  final VoidCallback onSettingsTap;

  @override
  State<PlayerSettingsCoachmarkOverlay> createState() =>
      _PlayerSettingsCoachmarkOverlayState();
}

class _PlayerSettingsCoachmarkOverlayState
    extends State<PlayerSettingsCoachmarkOverlay> {
  Rect? _targetInStack;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  @override
  void didUpdateWidget(covariant PlayerSettingsCoachmarkOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  void _measure() {
    final stackCtx = widget.stackKey.currentContext;
    final targetCtx = widget.settingsTargetKey.currentContext;
    if (stackCtx == null || targetCtx == null) return;

    final stackRb = stackCtx.findRenderObject() as RenderBox?;
    final targetRb = targetCtx.findRenderObject() as RenderBox?;
    if (stackRb == null || targetRb == null || !stackRb.hasSize) return;

    final topLeft =
        stackRb.globalToLocal(targetRb.localToGlobal(Offset.zero));
    final next = Rect.fromLTWH(
      topLeft.dx,
      topLeft.dy,
      targetRb.size.width,
      targetRb.size.height,
    );

    if (_targetInStack == next) return;
    setState(() => _targetInStack = next);
  }

  @override
  Widget build(BuildContext context) {
    final hole = _targetInStack;
    final media = MediaQuery.of(context);
    final horizontalInset = 20.0;
    final cardLeft = horizontalInset;
    final cardWidth = media.size.width - horizontalInset * 2;

    double cardTop;
    double arrowRightFromCardRight = 20;
    if (hole != null) {
      cardTop = hole.bottom + 12;
      final iconCenterX = hole.center.dx;
      final arrowCenterXFromCardLeft = iconCenterX - cardLeft;
      arrowRightFromCardRight = cardWidth - arrowCenterXFromCardLeft - 9;
      arrowRightFromCardRight =
          arrowRightFromCardRight.clamp(12.0, cardWidth - 12.0);
    } else {
      cardTop = 110;
    }

    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        if (hole != null)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {},
              child: CustomPaint(
                painter: _DimWithHolePainter(holeRect: hole),
              ),
            ),
          )
        else
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {},
              child: const ColoredBox(
                color: PlayerSettingsCoachmarkTokens.dim,
              ),
            ),
          ),
        if (hole != null)
          Positioned(
            left: hole.left,
            top: hole.top,
            width: hole.width,
            height: hole.height,
            child: Pressable(
              onTap: widget.onSettingsTap,
              borderRadius: BorderRadius.circular(999),
              child: const SizedBox.expand(),
            ),
          ),
        Positioned(
          left: cardLeft,
          right: horizontalInset,
          top: cardTop,
          child: _CoachmarkCard(
            arrowRightFromCardRight: arrowRightFromCardRight,
            onGotIt: widget.onGotIt,
          ),
        ),
      ],
    );
  }
}

class _DimWithHolePainter extends CustomPainter {
  _DimWithHolePainter({required this.holeRect});

  final Rect holeRect;

  @override
  void paint(Canvas canvas, Size size) {
    final full = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final pad = 6.0;
    final radius = math.max(holeRect.width, holeRect.height) / 2 + pad;
    final hole = Path()
      ..addOval(Rect.fromCircle(center: holeRect.center, radius: radius));
    final cut = Path.combine(PathOperation.difference, full, hole);
    canvas.drawPath(cut, Paint()..color = PlayerSettingsCoachmarkTokens.dim);
  }

  @override
  bool shouldRepaint(covariant _DimWithHolePainter oldDelegate) =>
      oldDelegate.holeRect != holeRect;
}

class _CoachmarkCard extends StatelessWidget {
  const _CoachmarkCard({
    required this.arrowRightFromCardRight,
    required this.onGotIt,
  });

  /// Distance from the **right edge of the card** to the arrow’s horizontal center.
  final double arrowRightFromCardRight;
  final VoidCallback onGotIt;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: PlayerSettingsCoachmarkTokens.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: PlayerSettingsCoachmarkTokens.gold,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 36,
              offset: const Offset(0, 18),
            ),
            BoxShadow(
              color: PlayerSettingsCoachmarkTokens.gold.withValues(alpha: 0.18),
              blurRadius: 60,
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: -9,
              right: arrowRightFromCardRight,
              child: Transform.rotate(
                angle: math.pi / 4,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: PlayerSettingsCoachmarkTokens.bgCard,
                    border: Border(
                      top: BorderSide(
                        color: PlayerSettingsCoachmarkTokens.gold,
                        width: 1,
                      ),
                      left: BorderSide(
                        color: PlayerSettingsCoachmarkTokens.gold,
                        width: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'QUICK TIP',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.8,
                      color: PlayerSettingsCoachmarkTokens.gold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Customize your experience',
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      height: 1.2,
                      color: PlayerSettingsCoachmarkTokens.text,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text.rich(
                    TextSpan(
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        height: 1.55,
                        color: PlayerSettingsCoachmarkTokens.textMuted,
                        fontWeight: FontWeight.w400,
                      ),
                      children: [
                        const TextSpan(text: 'Tap here to access '),
                        TextSpan(
                          text: 'Sleep Mode',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            height: 1.55,
                            fontWeight: FontWeight.w700,
                            color: PlayerSettingsCoachmarkTokens.text,
                          ),
                        ),
                        const TextSpan(text: ', '),
                        TextSpan(
                          text: 'Speed',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            height: 1.55,
                            fontWeight: FontWeight.w700,
                            color: PlayerSettingsCoachmarkTokens.text,
                          ),
                        ),
                        const TextSpan(text: ', and '),
                        TextSpan(
                          text: 'Loop',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            height: 1.55,
                            fontWeight: FontWeight.w700,
                            color: PlayerSettingsCoachmarkTokens.text,
                          ),
                        ),
                        const TextSpan(text: '.'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: Pressable(
                      onTap: onGotIt,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: PlayerSettingsCoachmarkTokens.gold,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: PlayerSettingsCoachmarkTokens.gold
                                  .withValues(alpha: 0.25),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Got it',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
