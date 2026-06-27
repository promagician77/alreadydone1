import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/features/profile/presentation/pages/profile/widgets/profile_upgrade_savings_arrow.dart';
import '/widgets/pressable.dart';

class ProfileUpgradeCard extends StatelessWidget {
  const ProfileUpgradeCard({
    super.key,
    required this.isSubscribed,
    required this.onUpgradeTap,
  });

  final bool isSubscribed;
  final VoidCallback onUpgradeTap;

  @override
  Widget build(BuildContext context) {
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
                'UPGRADE TO ANNUAL PLAN',
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
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 0,
                    runSpacing: 4,
                    children: [
                      Text('SAVE 44%', style: textStyle),
                      const ProfileUpgradeSavingsArrow(color: Colors.white),
                      Text('only \$8.33/month', style: textStyle),
                    ],
                  ),
                  Text('\$99.99/year', style: textStyle),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '3-day free trial · Billed annually · Cancel anytime',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.8),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 14),
              Pressable(
                onTap: onUpgradeTap,
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
                      isSubscribed ? 'Upgrade to Annual' : 'Start Free Trial',
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
