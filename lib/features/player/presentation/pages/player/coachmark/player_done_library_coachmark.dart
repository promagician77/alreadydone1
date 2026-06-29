import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/shared/widgets/pressable.dart';
import 'player_settings_coachmark.dart';

const double _kCaretSize = 18;

/// One-time tip pointing at the Done (library) tab; matches [done-library-coachmark.jsx].
class PlayerDoneLibraryCoachmarkOverlay extends StatefulWidget {
  const PlayerDoneLibraryCoachmarkOverlay({
    super.key,
    required this.stackKey,
    required this.doneTabTargetKey,
    required this.onGotIt,
  });

  final GlobalKey stackKey;
  final GlobalKey doneTabTargetKey;
  final VoidCallback onGotIt;

  @override
  State<PlayerDoneLibraryCoachmarkOverlay> createState() =>
      _PlayerDoneLibraryCoachmarkOverlayState();
}

class _PlayerDoneLibraryCoachmarkOverlayState
    extends State<PlayerDoneLibraryCoachmarkOverlay> {
  Rect? _targetInStack;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  @override
  void didUpdateWidget(covariant PlayerDoneLibraryCoachmarkOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  void _measure() {
    final stackCtx = widget.stackKey.currentContext;
    final targetCtx = widget.doneTabTargetKey.currentContext;
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
    const horizontalInset = 20.0;
    /// Space between Done tab top and the caret tip (keep small; was 12 + inflated card height).
    const gapAboveTarget = 4.0;
    /// Approximate card+caret height (QUICK TIP + title + body + button + padding); avoids huge vertical gap.
    const approxCardHeight = 200.0;

    final cardLeft = horizontalInset;
    final cardWidth = media.size.width - horizontalInset * 2;

    double arrowRightFromCardRight = 20;
    double? cardTop;
    if (hole != null) {
      final iconCenterX = hole.center.dx;
      final arrowCenterXFromCardLeft = iconCenterX - cardLeft;
      arrowRightFromCardRight =
          cardWidth - arrowCenterXFromCardLeft - 9;
      arrowRightFromCardRight =
          arrowRightFromCardRight.clamp(12.0, cardWidth - 12.0);

      final cardBottomY = hole.top - gapAboveTarget;
      cardTop = (cardBottomY - approxCardHeight).clamp(16.0, double.infinity);
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
        if (cardTop != null)
          Positioned(
            left: cardLeft,
            right: horizontalInset,
            top: cardTop,
            child: _LibraryCoachmarkCard(
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
    const pad = 2.0;
    final hole = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          holeRect.inflate(pad),
          const Radius.circular(12),
        ),
      );
    final cut = Path.combine(PathOperation.difference, full, hole);
    canvas.drawPath(cut, Paint()..color = PlayerSettingsCoachmarkTokens.dim);
  }

  @override
  bool shouldRepaint(covariant _DimWithHolePainter oldDelegate) =>
      oldDelegate.holeRect != holeRect;
}

class _LibraryCoachmarkCard extends StatelessWidget {
  const _LibraryCoachmarkCard({
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
              bottom: -9,
              right: arrowRightFromCardRight,
              child: Transform.rotate(
                angle: math.pi / 4,
                child: Container(
                  width: _kCaretSize,
                  height: _kCaretSize,
                  decoration: BoxDecoration(
                    color: PlayerSettingsCoachmarkTokens.bgCard,
                    border: Border(
                      right: BorderSide(
                        color: PlayerSettingsCoachmarkTokens.gold,
                        width: 1,
                      ),
                      bottom: BorderSide(
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
                    'Your library lives here',
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      height: 1.2,
                      color: PlayerSettingsCoachmarkTokens.text,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This is your library where all your manifestations are stored.',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      height: 1.55,
                      color: PlayerSettingsCoachmarkTokens.textMuted,
                      fontWeight: FontWeight.w400,
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
