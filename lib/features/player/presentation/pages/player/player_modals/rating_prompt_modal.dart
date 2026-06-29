import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/features/player/data/datasources/rating_prompt_prefs.dart';

/// Match [_PlayerColors] in player_widget — duplicated because that class is private.
class _R {
  static const ink = Color(0xFF1C1917);
  static const inkMid = Color(0xFF44403C);
  static const inkSoft = Color(0xFF78716C);
  static const stoneMid = Color(0xFFD6D0C8);
  static const gold = Color(0xFFB8861E);
  static const goldDark = Color(0xFF8B6914);
  static const goldPale = Color(0xFFFBF4E6);
  static const surface = Color(0xFFFFFFFF);
}

/// Full-screen backdrop + centered card matching the HTML rating design.
Future<void> showRatingPromptModal(
  BuildContext context, {
  required RatingPromptVariant variant,
  required VoidCallback onRate,
  required VoidCallback onMaybeLater,
  required VoidCallback onNoThanks,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.transparent,
    useRootNavigator: true,
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (ctx, animation, secondaryAnimation) {
      return _RatingPromptPage(
        fade: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        scale: Tween<double>(begin: 0.95, end: 1).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        ),
        variant: variant,
        onRate: onRate,
        onMaybeLater: onMaybeLater,
        onNoThanks: onNoThanks,
      );
    },
  );
}

class _RatingPromptPage extends StatefulWidget {
  const _RatingPromptPage({
    required this.fade,
    required this.scale,
    required this.variant,
    required this.onRate,
    required this.onMaybeLater,
    required this.onNoThanks,
  });

  final Animation<double> fade;
  final Animation<double> scale;
  final RatingPromptVariant variant;
  final VoidCallback onRate;
  final VoidCallback onMaybeLater;
  final VoidCallback onNoThanks;

  @override
  State<_RatingPromptPage> createState() => _RatingPromptPageState();
}

class _RatingPromptPageState extends State<_RatingPromptPage>
    with TickerProviderStateMixin {
  late AnimationController _starsAc;
  late List<Animation<double>> _starScales;
  bool _choiceHandled = false;

  @override
  void initState() {
    super.initState();
    _starsAc = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _starScales = List.generate(5, (i) {
      final begin = (0.05 * i).clamp(0.0, 0.75);
      final end = (0.35 + 0.12 * i).clamp(begin + 0.05, 1.0);
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _starsAc,
          curve: Interval(begin, end, curve: Curves.elasticOut),
        ),
      );
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _starsAc.forward();
    });
  }

  @override
  void dispose() {
    _starsAc.dispose();
    super.dispose();
  }

  void _popThen(VoidCallback fn) {
    _choiceHandled = true;
    Navigator.of(context).pop();
    fn();
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.variant;
    final badge = switch (v) {
      RatingPromptVariant.day7 => null,
      RatingPromptVariant.day30 => '30 Days',
      RatingPromptVariant.day90 => '90 Days 🎉',
    };
    final title = switch (v) {
      RatingPromptVariant.day7 => 'Loving Already Done?',
      RatingPromptVariant.day30 =>
        "You've Been Manifesting for 30 Days!",
      RatingPromptVariant.day90 => "You're a Manifestation Pro!",
    };
    final message = switch (v) {
      RatingPromptVariant.day7 =>
        "If you're enjoying your daily manifestation stories, would you mind rating us? It takes 5 seconds and helps us grow.",
      RatingPromptVariant.day30 =>
        'If Already Done has helped you, a quick rating would mean the world to us.',
      RatingPromptVariant.day90 =>
        'Would you share your experience with a rating? Your feedback shapes the app.',
    };
    final primaryLabel = switch (v) {
      RatingPromptVariant.day30 => 'Leave a Rating',
      RatingPromptVariant.day7 => 'Rate Already Done',
      RatingPromptVariant.day90 => 'Rate Already Done',
    };

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (_, __) {
        if (_choiceHandled) return;
        _choiceHandled = true;
        widget.onMaybeLater();
      },
      child: FadeTransition(
        opacity: widget.fade,
        child: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _popThen(widget.onMaybeLater),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                child: Container(
                  color: _R.ink.withValues(alpha: 0.6),
                ),
              ),
            ),
          ),
          Center(
            child: ScaleTransition(
              scale: widget.scale,
              child: Material(
                color: Colors.transparent,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 240),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                    decoration: BoxDecoration(
                      color: _R.surface,
                      borderRadius: BorderRadius.circular(16),
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
                        if (badge != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _R.goldPale,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              badge,
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _R.goldDark,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (i) {
                            return AnimatedBuilder(
                              animation: _starScales[i],
                              builder: (_, __) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 3),
                                  child: Transform.scale(
                                    scale: _starScales[i].value,
                                    child: const Icon(
                                      Icons.star_rounded,
                                      size: 28,
                                      color: _R.gold,
                                    ),
                                  ),
                                );
                              },
                            );
                          }),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cormorantGaramond(
                            fontSize: 22,
                            fontWeight: FontWeight.w500,
                            color: _R.ink,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          message,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            height: 1.5,
                            color: _R.inkMid,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _primaryButton(primaryLabel, () => _popThen(widget.onRate)),
                        const SizedBox(height: 8),
                        if (v == RatingPromptVariant.day30)
                          _secondaryFullWidth('Not Now', () => _popThen(widget.onMaybeLater))
                        else
                          Row(
                            children: [
                              Expanded(
                                child: _secondaryCompact(
                                  'Maybe Later',
                                  () => _popThen(widget.onMaybeLater),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _secondaryCompact(
                                  'No Thanks',
                                  () => _popThen(widget.onNoThanks),
                                ),
                              ),
                            ],
                          ),
                      ],
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
    );
  }

  Widget _primaryButton(String label, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: _R.gold,
          foregroundColor: Colors.white,
          elevation: 1,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _secondaryCompact(String label, VoidCallback onTap) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: _R.inkSoft,
        side: const BorderSide(color: _R.stoneMid),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _secondaryFullWidth(String label, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: _R.inkSoft,
          side: const BorderSide(color: _R.stoneMid),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
