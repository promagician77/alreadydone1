import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/nav/nav.dart';
import '/pages/auth/auth_theme.dart';
import '/services/backend_client.dart';
import '/services/supabase_service.dart';
import '/services/app_toast.dart';
import '/widgets/pressable.dart';
import '/widgets/animated_waveform_icon.dart';
import 'subscription_model.dart';
export 'subscription_model.dart';

/// Green accent for "current plan" card when user is on monthly.
const Color _currentPlanGreen = Color(0xFF2E7D32);
const Color _currentPlanGreenLight = Color(0xFFE8F5E9);

class SubscriptionWidget extends StatefulWidget {
  const SubscriptionWidget({super.key});

  static String routeName = 'Subscription';
  static String routePath = '/subscription';

  @override
  State<SubscriptionWidget> createState() => _SubscriptionWidgetState();
}

class _SubscriptionWidgetState extends State<SubscriptionWidget> {
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
      final plan = (status['subscription_plan'] ?? status['Subscription_Plan'])
          ?.toString()
          .trim()
          .toLowerCase();
      final statusStr = (status['subscription_status'] ?? status['Subscription_Status'])
          ?.toString()
          .trim()
          .toLowerCase();
      final isAnnual = plan == 'annual';
      final isMonthly = plan == 'monthly' || plan == 'weekly';
      final isTrialing = statusStr == 'trialing';
      final isCanceled = statusStr == 'canceled';
      if (mounted) {
        safeSetState(() {
          _model.isSubscribed = hasSub;
          _model.isAnnualPlan = isAnnual;
          _model.isMonthlyPlan = isMonthly;
          _model.isTrialing = isTrialing;
          _model.isCanceled = isCanceled;
          if (isMonthly && _model.selectedPlan == null) _model.selectedPlan = 0;
        });
      }
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
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                floating: false,
                toolbarHeight: 56,
                backgroundColor: AuthTheme.warmWhite,
                surfaceTintColor: Colors.transparent,
                leading: Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios, size: 20, color: AuthTheme.inkSoft),
                    onPressed: () => context.go('/'),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: AuthTheme.inkSoft,
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 24),
                      _buildHero(),
                      const SizedBox(height: 24),
                      _buildSocialProof(),
                      const SizedBox(height: 24),
                      _buildTrialBadge(),
                      const SizedBox(height: 20),
                      _buildPricingCards(),
                      if (!_model.isAnnualPlan || _model.isCanceled) ...[
                        const SizedBox(height: 24),
                        _buildCtaButton(),
                        if (_model.isSubscribed && !_model.isCanceled) ...[
                          const SizedBox(height: 12),
                          _buildCancelPaymentButton(),
                        ],
                      ] else ...[
                        const SizedBox(height: 24),
                        if (_model.isSubscribed && !_model.isCanceled) ...[
                          _buildCancelPaymentButton(),
                          const SizedBox(height: 12),
                        ],
                      ],
                      if (_model.isPaymentLoading)
                        const Padding(
                          padding: EdgeInsets.only(top: 12),
                          child: Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AuthTheme.gold,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      _buildLegalText(),
                      const SizedBox(height: 12),
                      _buildRestoreLink(),
                      const SizedBox(height: 28),
                      _buildFeaturesList(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHero() {
    return Column(
      children: [
        const AnimatedWaveformIcon(size: AnimatedWaveformSize.paywall, wrapped: false),
        const SizedBox(height: 20),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: AuthTheme.welcomeTitleStyle.copyWith(
              fontSize: 28,
              height: 1.2,
            ),
            children: [
              const TextSpan(text: 'Your dream life.\n'),
              TextSpan(
                text: 'Already done.',
                style: AuthTheme.welcomeTitleItalicStyle.copyWith(
                  fontSize: 28,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Unlimited stories in your voice',
          style: AuthTheme.welcomeSubStyle.copyWith(fontSize: 13, height: 1.5),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSocialProof() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AuthTheme.warmWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AuthTheme.stone),
      ),
      child: Column(
        children: [
          Text(
            'TRUSTED BY THOUSANDS',
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AuthTheme.inkMid,
              letterSpacing: 1,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statItem('4.8★', 'RATING'),
              _statItem('50K+', 'STORIES'),
              _statItem('12K+', 'USERS'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AuthTheme.gold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 9,
            color: AuthTheme.inkSoft,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildTrialBadge() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AuthTheme.goldLight, AuthTheme.goldDark],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AuthTheme.ink.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        '✨ Start your 7-day free trial today',
        style: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AuthTheme.surface,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildPricingCards() {
    // Canceled: show original UI (annual first). Monthly and not canceled: show upgrade-to-annual UI.
    final isMonthlyView = _model.isMonthlyPlan && !_model.isCanceled;
    if (isMonthlyView) {
      // Monthly user: show Monthly (current) first, Annual (upgrade) second.
      return Column(
        children: [
          _buildPricingCard(
            plan: 'Monthly',
            price: '\$9.99',
            period: '/month',
            breakdown: 'Billed monthly · Cancel anytime',
            features: [
              'Unlimited daily stories',
              'Sleep Mode & all speeds',
              'Re-record voice anytime',
            ],
            isSelected: _model.selectedPlan == 1,
            onTap: () => safeSetState(() => _model.selectedPlan = 1),
            badgeLabel: 'CURRENT PLAN',
          ),
          const SizedBox(height: 10),
          _buildPricingCard(
            plan: 'Annual',
            price: '\$69.99',
            period: '/year',
            savings: 'Save \$50 vs monthly plan',
            breakdown: 'Equivalent to \$5.83/month · Billed annually',
            features: [
              'Unlimited daily stories',
              'Sleep Mode & all speeds',
              'Re-record voice anytime',
              'Offline access forever',
            ],
            isPopular: false,
            isSelected: _model.selectedPlan == 0,
            onTap: () => safeSetState(() => _model.selectedPlan = 0),
            badgeLabel: 'UPGRADE NOW',
          ),
        ],
      );
    }
    return Column(
      children: [
        _buildPricingCard(
          plan: 'Annual',
          price: '\$69.99',
          period: '/year',
          savings: 'Best Value',
          breakdown: 'Equivalent to \$5.83/month · Billed annually',
          features: [
            'Unlimited daily stories',
            'Sleep Mode & all speeds',
            'Re-record voice anytime',
            'Offline access forever',
          ],
          isPopular: true,
          isSelected: _model.selectedPlan == 0,
          onTap: () => safeSetState(() => _model.selectedPlan = 0),
        ),
        const SizedBox(height: 10),
        _buildPricingCard(
          plan: 'Monthly',
          price: '\$9.99',
          period: '/month',
          breakdown: 'Billed monthly · Cancel anytime',
          features: [
            'Unlimited daily stories',
            'Sleep Mode & all speeds',
            'Re-record voice anytime',
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
    String? savings,
    required String breakdown,
    required List<String> features,
    bool isPopular = false,
    required bool isSelected,
    required VoidCallback onTap,
    String? badgeLabel,
  }) {
    final isCurrentPlan = badgeLabel == 'CURRENT PLAN';
    final isUpgradeBadge = badgeLabel == 'UPGRADE NOW';
    final useGoldStyle = isSelected || isUpgradeBadge;
    final useGreenStyle = isCurrentPlan;
    final accentColor = useGreenStyle ? _currentPlanGreen : AuthTheme.gold;
    final cardColor = useGreenStyle
        ? _currentPlanGreenLight
        : (useGoldStyle ? AuthTheme.goldPale : AuthTheme.surface);
    final borderColor = useGreenStyle ? _currentPlanGreen : (useGoldStyle ? AuthTheme.gold : AuthTheme.stone);
    final textColor = useGreenStyle ? AuthTheme.ink : (useGoldStyle ? AuthTheme.goldDark : AuthTheme.ink);
    final checkColor = useGreenStyle ? _currentPlanGreen : AuthTheme.gold;

    return Pressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: borderColor,
                width: (useGoldStyle || useGreenStyle) ? 2 : 2,
              ),
              boxShadow: useGoldStyle && !useGreenStyle
                  ? [
                      BoxShadow(
                        color: AuthTheme.gold.withValues(alpha: 0.1),
                        blurRadius: 0,
                        spreadRadius: 3,
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
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    if (!isCurrentPlan)
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected ? AuthTheme.gold : Colors.transparent,
                          border: Border.all(
                            color: isSelected ? AuthTheme.gold : AuthTheme.stoneMid,
                            width: 2,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, size: 12, color: AuthTheme.surface)
                            : null,
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      price,
                      style: GoogleFonts.outfit(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      period,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AuthTheme.inkSoft,
                      ),
                    ),
                  ],
                ),
                if (savings != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (useGreenStyle ? _currentPlanGreen : AuthTheme.gold).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      savings,
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: useGreenStyle ? _currentPlanGreen : AuthTheme.goldDark,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Text(
                  breakdown,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: useGoldStyle || useGreenStyle ? AuthTheme.inkMid : AuthTheme.inkSoft,
                  ),
                ),
                const SizedBox(height: 12),
                ...features.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '✓',
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          color: checkColor,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        f,
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: useGoldStyle || useGreenStyle ? AuthTheme.ink : AuthTheme.inkMid,
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),
          if (badgeLabel != null)
            Positioned(
              top: -8,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: accentColor,
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
                  badgeLabel,
                  style: GoogleFonts.outfit(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: AuthTheme.surface,
                    letterSpacing: 1,
                  ),
                ),
              ),
            )
          else if (isPopular)
            Positioned(
              top: -8,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                  'MOST POPULAR',
                  style: GoogleFonts.outfit(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: AuthTheme.surface,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCtaButton() {
    final label = _model.isCanceled
        ? 'Upgrade the Plan'
        : (_model.isMonthlyPlan
            ? 'Upgrade to Annual'
            : (_model.isSubscribed ? 'Upgrade the Plan' : 'Start 7-day free trial'));
    final onTap = _model.isCanceled
        ? () => _handleConfirmPayment(isStartTrial: false)
        : (_model.isMonthlyPlan ? _handleChangeToAnnual : () => _handleConfirmPayment(isStartTrial: !_model.isSubscribed));
    return _ctaButton(
      label: label,
      onTap: onTap,
    );
  }

  Widget _buildCancelPaymentButton() {
    return TextButton(
      onPressed: _model.isPaymentLoading ? null : _handleCancelPayment,
      child: Text(
        'Cancel payment',
        style: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AuthTheme.inkSoft,
        ),
      ),
    );
  }

  Future<void> _handleCancelPayment() async {
    if (_model.isPaymentLoading) return;
    final userId = await SupabaseService.getCurrentUserTableId();
    if (userId == null) {
      AppToast.error(context, 'Please sign in');
      return;
    }
    safeSetState(() => _model.isPaymentLoading = true);
    try {
      await BackendClient.cancelSubscription(userId: userId);
      if (!mounted) return;
      AppToast.success(context, 'Payment canceled');
      _loadSubscriptionStatus();
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst(RegExp(r'^Exception:?\s*'), '');
      AppToast.error(
        context,
        msg.startsWith('Instance of ') ? 'Could not cancel. Please try again.' : msg,
      );
    } finally {
      if (mounted) safeSetState(() => _model.isPaymentLoading = false);
    }
  }

  /// Plan for backend: "annual" or "monthly". Uses selected plan or default annual for trial.
  String get _planForBackend {
    if (_model.selectedPlan == 1) return 'monthly';
    return 'annual';
  }

  static bool _isStripeConfigError(Object e) {
    final s = e.toString();
    return s.contains('StripeConfigException') ||
        s.contains('publishable') && s.toLowerCase().contains('required') ||
        s.contains('Publishable Key is required');
  }

  /// Called when monthly-plan user taps "Upgrade to Annual". Calls change-plan API (no payment sheet).
  Future<void> _handleChangeToAnnual() async {
    if (_model.isPaymentLoading) return;
    final userId = await SupabaseService.getCurrentUserTableId();
    if (userId == null) {
      AppToast.error(context, 'Please sign in to upgrade');
      return;
    }
    safeSetState(() => _model.isPaymentLoading = true);
    try {
      await BackendClient.changeSubscriptionPlan(userId: userId, plan: 'annual');
      if (!mounted) return;
      AppToast.success(context, 'Upgraded to Annual!');
      context.go('/');
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst(RegExp(r'^Exception:?\s*'), '');
      AppToast.error(
        context,
        msg.startsWith('Instance of ') ? 'Upgrade failed. Please try again.' : msg,
      );
    } finally {
      if (mounted) safeSetState(() => _model.isPaymentLoading = false);
    }
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
      if (clientSecret == null || clientSecret.isEmpty || setupIntentId == null || setupIntentId.isEmpty) {
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

      AppToast.success(context, isStartTrial ? '7-day free trial started!' : 'Subscription active!');
      context.go('/');
    } catch (e) {
      if (!mounted) return;
      if (e is StripeException) {
        if (e.error.code == FailureCode.Canceled) {
          AppToast.info(context, 'Payment canceled');
          context.go(SubscriptionWidget.routePath);
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
          msg.startsWith('Instance of ') ? 'Payment failed. Please try again.' : msg,
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

  Widget _buildLegalText() {
    return Text(
      "After your 7-day trial, you'll be charged the selected plan amount. Cancel anytime in Settings. By continuing, you agree to our Terms and Privacy Policy.",
      style: GoogleFonts.outfit(
        fontSize: 10,
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
          color: AuthTheme.inkSoft,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildFeaturesList() {
    final items = [
      ('🎙️', 'Your Voice, Your Power',
          "Hear yourself narrate your completed dreams in past tense—not a stranger's voice"),
      ('✨', 'AI-Powered Stories',
          'Each story is personalized to your desires, location, and emotional energy'),
      ('🌙', 'Sleep Mode',
          'Slower pacing, theta waves, fade to silence for bedtime manifestation'),
      ('⚡', 'Unlimited Stories',
          'Create as many manifestations as you want—love, money, career, health, all of it'),
    ];
    return Column(
      children: items.asMap().entries.map((e) {
        final (icon, title, desc) = e.value;
        final isLast = e.key == items.length - 1;
        return Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(icon, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AuthTheme.ink,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        desc,
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: AuthTheme.inkSoft,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (!isLast)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Divider(height: 1, color: AuthTheme.stone),
              ),
          ],
        );
      }).toList(),
    );
  }
}
