import 'dart:developer' as developer;

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '/utils/platform_utils.dart';

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
        isWeeklyPlan: false,
        isMonthlyPlan: false,
      );
    }
    try {
      final info = await Purchases.getCustomerInfo();
      _log('getSubscriptionStatus: raw ${summarizeCustomerInfo(info)}');
      final entitlement = info.entitlements.all[entitlementId];
      final active = entitlement?.isActive == true;

      final isTrialing = entitlement?.periodType == PeriodType.trial;

      final productId = (entitlement?.productIdentifier ?? '').toLowerCase();

      final isWeekly = productId.contains('weekly') ||
          productId.contains('week') ||
          productId.contains(r'$rc_weekly');

      final isMonthly = !isWeekly &&
          (productId.contains('monthly') ||
              productId.contains('month') ||
              productId.contains(r'$rc_monthly'));

      final isCanceled = entitlement?.unsubscribeDetectedAt != null;

      _log(
        'getSubscriptionStatus: computed active=$active trialing=$isTrialing '
        'canceled=$isCanceled productId=$productId weekly=$isWeekly monthly=$isMonthly',
      );

      return RevenueCatSubscriptionStatus(
        isSubscribed: active,
        isTrialing: isTrialing,
        isCanceled: isCanceled,
        isWeeklyPlan: isWeekly,
        isMonthlyPlan: isMonthly,
      );
    } catch (e, st) {
      _log('getSubscriptionStatus: FAILED', error: e, stackTrace: st);
      return const RevenueCatSubscriptionStatus(
        isSubscribed: false,
        isTrialing: false,
        isCanceled: false,
        isWeeklyPlan: false,
        isMonthlyPlan: false,
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
      if (offerings == null) {
        _log('getOfferings: null response');
        return null;
      }
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

  Future<AvailablePlans> getAvailablePlans() async {
    if (!isSupported) {
      return const AvailablePlans(weekly: null, monthly: null);
    }
    try {
      final offerings = await getOfferings();
      final packages = offerings?.current?.availablePackages ?? [];

      _log(
        'getAvailablePlans: total=${packages.length} '
        'ids=${packages.map((p) => p.identifier).join(", ")}',
      );

      final weekly = packages.firstWhereOrNull(
        (p) =>
            p.packageType == PackageType.weekly ||
            p.identifier == r'$rc_weekly' ||
            p.identifier.toLowerCase().contains('weekly') ||
            p.identifier.toLowerCase().contains('week'),
      );

      final monthly = packages.firstWhereOrNull(
        (p) =>
            p.packageType == PackageType.monthly ||
            p.identifier == r'$rc_monthly' ||
            p.identifier.toLowerCase().contains('monthly') ||
            p.identifier.toLowerCase().contains('month'),
      );

      _log(
        'getAvailablePlans: weekly=${weekly != null ? summarizePackage(weekly!) : "NOT FOUND"} | '
        'monthly=${monthly != null ? summarizePackage(monthly!) : "NOT FOUND"}',
      );

      return AvailablePlans(weekly: weekly, monthly: monthly);
    } catch (e, st) {
      _log('getAvailablePlans: FAILED', error: e, stackTrace: st);
      return const AvailablePlans(weekly: null, monthly: null);
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
      final result = await Purchases.purchasePackage(package);
      _log('purchasePackage: SUCCESS ${summarizeCustomerInfo(result)}');
      return result;
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
    final isWeekly = productId.contains('weekly') ||
        productId.contains('week') ||
        productId.contains(r'$rc_weekly');
    final isMonthly = productId.contains('monthly') ||
        productId.contains('month') ||
        productId.contains(r'$rc_monthly');
    final String plan = isWeekly ? 'weekly' : (isMonthly ? 'monthly' : 'unknown');

    final payload = {
      'rc_customer_id': info.originalAppUserId,
      'rc_subscription_status': status,
      'rc_subscription_plan': plan,
      'subscription_provider': 'revenue_cat',
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

class AvailablePlans {
  const AvailablePlans({
    required this.weekly,
    required this.monthly,
  });

  final Package? weekly;
  final Package? monthly;

  bool get hasWeekly => weekly != null;
  bool get hasMonthly => monthly != null;
  bool get hasAnyPlan => hasWeekly || hasMonthly;
}

class RevenueCatSubscriptionStatus {
  const RevenueCatSubscriptionStatus({
    required this.isSubscribed,
    required this.isTrialing,
    required this.isCanceled,
    required this.isWeeklyPlan,
    required this.isMonthlyPlan,
  });

  final bool isSubscribed;
  final bool isTrialing;
  final bool isCanceled;
  final bool isWeeklyPlan;
  final bool isMonthlyPlan;

  bool get isActiveAndRenewing => isSubscribed && !isCanceled;
}