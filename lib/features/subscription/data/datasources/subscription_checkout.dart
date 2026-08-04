import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '/core/di/subscription_locator.dart';
import '/features/subscription/data/datasources/revenuecat_service.dart';
import '/shared/services/supabase_service.dart';

enum SubscriptionCheckoutResult {
  success,
  cancelled,
  failed,
  unsupported,
  notSignedIn,
  packageNotFound,
}

/// Shared purchase + backend sync used by onboarding paywall and upsell modal.
class SubscriptionCheckout {
  SubscriptionCheckout._();

  static Package? findPackage(Offerings? offerings, {required bool wantAnnual}) {
    final packages = offerings?.current?.availablePackages ?? [];
    for (final p in packages) {
      final id = p.identifier.toLowerCase();
      final isMonthly =
          id.contains('monthly') || id.contains('month') || id.contains(r'$rc_monthly');
      final isAnnual = id.contains('annual') ||
          id.contains('yearly') ||
          id.contains('year') ||
          id.contains(r'$rc_annual');
      if (wantAnnual && isAnnual) return p;
      if (!wantAnnual && isMonthly) return p;
    }
    if (packages.length == 1) return packages.first;
    return null;
  }

  static Future<void> _syncBackend(int userId, CustomerInfo info) async {
    final payload =
        RevenueCatService.instance.getSubscriptionPayloadForBackend(info);
    await subscriptionRepository.updateUserRevenueCatSubscription(
      userId,
      rcCustomerId: payload['rc_customer_id']!,
      rcSubscriptionStatus: payload['rc_subscription_status']!,
      rcSubscriptionPlan: payload['rc_subscription_plan']!,
      subscriptionProvider: payload['subscription_provider']!,
    );
  }

  /// Purchases monthly (`wantAnnual: false`) or annual/trial (`wantAnnual: true`).
  static Future<SubscriptionCheckoutResult> purchase({
    required bool wantAnnual,
    required String logScope,
  }) async {
    RevenueCatService.logFlow(
      logScope,
      'purchase: start wantAnnual=$wantAnnual',
    );

    if (!RevenueCatService.instance.isSupported) {
      RevenueCatService.logFlow(logScope, 'purchase: not supported');
      return SubscriptionCheckoutResult.unsupported;
    }

    final userId = await SupabaseService.getCurrentUserTableId();
    if (userId == null) {
      RevenueCatService.logFlow(logScope, 'purchase: userId null');
      return SubscriptionCheckoutResult.notSignedIn;
    }

    try {
      await RevenueCatService.instance.ensureReady(appUserId: userId.toString());
      final offerings = await RevenueCatService.instance.getOfferings();
      final package = findPackage(offerings, wantAnnual: wantAnnual);
      if (package == null) {
        RevenueCatService.logFlow(
          logScope,
          'purchase: package NOT FOUND wantAnnual=$wantAnnual',
        );
        return SubscriptionCheckoutResult.packageNotFound;
      }

      RevenueCatService.logFlow(
        logScope,
        'purchase: buying ${package.identifier}',
      );
      final info = await RevenueCatService.instance.purchasePackage(package);

      if (info != null) {
        try {
          await _syncBackend(userId, info);
        } catch (e, st) {
          RevenueCatService.logFlow(logScope, 'purchase: backend sync FAILED: $e');
          debugPrint('$st');
        }
      }

      RevenueCatService.logFlow(logScope, 'purchase: success');
      return SubscriptionCheckoutResult.success;
    } on PlatformException catch (e) {
      if (PurchasesErrorHelper.getErrorCode(e) ==
          PurchasesErrorCode.purchaseCancelledError) {
        RevenueCatService.logFlow(
          logScope,
          'purchase: USER CANCELLED — running sync workaround',
        );
        try {
          await RevenueCatService.instance.syncPurchases();
          for (final waitSeconds in [2, 3, 5]) {
            await Future<void>.delayed(Duration(seconds: waitSeconds));
            final info = await RevenueCatService.instance.getCustomerInfo();
            if (info == null) continue;
            final status =
                RevenueCatService.instance.getSubscriptionPayloadForBackend(info);
            if (status['rc_subscription_status'] == 'canceled') continue;
            try {
              await _syncBackend(userId, info);
            } catch (e, st) {
              RevenueCatService.logFlow(
                logScope,
                'purchase: cancel workaround backend sync FAILED: $e',
              );
              debugPrint('$st');
            }
            RevenueCatService.logFlow(
              logScope,
              'purchase: cancel workaround recovered active subscription',
            );
            return SubscriptionCheckoutResult.success;
          }
        } catch (e, st) {
          RevenueCatService.logFlow(logScope, 'purchase: cancel workaround $e');
          debugPrint('$st');
        }
        return SubscriptionCheckoutResult.cancelled;
      }
      RevenueCatService.logFlow(
        logScope,
        'purchase: PlatformException code=${e.code} message=${e.message}',
      );
      return SubscriptionCheckoutResult.failed;
    } catch (e, st) {
      RevenueCatService.logFlow(logScope, 'purchase: unexpected $e');
      debugPrint('$st');
      return SubscriptionCheckoutResult.failed;
    }
  }
}
