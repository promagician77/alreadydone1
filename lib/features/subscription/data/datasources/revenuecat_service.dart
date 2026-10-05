import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '/core/network/backend_client.dart';
import '/core/platform/platform_utils.dart';

class RevenueCatService {
  RevenueCatService._();
  static final RevenueCatService instance = RevenueCatService._();

  static const String entitlementId = 'Already Done Pro';

  /// Structured logs for DevTools (filter name: `RevenueCat`) plus console `[RevenueCat]`.
  static void _log(
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    developer.log(
      message,
      name: 'RevenueCat',
      error: error,
      stackTrace: stackTrace,
    );
    final suffix = error != null ? ' | $error' : '';
    debugPrint('[RevenueCat] $message$suffix');
  }

  /// Call from UI layers (subscription screen, onboarding, auth, home) for flow tracing.
  static void logFlow(String scope, String message) {
    _log('[$scope] $message');
  }

  /// One-line summary for debugging purchases and entitlement state.
  static String summarizeCustomerInfo(CustomerInfo info) {
    final activeKeys = info.entitlements.active.keys.join(',');
    final allKeys = info.entitlements.all.keys.join(',');
    final e = info.entitlements.all[entitlementId];
    final entitlementPart = e != null
        ? '$entitlementId: active=${e.isActive} product=${e.productIdentifier} '
            'period=${e.periodType} willRenew=${e.willRenew} '
            'expires=${e.expirationDate}'
        : '$entitlementId: <missing>';
    final purchases = info.allPurchasedProductIdentifiers.join(',');
    return 'originalAppUserId=${info.originalAppUserId} | '
        'activeEntitlements=[$activeKeys] all=[$allKeys] | $entitlementPart | '
        'allPurchasedProducts=[$purchases]';
  }

  static String summarizePackage(Package p) {
    try {
      final sp = p.storeProduct;
      return 'packageId=${p.identifier} packageType=${p.packageType} '
          'offeringId=${p.offeringIdentifier} storeProductId=${sp.identifier} '
          'price=${sp.priceString} title=${sp.title}';
    } catch (e) {
      return 'packageId=${p.identifier} (storeProduct: $e)';
    }
  }

  static String? get _appleApiKey => dotenv.env['REVENUECAT_APPLE_API_KEY']?.trim();
  static String? get _googleApiKey => dotenv.env['REVENUECAT_GOOGLE_API_KEY']?.trim();

  bool _configured = false;
  String? _currentUserId;

  bool get isSupported => isIOS || isAndroid;
  bool get isConfigured => _configured;

  Future<void> configure({String? appUserId}) async {
    if (!isIOS && !isAndroid) {
      _log('configure: skipped (not iOS/Android)');
      return;
    }
    if (_configured) {
      _log('configure: skipped (already configured) currentUserId=$_currentUserId');
      return;
    }
    try {
      final apiKey = isIOS ? _appleApiKey : _googleApiKey;
      final keyName = isIOS ? 'REVENUECAT_APPLE_API_KEY' : 'REVENUECAT_GOOGLE_API_KEY';
      if (apiKey == null || apiKey.isEmpty) {
        _log('configure: ABORT — $keyName missing or empty in .env');
        return;
      }
      _log(
        'configure: start platform=${isIOS ? "iOS" : "Android"} '
        'appUserId=${appUserId?.trim().isNotEmpty == true ? appUserId!.trim() : "(anonymous)"} '
        'apiKeyLength=${apiKey.length} entitlementId=$entitlementId',
      );
      await Purchases.setLogLevel(LogLevel.debug);

      final config = PurchasesConfiguration(apiKey);
      if (appUserId != null && appUserId.trim().isNotEmpty) {
        config.appUserID = appUserId.trim();
      }
      await Purchases.configure(config);
      Purchases.addCustomerInfoUpdateListener(_onCustomerInfoUpdated);

      _currentUserId = appUserId?.trim();
      _configured = true;
      _log('configure: OK isConfigured=$_configured userId=$_currentUserId');
    } catch (e, st) {
      _log('configure: FAILED', error: e, stackTrace: st);
    }
  }

