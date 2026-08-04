import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/nav/nav.dart';
import '/shared/state/onboarding_state.dart';
import '/shared/widgets/pressable.dart';
import 'onboarding_desire_widget.dart';
import 'onboarding_player_widget.dart';

const _gold = Color(0xFFC2922A);
const _goldLight = Color(0xFFD4A574);
const _goldSoft = Color(0xFFF7EFDC);
const _goldFaint = Color(0xFFFBF4E6);
const _ink = Color(0xFF1A1A1A);
const _inkSoft = Color(0xFF8A857C);
const _line = Color(0xFFE6E2D9);
const _bg = Color(0xFFF5F3EE);
const _surface = Colors.white;

/// Shown right after a successful in-sheet subscription from the onboarding
/// player upsell: continue with Part 2 (deepen) or start a new manifestation.
class OnboardingWhatsNextWidget extends StatelessWidget {
  const OnboardingWhatsNextWidget({super.key});

  static String routeName = 'OnboardingWhatsNext';
  static String routePath = '/onboarding/whats-next';

  void _hearPart2(BuildContext context) {
    // Player picks this up on load and deepens the current story automatically.
    OnboardingState.instance.pendingAutoDeepen = true;
    context.go(OnboardingPlayerWidget.routePath);
  }

  void _createNew(BuildContext context) {
    context.go(OnboardingDesireWidget.routePath);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  const Center(child: _YoureInPill()),
                  const SizedBox(height: 22),
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 34,
                        fontWeight: FontWeight.w500,
                        color: _ink,
                        height: 1.1,
                        letterSpacing: -0.4,
                      ),
                      children: [
                        const TextSpan(text: "What's "),
                        TextSpan(
                          text: 'next',
                          style: GoogleFonts.cormorantGaramond(
                            fontSize: 34,
                            fontWeight: FontWeight.w400,
                            fontStyle: FontStyle.italic,
                            color: _gold,
                            height: 1.1,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const TextSpan(text: ' for you?'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Pick where you want to go from here.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: _inkSoft,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _ChoiceCard(
                    primary: true,
                    icon: const Icon(Icons.graphic_eq,
                        size: 26, color: Colors.white),
                    tag: 'CONTINUE THE STORY',
                    title: 'Hear Part 2',
                    body:
                        'Deepen your manifestation with a new chapter of the same story.',
                    onTap: () => _hearPart2(context),
                  ),
                  const SizedBox(height: 14),
                  _ChoiceCard(
                    primary: false,
                    icon: const Icon(Icons.flare, size: 26, color: _gold),
                    tag: 'START FRESH',
                    title: 'Create a new manifestation',
                    body:
                        'Choose a new category: love, money, health, home, and more.',
                    onTap: () => _createNew(context),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: _surface,
                      border: Border.all(color: _line),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                            color: _goldFaint,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.schedule,
                              size: 14, color: _gold),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                color: _inkSoft,
                                height: 1.4,
                              ),
                              children: [
                                TextSpan(
                                  text: 'One story per day. ',
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: _ink,
                                    height: 1.4,
                                  ),
                                ),
                                const TextSpan(
                                    text: 'Your next unlock is in 24 hours.'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Gold "YOU'RE IN!" confirmation pill with a soft pulse.
class _YoureInPill extends StatefulWidget {
  const _YoureInPill();

  @override
  State<_YoureInPill> createState() => _YoureInPillState();
}

class _YoureInPillState extends State<_YoureInPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween<double>(begin: 1.0, end: 1.03).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_goldLight, _gold],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: _gold.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: _gold.withValues(alpha: 0.08),
              spreadRadius: 6,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.diamond, size: 15, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              "YOU'RE IN!",
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 2.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.primary,
    required this.icon,
    required this.tag,
    required this.title,
    required this.body,
    required this.onTap,
  });

  final bool primary;
  final Widget icon;
  final String tag;
  final String title;
  final String body;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      scaleDownTo: 0.98,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: primary
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFFFCF3), _goldSoft],
                )
              : null,
          color: primary ? null : _surface,
          border: Border.all(
            color: primary ? _gold : _line,
            width: primary ? 2 : 1.5,
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: primary
                        ? const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [_goldLight, _gold],
                          )
                        : null,
                    color: primary ? null : _goldSoft,
                    border:
                        primary ? null : Border.all(color: _goldLight),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: primary
                        ? [
                            BoxShadow(
                              color: _gold.withValues(alpha: 0.25),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(child: icon),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tag,
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: _gold,
                          letterSpacing: 1.4,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        title,
                        style: GoogleFonts.cormorantGaramond(
                          fontSize: 21,
                          fontWeight: FontWeight.w500,
                          color: _ink,
                          height: 1.1,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: primary ? _gold : _bg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward,
                    size: 14,
                    color: primary ? Colors.white : _ink,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 62),
              child: Text(
                body,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: _inkSoft,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
