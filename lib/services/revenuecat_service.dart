import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '/utils/platform_utils.dart';

class RevenueCatService {
  RevenueCatService._();
  static final RevenueCatService instance = RevenueCatService._();

  /// Entitlement identifier configured in RevenueCat dashboard (e.g. "premium").
  static const String entitlementId = 'premium';

  static const String _appleApiKey = 'appl_CybjOCqpxMwYbcbzbCuGoMqUjlq';

  bool _configured = false;

  /// Subscriptions are supported only on iOS (App Store). Android/web get false/null.
  bool get isSupported => isIOS;

  /// Call once at app startup (e.g. from main.dart). Only configures on iOS.
  Future<void> configure({String? appUserId}) async {
    if (!isIOS) {
      debugPrint('RevenueCat: skipped (iOS only)');
      return;
    }
    if (_configured) return;
    try {
      await Purchases.setLogLevel(LogLevel.debug);
      await Purchases.configure(PurchasesConfiguration(_appleApiKey));
      if (appUserId != null && appUserId.trim().isNotEmpty) {
        await Purchases.logIn(appUserId.trim());
      }
      _configured = true;
      debugPrint('RevenueCat: configured');
    } catch (e, st) {
      debugPrint('RevenueCat configure error: $e');
      debugPrint('$st');
    }
  }

  /// Call after user logs in to link RevenueCat to your user id. No-op on non-iOS.
  Future<void> logIn(String appUserId) async {
    if (!isIOS) return;
    try {
      await Purchases.logIn(appUserId.trim());
    } catch (e) {
      debugPrint('RevenueCat logIn error: $e');
    }
  }

  /// Call when user logs out. No-op on non-iOS.
  Future<void> logOut() async {
    if (!isIOS) return;
    try {
      await Purchases.logOut();
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
        isAnnualPlan: false,
        isMonthlyPlan: false,
      );
    }
    try {
      final info = await Purchases.getCustomerInfo();
      final entitlement = info.entitlements.all[entitlementId];
      final active = entitlement?.isActive == true;
      final periodType = entitlement?.periodType == PeriodType.trial
          ? 'trialing'
          : (entitlement?.periodType == PeriodType.normal ? 'active' : '');
      final productId = entitlement?.productIdentifier ?? '';
      final isAnnual = productId.toLowerCase().contains('annual') ||
          productId.toLowerCase().contains('yearly') ||
          productId.contains('\$rc_annual');
      final isMonthly = productId.toLowerCase().contains('monthly') ||
          productId.toLowerCase().contains('weekly') ||
          productId.contains('\$rc_monthly') ||
          productId.contains('\$rc_weekly');
      return RevenueCatSubscriptionStatus(
        isSubscribed: active,
        isTrialing: periodType == 'trialing',
        isCanceled: entitlement?.unsubscribeDetectedAt != null,
        isAnnualPlan: isAnnual && !isMonthly,
        isMonthlyPlan: isMonthly,
      );
    } catch (e) {
      debugPrint('RevenueCat getSubscriptionStatus error: $e');
      return const RevenueCatSubscriptionStatus(
        isSubscribed: false,
        isTrialing: false,
        isCanceled: false,
        isAnnualPlan: false,
        isMonthlyPlan: false,
      );
    }
  }

  /// Fetch current offerings. Returns null on non-iOS (so UI can show iOS-only message).
  /// In debug, logs what RevenueCat returned so you can fix "plan not available" (check
  /// dashboard: set a Current offering and add packages whose identifiers contain "weekly" or "monthly").
  Future<Offerings?> getOfferings() async {
    if (!isIOS) return null;
    try {
      final offerings = await Purchases.getOfferings();
      if (kDebugMode && offerings != null) {
        final current = offerings.current;
        if (current == null) {
          debugPrint(
            'RevenueCat: no current offering. In dashboard set one offering as "Current". '
            'Available offering ids: ${offerings.all.keys.join(", ")}',
          );
        } else {
          final packages = current.availablePackages;
          debugPrint(
            'RevenueCat: current offering="${current.identifier}", '
            'packages=${packages.map((p) => p.identifier).join(", ")}',
          );
          if (packages.isEmpty) {
            debugPrint(
              'RevenueCat: no packages in current offering. Add products to this offering '
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

  /// Purchase a package. No-op / throws on non-iOS (call only when isSupported).
  Future<CustomerInfo?> purchasePackage(Package package) async {
    if (!isIOS) {
      throw PlatformException(
        code: 'UNSUPPORTED',
        message: 'Subscriptions are available only on the App Store (iOS).',
      );
    }
    try {
      final result = await Purchases.purchasePackage(package);
      return result;
    } on PlatformException catch (e) {
      if (PurchasesErrorHelper.getErrorCode(e) == PurchasesErrorCode.purchaseCancelledError) {
        rethrow;
      }
      debugPrint('RevenueCat purchasePackage error: $e');
      rethrow;
    } catch (e) {
      debugPrint('RevenueCat purchasePackage error: $e');
      rethrow;
    }
  }

  /// Restore previous purchases. No-op on non-iOS.
  Future<CustomerInfo?> restorePurchases() async {
    if (!isIOS) {
      return null;
    }
    try {
      return await Purchases.restorePurchases();
    } catch (e) {
      debugPrint('RevenueCat restorePurchases error: $e');
      rethrow;
    }
  }
}

/// Status derived from RevenueCat CustomerInfo (no backend).
class RevenueCatSubscriptionStatus {
  const RevenueCatSubscriptionStatus({
    required this.isSubscribed,
    required this.isTrialing,
    required this.isCanceled,
    required this.isAnnualPlan,
    required this.isMonthlyPlan,
  });

  final bool isSubscribed;
  final bool isTrialing;
  final bool isCanceled;
  final bool isAnnualPlan;
  final bool isMonthlyPlan;
}
