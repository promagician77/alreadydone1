import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '/core/constants/legal_urls.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/shared/theme/auth_theme.dart';
import '/features/subscription/presentation/pages/subscription/subscription_model.dart';
import '/core/di/subscription_locator.dart';
import '/features/subscription/data/datasources/revenuecat_service.dart';
import '/shared/services/supabase_service.dart';
import '/shared/services/app_toast.dart';
import '/shared/services/onboarding_service.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '/shared/widgets/pressable.dart';
import 'package:url_launcher/url_launcher.dart';
import 'onboarding_desire_widget.dart';

class OnboardingSplashWidget extends StatefulWidget {
  const OnboardingSplashWidget({super.key});

  static String routeName = 'OnboardingSplash';
  static String routePath = '/onboarding';

  @override
  State<OnboardingSplashWidget> createState() => _OnboardingSplashWidgetState();
}

class _OnboardingSplashWidgetState extends State<OnboardingSplashWidget> {
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
    _loadSubscriptionStatus();
    _loadPlans();
  }

  /// Store prices and free-trial eligibility for the plan cards.
  Future<void> _loadPlans() async {
    final plans = await RevenueCatService.instance.getAvailablePlans();
    if (!mounted) return;
    safeSetState(() => _model.plans = plans);
  }

  /// Free trial to advertise for [plan]; none for existing subscribers.
  FreeTrial? _trialFor(SubscriptionPlan plan) {
    if (_model.isSubscribed) return null;
    return _model.plans.trialFor(plan);
  }

  /// "3-day free trial started!" when [trial] applied, else the plain confirmation.
  String _successMessage(FreeTrial? trial) => trial != null
      ? '${trial.adjective} free trial started!'
      : 'Subscription active!';

  Future<void> _loadSubscriptionStatus() async {
    try {
      RevenueCatService.logFlow('OnboardingPay', '_loadSubscriptionStatus');
      final status = await RevenueCatService.instance.getSubscriptionStatus();
      RevenueCatService.logFlow(
        'OnboardingPay',
        '_loadSubscriptionStatus: isSubscribed=${status.isSubscribed}',
      );
      if (mounted) safeSetState(() => _model.isSubscribed = status.isSubscribed);
    } catch (e, st) {
      RevenueCatService.logFlow('OnboardingPay', '_loadSubscriptionStatus FAILED: $e');
      debugPrint('$st');
    }
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  /// After successful subscribe: go to returnTo query param if set (e.g. /onboarding/player), else home.
  void _goAfterSubscribe(BuildContext context) {
    final returnTo = GoRouterState.of(context).uri.queryParameters['returnTo'];
    if (returnTo != null && returnTo.isNotEmpty) {
      context.go(returnTo);
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuthTheme.warmWhite,
      body: SafeArea(
        child: Stack(
          children: [
            AbsorbPointer(
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
                        _buildPlanPromoBadge(),
                        const SizedBox(height: 20),
                        _buildPricingCards(),
                        const SizedBox(height: 20),
                        _buildCtaButton(),
                        const SizedBox(height: 14),
                        _buildSecondaryText(),
                        const SizedBox(height: 10),
                        _buildRestoreLink(),
                        const SizedBox(height: 12),
                        _buildContinueWithoutSubscribing(),
                        const SizedBox(height: 16),
                        _buildFooterLinks(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (_model.isPaymentLoading)
              Container(
                color: AuthTheme.warmWhite.withValues(alpha: 0.85),
                alignment: Alignment.center,
                child: const SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AuthTheme.gold,
                  ),
                ),
              ),
          ],
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

  Widget _buildPlanPromoBadge() {
    final monthlySelected = _model.selectedPlan == SubscriptionPlan.monthly;
    final trial = _trialFor(_model.selectedPlan ?? SubscriptionPlan.monthly);
    final savings = _model.plans.monthlySavingsPercent;
    final String label;
    if (trial != null) {
      label = '✨ Start Your ${trial.titleAdjective} Free Trial';
    } else if (savings != null) {
      label = monthlySelected
          ? '✨ Best value — Monthly plan (save $savings%)'
          : '✨ Switch to Monthly and save $savings%';
    } else {
      label = '✨ Unlimited stories in your voice';
    }
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
          label,
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

  Widget _planCard(SubscriptionPlan plan, {required bool isRecommended}) {
    final savings = plan == SubscriptionPlan.monthly
        ? _model.plans.monthlySavingsPercent
        : null;
    return _buildPricingCard(
      plan: plan.label,
      price: _model.plans.priceString(plan),
      period: plan.periodSuffix,
      isRecommended: isRecommended,
      savingsLabel:
          savings != null ? 'Save $savings% vs weekly plan' : plan.billedLabel,
      features: const [
        'Daily manifestation stories',
        'Clone your own voice',
        'Sleep Mode with theta waves',
        'Professional voices available',
      ],
      isSelected: _model.selectedPlan == plan,
      onTap: () => safeSetState(() => _model.selectedPlan = plan),
    );
  }

  Widget _buildPricingCards() {
    return Column(
      children: [
        _planCard(SubscriptionPlan.weekly, isRecommended: false),
        const SizedBox(height: 12),
        _planCard(SubscriptionPlan.monthly, isRecommended: true),
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
    final plan = _model.selectedPlan;
    final trial = plan != null ? _trialFor(plan) : null;
    final String label;
    if (_model.isSubscribed) {
      label = 'Update Plan';
    } else if (trial != null) {
      label = 'Start ${trial.titleAdjective} Free Trial';
    } else {
      label = plan != null ? 'Subscribe to ${plan.label}' : 'Start Subscription';
    }
    return _ctaButton(
      label: label,
      onTap: _handleConfirmPayment,
    );
  }

  Future<void> _handleConfirmPayment() async {
    if (_model.isPaymentLoading) return;

    RevenueCatService.logFlow(
      'OnboardingPay',
      '_handleConfirmPayment: start selectedPlan=${_model.selectedPlan}',
    );
    if (!RevenueCatService.instance.isSupported) {
      RevenueCatService.logFlow('OnboardingPay', '_handleConfirmPayment: not supported');
      AppToast.error(
        context,
        'Subscriptions are available on the App Store (iPhone/iPad) and Google Play (Android). Please use a supported device.',
      );
      return;
    }

    final plan = _model.selectedPlan;
    if (plan == null) {
      RevenueCatService.logFlow('OnboardingPay', '_handleConfirmPayment: no plan selected');
      AppToast.info(context, 'Please select a plan first');
      return;
    }

    final userId = await SupabaseService.getCurrentUserTableId();
    if (userId == null) {
      RevenueCatService.logFlow('OnboardingPay', '_handleConfirmPayment: userId null');
      AppToast.error(context, 'Please sign in to subscribe');
      return;
    }

    final trial = _trialFor(plan);
    safeSetState(() => _model.isPaymentLoading = true);

    try {
      RevenueCatService.logFlow(
        'OnboardingPay',
        '_handleConfirmPayment: ensureReady userId=$userId',
      );
      await RevenueCatService.instance.ensureReady(appUserId: userId.toString());

      final offerings = await RevenueCatService.instance.getOfferings();
      final package = RevenueCatService.findPackage(offerings, plan);
      if (package == null) {
        RevenueCatService.logFlow(
          'OnboardingPay',
          '_handleConfirmPayment: package NOT FOUND plan=${plan.name}',
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

      RevenueCatService.logFlow(
        'OnboardingPay',
        '_handleConfirmPayment: purchase ${package.identifier}',
      );
      final info = await RevenueCatService.instance.purchasePackage(package);
      if (!mounted) return;

      if (info != null) {
        try {
          RevenueCatService.logFlow(
            'OnboardingPay',
            '_handleConfirmPayment: sync backend userId=$userId',
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
            'OnboardingPay',
            '_handleConfirmPayment: backend sync FAILED: $e',
          );
          debugPrint('$st');
        }
      }

      RevenueCatService.logFlow('OnboardingPay', '_handleConfirmPayment: success');
      AppToast.success(context, _successMessage(trial));
      await OnboardingService.setOnboardingCompleted();
      if (!mounted) return;
      _goAfterSubscribe(context);
    } on PlatformException catch (e) {
      if (!mounted) return;
      if (PurchasesErrorHelper.getErrorCode(e) ==
          PurchasesErrorCode.purchaseCancelledError) {
        RevenueCatService.logFlow(
          'OnboardingPay',
          '_handleConfirmPayment: USER CANCELLED code=${e.code} message=${e.message} '
          'details=${e.details} — running sync workaround',
        );
        try {
          await RevenueCatService.instance.syncPurchases();
          for (final waitSeconds in [2, 3, 5]) {
            RevenueCatService.logFlow(
              'OnboardingPay',
              'cancel workaround: wait ${waitSeconds}s then getCustomerInfo',
            );
            await Future<void>.delayed(Duration(seconds: waitSeconds));
            if (!mounted) return;
            final info = await RevenueCatService.instance.getCustomerInfo();
            if (info != null) {
              final status = RevenueCatService.instance.getSubscriptionPayloadForBackend(info);
              if (status['rc_subscription_status'] != 'canceled') {
                try {
                  await subscriptionRepository.updateUserRevenueCatSubscription(
                    userId,
                    rcCustomerId: status['rc_customer_id']!,
                    rcSubscriptionStatus: status['rc_subscription_status']!,
                    rcSubscriptionPlan: status['rc_subscription_plan']!,
                    subscriptionProvider: status['subscription_provider']!,
                  );
                } catch (e, st) {
                  RevenueCatService.logFlow(
                    'OnboardingPay',
                    'cancel workaround: backend sync FAILED: $e',
                  );
                  debugPrint('$st');
                }
                RevenueCatService.logFlow(
                  'OnboardingPay',
                  'cancel workaround: recovered active subscription',
                );
                AppToast.success(context, _successMessage(trial));
                await OnboardingService.setOnboardingCompleted();
                if (!mounted) return;
                _goAfterSubscribe(context);
                return;
              }
            }
          }
        } catch (e, st) {
          RevenueCatService.logFlow(
            'OnboardingPay',
            'cancel workaround: outer catch $e',
          );
          debugPrint('$st');
        }
        if (!mounted) return;
        RevenueCatService.logFlow(
          'OnboardingPay',
          'cancel workaround: still no subscription after retries',
        );
        AppToast.info(
          context,
          'Subscription not started. Tap Subscribe again and complete both Apple ID and the subscription step.',
        );
      } else {
        RevenueCatService.logFlow(
          'OnboardingPay',
          '_handleConfirmPayment: PlatformException code=${e.code} '
          'message=${e.message} details=${e.details}',
        );
        AppToast.error(context, e.message ?? 'Payment failed');
      }
    } catch (e, st) {
      RevenueCatService.logFlow('OnboardingPay', '_handleConfirmPayment: unexpected $e');
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
    RevenueCatService.logFlow('OnboardingPay', '_handleRestorePurchases: start');
    if (!RevenueCatService.instance.isSupported) {
      RevenueCatService.logFlow('OnboardingPay', '_handleRestorePurchases: not supported');
      AppToast.error(
        context,
        'Subscriptions are available on the App Store (iPhone/iPad) and Google Play (Android). Please use a supported device.',
      );
      return;
    }
    safeSetState(() => _model.isPaymentLoading = true);
    try {
      final userId = await SupabaseService.getCurrentUserTableId();
      RevenueCatService.logFlow('OnboardingPay', '_handleRestorePurchases: userId=$userId');
      final info = await RevenueCatService.instance.restorePurchases();
      if (!mounted) return;
      if (info != null && userId != null) {
        try {
          RevenueCatService.logFlow(
            'OnboardingPay',
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
            'OnboardingPay',
            '_handleRestorePurchases: backend sync FAILED: $e',
          );
          debugPrint('$st');
        }
      }
      RevenueCatService.logFlow('OnboardingPay', '_handleRestorePurchases: done');
      AppToast.success(context, 'Purchases restored');
      _loadSubscriptionStatus();
    } catch (e, st) {
      RevenueCatService.logFlow('OnboardingPay', '_handleRestorePurchases: FAILED $e');
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

  Widget _buildSecondaryText() {
    final lines = <String>[
      for (final plan in SubscriptionPlan.values)
        _trialFor(plan) != null
            ? '${plan.label}: ${_trialFor(plan)!.duration} free, then ${_model.plans.priceString(plan)}${plan.periodSuffix}.'
            : '${plan.label}: ${_model.plans.priceString(plan)}${plan.periodSuffix}.',
      'Cancel anytime in settings.',
    ];
    return Text(
      lines.join('\n'),
      style: GoogleFonts.outfit(
        fontSize: 11,
        color: AuthTheme.inkSoft,
        height: 1.5,
      ),
      textAlign: TextAlign.center,
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
            color: AuthTheme.goldDark,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildContinueWithoutSubscribing() {
    final returnTo = GoRouterState.of(context).uri.queryParameters['returnTo'];
    if (returnTo == null || returnTo.isEmpty) return const SizedBox.shrink();
    return Pressable(
      onTap: () => context.go(OnboardingDesireWidget.routePath),
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Text(
          'Continue without subscribing',
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

  Widget _buildFooterLinks() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Pressable(
          onTap: () {
            _openExternalLink(kTermsOfServiceUri);
          },
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            child: Text(
              'Terms of Service',
              style: GoogleFonts.outfit(
                fontSize: 10,
                color: AuthTheme.inkSoft,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Pressable(
          onTap: () {
            _openExternalLink(kPrivacyPolicyUri);
          },
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            child: Text(
              'Privacy Policy',
              style: GoogleFonts.outfit(
                fontSize: 10,
                color: AuthTheme.inkSoft,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
