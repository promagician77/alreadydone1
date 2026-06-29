import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/shared/widgets/modal_kit.dart';
import '/shared/widgets/pressable.dart';

class _SleepColors {
  _SleepColors._();
  static const sleepPurple = Color(0xFF4A3B5F);
  static const goldPale = Color(0xFFFBF4E6);
  static const goldLight = Color(0xFFD4A574);
  static const goldDark = Color(0xFF8B6914);
}

void showSleepTimerModal(
  BuildContext context, {
  required int selectedMinutes,
  required ValueChanged<int?> onSelect,
  required VoidCallback onStartSleepMode,
  required VoidCallback onCancel,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => _SleepTimerSheet(
      selectedMinutes: selectedMinutes,
      onSelect: onSelect,
      onStartSleepMode: onStartSleepMode,
      onCancel: onCancel,
    ),
  );
}

class _SleepTimerSheet extends StatefulWidget {
  final int selectedMinutes;
  final ValueChanged<int?> onSelect;
  final VoidCallback onStartSleepMode;
  final VoidCallback onCancel;

  const _SleepTimerSheet({
    required this.selectedMinutes,
    required this.onSelect,
    required this.onStartSleepMode,
    required this.onCancel,
  });

  @override
  State<_SleepTimerSheet> createState() => _SleepTimerSheetState();
}

class _SleepTimerSheetState extends State<_SleepTimerSheet> {
  late int? _selected;
  static const _options = [15, 30, 45, 60];

  @override
  void initState() {
    super.initState();
    _selected = widget.selectedMinutes;
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final width = media.size.width;
    // Use stacked buttons on narrow screens so "Start Sleep Mode" has full width
    // and never truncates (Samsung, Xiaomi, small devices, etc.).
    final isCompactWidth = width < 400;
    final padding = media.padding;

    return Container(
      padding: EdgeInsets.fromLTRB(
        20 + padding.left,
        20,
        20 + padding.right,
        padding.bottom + 30,
      ),
      decoration: const BoxDecoration(
        color: ModalColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(color: Color(0x261C1917), blurRadius: 20, offset: Offset(0, -4)),
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
            'Set Sleep Timer',
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, color: ModalColors.ink),
          ),
          const SizedBox(height: 4),
          Text(
            'How long should your story play tonight?',
            style: GoogleFonts.outfit(fontSize: 12, color: ModalColors.inkSoft),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final m in _options) _timerBtn('$m min', m),
              _timerBtn('Loop', null),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _SleepColors.goldPale,
              border: Border.all(color: _SleepColors.goldLight),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sleep Mode will activate:',
                  style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: _SleepColors.goldDark),
                ),
                const SizedBox(height: 6),
                Text(
                  '• Slower pace (0.75x speed)\n• Theta wave background\n• Auto-loop until timer ends\n• Gradual fade to silence',
                  style: GoogleFonts.outfit(fontSize: 11, color: ModalColors.inkMid, height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          isCompactWidth
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _actionButton(
                      label: 'Start Sleep Mode',
                      primary: true,
                      onTap: widget.onStartSleepMode,
                      fontSize: 14,
                      verticalPadding: 13,
                    ),
                    const SizedBox(height: 8),
                    _actionButton(
                      label: 'Cancel',
                      primary: false,
                      onTap: widget.onCancel,
                      fontSize: 14,
                      verticalPadding: 13,
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: _actionButton(
                        label: 'Cancel',
                        primary: false,
                        onTap: widget.onCancel,
                        fontSize: 15,
                        verticalPadding: 14,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _actionButton(
                        label: 'Start Sleep Mode',
                        primary: true,
                        onTap: widget.onStartSleepMode,
                        fontSize: 15,
                        verticalPadding: 14,
                      ),
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required bool primary,
    required VoidCallback onTap,
    double fontSize = 15,
    double verticalPadding = 14,
  }) {
    final textStyle = GoogleFonts.outfit(
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
      color: primary ? Colors.white : ModalColors.ink,
    );

    final decoration = primary
        ? BoxDecoration(
            color: _SleepColors.sleepPurple,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1C1917).withValues(alpha: 0.06),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          )
        : BoxDecoration(
            color: ModalColors.warmWhite,
            border: Border.all(color: ModalColors.stone, width: 1.5),
            borderRadius: BorderRadius.circular(12),
          );

    return Pressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: verticalPadding, horizontal: 16),
        decoration: decoration,
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: textStyle,
              maxLines: 1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _timerBtn(String label, int? minutes) {
    final isSelected = _selected == minutes;
    return Pressable(
      onTap: () {
        setState(() => _selected = minutes);
        widget.onSelect(minutes);
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? _SleepColors.sleepPurple.withValues(alpha: 0.1) : ModalColors.surface,
          border: Border.all(color: isSelected ? _SleepColors.sleepPurple : ModalColors.stone, width: 1.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: isSelected ? _SleepColors.sleepPurple : ModalColors.ink),
        ),
      ),
    );
  }
}
