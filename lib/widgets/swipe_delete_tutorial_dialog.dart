import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '/services/supabase_service.dart';
import '/widgets/pressable.dart';

/// Design tokens aligned with [desires_widget.dart] `_DesiresColors`.
class _DoneTokens {
  static const warmWhite = Color(0xFFF9F7F4);
  static const surface = Color(0xFFFEFDFB);
  static const ink = Color(0xFF1C1917);
  static const inkMid = Color(0xFF44403C);
  static const inkSoft = Color(0xFF78716C);
  static const stone = Color(0xFFE8E2DA);
  static const gold = Color(0xFFB8861E);
  static const goldPale = Color(0xFFFBF4E6);
  static const goldLight = Color(0xFFD4A574);
  static const red = Color(0xFFDC2626);
  static const redDark = Color(0xFF991B1B);
  static const redPale = Color(0xFFFEE2E2);
}

/// One-time "Swipe to delete" tutorial after the user taps the Done nav tab.
class SwipeDeleteTutorial {
  SwipeDeleteTutorial._();

  static const String _prefsKeyPrefix = 'done_swipe_delete_tutorial_v1_';

  static String? _storageKeyOrNull() {
    final id = SupabaseService.currentUser?.id;
    if (id == null || id.isEmpty) return null;
    return '$_prefsKeyPrefix${id.toLowerCase()}';
  }

  /// Call after switching to the Done tab via the bottom nav tap handler only.
  static Future<void> maybeShowAfterDoneNavTap(BuildContext context) async {
    final key = _storageKeyOrNull();
    if (key == null) return;
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(key) ?? false) return;
    if (!context.mounted) return;

    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      transitionDuration: Duration.zero,
      pageBuilder: (dialogContext, _, __) {
        return _SwipeDeleteTutorialOverlay(
          onDismiss: () => Navigator.of(dialogContext).pop(),
        );
      },
    );

    await prefs.setBool(key, true);
  }
}

class _SwipeDeleteTutorialOverlay extends StatefulWidget {
  const _SwipeDeleteTutorialOverlay({required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  State<_SwipeDeleteTutorialOverlay> createState() =>
      _SwipeDeleteTutorialOverlayState();
}

class _SwipeDeleteTutorialOverlayState extends State<_SwipeDeleteTutorialOverlay>
    with SingleTickerProviderStateMixin {
  static const _laneHeight = 96.0;

  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final modalMaxW = math.min(media.size.width - 40, 340.0);

    return Material(
      color: Colors.transparent,
      child: Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onDismiss,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: Container(
                color: _DoneTokens.ink.withValues(alpha: 0.72),
              ),
            ),
          ),
          Center(
            child: GestureDetector(
              onTap: () {},
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 420),
                curve: Curves.easeOutCubic,
                builder: (context, slideUp, child) {
                  return Transform.translate(
                    offset: Offset(0, (1 - slideUp) * 36),
                    child: Opacity(opacity: slideUp, child: child),
                  );
                },
                child: Container(
                  constraints: BoxConstraints(maxWidth: modalMaxW),
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.fromLTRB(28, 36, 28, 28),
                  decoration: BoxDecoration(
                    color: _DoneTokens.surface,
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: _DoneTokens.stone, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: _DoneTokens.ink.withValues(alpha: 0.14),
                        blurRadius: 48,
                        offset: const Offset(0, 18),
                        spreadRadius: -4,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final laneW = constraints.maxWidth.clamp(248.0, 302.0);
                          return AnimatedBuilder(
                            animation: _pulse,
                            builder: (context, _) {
                              final t =
                                  Curves.easeInOut.transform(_pulse.value);
                              final reveal = math
                                  .pow(math.sin(math.pi * t), 0.85)
                                  .clamp(0.0, 1.0)
                                  .toDouble();
                              final swipeDx =
                                  (-laneW * 0.175) *
                                  math.pow(math.sin(math.pi * t), 0.9)
                                      .clamp(0.0, 1.0)
                                      .toDouble();

                              return Column(
                                children: [
                                  Icon(
                                    Icons.arrow_back_rounded,
                                    size: 34,
                                    color: Color.lerp(
                                      _DoneTokens.gold
                                          .withValues(alpha: 0.55),
                                      _DoneTokens.gold,
                                      reveal,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  _SwipeTutorialLane(
                                    laneWidth: laneW,
                                    laneHeight: _laneHeight,
                                    swipeDx: swipeDx,
                                    reveal: reveal,
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 28),
                      Text(
                        'Swipe to Delete',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cormorantGaramond(
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          color: _DoneTokens.ink,
                          height: 1.25,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text.rich(
                        TextSpan(
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            color: _DoneTokens.inkMid,
                            height: 1.55,
                          ),
                          children: [
                            const TextSpan(
                              text: 'To delete a story from your library (',
                            ),
                            WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 1),
                                child: Icon(
                                  Icons.check_circle,
                                  size: 16,
                                  color: _DoneTokens.gold,
                                ),
                              ),
                            ),
                            const TextSpan(
                              text: 'Done), swipe left.',
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),
                      Pressable(
                        onTap: widget.onDismiss,
                        borderRadius: BorderRadius.circular(14),
                        backgroundColor: _DoneTokens.gold,
                        splashColor: Colors.white24,
                        highlightColor: Colors.white12,
                        enableScaleAnimation: true,
                        child: SizedBox(
                          width: double.infinity,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: Text(
                                'Got It',
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Peek lane + foreground row matching Done library normal story row.
class _SwipeTutorialLane extends StatelessWidget {
  const _SwipeTutorialLane({
    required this.laneWidth,
    required this.laneHeight,
    required this.swipeDx,
    required this.reveal,
  });

  final double laneWidth;
  final double laneHeight;
  final double swipeDx;
  final double reveal;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: laneWidth,
        height: laneHeight,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: _DoneTokens.warmWhite,
                  border: Border.all(color: _DoneTokens.stone, width: 1.5),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            _DoneTokens.redPale,
                            _DoneTokens.red.withValues(
                              alpha: 0.18 + 0.72 * reveal,
                            ),
                          ],
                          stops: const [0.35, 1],
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 14),
                        child: Opacity(
                          opacity: reveal.clamp(0.0, 1.0),
                          child: Transform.scale(
                            scale: 0.88 + 0.12 * reveal,
                            child: Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                color: _DoneTokens.redDark,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: _DoneTokens.red.withValues(
                                      alpha: 0.35,
                                    ),
                                    blurRadius: 10,
                                    offset: const Offset(-2, 2),
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.delete_outline_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Transform.translate(
              offset: Offset(swipeDx, 0),
              child: _TutorialNormalStoryRow(width: laneWidth),
            ),
          ],
        ),
      ),
    );
  }
}

/// Mirrors `_buildStoryItem` normal state in [desires_widget.dart].
class _TutorialNormalStoryRow extends StatelessWidget {
  const _TutorialNormalStoryRow({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: _DoneTokens.surface,
        border: Border.all(color: _DoneTokens.stone, width: 1.5),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: _DoneTokens.ink.withValues(alpha: 0.07),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_DoneTokens.goldPale, _DoneTokens.warmWhite],
              ),
              border: Border.all(color: _DoneTokens.goldLight, width: 1.5),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              '✓',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: _DoneTokens.ink,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'The Joy That Changed Everything',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _DoneTokens.ink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '1w ago · 02:12',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: _DoneTokens.inkSoft,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _DoneTokens.gold,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _DoneTokens.ink.withValues(alpha: 0.06),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: const Icon(
              Icons.play_arrow_rounded,
              size: 18,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
