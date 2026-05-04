import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/pages/player/coachmark/player_settings_coachmark.dart';
import '/widgets/pressable.dart';

/// One-time home tip: dim + cutout over **+ Add New Manifestation**; bottom nav is outside this stack.
class HomeNewManifestationCoachmarkOverlay extends StatefulWidget {
  const HomeNewManifestationCoachmarkOverlay({
    super.key,
    required this.stackKey,
    required this.addButtonTargetKey,
    required this.onGotIt,
  });

  final GlobalKey stackKey;
  final GlobalKey addButtonTargetKey;
  final VoidCallback onGotIt;

  @override
  State<HomeNewManifestationCoachmarkOverlay> createState() =>
      _HomeNewManifestationCoachmarkOverlayState();
}

class _HomeNewManifestationCoachmarkOverlayState
    extends State<HomeNewManifestationCoachmarkOverlay> {
  Rect? _targetInStack;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  @override
  void didUpdateWidget(covariant HomeNewManifestationCoachmarkOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  void _measure() {
    final stackCtx = widget.stackKey.currentContext;
    final targetCtx = widget.addButtonTargetKey.currentContext;
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
    const horizontalInset = 20.0;

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
              child: const ColoredBox(color: PlayerSettingsCoachmarkTokens.dim),
            ),
          ),
        Positioned.fill(
          child: Align(
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: horizontalInset),
              child: _CoachmarkCard(onGotIt: widget.onGotIt),
            ),
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
    const pad = 4.0;
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

class _CoachmarkCard extends StatelessWidget {
  const _CoachmarkCard({required this.onGotIt});

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
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 36,
              offset: const Offset(0, 18),
            ),
            BoxShadow(
              color: PlayerSettingsCoachmarkTokens.gold.withValues(alpha: 0.2),
              blurRadius: 60,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
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
                'Create new manifestations',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                  color: PlayerSettingsCoachmarkTokens.text,
                ),
              ),
              const SizedBox(height: 10),
              Text.rich(
                TextSpan(
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    height: 1.55,
                    color: PlayerSettingsCoachmarkTokens.textMuted,
                    fontWeight: FontWeight.w400,
                  ),
                  children: [
                    const TextSpan(text: 'Tap '),
                    TextSpan(
                      text: 'Home',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        height: 1.55,
                        fontWeight: FontWeight.w700,
                        color: PlayerSettingsCoachmarkTokens.text,
                      ),
                    ),
                    const TextSpan(
                      text: ' in the navigation, then scroll down and tap ',
                    ),
                    TextSpan(
                      text: '+ Add New Manifestation',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        height: 1.55,
                        fontWeight: FontWeight.w700,
                        color: PlayerSettingsCoachmarkTokens.text,
                      ),
                    ),
                    const TextSpan(text: ' to create a new story.'),
                  ],
                ),
              ),
              const SizedBox(height: 18),
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
                              .withValues(alpha: 0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Got it',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
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
}
