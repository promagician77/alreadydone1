import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '/core/constants/legal_urls.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/nav/nav.dart';
import '/shared/theme/auth_theme.dart';
import '/core/di/subscription_locator.dart';
import '/core/di/profile_locator.dart';
import '/features/subscription/data/datasources/revenuecat_service.dart';
import '/shared/services/supabase_service.dart';
import '/shared/services/app_toast.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '/shared/widgets/pressable.dart';
import '/shared/widgets/animated_waveform_icon.dart';
import 'package:url_launcher/url_launcher.dart';
import 'subscription_model.dart';
export 'subscription_model.dart';

/// Green accent for the "current plan" card.
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

  Future<void> _openExternalLink(Uri url) async {
    final ok = await launchUrl(url, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      AppToast.info(context, 'Could not open link.');
    }
  }

  /// False until store prices / free-trial eligibility have been fetched.
  bool _plansLoaded = false;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SubscriptionModel());
    _model.selectedPlan = SubscriptionPlan.monthly;
    _loadProfileSubscriptionState();
    _loadPlans();
  }

  /// Store prices and free-trial eligibility for the plan cards.
  Future<void> _loadPlans() async {
    final plans = await RevenueCatService.instance.getAvailablePlans();
    if (!mounted) return;
    safeSetState(() {
      _model.plans = plans;
      _plansLoaded = true;
    });
  }

  /// Derive subscription/plan state from user profile so the correct theme shows:
  /// weekly → monthly upgrade; monthly → current + manage; legacy annual → current, no purchase.
  Future<void> _loadProfileSubscriptionState() async {
    final userId = await SupabaseService.getCurrentUserTableId();
    if (userId == null || !mounted) {
      if (mounted) safeSetState(() => _model.subscriptionStateLoaded = true);
      return;
    }
    try {
      final profile = await profileRepository.getUserProfile(userId);
      if (!mounted) return;
      final rcStatus = (profile['rc_subscription_status'] ?? profile['rc_subscription_Status'])
          ?.toString()
          .trim()
          .toLowerCase();
      final rcPlan = (profile['rc_subscription_plan'] ?? profile['rc_subscription_Plan'])
          ?.toString()
          .trim()
          .toLowerCase();
      final isWeeklyPlan =
          rcPlan != null && rcPlan.isNotEmpty && rcPlan.contains('week');
      final isMonthlyPlan = rcPlan != null &&
          rcPlan.isNotEmpty &&
          rcPlan.contains('month') &&
          !rcPlan.contains('week');
      final isLegacyAnnual = rcPlan != null &&
          rcPlan.isNotEmpty &&
          (rcPlan.contains('annual') ||
              rcPlan.contains('yearly') ||
              (rcPlan.contains('year') && !rcPlan.contains('week')));
      final isCanceled = rcStatus == 'canceled' || rcStatus == 'cancelled';
      RevenueCatService.logFlow(
        'Subscription',
        '_loadProfileSubscriptionState: rcStatus=$rcStatus rcPlan=$rcPlan '
        'weekly=$isWeeklyPlan monthly=$isMonthlyPlan legacyAnnual=$isLegacyAnnual canceled=$isCanceled',
      );
      safeSetState(() {
        _model.isSubscribed = rcStatus == 'active' || rcStatus == 'trial';
        _model.isWeeklyPlan = isWeeklyPlan;
        _model.isMonthlyPlan = isMonthlyPlan;
        _model.isLegacyAnnualPlan = isLegacyAnnual;
        _model.isTrialing = rcStatus == 'trial';
        _model.isCanceled = isCanceled;
        _model.subscriptionStateLoaded = true;
      });
    } catch (e, st) {
      RevenueCatService.logFlow('Subscription', '_loadProfileSubscriptionState FAILED: $e');
      debugPrint('$st');
      if (mounted) safeSetState(() => _model.subscriptionStateLoaded = true);
    }
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  /// Subscribed and not canceled: the plan keeps renewing.
  bool get _isRenewing => _model.isSubscribed && !_model.isCanceled;

  /// Monthly is the top plan sold, and legacy annual subscribers already have more.
  bool get _hidePurchaseCta =>
      _isRenewing && (_model.isMonthlyPlan || _model.isLegacyAnnualPlan);

  /// Store offer for the selected plan; null until loaded or when unavailable.
  PlanOffer? get _selectedOffer =>
      _model.plans[_model.selectedPlan ?? SubscriptionPlan.monthly];

  /// Free trial to advertise for [plan]: only to users without a running
  /// subscription, and only when the store says they would actually get it.
  FreeTrial? _trialFor(SubscriptionPlan plan) {
    if (_isRenewing) return null;
    return _model.plans[plan]?.freeTrial;
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
                      if (_model.subscriptionStateLoaded &&
                          _selectedOffer != null) ...[
                        _buildPlanPromoBadge(),
                        const SizedBox(height: 20),
                      ],
                      if (!_model.subscriptionStateLoaded || !_plansLoaded)
                        _buildPricingCardsLoadingPlaceholder()
                      else ...[
                        _buildPricingCards(),
                        if (!_hidePurchaseCta) ...[
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

  Widget _buildPlanPromoBadge() {
    final plan = _model.selectedPlan ?? SubscriptionPlan.monthly;
    final price = '${_selectedOffer?.priceString ?? ''}${plan.periodSuffix}';
    final trial = _trialFor(plan);
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
        trial != null
            ? '✨ ${plan.label}: ${trial.adjective} free trial · then $price'
            : '✨ ${plan.label}: $price',
        style: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AuthTheme.surface,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  /// Shown until profile subscription state is loaded to avoid flashing wrong layout.
  Widget _buildPricingCardsLoadingPlaceholder() {
    return SizedBox(
      height: 320,
      child: Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AuthTheme.gold,
          ),
        ),
      ),
    );
  }

  static const _planFeatures = [
    'Daily manifestation stories',
    'Clone your own voice',
    'Sleep Mode with theta waves',
    'Professional voices available',
  ];

  /// Card for [plan] with the store price, and the free trial when it applies.
  Widget _planCard(
    SubscriptionPlan plan, {
    String? badgeLabel,
    bool isPopular = false,
  }) {
    final offer = _model.plans[plan];
    final trial = _trialFor(plan);
    final savings = plan == SubscriptionPlan.monthly
        ? _model.plans.monthlySavingsPercent
        : null;
    return _buildPricingCard(
      plan: plan.label,
      price: offer?.priceString ?? '—',
      period: plan.periodSuffix,
      savings: savings != null ? 'SAVE $savings% vs weekly' : plan.billedLabel,
      breakdown: trial != null
          ? '${trial.adjective} free trial · ${plan.billedLabel} · Cancel anytime'
          : '${plan.billedLabel} · Cancel anytime',
      features: _planFeatures,
      isPopular: isPopular,
      isSelected: _model.selectedPlan == plan,
      onTap: () => safeSetState(() => _model.selectedPlan = plan),
      badgeLabel: badgeLabel,
    );
  }

  Widget _buildPricingCards() {
    // Monthly subscriber: monthly current, weekly secondary (no purchase CTA).
    if (_isRenewing && _model.isMonthlyPlan) {
      return Column(
        children: [
          _planCard(SubscriptionPlan.monthly, badgeLabel: 'CURRENT PLAN'),
          const SizedBox(height: 10),
          _planCard(SubscriptionPlan.weekly),
        ],
      );
    }

    // Weekly subscriber: weekly current, monthly upgrade.
    if (_isRenewing && _model.isWeeklyPlan) {
      return Column(
        children: [
          _planCard(SubscriptionPlan.weekly, badgeLabel: 'CURRENT PLAN'),
          const SizedBox(height: 10),
          _planCard(SubscriptionPlan.monthly, badgeLabel: 'UPGRADE NOW'),
        ],
      );
    }

    // New, canceled, or legacy annual: weekly + monthly (monthly is best value).
    return Column(
      children: [
        if (_isRenewing && _model.isLegacyAnnualPlan) ...[
          _buildLegacyAnnualNotice(),
          const SizedBox(height: 16),
        ],
        _planCard(SubscriptionPlan.weekly),
        const SizedBox(height: 10),
        _planCard(SubscriptionPlan.monthly, isPopular: true),
      ],
    );
  }

  /// Annual is no longer sold; existing annual subscribers keep it until they cancel.
  Widget _buildLegacyAnnualNotice() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _currentPlanGreenLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _currentPlanGreen, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CURRENT PLAN · YEARLY',
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: _currentPlanGreen,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Your yearly plan stays active and renews as usual. '
            'It is no longer offered to new subscribers.',
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: AuthTheme.inkMid,
              height: 1.4,
            ),
          ),
        ],
      ),
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
    if (_isRenewing && _model.isWeeklyPlan) {
      return _ctaButton(
        label: 'Upgrade to Monthly',
        onTap: () => _handlePurchase(SubscriptionPlan.monthly, isUpgrade: true),
      );
    }
    final plan = _model.selectedPlan ?? SubscriptionPlan.monthly;
    final trial = _trialFor(plan);
    final String label;
    if (trial != null) {
      label = 'Start ${trial.titleAdjective} Free Trial';
    } else if (_model.isCanceled || _model.isSubscribed) {
      label = 'Upgrade the Plan';
    } else {
      label = 'Subscribe to ${plan.label}';
    }
    return _ctaButton(
      label: label,
      onTap: _handleConfirmPayment,
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

  /// Opens system subscription management (e.g. App Store / Play Store).
  Future<void> _handleCancelPayment() async {
    AppToast.info(
      context,
      'Manage or cancel your subscription in your device Settings → Subscriptions.',
    );
    _loadProfileSubscriptionState();
  }

  /// After successful subscribe: go to returnTo query param if set (e.g. from onboarding), else home.
  void _goAfterSubscribe(BuildContext context) {
    final returnTo = GoRouterState.of(context).uri.queryParameters['returnTo'];
    if (returnTo != null && returnTo.isNotEmpty) {
      context.go(returnTo);
    } else {
      context.go('/');
    }
  }

  Future<void> _handleConfirmPayment() async {
    final plan = _model.selectedPlan;
    if (plan == null) {
      RevenueCatService.logFlow('Subscription', '_handleConfirmPayment: no plan selected');
      AppToast.info(context, 'Please select a plan first');
      return;
    }
    await _handlePurchase(plan);
  }

  /// Purchases [plan] via RevenueCat and syncs the backend. The store applies the
  /// free trial itself when the user is eligible. [isUpgrade] only changes the
  /// wording (weekly subscriber moving to monthly).
  Future<void> _handlePurchase(
    SubscriptionPlan plan, {
    bool isUpgrade = false,
  }) async {
    if (_model.isPaymentLoading) return;

    RevenueCatService.logFlow(
      'Subscription',
      '_handlePurchase: start plan=${plan.name} isUpgrade=$isUpgrade',
    );
    if (!RevenueCatService.instance.isSupported) {
      RevenueCatService.logFlow('Subscription', '_handlePurchase: not supported');
      AppToast.error(
        context,
        'Subscriptions are available on the App Store (iPhone/iPad) and Google Play (Android). Please use a supported device.',
      );
      return;
    }

    final userId = await SupabaseService.getCurrentUserTableId();
    if (!mounted) return;
    if (userId == null) {
      RevenueCatService.logFlow('Subscription', '_handlePurchase: userId null');
      AppToast.error(context, 'Please sign in to subscribe');
      return;
    }

    safeSetState(() => _model.isPaymentLoading = true);

    try {
      await RevenueCatService.instance.ensureReady(appUserId: userId.toString());
      final offerings = await RevenueCatService.instance.getOfferings();
      final package = RevenueCatService.findPackage(offerings, plan);
      if (package == null) {
        RevenueCatService.logFlow(
          'Subscription',
          '_handlePurchase: package NOT FOUND for plan=${plan.name}',
        );
        if (!mounted) return;
        AppToast.error(
          context,
          isUpgrade
              ? 'Monthly plan not available. Please try later.'
              : 'Plans not available. Please try later.',
        );
        return;
      }
      if (!mounted) return;

      RevenueCatService.logFlow(
        'Subscription',
        '_handlePurchase: purchasing ${package.identifier} userId=$userId',
      );
      final trial = _trialFor(plan);
      final info = await RevenueCatService.instance.purchasePackage(package);
      if (!mounted) return;

      if (info != null) {
        try {
          RevenueCatService.logFlow(
            'Subscription',
            '_handlePurchase: sync backend userId=$userId',
          );
          final payload = RevenueCatService.instance.getSubscriptionPayloadForBackend(info);
          await subscriptionRepository.updateUserRevenueCatSubscription(
            userId,
            rcCustomerId: payload['rc_customer_id']!,
            rcSubscriptionStatus: payload['rc_subscription_status']!,
            rcSubscriptionPlan: payload['rc_subscription_plan']!,
            subscriptionProvider: payload['subscription_provider']!,
          );
        } catch (e, st) {
          RevenueCatService.logFlow(
            'Subscription',
            '_handlePurchase: backend sync FAILED: $e',
          );
          debugPrint('$st');
        }
      }
      if (!mounted) return;

      final startedTrial = info
              ?.entitlements.all[RevenueCatService.entitlementId]?.periodType ==
          PeriodType.trial;
      RevenueCatService.logFlow(
        'Subscription',
        '_handlePurchase: success startedTrial=$startedTrial',
      );
      final String successMessage;
      if (isUpgrade) {
        successMessage = 'Upgraded to Monthly!';
      } else if (startedTrial) {
        successMessage = trial != null
            ? '${trial.adjective} free trial started!'
            : 'Free trial started!';
      } else {
        successMessage = 'Subscription active!';
      }
      AppToast.success(context, successMessage);
      _goAfterSubscribe(context);
    } on PlatformException catch (e) {
      RevenueCatService.logFlow(
        'Subscription',
        '_handlePurchase: PlatformException code=${e.code} message=${e.message}',
      );
      if (!mounted) return;
      if (PurchasesErrorHelper.getErrorCode(e) == PurchasesErrorCode.purchaseCancelledError) {
        AppToast.info(context, isUpgrade ? 'Upgrade canceled' : 'Payment canceled');
      } else {
        AppToast.error(
          context,
          e.message ?? (isUpgrade ? 'Upgrade failed' : 'Payment failed'),
        );
      }
    } catch (e, st) {
      RevenueCatService.logFlow('Subscription', '_handlePurchase: unexpected $e');
      debugPrint('$st');
      if (!mounted) return;
      AppToast.error(
        context,
        e.toString().replaceFirst(RegExp(r'^Exception:?\s*'), '').startsWith('Instance of ')
            ? (isUpgrade
                ? 'Upgrade failed. Please try again.'
                : 'Payment failed. Please try again.')
            : e.toString().replaceFirst(RegExp(r'^Exception:?\s*'), ''),
      );
    } finally {
      if (mounted) safeSetState(() => _model.isPaymentLoading = false);
    }
  }

  Future<void> _handleRestorePurchases() async {
    if (_model.isPaymentLoading) return;
    RevenueCatService.logFlow('Subscription', '_handleRestorePurchases: start');
    if (!RevenueCatService.instance.isSupported) {
      RevenueCatService.logFlow('Subscription', '_handleRestorePurchases: not supported');
      AppToast.error(
        context,
        'Subscriptions are available on the App Store (iPhone/iPad) and Google Play (Android). Please use a supported device.',
      );
      return;
    }
    safeSetState(() => _model.isPaymentLoading = true);
    try {
      final userId = await SupabaseService.getCurrentUserTableId();
      RevenueCatService.logFlow('Subscription', '_handleRestorePurchases: userId=$userId');
      final info = await RevenueCatService.instance.restorePurchases();
      if (!mounted) return;
      if (info != null && userId != null) {
        try {
          RevenueCatService.logFlow(
            'Subscription',
            '_handleRestorePurchases: sync backend userId=$userId',
          );
          final payload = RevenueCatService.instance.getSubscriptionPayloadForBackend(info);
          await subscriptionRepository.updateUserRevenueCatSubscription(
            userId,
            rcCustomerId: payload['rc_customer_id']!,
            rcSubscriptionStatus: payload['rc_subscription_status']!,
            rcSubscriptionPlan: payload['rc_subscription_plan']!,
            subscriptionProvider: payload['subscription_provider']!,
          );
        } catch (e, st) {
          RevenueCatService.logFlow(
            'Subscription',
            '_handleRestorePurchases: backend sync FAILED: $e',
          );
          debugPrint('$st');
        }
      }
      RevenueCatService.logFlow('Subscription', '_handleRestorePurchases: done');
      AppToast.success(context, 'Purchases restored');
      _loadProfileSubscriptionState();
    } catch (e, st) {
      RevenueCatService.logFlow('Subscription', '_handleRestorePurchases: FAILED $e');
      debugPrint('$st');
      if (!mounted) return;
      AppToast.error(context, 'Could not restore. Please try again.');
    } finally {
      if (mounted) safeSetState(() => _model.isPaymentLoading = false);
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

  /// "Weekly: 3 days free, then $4.99/week. Monthly: … " from the store prices.
  /// Empty when no plan could be loaded.
  String _pricingDisclosure() {
    final buffer = StringBuffer();
    for (final plan in SubscriptionPlan.values) {
      final offer = _model.plans[plan];
      if (offer == null) continue;
      final price = '${offer.priceString}${plan.periodSuffix}';
      final trial = _trialFor(plan);
      buffer.write(
        trial != null
            ? '${plan.label}: ${trial.duration} free, then $price. '
            : '${plan.label}: $price. ',
      );
    }
    return buffer.toString();
  }

  Widget _buildLegalText() {
    final baseStyle = GoogleFonts.outfit(
      fontSize: 10,
      color: AuthTheme.inkSoft,
      height: 1.5,
    );
    final linkStyle = baseStyle.copyWith(
      color: AuthTheme.goldDark,
      decoration: TextDecoration.underline,
    );
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: baseStyle,
        children: [
          TextSpan(
            text:
                '${_pricingDisclosure()}Renews automatically until canceled. Cancel anytime in settings. By continuing, you agree to our ',
          ),
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: Pressable(
              onTap: () => _openExternalLink(kTermsOfServiceUri),
              borderRadius: BorderRadius.circular(4),
              child: Text('Terms', style: linkStyle),
            ),
          ),
          const TextSpan(text: ' and '),
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: Pressable(
              onTap: () => _openExternalLink(kPrivacyPolicyUri),
              borderRadius: BorderRadius.circular(4),
              child: Text('Privacy Policy', style: linkStyle),
            ),
          ),
          const TextSpan(text: '.'),
        ],
      ),
    );
  }

  Widget _buildRestoreLink() {
    return Pressable(
      onTap: _handleRestorePurchases,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Text(
          'Restore Purchase',
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AuthTheme.inkSoft,
          ),
          textAlign: TextAlign.center,
        ),
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
          'Create as many manifestations as you want—love, money/lifestyle, career/business, health, all of it'),
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
