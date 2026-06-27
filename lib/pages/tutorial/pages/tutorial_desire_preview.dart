import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/shared/theme/auth_theme.dart';
import '../widgets/tutorial_preview_primitives.dart';

enum TutorialDesirePreviewHighlight { categories, describe, button }

class TutorialDesirePreview extends StatelessWidget {
  const TutorialDesirePreview({super.key, required this.highlight});

  final TutorialDesirePreviewHighlight highlight;

  static const _categories = [
    ('❤️', 'Love'),
    ('💰', 'Money/Lifestyle'),
    ('💼', 'Career/Business'),
    ('🌟', 'Health'),
    ('🏠', 'Home'),
    ('✨', 'Personal Growth'),
  ];

  Widget _maybeHighlight({
    required bool active,
    required Widget child,
  }) {
    if (!active) return child;
    return TutorialHighlightedBox(child: child);
  }

  @override
  Widget build(BuildContext context) {
    final categoryGrid = GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 2.35,
      children: List.generate(_categories.length, (i) {
        final (icon, label) = _categories[i];
        final selected = i == 0;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AuthTheme.goldPale : AuthTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AuthTheme.gold : AuthTheme.stone,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(icon, style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AuthTheme.ink,
                  height: 1.15,
                ),
              ),
            ],
          ),
        );
      }),
    );

    final describeSection = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Describe What\'s Already Yours',
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AuthTheme.ink,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '(Write Your Desired Manifestation Here)',
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AuthTheme.inkSoft,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          constraints: const BoxConstraints(minHeight: 188),
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AuthTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AuthTheme.stone),
          ),
          child: Text(
            'Write it like it already happened. Be specific. Be emotional.\n\nExample: The deeply loving relationship where I felt completely seen, valued, and cherished every single day',
            style: AuthTheme.placeholderStyle.copyWith(fontSize: 14, height: 1.4),
          ),
        ),
      ],
    );

    final buttonBar = Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AuthTheme.surface,
        border: Border(
          top: BorderSide(color: AuthTheme.stone.withValues(alpha: 0.6)),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: const TutorialPulsingButton(label: 'Create My Story'),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: List.generate(4, (i) {
            return Expanded(
              child: Container(
                height: 3,
                margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                decoration: BoxDecoration(
                  color: i < 2 ? AuthTheme.gold : AuthTheme.stone,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 12),
        Text(
          "What's already done\nfor you?",
          style: AuthTheme.welcomeTitleStyle.copyWith(fontSize: 20),
        ),
        const SizedBox(height: 4),
        Text('Choose a category', style: AuthTheme.welcomeSubStyle),
        const SizedBox(height: 12),
        _maybeHighlight(
          active: highlight == TutorialDesirePreviewHighlight.categories,
          child: categoryGrid,
        ),
        const SizedBox(height: 12),
        _maybeHighlight(
          active: highlight == TutorialDesirePreviewHighlight.describe,
          child: describeSection,
        ),
        const SizedBox(height: 12),
        _maybeHighlight(
          active: highlight == TutorialDesirePreviewHighlight.button,
          child: buttonBar,
        ),
      ],
    );
  }
}
