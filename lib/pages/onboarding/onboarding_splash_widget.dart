import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '/constants/legal_urls.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/auth/auth_theme.dart';
import '/pages/subscription/subscription_model.dart';
import '/services/backend_client.dart';
import '/services/revenuecat_service.dart';
import '/services/supabase_service.dart';
import '/services/app_toast.dart';
import '/services/onboarding_service.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '/widgets/pressable.dart';
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
  }

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
                        _buildTrialBadge(),
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
          '✨ Start Your 3-Day Free Trial',
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
          plan: 'Monthly',
          price: '\$29.99',
          period: '/month',
          isRecommended: true,
          savingsLabel: 'Save 30% vs weekly plan',
          features: const [
            'Daily manifestation stories',
            'Clone your own voice',
            'Sleep Mode with theta waves',
            'Professional voices available',
          ],
          isSelected: _model.selectedPlan == 0,
          onTap: () => safeSetState(() => _model.selectedPlan = 0),
        ),
        const SizedBox(height: 12),
        _buildPricingCard(
          plan: 'Weekly',
          price: '\$9.99',
          period: '/week',
          isRecommended: false,
          savingsLabel: null,
          features: const [
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

  Package? _findPackage(Offerings? offerings, {required bool wantMonthly}) {
    final packages = offerings?.current?.availablePackages ?? [];
    for (final p in packages) {
      final id = p.identifier.toLowerCase();
      final isMonthly = id.contains('monthly') || id.contains('month') || id.contains(r'$rc_monthly');
      final isWeekly = id.contains('weekly') || id.contains('week') || id.contains(r'$rc_weekly');
      if (wantMonthly && isMonthly) return p;
      if (!wantMonthly && isWeekly) return p;
    }
    // Fallback: if only one plan exists, use it (dashboard may have single package)
    if (packages.length == 1) return packages.first;
    return null;
  }

  Future<void> _handleConfirmPayment({required bool isStartTrial}) async {
    if (_model.isPaymentLoading) return;

    RevenueCatService.logFlow(
      'OnboardingPay',
      '_handleConfirmPayment: start isStartTrial=$isStartTrial selectedPlan=${_model.selectedPlan}',
    );
    if (!RevenueCatService.instance.isSupported) {
      RevenueCatService.logFlow('OnboardingPay', '_handleConfirmPayment: not supported');
      AppToast.error(
        context,
        'Subscriptions are available on the App Store (iPhone/iPad) and Google Play (Android). Please use a supported device.',
      );
      return;
    }

    if (_model.selectedPlan == null) {
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

    safeSetState(() => _model.isPaymentLoading = true);

    try {
      RevenueCatService.logFlow(
        'OnboardingPay',
        '_handleConfirmPayment: ensureReady userId=$userId',
      );
      await RevenueCatService.instance.ensureReady(appUserId: userId.toString());

      final offerings = await RevenueCatService.instance.getOfferings();
      final wantMonthly = _model.selectedPlan == 0;
      final package = _findPackage(offerings, wantMonthly: wantMonthly);
      if (package == null) {
        RevenueCatService.logFlow(
          'OnboardingPay',
          '_handleConfirmPayment: package NOT FOUND wantMonthly=$wantMonthly',
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
          await BackendClient.updateUserRevenueCatSubscription(
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
      AppToast.success(
        context,
        isStartTrial ? '3-day free trial started!' : 'Subscription active!',
      );
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
                  await BackendClient.updateUserRevenueCatSubscription(
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
                AppToast.success(
                  context,
                  isStartTrial ? '3-day free trial started!' : 'Subscription active!',
                );
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
          'Subscription not started. Tap Start Free Trial again and complete both Apple ID and the subscription step.',
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
          await BackendClient.updateUserRevenueCatSubscription(
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
    return Text(
      'Free for 3 days, then \$9.99/week or \$29.99/month.\nCancel anytime in settings.',
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

  /// When paywall is shown during onboarding (returnTo set), show a link to continue without subscribing.
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
