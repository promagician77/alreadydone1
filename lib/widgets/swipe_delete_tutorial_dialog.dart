import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '/services/supabase_service.dart';

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
  static const _ink = Color(0xFF1C1917);
  static const _inkMid = Color(0xFF44403C);
  static const _inkSoft = Color(0xFF78716C);
  static const _offWhite = Color(0xFFF2F0ED);
  static const _stone = Color(0xFFE8E2DA);
  static const _stoneMid = Color(0xFFD6D0C8);
  static const _gold = Color(0xFFB8861E);
  static const _red = Color(0xFFC54B3D);

  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onDismiss,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
              child: Container(
                color: const Color(0xBF1C1917),
              ),
            ),
          ),
          Center(
            child: GestureDetector(
              onTap: () {},
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutCubic,
                builder: (context, slideUp, child) {
                  return Transform.translate(
                    offset: Offset(0, (1 - slideUp) * 30),
                    child: Opacity(opacity: slideUp, child: child),
                  );
                },
                child: Container(
                  width: 280,
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 60,
                        offset: const Offset(0, 20),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedBuilder(
                        animation: _pulse,
                        builder: (context, _) {
                          final t =
                              Curves.easeInOut.transform(_pulse.value);
                          final swipeDx = -30 * math.sin(math.pi * t);
                          final reveal = math.sin(math.pi * t);

                          return SizedBox(
                            height: 120,
                            width: 220,
                            child: Stack(
                              alignment: Alignment.center,
                              clipBehavior: Clip.none,
                              children: [
                                Positioned(
                                  top: 0,
                                  child: Transform.translate(
                                    offset: Offset(-25 * reveal, 0),
                                    child: Opacity(
                                      opacity: 0.4 + 0.6 * reveal,
                                      child: Icon(
                                        Icons.arrow_back,
                                        size: 36,
                                        color: Color.lerp(
                                          _gold.withValues(alpha: 0.85),
                                          _gold,
                                          reveal,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  child: Transform.translate(
                                    offset: Offset(swipeDx, 0),
                                    child: _StoryDemoCard(
                                      offWhite: _offWhite,
                                      stone: _stone,
                                      stoneMid: _stoneMid,
                                      ink: _ink,
                                      inkSoft: _inkSoft,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  right: 8,
                                  bottom: 16,
                                  child: Opacity(
                                    opacity: reveal.clamp(0.0, 1.0),
                                    child: Transform.scale(
                                      scale: 0.9 + 0.1 * reveal,
                                      child: Container(
                                        width: 56,
                                        height: 56,
                                        decoration: BoxDecoration(
                                          color: _red,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        alignment: Alignment.center,
                                        child: const Icon(
                                          Icons.delete_outline,
                                          color: Colors.white,
                                          size: 28,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      Text(
                        'Swipe to Delete',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cormorantGaramond(
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                          color: _ink,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text.rich(
                        TextSpan(
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            color: _inkMid,
                            height: 1.5,
                          ),
                          children: [
                            const TextSpan(text: 'Swipe any story '),
                            TextSpan(
                              text: 'left',
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: _ink,
                                height: 1.5,
                              ),
                            ),
                            const TextSpan(
                              text: ' to reveal the delete button.',
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: _GotItButton(
                          gold: _gold,
                          onPressed: widget.onDismiss,
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

class _StoryDemoCard extends StatelessWidget {
  const _StoryDemoCard({
    required this.offWhite,
    required this.stone,
    required this.stoneMid,
    required this.ink,
    required this.inkSoft,
  });

  final Color offWhite;
  final Color stone;
  final Color stoneMid;
  final Color ink;
  final Color inkSoft;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      height: 72,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: offWhite,
        border: Border.all(color: stone, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: stoneMid, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              '✓',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: ink,
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
                  'The Joy That Changed...',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '1w ago · 02:12',
                  style: GoogleFonts.outfit(
                    fontSize: 9,
                    color: inkSoft,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GotItButton extends StatelessWidget {
  const _GotItButton({
    required this.gold,
    required this.onPressed,
  });

  final Color gold;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: gold,
      borderRadius: BorderRadius.circular(10),
      elevation: 0,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        splashColor: Colors.white24,
        highlightColor: Colors.white10,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: gold,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            child: Center(
              child: Text(
                'Got It',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