  /// Ensure the SDK is configured and the correct user is logged in.
  /// ✅ FIX 1: Call this during app startup or login, NOT before purchase.
  /// Safe to call multiple times — only acts when needed.
  Future<void> ensureReady({required String appUserId}) async {
    if (!isSupported) {
      _log('ensureReady: skipped (platform not supported)');
      return;
    }

    // Configure if not yet done
    if (!_configured) {
      _log('ensureReady: SDK not configured yet — calling configure(appUserId)');
      await configure(appUserId: appUserId);
      return; // configure already sets the user
    }

    // If already configured but for a different (or no) user, log in
    final trimmed = appUserId.trim();
    _log(
      'ensureReady: current=$_currentUserId requested=$trimmed '
      'match=${_currentUserId == trimmed}',
    );
    if (_currentUserId != trimmed) {
      await logIn(trimmed);
    } else {
      _log('ensureReady: no logIn needed (same user)');
    }
  }

  /// Link RevenueCat to your user id. No-op on unsupported platforms.
  Future<void> logIn(String appUserId) async {
    if (!isSupported) return;
    final trimmed = appUserId.trim();
    _log('logIn: calling Purchases.logIn for appUserId=$trimmed');
    try {
      final result = await Purchases.logIn(trimmed);
      _currentUserId = trimmed;
      _log('logIn: OK ${summarizeCustomerInfo(result.customerInfo)}');
    } catch (e, st) {
      _log('logIn: FAILED', error: e, stackTrace: st);
    }
  }

  /// Call when user logs out. No-op on unsupported platforms.
  /// Only calls native Purchases.logOut() when the SDK has been configured,
  /// to avoid native fatalError (CommonFunctionality.sharedInstance) when
  /// logout runs before deferred init (e.g. user signs out before configure).
  Future<void> logOut() async {
    if (!isSupported) return;
    _currentUserId = null;
    if (!_configured) {
      _log('logOut: skipped (SDK not configured)');
      return;
    }
    _log('logOut: calling Purchases.logOut');
    try {
      final info = await Purchases.logOut();
      _log('logOut: OK ${summarizeCustomerInfo(info)}');
    } catch (e, st) {
      _log('logOut: FAILED', error: e, stackTrace: st);
    }
  }

  /// Called by the RevenueCat SDK whenever subscription state changes (e.g. trial → paid).
  /// Pushes the updated status to the backend so the DB stays in sync without a webhook.
  void _onCustomerInfoUpdated(CustomerInfo info) {
    final userId = _currentUserId;
    if (userId == null) {
      _log('_onCustomerInfoUpdated: skipped (no current user)');
      return;
    }
    final numericId = int.tryParse(userId);
    if (numericId == null) {
      _log('_onCustomerInfoUpdated: skipped (non-numeric userId=$userId)');
      return;
    }
    _log('_onCustomerInfoUpdated: pushing update to backend userId=$userId');
    final payload = getSubscriptionPayloadForBackend(info);
    BackendClient.updateUserRevenueCatSubscription(
      numericId,
      rcCustomerId: payload['rc_customer_id']!,
      rcSubscriptionStatus: payload['rc_subscription_status']!,
      rcSubscriptionPlan: payload['rc_subscription_plan']!,
      subscriptionProvider: payload['subscription_provider']!,
    ).then((_) {
      _log('_onCustomerInfoUpdated: backend updated status=${payload['rc_subscription_status']}');
    }).catchError((Object e) {
      _log('_onCustomerInfoUpdated: backend update failed', error: e);
    });
  }

  /// Whether the user has active premium access. Returns false when unsupported.
  Future<bool> isSubscribed() async {
    if (!isSupported) {
      _log('isSubscribed: false (platform not supported)');
      return false;
    }
    try {
      final info = await Purchases.getCustomerInfo();
      final entitlement = info.entitlements.all[entitlementId];
      final ok = entitlement?.isActive == true;
      _log(
        'isSubscribed: $ok | entitlement active=${entitlement?.isActive} '
        'product=${entitlement?.productIdentifier} period=${entitlement?.periodType}',
      );
      return ok;
    } catch (e, st) {
      _log('isSubscribed: FAILED', error: e, stackTrace: st);
      return false;
    }
  }

