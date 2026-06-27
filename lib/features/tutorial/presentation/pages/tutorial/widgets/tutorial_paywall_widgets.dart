import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/shared/theme/auth_theme.dart';

class TutorialPlanCard extends StatelessWidget {
  const TutorialPlanCard({
    super.key,
    required this.title,
    required this.price,
    required this.period,
    this.selected = false,
    this.note,
  });

  final String title;
  final String price;
  final String period;
  final bool selected;
  final String? note;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFE3F0E0) : AuthTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected ? const Color(0xFF5A8A4A) : AuthTheme.stone,
          width: selected ? 1.6 : 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AuthTheme.ink,
                  ),
                ),
                const SizedBox(height: 2),
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AuthTheme.ink,
                    ),
                    children: [
                      TextSpan(text: price),
                      TextSpan(
                        text: ' $period',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AuthTheme.inkSoft,
                        ),
                      ),
                    ],
                  ),
                ),
                if (note != null) ...[
                  const SizedBox(height: 7),
                  Text(
                    note!,
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF5A8A4A),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? const Color(0xFF5A8A4A) : AuthTheme.stoneMid,
                width: 1.5,
              ),
            ),
            child: selected
                ? Center(
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF5A8A4A),
                      ),
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
  }
}
