import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class RevenueCatService {
  RevenueCatService._();
  static final RevenueCatService instance = RevenueCatService._();

  /// Entitlement identifier configured in RevenueCat dashboard (e.g. "premium").
  static const String entitlementId = 'premium';

  static const String _appleApiKey = 'appl_CybjOCqpxMwYbcbzbCuGoMqUjlq';

  bool _configured = false;

  /// Call once at app startup (e.g. from main.dart after Supabase auth is ready).
  /// Pass [appUserId] to link purchases to your user (e.g. Supabase user id); optional.
  Future<void> configure({String? appUserId}) async {
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

  /// Call after user logs in to link RevenueCat to your user id.
  Future<void> logIn(String appUserId) async {
    try {
      await Purchases.logIn(appUserId.trim());
    } catch (e) {
      debugPrint('RevenueCat logIn error: $e');
    }
  }

  /// Call when user logs out so RevenueCat uses anonymous id.
  Future<void> logOut() async {
    try {
      await Purchases.logOut();
    } catch (e) {
      debugPrint('RevenueCat logOut error: $e');
    }
  }

  /// Whether the user has active premium access (no backend/database needed).
  Future<bool> isSubscribed() async {
    try {
      final info = await Purchases.getCustomerInfo();
      final entitlement = info.entitlements.all[entitlementId];
      return entitlement?.isActive == true;
    } catch (e) {
      debugPrint('RevenueCat isSubscribed error: $e');
      return false;
    }
  }

  /// Subscription status for UI that expects a map (e.g. plan, isCanceled).
  /// All from RevenueCat — no backend call.
  Future<RevenueCatSubscriptionStatus> getSubscriptionStatus() async {
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

  /// Fetch current offerings (packages). Use default offering or a specific placement.
  Future<Offerings?> getOfferings() async {
    try {
      return await Purchases.getOfferings();
    } catch (e) {
      debugPrint('RevenueCat getOfferings error: $e');
      return null;
    }
  }

  /// Purchase a package (e.g. monthly or annual). Returns updated customer info on success.
  Future<CustomerInfo?> purchasePackage(Package package) async {
    try {
      final result = await Purchases.purchasePackage(package);
      return result;
    } on PlatformException catch (e) {
      if (PurchasesErrorHelper.getErrorCode(e) == PurchasesErrorCode.purchaseCancelledError) {
        rethrow; // Caller can treat as user cancelled
      }
      debugPrint('RevenueCat purchasePackage error: $e');
      rethrow;
    } catch (e) {
      debugPrint('RevenueCat purchasePackage error: $e');
      rethrow;
    }
  }

  /// Restore previous purchases.
  Future<CustomerInfo?> restorePurchases() async {
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
