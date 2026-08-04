import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/features/subscription/data/datasources/subscription_checkout.dart';
import '/shared/services/app_toast.dart';
import '/shared/services/onboarding_service.dart';
import '/shared/widgets/pressable.dart';

/// Result of the onboarding subscription upsell sheet.
enum SubscriptionUpsellOutcome {
  /// User subscribed successfully in the modal.
  subscribed,

  /// User tapped Maybe later / close / barrier (skip subscribe).
  declined,
}

/// Shows the "Keep going." subscription upsell bottom sheet.
/// Purchase happens in-sheet; on success the caller should go to What's Next.
Future<SubscriptionUpsellOutcome> showSubscriptionUpsellModal(
  BuildContext context,
) async {
  final outcome = await showModalBottomSheet<SubscriptionUpsellOutcome>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x801C1917),
    isDismissible: true,
    enableDrag: true,
    builder: (modalContext) => const SubscriptionUpsellModal(),
  );
  return outcome ?? SubscriptionUpsellOutcome.declined;
}

class SubscriptionUpsellModal extends StatefulWidget {
  const SubscriptionUpsellModal({super.key});

  @override
  State<SubscriptionUpsellModal> createState() =>
      _SubscriptionUpsellModalState();
}

class _SubscriptionUpsellModalState extends State<SubscriptionUpsellModal> {
  static const _gold = Color(0xFFC2922A);
  static const _goldLight = Color(0xFFD4A574);
  static const _goldSoft = Color(0xFFF7EFDC);
  static const _goldFaint = Color(0xFFFBF4E6);
  static const _goldDark = Color(0xFF8B6914);
  static const _ink = Color(0xFF1A1A1A);
  static const _inkSoft = Color(0xFF8A857C);
  static const _line = Color(0xFFE6E2D9);
  static const _bg = Color(0xFFF5F3EE);

  bool _annualSelected = true;
  bool _isPurchasing = false;

  void _pop(SubscriptionUpsellOutcome outcome) {
    if (!mounted || _isPurchasing) return;
    Navigator.of(context).pop(outcome);
  }

