import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/pages/profile/profile_modals/shared.dart';
import '/widgets/pressable.dart';

/// Sleep mode colors (from HTML design)
class _SleepColors {
  static const sleepPurple = Color(0xFF4A3B5F);
  static const sleepBlue = Color(0xFF2A3B5F);
  static const sleepDark = Color(0xFF1A1F3A);
}

/// Playback Settings modal - shown when clicking settings icon in player.
/// [sleepModeAllowed] gates sleep mode by subscription (trial/active + weekly/monthly).
/// [loopListenable] when provided, the Loop row updates immediately when the value changes.
/// [speedListenable] when provided, the Speed row updates immediately when speed is changed.
void showPlaybackSettingsModal(
  BuildContext context, {
  required bool sleepModeEnabled,
  required bool sleepModeAllowed,
  required ValueChanged<bool> onSleepModeChanged,
  required String speedLabel,
  ValueListenable<String>? speedListenable,
  required bool loopEnabled,
  ValueListenable<bool>? loopListenable,
  required VoidCallback onSpeedTap,
  required VoidCallback onLoopTap,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _PlaybackSettingsSheet(
      sleepModeEnabled: sleepModeEnabled,
      sleepModeAllowed: sleepModeAllowed,
      onSleepModeChanged: onSleepModeChanged,
      speedLabel: speedLabel,
      speedListenable: speedListenable,
      loopEnabled: loopEnabled,
      loopListenable: loopListenable,
      onSpeedTap: onSpeedTap,
      onLoopTap: onLoopTap,
    ),
  );
}

class _PlaybackSettingsSheet extends StatelessWidget {
  final bool sleepModeEnabled;
  final bool sleepModeAllowed;
  final ValueChanged<bool> onSleepModeChanged;
  final String speedLabel;
  final ValueListenable<String>? speedListenable;
  final bool loopEnabled;
  final ValueListenable<bool>? loopListenable;
  final VoidCallback onSpeedTap;
  final VoidCallback onLoopTap;

  const _PlaybackSettingsSheet({
    required this.sleepModeEnabled,
    required this.sleepModeAllowed,
    required this.onSleepModeChanged,
    required this.speedLabel,
    this.speedListenable,
    required this.loopEnabled,
    this.loopListenable,
    required this.onSpeedTap,
    required this.onLoopTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
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
            'Playback Settings',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: ModalColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Customize your listening experience',
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: ModalColors.inkSoft,
            ),
          ),
          const SizedBox(height: 20),
          if (speedListenable != null)
            ValueListenableBuilder<String>(
              valueListenable: speedListenable!,
              builder: (_, label, __) => _settingRow(
                icon: '⚡',
                label: 'Speed',
                value: '$label →',
                onTap: onSpeedTap,
              ),
            )
          else
            _settingRow(
              icon: '⚡',
              label: 'Speed',
              value: '$speedLabel →',
              onTap: onSpeedTap,
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Text('🌙', style: GoogleFonts.outfit(fontSize: 18)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sleep Mode',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: sleepModeAllowed ? ModalColors.ink : ModalColors.inkSoft,
                        ),
                      ),
                      if (!sleepModeAllowed)
                        Text(
                          'Available for subscribers',
                          style: GoogleFonts.outfit(fontSize: 11, color: ModalColors.inkSoft),
                        ),
                    ],
                  ),
                ),
                Switch(
                  value: sleepModeEnabled,
                  onChanged: sleepModeAllowed ? onSleepModeChanged : null,
                  activeTrackColor: _SleepColors.sleepPurple,
                  activeThumbColor: Colors.white,
                ),
              ],
            ),
          ),
          if (loopListenable != null)
            ValueListenableBuilder<bool>(
              valueListenable: loopListenable!,
              builder: (_, loopOn, __) => _settingRow(
                icon: '🔁',
                label: 'Loop',
                value: loopOn ? 'On →' : 'Off →',
                onTap: onLoopTap,
              ),
            )
          else
            _settingRow(
              icon: '🔁',
              label: 'Loop',
              value: loopEnabled ? 'On →' : 'Off →',
              onTap: onLoopTap,
            ),
        ],
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
          const Spacer(),
          if (value != null)
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: ModalColors.inkSoft,
              ),
            ),
          if (trailing != null) trailing,
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
