import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/auth/auth_theme.dart';
import '/pages/subscription/subscription_model.dart';
import '/services/backend_client.dart';
import '/services/supabase_service.dart';
import '/services/app_toast.dart';
import '/widgets/pressable.dart';
import 'onboarding_personalize_widget.dart';

class OnboardingSplashWidget extends StatefulWidget {
  const OnboardingSplashWidget({super.key});

  static String routeName = 'OnboardingSplash';
  static String routePath = '/onboarding';

  @override
  State<OnboardingSplashWidget> createState() => _OnboardingSplashWidgetState();
}

class _OnboardingSplashWidgetState extends State<OnboardingSplashWidget> {
  late SubscriptionModel _model;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SubscriptionModel());
    _loadSubscriptionStatus();
  }

  Future<void> _loadSubscriptionStatus() async {
    final userId = await SupabaseService.getCurrentUserTableId();
    if (userId == null) return;
    try {
      final status = await BackendClient.getSubscriptionStatus(userId);
      final subId = status['stripe_subscription_id']?.toString().trim();
      final hasSub = subId != null && subId.isNotEmpty;
      if (mounted) safeSetState(() => _model.isSubscribed = hasSub);
    } catch (_) {}
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuthTheme.warmWhite,
      body: SafeArea(
        child: AbsorbPointer(
          absorbing: _model.isPaymentLoading,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 20),
                    _buildWelcomeHero(),
                    const SizedBox(height: 16),
                    _buildTrialBadge(),
                    const SizedBox(height: 20),
                    _buildPricingCards(),
                    const SizedBox(height: 20),
                    _buildCtaButton(),
                    if (_model.isPaymentLoading)
                      const Padding(
                        padding: EdgeInsets.only(top: 10),
                        child: Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AuthTheme.gold,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 14),
                    _buildSecondaryText(),
                    const SizedBox(height: 10),
                    _buildRestoreLink(),
                    const SizedBox(height: 12),
                    _buildFooterLinks(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: GoogleFonts.cormorantGaramond(
              fontSize: 34,
              fontWeight: FontWeight.w300,
              letterSpacing: -1,
              height: 1.1,
              color: AuthTheme.ink,
            ),
            children: [
              const TextSpan(text: 'Already '),
              TextSpan(
                text: 'Done',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 34,
                  fontWeight: FontWeight.w300,
                  fontStyle: FontStyle.italic,
                  letterSpacing: -1,
                  height: 1.1,
                  color: AuthTheme.gold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeHero() {
    return Column(
      children: [
        Text(
          'Manifest your dreams by hearing YOUR voice narrate them as already complete',
          style: GoogleFonts.outfit(
            fontSize: 13,
            color: AuthTheme.inkSoft,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTrialBadge() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AuthTheme.goldPale, AuthTheme.warmWhite],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AuthTheme.goldLight, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AuthTheme.ink.withValues(alpha: 0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          '✨ Start Your 7-Day Free Trial',
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AuthTheme.goldDark,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildPricingCards() {
    return Column(
      children: [
        _buildPricingCard(
          plan: 'Annual',
          price: '\$69.99',
          period: '/year',
          isRecommended: true,
          savingsLabel: 'Save \$50 vs monthly plan',
          features: const [
            'Unlimited manifestation stories',
            'Custom voice cloning',
            'Sleep Mode with theta waves',
            'All premium voices',
          ],
          isSelected: _model.selectedPlan == 0,
          onTap: () => safeSetState(() => _model.selectedPlan = 0),
        ),
        const SizedBox(height: 12),
        _buildPricingCard(
          plan: 'Monthly',
          price: '\$9.99',
          period: '/month',
          isRecommended: false,
          savingsLabel: null,
          features: const [
            'Unlimited manifestation stories',
            'Custom voice cloning',
            'Sleep Mode with theta waves',
            'All premium voices',
          ],
          isSelected: _model.selectedPlan == 1,
          onTap: () => safeSetState(() => _model.selectedPlan = 1),
        ),
      ],
    );
  }

  Widget _buildPricingCard({
    required String plan,
    required String price,
    required String period,
    required bool isRecommended,
    required List<String> features,
    String? savingsLabel,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Pressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected ? AuthTheme.goldPale : AuthTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? AuthTheme.gold : AuthTheme.stone,
                width: 2,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AuthTheme.ink.withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      plan,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AuthTheme.ink,
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          price,
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AuthTheme.ink,
                          ),
                        ),
                        Text(
                          period,
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: AuthTheme.inkSoft,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: features
                      .map(
                        (f) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '✓',
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  color: AuthTheme.gold,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  f,
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    color: AuthTheme.inkSoft,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
                if (savingsLabel != null) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AuthTheme.goldPale,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      savingsLabel,
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AuthTheme.goldDark,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (isRecommended)
            Positioned(
              top: -10,
              right: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AuthTheme.gold,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: AuthTheme.ink.withValues(alpha: 0.06),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Text(
                  'BEST VALUE',
                  style: GoogleFonts.outfit(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: AuthTheme.surface,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCtaButton() {
    final label =
        _model.isSubscribed ? 'Update Plan' : 'Start Free Trial';
    return _ctaButton(
      label: label,
      onTap: () => _handleConfirmPayment(isStartTrial: !_model.isSubscribed),
    );
  }

  String get _planForBackend {
    if (_model.selectedPlan == 1) return 'weekly';
    return 'annual';
  }

  static bool _isStripeConfigError(Object e) {
    final s = e.toString();
    return s.contains('StripeConfigException') ||
        s.contains('publishable') && s.toLowerCase().contains('required') ||
        s.contains('Publishable Key is required');
  }

  Future<void> _handleConfirmPayment({required bool isStartTrial}) async {
    if (_model.isPaymentLoading) return;

    if (_model.selectedPlan == null) {
      AppToast.info(context, 'Please select a plan first');
      return;
    }

    final userId = await SupabaseService.getCurrentUserTableId();
    final email = SupabaseService.currentUser?.email?.trim();
    if (userId == null || email == null || email.isEmpty) {
      AppToast.error(context, 'Please sign in to subscribe');
      return;
    }

    safeSetState(() => _model.isPaymentLoading = true);

    try {
      final setupResponse = await BackendClient.createSetupIntent(
        userId: userId,
        customerEmail: email,
      );
      final clientSecret = setupResponse['client_secret'] as String?;
      final setupIntentId = setupResponse['setup_intent_id'] as String?;
      if (clientSecret == null ||
          clientSecret.isEmpty ||
          setupIntentId == null ||
          setupIntentId.isEmpty) {
        throw Exception('Invalid setup intent response');
      }
      if (!mounted) return;

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          setupIntentClientSecret: clientSecret,
          merchantDisplayName: 'Already Done',
        ),
      );
      if (!mounted) return;

      await Stripe.instance.presentPaymentSheet();
      if (!mounted) return;

      await BackendClient.createSubscription(
        userId: userId,
        plan: _planForBackend,
        setupIntentId: setupIntentId,
        customerEmail: email,
      );
      if (!mounted) return;

      AppToast.success(
        context,
        isStartTrial ? '7-day free trial started!' : 'Subscription active!',
      );
      context.go(OnboardingPersonalizeWidget.routePath);
    } catch (e) {
      if (!mounted) return;
      if (e is StripeException) {
        if (e.error.code == FailureCode.Canceled) {
          AppToast.info(context, 'Payment canceled');
        } else {
          AppToast.error(context, e.error.localizedMessage ?? 'Payment failed');
        }
      } else if (_isStripeConfigError(e)) {
        AppToast.error(
          context,
          'Payment is not configured. Add STRIPE_PUBLISHABLE_KEY to your .env file (get it from Stripe Dashboard → API keys).',
        );
      } else {
        final msg = e.toString().replaceFirst(RegExp(r'^Exception: '), '');
        AppToast.error(
          context,
          msg.startsWith('Instance of ')
              ? 'Payment failed. Please try again.'
              : msg,
        );
      }
    } finally {
      if (mounted) {
        safeSetState(() => _model.isPaymentLoading = false);
      }
    }
  }

  Widget _ctaButton({required String label, required VoidCallback onTap}) {
    return Material(
      color: _model.isPaymentLoading ? AuthTheme.goldDark : AuthTheme.gold,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: _model.isPaymentLoading ? null : onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AuthTheme.surface,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryText() {
    return Text(
      'Free for 7 days, then \$69.99/year or \$9.99/month.\nCancel anytime in Settings.',
      style: GoogleFonts.outfit(
        fontSize: 11,
        color: AuthTheme.inkSoft,
        height: 1.5,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildRestoreLink() {
    return GestureDetector(
      onTap: () {
        // TODO: Restore purchase
      },
      child: Text(
        'Restore Purchase',
        style: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AuthTheme.goldDark,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildFooterLinks() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () {
            // TODO: Open Terms of Service
          },
          child: Text(
            'Terms of Service',
            style: GoogleFonts.outfit(
              fontSize: 10,
              color: AuthTheme.inkSoft,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
        const SizedBox(width: 16),
        GestureDetector(
          onTap: () {
            // TODO: Open Privacy Policy
          },
          child: Text(
            'Privacy Policy',
            style: GoogleFonts.outfit(
              fontSize: 10,
              color: AuthTheme.inkSoft,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }
}
