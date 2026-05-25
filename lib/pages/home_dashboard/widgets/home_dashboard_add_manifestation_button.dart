import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/pages/home_dashboard/home_dashboard_colors.dart';
import '/widgets/pressable.dart';

class HomeDashboardAddManifestationButton extends StatelessWidget {
  const HomeDashboardAddManifestationButton({
    super.key,
    required this.buttonKey,
    required this.onTap,
    required this.showCoachmark,
    required this.pulseController,
  });

  final GlobalKey buttonKey;
  final VoidCallback onTap;
  final bool showCoachmark;
  final AnimationController pulseController;

  @override
  Widget build(BuildContext context) {
    final button = Pressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: HomeDashboardColors.gold,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add, color: HomeDashboardColors.surface, size: 18),
            const SizedBox(width: 8),
            Text(
              'Add New Manifestation',
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: HomeDashboardColors.surface,
              ),
            ),
          ],
        ),
      ),
    );

    return KeyedSubtree(
      key: buttonKey,
      child: AnimatedBuilder(
        animation: pulseController,
        builder: (context, child) {
          if (!showCoachmark) return child!;
          final t = (math.sin(pulseController.value * math.pi * 2) + 1) / 2;
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.65 + 0.25 * t),
                  blurRadius: 30 + 18 * t,
                  spreadRadius: 1 + 2 * t,
                ),
                BoxShadow(
                  color: HomeDashboardColors.gold.withValues(alpha: 0.35 + 0.2 * t),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: child,
          );
        },
        child: button,
      ),
    );
  }
}
