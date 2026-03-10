import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '/utils/platform_utils.dart';

class RevenueCatService {
  RevenueCatService._();
  static final RevenueCatService instance = RevenueCatService._();

  static const String entitlementId = 'Already Done Pro';
  static const String _appleApiKey = 'appl_CybjOCqpxMwYbcbzbCuGoMqUjlq';

  bool _configured = false;
  String? _currentUserId;

  bool get isSupported => isIOS;
  bool get isConfigured => _configured;

  Future<void> configure({String? appUserId}) async {
    if (!isIOS) {
      debugPrint('RevenueCat: skipped (iOS only)');
      return;
    }
    if (_configured) return;
    try {
      await Purchases.setLogLevel(LogLevel.debug);

      final config = PurchasesConfiguration(_appleApiKey);
      if (appUserId != null && appUserId.trim().isNotEmpty) {
        config.appUserID = appUserId.trim();
      }
      await Purchases.configure(config);

      _currentUserId = appUserId?.trim();
      _configured = true;
      debugPrint('RevenueCat: configured with userId=$_currentUserId');
    } catch (e, st) {
      debugPrint('RevenueCat configure error: $e');
      debugPrint('$st');
    }
  }

  /// Ensure the SDK is configured and the correct user is logged in.
  /// ✅ FIX 1: Call this during app startup or login, NOT before purchase.
  /// Safe to call multiple times — only acts when needed.
  Future<void> ensureReady({required String appUserId}) async {
    if (!isIOS) return;

    // Configure if not yet done
    if (!_configured) {
      await configure(appUserId: appUserId);
      return; // configure already sets the user
    }

    // If already configured but for a different (or no) user, log in
    final trimmed = appUserId.trim();
    debugPrint(
      'RevenueCat ensureReady: current=$_currentUserId, '
      'requested=$trimmed, match=${_currentUserId == trimmed}',
    );
    if (_currentUserId != trimmed) {
      await logIn(trimmed);
    }
  }

  /// Link RevenueCat to your user id. No-op on non-iOS.
  Future<void> logIn(String appUserId) async {
    if (!isIOS) return;
    try {
      final trimmed = appUserId.trim();
      await Purchases.logIn(trimmed);
      _currentUserId = trimmed;
      debugPrint('RevenueCat: logIn success for $trimmed');
    } catch (e) {
      debugPrint('RevenueCat logIn error: $e');
    }
  }

  /// Call when user logs out. No-op on non-iOS.
  Future<void> logOut() async {
    if (!isIOS) return;
    try {
      await Purchases.logOut();
      _currentUserId = null;
      debugPrint('RevenueCat: logOut success');
    } catch (e) {
      debugPrint('RevenueCat logOut error: $e');
    }
  }

  /// Whether the user has active premium access. Returns false on non-iOS.
  Future<bool> isSubscribed() async {
    if (!isIOS) return false;
    try {
      final info = await Purchases.getCustomerInfo();
      final entitlement = info.entitlements.all[entitlementId];
      return entitlement?.isActive == true;
    } catch (e) {
      debugPrint('RevenueCat isSubscribed error: $e');
      return false;
    }
  }

  /// Subscription status for UI. Returns default (not subscribed) on non-iOS.
  Future<RevenueCatSubscriptionStatus> getSubscriptionStatus() async {
    if (!isIOS) {
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

      debugPrint(
        'RevenueCat status: active=$active, trialing=$isTrialing, '
        'canceled=$isCanceled, productId=$productId, '
        'weekly=$isWeekly, monthly=$isMonthly',
      );

      return RevenueCatSubscriptionStatus(
        isSubscribed: active,
        isTrialing: isTrialing,
        isCanceled: isCanceled,
        isWeeklyPlan: isWeekly,
        isMonthlyPlan: isMonthly,
      );
    } catch (e) {
      debugPrint('RevenueCat getSubscriptionStatus error: $e');
      return const RevenueCatSubscriptionStatus(
        isSubscribed: false,
        isTrialing: false,
        isCanceled: false,
        isWeeklyPlan: false,
        isMonthlyPlan: false,
      );
    }
  }

