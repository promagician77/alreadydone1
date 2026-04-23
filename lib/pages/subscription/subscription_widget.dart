import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '/constants/legal_urls.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/nav/nav.dart';
import '/pages/auth/auth_theme.dart';
import '/services/backend_client.dart';
import '/services/revenuecat_service.dart';
import '/services/supabase_service.dart';
import '/services/app_toast.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '/widgets/pressable.dart';
import '/widgets/animated_waveform_icon.dart';
import 'package:url_launcher/url_launcher.dart';
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

  Future<void> _openExternalLink(Uri url) async {
    final ok = await launchUrl(url, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      AppToast.info(context, 'Could not open link.');
    }
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SubscriptionModel());
    _loadProfileSubscriptionState();
  }

  /// Derive subscription/plan state from user profile so the correct theme shows:
  /// when rc_subscription_plan is weekly, show weekly (current) + monthly "UPGRADE NOW" UI.
  Future<void> _loadProfileSubscriptionState() async {
    final userId = await SupabaseService.getCurrentUserTableId();
    if (userId == null || !mounted) {
      if (mounted) safeSetState(() => _model.subscriptionStateLoaded = true);
      return;
    }
    try {
      final profile = await BackendClient.getUserProfile(userId);
      if (!mounted) return;
      final rcStatus = (profile['rc_subscription_status'] ?? profile['rc_subscription_Status'])
          ?.toString()
          .trim()
          .toLowerCase();
      final rcPlan = (profile['rc_subscription_plan'] ?? profile['rc_subscription_Plan'])
          ?.toString()
          .trim()
          .toLowerCase();
      final isWeeklyPlan = rcPlan != null && rcPlan.isNotEmpty && rcPlan.contains('week');
      final isMonthlyPlan = rcPlan != null && rcPlan.isNotEmpty && rcPlan.contains('month') && !rcPlan.contains('week');
      final isCanceled = rcStatus == 'canceled' || rcStatus == 'cancelled';
      RevenueCatService.logFlow(
        'Subscription',
        '_loadProfileSubscriptionState: rcStatus=$rcStatus rcPlan=$rcPlan '
        'weekly=$isWeeklyPlan monthly=$isMonthlyPlan canceled=$isCanceled',
      );
      safeSetState(() {
        _model.isSubscribed = rcStatus == 'active' || rcStatus == 'trial';
        _model.isMonthlyPlan = isMonthlyPlan;
        _model.isWeeklyPlan = isWeeklyPlan;
        _model.isTrialing = rcStatus == 'trial';
        _model.isCanceled = isCanceled;
        if (_model.selectedPlan == null) _model.selectedPlan = 0;
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
                      if (!_model.subscriptionStateLoaded)
                        _buildPricingCardsLoadingPlaceholder()
                      else ...[
                        _buildPricingCards(),
                        if (!_model.isMonthlyPlan || _model.isCanceled) ...[
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
        '✨ Start your 3-day free trial today',
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

  Widget _buildPricingCards() {
    // Monthly plan user: show Monthly (current) first, Weekly second. No upgrade CTA.
    final isMonthlyView = _model.isMonthlyPlan && !_model.isCanceled;
    if (isMonthlyView) {
      return Column(
        children: [
          _buildPricingCard(
            plan: 'Monthly',
            price: '\$29.99',
            period: '/month',
            savings: 'Save 30% vs weekly plan',
            breakdown: 'Billed monthly · Cancel anytime',
            features: [
              'Daily manifestation stories',
              'Clone your own voice',
              'Sleep Mode with theta waves',
              'Professional voice available',
            ],
            isSelected: _model.selectedPlan == 0,
            onTap: () => safeSetState(() => _model.selectedPlan = 0),
            badgeLabel: 'CURRENT PLAN',
          ),
          const SizedBox(height: 10),
          _buildPricingCard(
            plan: 'Weekly',
            price: '\$9.99',
            period: '/week',
            breakdown: 'Billed weekly · Cancel anytime',
            features: [
              'Daily manifestation stories',
              'Clone your own voice',
              'Sleep Mode with theta waves',
              'Professional voice available',
            ],
            isPopular: false,
            isSelected: _model.selectedPlan == 1,
            onTap: () => safeSetState(() => _model.selectedPlan = 1),
          ),
        ],
      );
    }
    // Weekly plan user: show Weekly (current) first, Monthly (upgrade) second.
    final isWeeklyView = _model.isWeeklyPlan && !_model.isCanceled;
    if (isWeeklyView) {
      return Column(
        children: [
          _buildPricingCard(
            plan: 'Weekly',
            price: '\$9.99',
            period: '/week',
            breakdown: 'Billed weekly · Cancel anytime',
            features: [
              'Daily manifestation stories',
              'Clone your own voice',
              'Sleep Mode with theta waves',
              'Professional voice available',
            ],
            isPopular: false,
            isSelected: _model.selectedPlan == 1,
            onTap: () => safeSetState(() => _model.selectedPlan = 1),
            badgeLabel: 'CURRENT PLAN',
          ),
          const SizedBox(height: 10),
          _buildPricingCard(
            plan: 'Monthly',
            price: '\$29.99',
            period: '/month',
            savings: 'Save 30% vs weekly plan',
            breakdown: 'Billed monthly · Cancel anytime',
            features: [
              'Daily manifestation stories',
              'Clone your own voice',
              'Sleep Mode with theta waves',
              'Professional voice available',
            ],
            isSelected: _model.selectedPlan == 0,
            onTap: () => safeSetState(() => _model.selectedPlan = 0),
            badgeLabel: 'UPGRADE NOW',
          ),
        ],
      );
    }
    // Not subscribed or canceled: show Monthly (best value) first, Weekly second.
    return Column(
      children: [
        _buildPricingCard(
          plan: 'Monthly',
          price: '\$29.99',
          period: '/month',
          savings: 'BEST VALUE',
          breakdown: 'Billed monthly · Cancel anytime',
          features: [
            'Daily manifestation stories',
            'Clone your own voice',
            'Sleep Mode with theta waves',
            'Professional voice available',
          ],
          isPopular: true,
          isSelected: _model.selectedPlan == 0,
          onTap: () => safeSetState(() => _model.selectedPlan = 0),
        ),
        const SizedBox(height: 10),
        _buildPricingCard(
          plan: 'Weekly',
          price: '\$9.99',
          period: '/week',
          breakdown: 'Billed weekly · Cancel anytime',
          features: [
            'Daily manifestation stories',
            'Clone your own voice',
            'Sleep Mode with theta waves',
            'Professional voice available',
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
        : (_model.isWeeklyPlan
            ? 'Upgrade to Monthly'
            : (_model.isSubscribed ? 'Upgrade the Plan' : 'Start Free Trial'));
    final onTap = _model.isCanceled
        ? () => _handleConfirmPayment(isStartTrial: false)
        : (_model.isWeeklyPlan ? _handleChangeToMonthly : () => _handleConfirmPayment(isStartTrial: !_model.isSubscribed));
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

  /// Upgrade weekly → monthly: purchase the monthly package via RevenueCat.
  Future<void> _handleChangeToMonthly() async {
    if (_model.isPaymentLoading) return;
    RevenueCatService.logFlow('Subscription', '_handleChangeToMonthly: start');
    if (!RevenueCatService.instance.isSupported) {
      RevenueCatService.logFlow('Subscription', '_handleChangeToMonthly: not supported');
      AppToast.error(
        context,
        'Subscriptions are available on the App Store (iPhone/iPad) and Google Play (Android). Please use a supported device.',
      );
      return;
    }
    safeSetState(() => _model.isPaymentLoading = true);
    try {
      final userId = await SupabaseService.getCurrentUserTableId();
      RevenueCatService.logFlow('Subscription', '_handleChangeToMonthly: userId=$userId');
      final offerings = await RevenueCatService.instance.getOfferings();
      final package = _findPackage(offerings, wantMonthly: true);
      if (package == null) {
        RevenueCatService.logFlow(
          'Subscription',
          '_handleChangeToMonthly: monthly package NOT FOUND',
        );
        if (!mounted) return;
        AppToast.error(context, 'Monthly plan not available. Please try later.');
        return;
      }
      RevenueCatService.logFlow(
        'Subscription',
        '_handleChangeToMonthly: purchasing ${package.identifier}',
      );
      final info = await RevenueCatService.instance.purchasePackage(package);
      if (!mounted) return;
      if (info != null && userId != null) {
        try {
          RevenueCatService.logFlow(
            'Subscription',
            '_handleChangeToMonthly: syncing backend userId=$userId',
          );
          final payload = RevenueCatService.instance.getSubscriptionPayloadForBackend(info);
          await BackendClient.updateUserRevenueCatSubscription(
            userId,
            rcCustomerId: payload['rc_customer_id']!,
            rcSubscriptionStatus: payload['rc_subscription_status']!,
            rcSubscriptionPlan: payload['rc_subscription_plan']!,
            subscriptionProvider: payload['subscription_provider']!,
          );
        } catch (e, st) {
          RevenueCatService.logFlow(
            'Subscription',
            '_handleChangeToMonthly: backend sync FAILED: $e',
          );
          debugPrint('$st');
        }
      }
      RevenueCatService.logFlow('Subscription', '_handleChangeToMonthly: success');
      AppToast.success(context, 'Upgraded to Monthly!');
      _goAfterSubscribe(context);
    } on PlatformException catch (e) {
      RevenueCatService.logFlow(
        'Subscription',
        '_handleChangeToMonthly: PlatformException code=${e.code} message=${e.message}',
      );
      if (!mounted) return;
      if (PurchasesErrorHelper.getErrorCode(e) == PurchasesErrorCode.purchaseCancelledError) {
        AppToast.info(context, 'Upgrade canceled');
      } else {
        AppToast.error(context, e.message ?? 'Upgrade failed');
      }
    } catch (e, st) {
      RevenueCatService.logFlow('Subscription', '_handleChangeToMonthly: unexpected $e');
      debugPrint('$st');
      if (!mounted) return;
      AppToast.error(
        context,
        e.toString().replaceFirst(RegExp(r'^Exception:?\s*'), '').startsWith('Instance of ')
            ? 'Upgrade failed. Please try again.'
            : e.toString().replaceFirst(RegExp(r'^Exception:?\s*'), ''),
      );
    } finally {
      if (mounted) safeSetState(() => _model.isPaymentLoading = false);
    }
  }

  Package? _findPackage(Offerings? offerings, {required bool wantMonthly}) {
    final packages = offerings?.current?.availablePackages ?? [];
    for (final p in packages) {
      final id = p.identifier.toLowerCase();
      final isMonthly = id.contains('monthly') || id.contains('month') || id.contains(r'$rc_monthly');
      final isWeekly = id.contains('weekly') || id.contains('week') || id.contains(r'$rc_weekly');
      if (wantMonthly && isMonthly) return p;
      if (!wantMonthly && isWeekly) return p;
    }
    if (packages.length == 1) return packages.first;
    return null;
  }

  Future<void> _handleConfirmPayment({required bool isStartTrial}) async {
    if (_model.isPaymentLoading) return;

    RevenueCatService.logFlow(
      'Subscription',
      '_handleConfirmPayment: start isStartTrial=$isStartTrial selectedPlan=${_model.selectedPlan}',
    );
    if (!RevenueCatService.instance.isSupported) {
      RevenueCatService.logFlow('Subscription', '_handleConfirmPayment: not supported');
      AppToast.error(
        context,
        'Subscriptions are available on the App Store (iPhone/iPad) and Google Play (Android). Please use a supported device.',
      );
      return;
    }

    if (_model.selectedPlan == null) {
      RevenueCatService.logFlow('Subscription', '_handleConfirmPayment: no plan selected');
      AppToast.info(context, 'Please select a plan first');
      return;
    }

    final userId = await SupabaseService.getCurrentUserTableId();
    if (userId == null) {
      RevenueCatService.logFlow('Subscription', '_handleConfirmPayment: userId null');
      AppToast.error(context, 'Please sign in to subscribe');
      return;
    }

    safeSetState(() => _model.isPaymentLoading = true);

    try {
      final offerings = await RevenueCatService.instance.getOfferings();
      final wantMonthly = _model.selectedPlan == 0;
      RevenueCatService.logFlow(
        'Subscription',
        '_handleConfirmPayment: wantMonthly=$wantMonthly userId=$userId',
      );
      final package = _findPackage(offerings, wantMonthly: wantMonthly);
      if (package == null) {
        RevenueCatService.logFlow(
          'Subscription',
          '_handleConfirmPayment: package NOT FOUND for wantMonthly=$wantMonthly',
        );
        if (!mounted) return;
        AppToast.error(
          context,
          RevenueCatService.instance.isSupported
              ? 'Plans not available. Please try later.'
              : 'Subscriptions are available on the App Store (iPhone/iPad) and Google Play (Android). Please use a supported device.',
        );
        return;
      }
      if (!mounted) return;

      final info = await RevenueCatService.instance.purchasePackage(package);
      if (!mounted) return;

      if (info != null) {
        try {
          RevenueCatService.logFlow(
            'Subscription',
            '_handleConfirmPayment: sync backend userId=$userId',
          );
          final payload = RevenueCatService.instance.getSubscriptionPayloadForBackend(info);
          await BackendClient.updateUserRevenueCatSubscription(
            userId,
            rcCustomerId: payload['rc_customer_id']!,
            rcSubscriptionStatus: payload['rc_subscription_status']!,
            rcSubscriptionPlan: payload['rc_subscription_plan']!,
            subscriptionProvider: payload['subscription_provider']!,
          );
        } catch (e, st) {
          RevenueCatService.logFlow(
            'Subscription',
            '_handleConfirmPayment: backend sync FAILED: $e',
          );
          debugPrint('$st');
        }
      }

      RevenueCatService.logFlow('Subscription', '_handleConfirmPayment: success');
      AppToast.success(context, isStartTrial ? '3-day free trial started!' : 'Subscription active!');
      _goAfterSubscribe(context);
    } on PlatformException catch (e) {
      RevenueCatService.logFlow(
        'Subscription',
        '_handleConfirmPayment: PlatformException code=${e.code} message=${e.message}',
      );
      if (!mounted) return;
      if (PurchasesErrorHelper.getErrorCode(e) == PurchasesErrorCode.purchaseCancelledError) {
        AppToast.info(context, 'Payment canceled');
      } else {
        AppToast.error(context, e.message ?? 'Payment failed');
      }
    } catch (e, st) {
      RevenueCatService.logFlow('Subscription', '_handleConfirmPayment: unexpected $e');
      debugPrint('$st');
      if (!mounted) return;
      AppToast.error(
        context,
        e.toString().replaceFirst(RegExp(r'^Exception:?\s*'), '').startsWith('Instance of ')
            ? 'Payment failed. Please try again.'
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
          await BackendClient.updateUserRevenueCatSubscription(
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
          const TextSpan(
            text:
                'Free for 3 days, then \$9.99/week or \$29.99/month. Cancel anytime in settings. By continuing, you agree to our ',
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