  /// Subscription status for UI. Returns default (not subscribed) when unsupported.
  Future<RevenueCatSubscriptionStatus> getSubscriptionStatus() async {
    if (!isSupported) {
      _log('getSubscriptionStatus: default (not supported)');
      return const RevenueCatSubscriptionStatus(
        isSubscribed: false,
        isTrialing: false,
        isCanceled: false,
        isAnnualPlan: false,
        isMonthlyPlan: false,
        isWeeklyPlan: false,
      );
    }
    try {
      final info = await Purchases.getCustomerInfo();
      _log('getSubscriptionStatus: raw ${summarizeCustomerInfo(info)}');
      final entitlement = info.entitlements.all[entitlementId];
      final active = entitlement?.isActive == true;

      final isTrialing = entitlement?.periodType == PeriodType.trial;

      final productId = (entitlement?.productIdentifier ?? '').toLowerCase();

      final isAnnual = productId.contains('annual') ||
          productId.contains('yearly') ||
          (productId.contains('year') && !productId.contains('week'));

      final isWeekly = !isAnnual && productId.contains('week');

      final isMonthly = !isAnnual &&
          !isWeekly &&
          (productId.contains('monthly') ||
              productId.contains('month') ||
              productId.contains(r'$rc_monthly'));

      final isCanceled = entitlement?.unsubscribeDetectedAt != null;

      _log(
        'getSubscriptionStatus: computed active=$active trialing=$isTrialing '
        'canceled=$isCanceled productId=$productId annual=$isAnnual '
        'monthly=$isMonthly weekly=$isWeekly',
      );

      return RevenueCatSubscriptionStatus(
        isSubscribed: active,
        isTrialing: isTrialing,
        isCanceled: isCanceled,
        isAnnualPlan: isAnnual,
        isMonthlyPlan: isMonthly,
        isWeeklyPlan: isWeekly,
      );
    } catch (e, st) {
      _log('getSubscriptionStatus: FAILED', error: e, stackTrace: st);
      return const RevenueCatSubscriptionStatus(
        isSubscribed: false,
        isTrialing: false,
        isCanceled: false,
        isAnnualPlan: false,
        isMonthlyPlan: false,
        isWeeklyPlan: false,
      );
    }
  }

  /// Fetch current offerings. Returns null when unsupported.
  Future<Offerings?> getOfferings() async {
    if (!isSupported) {
      _log('getOfferings: null (not supported)');
      return null;
    }
    try {
      _log('getOfferings: requesting Purchases.getOfferings()');
      final offerings = await Purchases.getOfferings();
      final current = offerings.current;
      if (current == null) {
        _log(
          'getOfferings: NO current offering — set one as "Current" in RevenueCat. '
          'allOfferingIds=[${offerings.all.keys.join(", ")}]',
        );
      } else {
        final packages = current.availablePackages;
        for (var i = 0; i < packages.length; i++) {
          _log('getOfferings: package[$i] ${summarizePackage(packages[i])}');
        }
        _log(
          'getOfferings: current="${current.identifier}" '
          'packageCount=${packages.length}',
        );
        if (packages.isEmpty) {
          _log(
            'getOfferings: empty packages — add \$rc_weekly / \$rc_monthly '
            'and ensure store products are approved and linked',
          );
        }
      }
      return offerings;
    } catch (e, st) {
      _log('getOfferings: FAILED', error: e, stackTrace: st);
      return null;
    }
  }

  /// Plan a package / store product identifier refers to, or null when it is not one
  /// of the plans currently sold (e.g. the legacy annual product).
  static SubscriptionPlan? _planFromIdentifier(String identifier) {
    final id = identifier.toLowerCase();
    if (id.contains('annual') || id.contains('year')) return null;
    if (id.contains('week')) return SubscriptionPlan.weekly;
    if (id.contains('month')) return SubscriptionPlan.monthly;
    return null;
  }

