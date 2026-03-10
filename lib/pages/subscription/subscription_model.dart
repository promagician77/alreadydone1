import 'package:flutter/material.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'subscription_widget.dart' show SubscriptionWidget;

class SubscriptionModel extends FlutterFlowModel<SubscriptionWidget> {
  int? selectedPlan;

  bool isPaymentLoading = false;

  /// True when user has stripe_subscription_id (already subscribed).
  bool isSubscribed = false;

  /// True when user's plan is monthly (show current plan; hide upgrade CTA when not canceled).
  bool isMonthlyPlan = false;

  /// True when subscription_status is trialing (show cancel payment button if monthly).
  bool isTrialing = false;

  /// True when subscription_status is canceled (show original UI + "Upgrade the Plan" button).
  bool isCanceled = false;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}