  Future<void> _handleSubscribe() async {
    if (_isPurchasing) return;
    setState(() => _isPurchasing = true);

    final wantAnnual = _annualSelected;
    final result = await SubscriptionCheckout.purchase(
      wantAnnual: wantAnnual,
      logScope: 'OnboardingUpsell',
    );

    if (!mounted) return;

    switch (result) {
      case SubscriptionCheckoutResult.success:
        AppToast.success(
          context,
          wantAnnual ? '3-day free trial started!' : 'Subscription active!',
        );
        await OnboardingService.setOnboardingCompleted();
        if (!mounted) return;
        setState(() => _isPurchasing = false);
        Navigator.of(context).pop(SubscriptionUpsellOutcome.subscribed);
        return;
      case SubscriptionCheckoutResult.unsupported:
        AppToast.error(
          context,
          'Subscriptions are available on the App Store (iPhone/iPad) and Google Play (Android). Please use a supported device.',
        );
      case SubscriptionCheckoutResult.notSignedIn:
        AppToast.error(context, 'Please sign in to subscribe');
      case SubscriptionCheckoutResult.packageNotFound:
        AppToast.error(context, 'Plans not available. Please try later.');
      case SubscriptionCheckoutResult.cancelled:
        AppToast.info(
          context,
          'Subscription not started. Tap again and complete both Apple ID and the subscription step.',
        );
      case SubscriptionCheckoutResult.failed:
        AppToast.error(context, 'Payment failed. Please try again.');
    }

    if (mounted) setState(() => _isPurchasing = false);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final ctaLabel = _annualSelected
        ? 'Start 3-Day Free Trial'
        : 'Subscribe & continue';

    return PopScope(
      canPop: !_isPurchasing,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1C1917).withValues(alpha: 0.15),
                  blurRadius: 40,
                  offset: const Offset(0, -12),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Stack(
                children: [
                  Padding(
                    padding:
                        EdgeInsets.fromLTRB(20, 20, 20, 24 + bottomInset),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1C1917)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildMiniWave(),
                        const SizedBox(height: 14),
                        _buildTitle(),
                        const SizedBox(height: 8),
                        _buildSubtitle(),
                        const SizedBox(height: 20),
                        _planTile(
                          title: 'Monthly',
                          price: '\$14.99',
                          period: '/mo',
                          subtitle: 'Billed monthly · Cancel anytime',
                          selected: !_annualSelected,
                          onTap: _isPurchasing
                              ? null
                              : () => setState(() => _annualSelected = false),
                        ),
                        const SizedBox(height: 10),
                        _planTile(
                          title: 'Yearly',
                          price: '\$99.99',
                          period: '/yr',
                          subtitle: 'Billed annually · Cancel anytime',
                          selected: _annualSelected,
                          showSaveBadge: true,
                          onTap: _isPurchasing
                              ? null
                              : () => setState(() => _annualSelected = true),
                        ),
                        const SizedBox(height: 16),
                        Pressable(
                          onTap: _isPurchasing ? null : _handleSubscribe,
                          borderRadius: BorderRadius.circular(14),
                          scaleDownTo: 0.98,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            decoration: BoxDecoration(
                              color: _isPurchasing ? _goldDark : _gold,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: _gold.withValues(alpha: 0.35),
                                  blurRadius: 14,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: _isPurchasing
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    ctaLabel,
                                    style: GoogleFonts.outfit(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Pressable(
                          onTap: _isPurchasing
                              ? null
                              : () => _pop(SubscriptionUpsellOutcome.declined),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 8,
                            ),
                            child: Text(
                              'Maybe later',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: _inkSoft,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Cancel anytime · One story every 24 hours',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.w400,
                            color: _inkSoft,
                            letterSpacing: 0.2,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 14,
                    right: 14,
                    child: Pressable(
                      onTap: _isPurchasing
                          ? null
                          : () => _pop(SubscriptionUpsellOutcome.declined),
                      borderRadius: BorderRadius.circular(15),
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: const BoxDecoration(
                          color: _bg,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 14,
                          color: _inkSoft,
                        ),
                      ),
                    ),
                  ),
                  if (_isPurchasing)
                    Positioned.fill(
                      child: AbsorbPointer(
                        child: ColoredBox(
                          color: Colors.white.withValues(alpha: 0.35),
                        ),
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

  Widget _buildMiniWave() {
    const heights = [10.0, 18.0, 26.0, 22.0, 14.0];
    return SizedBox(
      height: 26,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (var i = 0; i < heights.length; i++) ...[
            if (i > 0) const SizedBox(width: 3),
            Container(
              width: 4,
              height: heights[i],
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_goldLight, _gold, _goldDark],
                  stops: [0.0, 0.6, 1.0],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: GoogleFonts.cormorantGaramond(
          fontSize: 30,
          fontWeight: FontWeight.w500,
          color: _ink,
          height: 1.1,
          letterSpacing: -0.4,
        ),
        children: [
          const TextSpan(text: 'Keep '),
          TextSpan(
            text: 'going.',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 30,
              fontWeight: FontWeight.w400,
              fontStyle: FontStyle.italic,
              color: _gold,
              height: 1.1,
              letterSpacing: -0.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubtitle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text.rich(
        TextSpan(
          style: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: _ink,
            height: 1.5,
          ),
          children: [
            const TextSpan(text: 'Subscribe to hear '),
            TextSpan(
              text: 'Part 2',
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _gold,
                height: 1.5,
              ),
            ),
            const TextSpan(text: ' or '),
            TextSpan(
              text: 'manifest something new',
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _gold,
                height: 1.5,
              ),
            ),
            TextSpan(
              text: ' (love, money, health, home, and more)',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                fontStyle: FontStyle.italic,
                color: _gold,
                height: 1.5,
              ),
            ),
            const TextSpan(text: '.'),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _planTile({
    required String title,
    required String price,
    required String period,
    required String subtitle,
    required bool selected,
    bool showSaveBadge = false,
    VoidCallback? onTap,
  }) {
    return Pressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: selected ? 15 : 16,
          vertical: selected ? 13 : 14,
        ),
        decoration: BoxDecoration(
          color: selected ? _goldSoft : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? _gold : _line,
            width: selected ? 2 : 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _radio(selected),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _ink,
                    ),
                  ),
                ),
                Text.rich(
                  TextSpan(
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: _ink,
                    ),
                    children: [
                      TextSpan(text: price),
                      TextSpan(
                        text: ' $period',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: _inkSoft,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showSaveBadge) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _goldFaint,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'SAVE 44%',
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: _gold,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'only \$8.33/mo',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _gold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ] else
                    const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: _inkSoft,
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

  Widget _radio(bool selected) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? _gold : Colors.white,
        border: Border.all(
          color: selected ? _gold : _line,
          width: 1.5,
        ),
      ),
      child: selected
          ? const Center(
              child: SizedBox(
                width: 8,
                height: 8,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            )
          : null,
    );
  }
}
