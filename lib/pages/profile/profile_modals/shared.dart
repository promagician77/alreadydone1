import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/widgets/pressable.dart';

/// Design tokens for modals (matches HTML).
class ModalColors {
  ModalColors._();
  static const warmWhite = Color(0xFFF9F7F4);
  static const surface = Color(0xFFFEFDFB);
  static const ink = Color(0xFF1C1917);
  static const inkMid = Color(0xFF44403C);
  static const inkSoft = Color(0xFF78716C);
  static const stone = Color(0xFFE8E2DA);
  static const stoneMid = Color(0xFFD6D0C8);
  static const gold = Color(0xFFB8861E);
  static const goldDark = Color(0xFF8B6914);
  static const goldPale = Color(0xFFFBF4E6);
}

/// Shared bottom sheet wrapper with handle, title, subtitle.
Widget buildSheetHeader({
  required String title,
  required String subtitle,
}) {
  return Column(
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
        title,
        style: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: ModalColors.ink,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        subtitle,
        style: GoogleFonts.outfit(
          fontSize: 12,
          color: ModalColors.inkSoft,
        ),
      ),
    ],
  );
}

/// Shared Cancel / Save button row.
/// When [saving] is true, both buttons are disabled and Save shows a loading indicator.
Widget buildActionButtons({
  required VoidCallback? onCancel,
  required VoidCallback? onSave,
  String saveLabel = 'Save',
  bool saving = false,
}) {
  final cancelCallback = saving ? null : onCancel;
  final saveCallback = saving ? null : onSave;
  return Row(
    children: [
      Expanded(
        child: Opacity(
          opacity: saving ? 0.6 : 1,
          child: Pressable(
            onTap: cancelCallback,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: ModalColors.warmWhite,
              border: Border.all(color: ModalColors.stone, width: 1.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                'Cancel',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: ModalColors.ink,
                ),
              ),
            ),
          ),
        ),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Opacity(
          opacity: saving ? 0.8 : 1,
          child: Pressable(
            onTap: saveCallback,
            borderRadius: BorderRadius.circular(12),
            splashColor: Colors.white.withValues(alpha: 0.3),
            highlightColor: Colors.white.withValues(alpha: 0.15),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: saving ? ModalColors.stoneMid : ModalColors.gold,
                borderRadius: BorderRadius.circular(12),
                boxShadow: saving
                    ? null
                    : [
                        BoxShadow(
                          color: const Color(0xFF1C1917).withValues(alpha: 0.06),
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
              ),
              child: Center(
                child: saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        saveLabel,
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    ],
  );
}
