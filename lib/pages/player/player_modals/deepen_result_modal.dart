import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/pages/profile/profile_modals/shared.dart';

/// Shows the deepened story result: theme as title and story content in a scrollable body.
void showDeepenResultModal(
  BuildContext context, {
  required String theme,
  required String story,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(ctx).size.height * 0.85,
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(ctx).padding.bottom + 24,
      ),
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
            theme,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: ModalColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Deepened story',
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: ModalColors.inkSoft,
            ),
          ),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.5,
            ),
            child: SingleChildScrollView(
              child: Text(
                story,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: ModalColors.inkMid,
                  height: 1.6,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: GestureDetector(
              onTap: () => Navigator.of(ctx).pop(),
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