  /// Package for [plan] in the current offering. Matches the RevenueCat package type
  /// first, then falls back to the package / store product identifiers. Returns null
  /// rather than another plan's package, so the user is never sold the wrong plan.
  static Package? findPackage(Offerings? offerings, SubscriptionPlan plan) {
    final packages = offerings?.current?.availablePackages ?? const <Package>[];
    final wantedType = plan == SubscriptionPlan.weekly
        ? PackageType.weekly
        : PackageType.monthly;
    for (final p in packages) {
      if (p.packageType == wantedType) return p;
    }
    for (final p in packages) {
      if (_planFromIdentifier(p.identifier) == plan ||
          _planFromIdentifier(p.storeProduct.identifier) == plan) {
        return p;
      }
    }
    return null;
  }

  /// Store product ids whose intro offer this user has already used. Only the App
  /// Store reports this; Google Play only returns offers the user is eligible for.
  Future<Set<String>> _trialIneligibleProductIds(List<String> productIds) async {
    if (productIds.isEmpty) return const <String>{};
    try {
      final result =
          await Purchases.checkTrialOrIntroductoryPriceEligibility(productIds);
      return {
        for (final e in result.entries)
          if (e.value.status ==
              IntroEligibilityStatus.introEligibilityStatusIneligible)
            e.key,
      };
    } catch (e, st) {
      _log('_trialIneligibleProductIds: FAILED', error: e, stackTrace: st);
      return const <String>{};
    }
  }

  /// Weekly and monthly plans with their store price and free trial, for display.
  /// Either plan is null when unsupported or missing from the current offering.
  Future<AvailablePlans> getAvailablePlans() async {
    if (!isSupported) {
      return const AvailablePlans();
    }
    try {
      if (!_configured) await configure();
      if (!_configured) return const AvailablePlans();

      final offerings = await getOfferings();
      final packages = {
        for (final plan in SubscriptionPlan.values)
          plan: findPackage(offerings, plan),
      };
      final ineligible = await _trialIneligibleProductIds([
        for (final p in packages.values)
          if (p != null) p.storeProduct.identifier,
      ]);

      PlanOffer? offerFor(SubscriptionPlan plan) {
        final package = packages[plan];
        if (package == null) return null;
        final product = package.storeProduct;
        final intro = product.introductoryPrice;
        final freeTrial = intro != null &&
                intro.price == 0 &&
                !ineligible.contains(product.identifier)
            ? FreeTrial.fromIso8601(intro.period)
            : null;
        return PlanOffer(plan: plan, package: package, freeTrial: freeTrial);
      }

      final plans = AvailablePlans(
        weekly: offerFor(SubscriptionPlan.weekly),
        monthly: offerFor(SubscriptionPlan.monthly),
      );
      for (final plan in SubscriptionPlan.values) {
        final offer = plans[plan];
        _log(
          'getAvailablePlans: ${plan.name}='
          '${offer != null ? "${summarizePackage(offer.package)} freeTrial=${offer.freeTrial?.adjective}" : "NOT FOUND"}',
        );
      }
      return plans;
    } catch (e, st) {
      _log('getAvailablePlans: FAILED', error: e, stackTrace: st);
      return const AvailablePlans();
    }
  }

