import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/features/profile/presentation/pages/profile/widgets/profile_upgrade_savings_arrow.dart';
import '/features/subscription/data/datasources/revenuecat_service.dart';
import '/shared/widgets/pressable.dart';

/// Shown to weekly subscribers: upgrade to the monthly plan.
class ProfileUpgradeCard extends StatefulWidget {
  const ProfileUpgradeCard({
    super.key,
    required this.isSubscribed,
    required this.onUpgradeTap,
  });

  final bool isSubscribed;
  final VoidCallback onUpgradeTap;

  @override
  State<ProfileUpgradeCard> createState() => _ProfileUpgradeCardState();
}

class _ProfileUpgradeCardState extends State<ProfileUpgradeCard> {
  /// Store prices for the savings line. Empty until loaded.
  AvailablePlans _plans = const AvailablePlans();

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    final plans = await RevenueCatService.instance.getAvailablePlans();
    if (!mounted) return;
    setState(() => _plans = plans);
  }

  @override
  Widget build(BuildContext context) {
    final savings = _plans.monthlySavingsPercent;
    final textStyle = GoogleFonts.cormorantGaramond(
      fontSize: 20,
      fontWeight: FontWeight.w400,
      color: Colors.white,
      height: 1.2,
    );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4E5F9C), Color(0xFF2A3B5F)],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 18,
            right: 18,
            child: Text(
              '✓',
              style: GoogleFonts.outfit(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white.withValues(alpha: 0.2),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'UPGRADE TO MONTHLY PLAN',
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (savings != null)
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 0,
                      runSpacing: 4,
                      children: [
                        Text('SAVE $savings%', style: textStyle),
                        const ProfileUpgradeSavingsArrow(color: Colors.white),
                        Text('vs weekly plan', style: textStyle),
                      ],
                    ),
                  Text(
                    '${_plans.priceString(SubscriptionPlan.monthly)}/month',
                    style: textStyle,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Billed monthly · Cancel anytime',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.8),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 14),
              Pressable(
                onTap: widget.onUpgradeTap,
                borderRadius: BorderRadius.circular(10),
                splashColor: Colors.white.withValues(alpha: 0.2),
                highlightColor: Colors.white.withValues(alpha: 0.1),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      widget.isSubscribed
                          ? 'Upgrade to Monthly'
                          : 'Start Subscription',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
