import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/shared/widgets/modal_kit.dart';
import '/widgets/pressable.dart';

/// Sleep mode colors
class _SleepColors {
  static const sleepPurple = Color(0xFF4A3B5F);
  static const sleepBlue = Color(0xFF2A3B5F);
}

/// Sleep Mode Settings modal - shown when clicking settings in sleep mode.
/// [sleepSpeedListenable] when provided, the Sleep Speed row updates immediately when speed is changed.
/// [backgroundSoundListenable] when provided, the Select Sound value updates immediately when changed.
void showSleepModeSettingsModal(
  BuildContext context, {
  required int selectedMinutes,
  required ValueChanged<int?> onTimerSelect,
  required ValueChanged<bool> onSleepModeChanged,
  required String sleepSpeedLabel,
  ValueListenable<String>? sleepSpeedListenable,
  required bool backgroundSoundEnabled,
  required ValueChanged<bool> onBackgroundSoundEnabledChanged,
  required String backgroundSoundName,
  ValueListenable<String>? backgroundSoundListenable,
  required VoidCallback onSleepSpeedTap,
  required VoidCallback onBackgroundSoundTap,
  required VoidCallback onClose,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => _SleepModeSettingsSheet(
      selectedMinutes: selectedMinutes,
      onTimerSelect: onTimerSelect,
      onSleepModeChanged: onSleepModeChanged,
      sleepSpeedLabel: sleepSpeedLabel,
      sleepSpeedListenable: sleepSpeedListenable,
      backgroundSoundEnabled: backgroundSoundEnabled,
      onBackgroundSoundEnabledChanged: onBackgroundSoundEnabledChanged,
      backgroundSoundName: backgroundSoundName,
      backgroundSoundListenable: backgroundSoundListenable,
      onSleepSpeedTap: onSleepSpeedTap,
      onBackgroundSoundTap: onBackgroundSoundTap,
      onClose: onClose,
    ),
  );
}

class _SleepModeSettingsSheet extends StatefulWidget {
  final int selectedMinutes;
  final ValueChanged<int?> onTimerSelect;
  final ValueChanged<bool> onSleepModeChanged;
  final String sleepSpeedLabel;
  final ValueListenable<String>? sleepSpeedListenable;
  final bool backgroundSoundEnabled;
  final ValueChanged<bool> onBackgroundSoundEnabledChanged;
  final String backgroundSoundName;
  final ValueListenable<String>? backgroundSoundListenable;
  final VoidCallback onSleepSpeedTap;
  final VoidCallback onBackgroundSoundTap;
  final VoidCallback onClose;

  _SleepModeSettingsSheet({
    required this.selectedMinutes,
    required this.onTimerSelect,
    required this.onSleepModeChanged,
    required this.sleepSpeedLabel,
    this.sleepSpeedListenable,
    required this.backgroundSoundEnabled,
    required this.onBackgroundSoundEnabledChanged,
    required this.backgroundSoundName,
    this.backgroundSoundListenable,
    required this.onSleepSpeedTap,
    required this.onBackgroundSoundTap,
    required this.onClose,
  });

  @override
  State<_SleepModeSettingsSheet> createState() => _SleepModeSettingsSheetState();
}

class _SleepModeSettingsSheetState extends State<_SleepModeSettingsSheet> {
  late int? _selectedTimer;
  bool _backgroundSoundEnabled = false;

  @override
  void initState() {
    super.initState();
    _selectedTimer = widget.selectedMinutes;
    _backgroundSoundEnabled = widget.backgroundSoundEnabled;
  }

  static const _options = [15, 30, 45, 60];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).padding.bottom + 30),
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
            'Sleep Mode Settings',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: ModalColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Customize your bedtime experience',
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: ModalColors.inkSoft,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Sleep Timer',
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: ModalColors.inkMid,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final m in _options) _timerBtn('$m min', m),
              _timerBtn('Loop', null),
            ],
          ),
          const SizedBox(height: 20),
          _sleepSpeedRow(),
          _backgroundSoundRow(),
          if (_backgroundSoundEnabled) _selectSoundRow(),
          _settingRow(
            icon: '🌙',
            label: 'Sleep Mode',
            trailing: Switch(
              value: true,
              onChanged: widget.onSleepModeChanged,
              activeTrackColor: _SleepColors.sleepPurple,
              activeThumbColor: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Pressable(
              onTap: widget.onClose,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
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
          ),
        ],
      ),
    );
  }

  Widget _sleepSpeedRow() {
    final listenable = widget.sleepSpeedListenable;
    if (listenable != null) {
      return ValueListenableBuilder<String>(
        valueListenable: listenable,
        builder: (context, label, _) => _settingRow(
          icon: '⚡',
          label: 'Sleep Speed',
          value: '$label →',
          onTap: widget.onSleepSpeedTap,
        ),
      );
    }
    return _settingRow(
      icon: '⚡',
      label: 'Sleep Speed',
      value: '${widget.sleepSpeedLabel} →',
      onTap: widget.onSleepSpeedTap,
    );
  }

  Widget _backgroundSoundRow() {
    return _settingRow(
      icon: '🎵',
      label: 'Background Sound',
      trailing: Switch(
        value: _backgroundSoundEnabled,
        onChanged: (value) {
          setState(() => _backgroundSoundEnabled = value);
          widget.onBackgroundSoundEnabledChanged(value);
        },
        activeTrackColor: _SleepColors.sleepPurple,
        activeThumbColor: Colors.white,
      ),
    );
  }

  Widget _selectSoundRow() {
    final listenable = widget.backgroundSoundListenable;
    if (listenable != null) {
      return ValueListenableBuilder<String>(
        valueListenable: listenable,
        builder: (context, name, _) => _settingSubRow(
          label: 'Select Sound',
          value: '$name →',
          onTap: widget.onBackgroundSoundTap,
        ),
      );
    }
    return _settingSubRow(
      label: 'Select Sound',
      value: '${widget.backgroundSoundName} →',
      onTap: widget.onBackgroundSoundTap,
    );
  }

  Widget _settingSubRow({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return Pressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            const SizedBox(width: 30),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: ModalColors.inkSoft,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: ModalColors.inkSoft,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _timerBtn(String label, int? minutes) {
    final isSelected = _selectedTimer == minutes;
    return Pressable(
      onTap: () {
        setState(() => _selectedTimer = minutes);
        widget.onTimerSelect(minutes);
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? _SleepColors.sleepPurple.withValues(alpha: 0.1) : ModalColors.surface,
          border: Border.all(
            color: isSelected ? _SleepColors.sleepPurple : ModalColors.stone,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? _SleepColors.sleepPurple : ModalColors.ink,
          ),
        ),
      ),
    );
  }

  Widget _settingRow({
    required String icon,
    required String label,
    String? value,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final child = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Text(icon, style: GoogleFonts.outfit(fontSize: 18)),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: ModalColors.ink,
            ),
          ),
          const SizedBox(width: 8),
          if (value != null)
            Expanded(
              child: Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: ModalColors.inkSoft,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                textAlign: TextAlign.end,
              ),
            ),
          if (trailing != null) ...[const Spacer(), trailing],
        ],
      ),
    );
    if (onTap != null) {
      return Pressable(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: child,
      );
    }
    return child;
  }
}
