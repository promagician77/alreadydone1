import 'package:flutter/material.dart';
import '/features/subscription/data/datasources/revenuecat_service.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'subscription_widget.dart' show SubscriptionWidget;

class SubscriptionModel extends FlutterFlowModel<SubscriptionWidget> {
  SubscriptionPlan? selectedPlan;

  /// Weekly / monthly store prices and free trials. Empty until loaded, or when the
  /// store has nothing to sell.
  AvailablePlans plans = const AvailablePlans();

  bool isPaymentLoading = false;

  /// True when rc_subscription_status is "active" or "trial".
  bool isSubscribed = false;

  /// True when user's plan is weekly (show current plan; offer monthly upgrade).
  bool isWeeklyPlan = false;

  /// True when user's plan is monthly.
  bool isMonthlyPlan = false;

  /// Legacy plan still stored as annual/yearly. No longer sold.
  bool isLegacyAnnualPlan = false;

  /// True when subscription_status is "trial".
  bool isTrialing = false;

  /// True when subscription_status is canceled (show original UI + "Upgrade the Plan" button).
  bool isCanceled = false;

  /// True after profile subscription state has been loaded. Until then, show loading placeholder
  /// for pricing/CTA to avoid flashing wrong layout (e.g. default then upgrade-to-monthly).
  bool subscriptionStateLoaded = false;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}
