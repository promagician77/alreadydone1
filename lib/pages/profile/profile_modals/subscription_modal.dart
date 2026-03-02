import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'shared.dart';

/// Subscription modal.
void showSubscriptionModal(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => const _SubscriptionSheet(),
  );
}

class _SubscriptionSheet extends StatelessWidget {
  const _SubscriptionSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).padding.bottom + 40),
      decoration: const BoxDecoration(
        color: ModalColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Color(0x261C1917),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: ModalColors.stoneMid,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Your Subscription',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: ModalColors.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Manage your plan and billing',
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: ModalColors.inkSoft,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ModalColors.warmWhite,
                border: Border.all(color: ModalColors.stone),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Free Plan',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: ModalColors.ink,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '1 story per day',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: ModalColors.inkSoft,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: ModalColors.stone,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Current',
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: ModalColors.inkSoft,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '• Standard playback only\n• No Sleep Mode\n• Limited to 1 manifestation per day',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: ModalColors.inkSoft,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'UPGRADE TO UNLIMITED',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: ModalColors.inkMid,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ModalColors.goldPale,
                border: Border.all(color: ModalColors.gold, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    top: -8,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: ModalColors.gold,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Best Value',
                        style: GoogleFonts.outfit(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '\$9.99/month · \$69.99/year',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: ModalColors.goldDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Best value when billed annually',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: ModalColors.inkMid,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '✓ Unlimited daily stories\n✓ Sleep Mode & all speeds\n✓ Re-record voice anytime',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: ModalColors.inkMid,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: ModalColors.gold,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF1C1917).withValues(alpha: 0.06),
                                blurRadius: 3,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              'Start 7-Day Free Trial',
                              style: GoogleFonts.outfit(
                                fontSize: 14,
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
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ModalColors.surface,
                border: Border.all(color: ModalColors.stone, width: 1.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '\$7.99/week',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: ModalColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Billed weekly · Cancel anytime',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: ModalColors.inkSoft,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '✓ Unlimited daily stories\n✓ Sleep Mode & all speeds\n✓ Re-record voice anytime',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: ModalColors.inkSoft,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: ModalColors.warmWhite,
                        border: Border.all(color: ModalColors.stone, width: 1.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          'Start 7-Day Free Trial',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: ModalColors.ink,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Text(
                  'Close',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: ModalColors.inkSoft,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
