import 'package:flutter/material.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'subscription_widget.dart' show SubscriptionWidget;

class SubscriptionModel extends FlutterFlowModel<SubscriptionWidget> {
  int? selectedPlan;

  bool isPaymentLoading = false;

  /// True when user has stripe_subscription_id (already subscribed).
  bool isSubscribed = false;

  /// True when user's plan is monthly (show current plan; offer annual upgrade).
  bool isMonthlyPlan = false;

  /// True when user's plan is annual/yearly.
  bool isAnnualPlan = false;

  /// Legacy RevenueCat / backend plan still stored as weekly.
  bool isLegacyWeeklyPlan = false;

  /// True when subscription_status is "trial" (show cancel payment button if monthly).
  bool isTrialing = false;

  /// True when subscription_status is canceled (show original UI + "Upgrade the Plan" button).
  bool isCanceled = false;

  /// True after profile subscription state has been loaded. Until then, show loading placeholder
  /// for pricing/CTA to avoid flashing wrong layout (e.g. default then upgrade-to-annual).
  bool subscriptionStateLoaded = false;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}