  /// Fetch current offerings. Returns null on non-iOS.
  Future<Offerings?> getOfferings() async {
    if (!isIOS) return null;
    try {
      final offerings = await Purchases.getOfferings();
      if (kDebugMode && offerings != null) {
        final current = offerings.current;
        if (current == null) {
          debugPrint(
            'RevenueCat: no current offering. '
            'In dashboard set one offering as "Current". '
            'Available offering ids: ${offerings.all.keys.join(", ")}',
          );
        } else {
          final packages = current.availablePackages;
          debugPrint(
            'RevenueCat: current offering="${current.identifier}", '
            'packages=${packages.map((p) => '${p.identifier}(${p.packageType})').join(", ")}',
          );
          if (packages.isEmpty) {
            debugPrint(
              'RevenueCat: no packages in current offering. '
              'Add \$rc_weekly and \$rc_monthly products to this offering '
              'and ensure App Store Connect in-app products are approved and synced.',
            );
          }
        }
      }
      return offerings;
    } catch (e) {
      debugPrint('RevenueCat getOfferings error: $e');
      return null;
    }
  }

  Future<AvailablePlans> getAvailablePlans() async {
    if (!isIOS) {
      return const AvailablePlans(weekly: null, monthly: null);
    }
    try {
      final offerings = await getOfferings();
      final packages = offerings?.current?.availablePackages ?? [];

      if (kDebugMode) {
        debugPrint(
          'RevenueCat getAvailablePlans: total packages=${packages.length}, '
          'identifiers=${packages.map((p) => p.identifier).join(", ")}',
        );
      }

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

      debugPrint(
        'RevenueCat: weekly=${weekly?.identifier ?? "NOT FOUND"}, '
        'monthly=${monthly?.identifier ?? "NOT FOUND"}',
      );

      return AvailablePlans(weekly: weekly, monthly: monthly);
    } catch (e) {
      debugPrint('RevenueCat getAvailablePlans error: $e');
      return const AvailablePlans(weekly: null, monthly: null);
    }
  }

  /// Purchase a package. Throws on non-iOS or if cancelled.
  Future<CustomerInfo?> purchasePackage(Package package) async {
    if (!isIOS) {
      throw PlatformException(
        code: 'UNSUPPORTED',
        message: 'Subscriptions are available only on the App Store (iOS).',
      );
    }
    try {
      debugPrint('RevenueCat: starting purchase for ${package.identifier}');
      final result = await Purchases.purchasePackage(package);
      debugPrint('RevenueCat: purchase success for ${package.identifier}');
      return result;
    } on PlatformException catch (e) {
      if (PurchasesErrorHelper.getErrorCode(e) ==
          PurchasesErrorCode.purchaseCancelledError) {
        debugPrint(
          'RevenueCat: purchase cancelled. '
          'code=${e.code}, message=${e.message}, details=${e.details}',
        );
        // Note: StoreKit can return userCancelled=true even when the subscription
        // sheet never appeared (e.g. after Apple ID sign-in). Callers may sync and
        // recheck entitlement when this happens (see RevenueCat/purchases-ios#4903).
        rethrow;
      }
      debugPrint(
        'RevenueCat purchasePackage error: code=${e.code}, '
        'message=${e.message}, details=${e.details}',
      );
      rethrow;
    } catch (e) {
      debugPrint('RevenueCat purchasePackage error: $e');
      rethrow;
    }
  }

  /// Restore previous purchases. No-op on non-iOS.
  Future<CustomerInfo?> restorePurchases() async {
    if (!isIOS) return null;
    try {
      final info = await Purchases.restorePurchases();
      debugPrint('RevenueCat: restore success');
      return info;
    } catch (e) {
      debugPrint('RevenueCat restorePurchases error: $e');
      rethrow;
    }
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