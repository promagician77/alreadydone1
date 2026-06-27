/// Profile display and parsing helpers.
abstract final class ProfileUtils {
  static bool parseBool(dynamic value, bool defaultValue) {
    if (value == null) return defaultValue;
    if (value is bool) return value;
    final s = value.toString().toLowerCase();
    if (s == 'true' || s == '1') return true;
    if (s == 'false' || s == '0') return false;
    return defaultValue;
  }

  static String formatSpeed(dynamic speed) {
    if (speed == null) return 'Normal (1.0x)';
    final s = speed.toString().toLowerCase();
    if (s == 'slow') return 'Slow (0.85x)';
    if (s == 'normal') return 'Normal (1.0x)';
    if (s == 'fast') return 'Fast (1.15x)';
    if (s == 'very_fast') return 'Very Fast (1.35x)';
    return 'Normal (1.0x)';
  }

  static String getSpeedValue(dynamic speed) {
    if (speed == null) return 'normal';
    final s = speed.toString().toLowerCase();
    if (s == 'slow' || s == 'normal' || s == 'fast' || s == 'very_fast') {
      return s;
    }
    return 'normal';
  }
}

/// Subscription fields derived from profile API data.
class ProfileSubscriptionInfo {
  const ProfileSubscriptionInfo({
    required this.isSubscribedFromRC,
    required this.showUpgradeCardFromRC,
    required this.subscriptionRowLabel,
  });

  final bool isSubscribedFromRC;
  final bool showUpgradeCardFromRC;
  final String subscriptionRowLabel;
}

abstract final class ProfileSubscriptionUtils {
  static ProfileSubscriptionInfo fromProfile(Map<String, dynamic> data) {
    final rcStatus = (data['rc_subscription_status'] ??
            data['rc_subscription_Status'])
        ?.toString()
        .trim()
        .toLowerCase();
    final rcPlan = (data['rc_subscription_plan'] ??
            data['rc_subscription_Plan'])
        ?.toString()
        .trim()
        .toLowerCase();
    final isWeeklyPlan =
        rcPlan != null && rcPlan.isNotEmpty && rcPlan.contains('week');
    final isMonthlyPlan = rcPlan != null &&
        rcPlan.isNotEmpty &&
        rcPlan.contains('month') &&
        !rcPlan.contains('week');
    final isAnnualPlan = rcPlan != null &&
        rcPlan.isNotEmpty &&
        (rcPlan.contains('annual') ||
            rcPlan.contains('yearly') ||
            (rcPlan.contains('year') && !rcPlan.contains('week')));
    final isCanceled = rcStatus == 'canceled' || rcStatus == 'cancelled';
    final isSubscribedFromRC = rcStatus == 'active' || rcStatus == 'trial';
    final onLowerTierPlan = isWeeklyPlan || isMonthlyPlan;
    final showUpgradeCardFromRC =
        isSubscribedFromRC && !isCanceled && onLowerTierPlan && !isAnnualPlan;

    String subscriptionRowLabel;
    if (!isSubscribedFromRC || isCanceled) {
      subscriptionRowLabel = 'Free';
    } else if (rcStatus == 'trial') {
      subscriptionRowLabel = 'Trial';
    } else if (isMonthlyPlan) {
      subscriptionRowLabel = 'Monthly';
    } else if (isWeeklyPlan) {
      subscriptionRowLabel = 'Weekly';
    } else if (isAnnualPlan) {
      subscriptionRowLabel = 'Annual';
    } else {
      subscriptionRowLabel = 'Active';
    }

    return ProfileSubscriptionInfo(
      isSubscribedFromRC: isSubscribedFromRC,
      showUpgradeCardFromRC: showUpgradeCardFromRC,
      subscriptionRowLabel: subscriptionRowLabel,
    );
  }
}