  /// Purchase a package. Throws when unsupported or if cancelled.
  Future<CustomerInfo?> purchasePackage(Package package) async {
    if (!isSupported) {
      _log('purchasePackage: ABORT — platform not supported');
      throw PlatformException(
        code: 'UNSUPPORTED',
        message: 'Subscriptions are available on the App Store (iOS) or Google Play (Android).',
      );
    }
    _log('purchasePackage: START ${summarizePackage(package)}');
    try {
      // purchases_flutter 9.x returns PurchaseResult; callers need CustomerInfo.
      final result = await Purchases.purchasePackage(package);
      final info = result.customerInfo;
      _log('purchasePackage: SUCCESS ${summarizeCustomerInfo(info)}');
      return info;
    } on PlatformException catch (e, st) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      if (code == PurchasesErrorCode.purchaseCancelledError) {
        _log(
          'purchasePackage: USER CANCELLED code=${e.code} message=${e.message} '
          'details=${e.details}',
        );
        // Note: StoreKit can return userCancelled=true even when the subscription
        // sheet never appeared (e.g. after Apple ID sign-in). Callers may sync and
        // recheck entitlement when this happens (see RevenueCat/purchases-ios#4903).
        rethrow;
      }
      _log(
        'purchasePackage: PlatformException code=$code raw=${e.code} '
        'message=${e.message} details=${e.details}',
        error: e,
        stackTrace: st,
      );
      rethrow;
    } catch (e, st) {
      _log('purchasePackage: FAILED', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Sync purchases to RevenueCat backend from device cache. Does not trigger
  /// Apple ID prompt (unlike restorePurchases). Use in cancel-workaround flows.
  Future<void> syncPurchases() async {
    if (!isSupported) {
      _log('syncPurchases: skipped (not supported)');
      return;
    }
    try {
      _log('syncPurchases: calling Purchases.syncPurchases()');
      await Purchases.syncPurchases();
      final info = await Purchases.getCustomerInfo();
      _log('syncPurchases: done ${summarizeCustomerInfo(info)}');
    } catch (e, st) {
      _log('syncPurchases: FAILED', error: e, stackTrace: st);
    }
  }

  /// Restore previous purchases. Can trigger Apple ID sign-in on iOS.
  /// Prefer syncPurchases() when you only need to recheck entitlement after a cancel.
  Future<CustomerInfo?> restorePurchases() async {
    if (!isSupported) {
      _log('restorePurchases: null (not supported)');
      return null;
    }
    try {
      _log('restorePurchases: calling Purchases.restorePurchases()');
      final info = await Purchases.restorePurchases();
      _log('restorePurchases: OK ${summarizeCustomerInfo(info)}');
      return info;
    } catch (e, st) {
      _log('restorePurchases: FAILED', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Fetch current customer info from RevenueCat (e.g. after syncPurchases).
  Future<CustomerInfo?> getCustomerInfo() async {
    if (!isSupported) return null;
    try {
      final info = await Purchases.getCustomerInfo();
      _log('getCustomerInfo: ${summarizeCustomerInfo(info)}');
      return info;
    } catch (e, st) {
      _log('getCustomerInfo: FAILED', error: e, stackTrace: st);
      return null;
    }
  }

  /// Build payload for PATCH api/users/{user_id}: rc_customer_id, rc_subscription_status,
  /// rc_subscription_plan, subscription_provider. Use after purchase or restore.
  Map<String, String> getSubscriptionPayloadForBackend(CustomerInfo info) {
    final entitlement = info.entitlements.all[entitlementId];
    final isActive = entitlement?.isActive == true;
    final isTrialing = entitlement?.periodType == PeriodType.trial;
    final canceled = entitlement?.unsubscribeDetectedAt != null;

    String status = 'canceled';
    if (isActive) {
      // Normalize trial state to "trial" (avoid "trialing" in backend).
      status = isTrialing ? 'trial' : 'active';
    }

    final productId = (entitlement?.productIdentifier ?? '').toLowerCase();
    final isAnnual = productId.contains('annual') ||
        productId.contains('yearly') ||
        (productId.contains('year') && !productId.contains('week'));
    final isWeekly = !isAnnual &&
        (productId.contains('weekly') ||
            productId.contains('week') ||
            productId.contains(r'$rc_weekly'));
    final isMonthly = !isAnnual &&
        !isWeekly &&
        (productId.contains('monthly') ||
            productId.contains('month') ||
            productId.contains(r'$rc_monthly'));
    final String plan =
        isAnnual ? 'annual' : (isWeekly ? 'weekly' : (isMonthly ? 'monthly' : 'unknown'));

    final payload = {
      'rc_customer_id': info.originalAppUserId,
      'rc_subscription_status': status,
      'rc_subscription_plan': plan,
      'subscription_provider': 'revenuecat',
    };
    _log(
      'getSubscriptionPayloadForBackend: status=$status plan=$plan '
      'productId=$productId canceledFlag=$canceled payload=$payload',
    );
    return payload;
  }
}

// ---------------------------------------------------------------------------
// Data classes
// ---------------------------------------------------------------------------

/// Plans currently sold. Annual is legacy: existing subscribers keep it, but it is
/// no longer offered.
enum SubscriptionPlan {
  weekly,
  monthly;

  /// "Weekly" / "Monthly"
  String get label => this == weekly ? 'Weekly' : 'Monthly';

  /// "/week" / "/month"
  String get periodSuffix => this == weekly ? '/week' : '/month';

  /// "Billed weekly" / "Billed monthly"
  String get billedLabel => this == weekly ? 'Billed weekly' : 'Billed monthly';
}

/// Free-trial length reported by the store, e.g. 3 days.
class FreeTrial {
  const FreeTrial(this.count, this.unit);

  final int count;

  /// Singular unit: "day", "week", "month" or "year".
  final String unit;

  /// "3-day"
  String get adjective => '$count-$unit';

  /// "3-Day"
  String get titleAdjective =>
      '$count-${unit[0].toUpperCase()}${unit.substring(1)}';

  /// "3 days"
  String get duration => count == 1 ? '1 $unit' : '$count ${unit}s';

  /// Parses an ISO 8601 period such as "P3D" or "P1W".
  static FreeTrial? fromIso8601(String period) {
    final match =
        RegExp(r'^P(\d+)([DWMY])$').firstMatch(period.trim().toUpperCase());
    if (match == null) return null;
    final count = int.parse(match.group(1)!);
    if (count <= 0) return null;
    const units = {'D': 'day', 'W': 'week', 'M': 'month', 'Y': 'year'};
    return FreeTrial(count, units[match.group(2)]!);
  }
}

/// A purchasable plan with what the store will actually charge this user.
class PlanOffer {
  const PlanOffer({
    required this.plan,
    required this.package,
    this.freeTrial,
  });

  final SubscriptionPlan plan;
  final Package package;

  /// Free trial this user gets on purchase. Null when the store product has none
  /// or the user has already used it.
  final FreeTrial? freeTrial;

  /// Localized store price, e.g. "$4.99".
  String get priceString => package.storeProduct.priceString;
  double get price => package.storeProduct.price;
  bool get hasFreeTrial => freeTrial != null;
}

class AvailablePlans {
  const AvailablePlans({this.weekly, this.monthly});

  final PlanOffer? weekly;
  final PlanOffer? monthly;

  PlanOffer? operator [](SubscriptionPlan plan) =>
      plan == SubscriptionPlan.weekly ? weekly : monthly;

  /// Whole-percent saving of the monthly plan over paying weekly for a month.
  /// Null when either price is missing or monthly is not cheaper.
  int? get monthlySavingsPercent {
    final weeklyPrice = weekly?.price;
    final monthlyPrice = monthly?.price;
    if (weeklyPrice == null || monthlyPrice == null) return null;
    if (weeklyPrice <= 0 || monthlyPrice <= 0) return null;
    final weeklyCostPerMonth = weeklyPrice * 52 / 12;
    final percent = ((1 - monthlyPrice / weeklyCostPerMonth) * 100).floor();
    return percent > 0 ? percent : null;
  }
}

class RevenueCatSubscriptionStatus {
  const RevenueCatSubscriptionStatus({
    required this.isSubscribed,
    required this.isTrialing,
    required this.isCanceled,
    required this.isAnnualPlan,
    required this.isMonthlyPlan,
    required this.isWeeklyPlan,
  });

  final bool isSubscribed;
  final bool isTrialing;
  final bool isCanceled;

  /// Legacy plan: no longer sold, but existing subscribers keep it.
  final bool isAnnualPlan;
  final bool isMonthlyPlan;
  final bool isWeeklyPlan;

  bool get isActiveAndRenewing => isSubscribed && !isCanceled;
}