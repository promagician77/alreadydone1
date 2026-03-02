import 'package:flutter/material.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'subscription_widget.dart' show SubscriptionWidget;

class SubscriptionModel extends FlutterFlowModel<SubscriptionWidget> {
  /// 0 = Annual, 1 = Weekly. Null = no plan selected (first visit).
  int? selectedPlan;

  bool isPaymentLoading = false;

  /// True when user has stripe_subscription_id (already subscribed).
  bool isSubscribed = false;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}
