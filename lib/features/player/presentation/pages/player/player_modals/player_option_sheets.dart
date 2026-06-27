import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/features/player/presentation/pages/player/player_colors.dart';
import '/features/player/presentation/pages/player/player_constants.dart';
import '/features/player/presentation/pages/player/player_story_utils.dart';
import '/widgets/pressable.dart';

/// Bottom sheets for speed, loop, and theta background selection.
abstract final class PlayerOptionSheets {
  static Future<double?> showSpeedSheet(
    BuildContext context, {
    required double currentRate,
    required String title,
    required String subtitle,
    bool sleepStyle = false,
  }) {
    return showModalBottomSheet<double>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SpeedSheet(
        currentRate: currentRate,
        title: title,
        subtitle: subtitle,
        sleepStyle: sleepStyle,
      ),
    );
  }

  static Future<bool?> showLoopSheet(
    BuildContext context, {
    required bool currentEnabled,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _LoopSheet(currentEnabled: currentEnabled),
    );
  }

  static Future<int?> showThetaBackgroundSheet(
    BuildContext context, {
    required int currentIndex,
  }) {
    return showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ThetaBackgroundSheet(currentIndex: currentIndex),
    );
  }
}

class _SheetShell extends StatelessWidget {
  const _SheetShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).padding.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: PlayerColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Color(0x261C1917),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 36,
        height: 4,
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: PlayerColors.stoneMid,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _SpeedSheet extends StatelessWidget {
  const _SpeedSheet({
    required this.currentRate,
    required this.title,
    required this.subtitle,
    required this.sleepStyle,
  });

  final double currentRate;
  final String title;
  final String subtitle;
  final bool sleepStyle;

  @override
  Widget build(BuildContext context) {
    return _SheetShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SheetHandle(),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: PlayerColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: PlayerColors.inkSoft,
            ),
          ),
          const SizedBox(height: 16),
          Column(
            children: PlayerConstants.speedOptions.map((v) {
              final isSelected = v == currentRate;
              final label = sleepStyle
                  ? '${PlayerStoryUtils.formatSleepSpeed(v)}x'
                  : (v == 1.0
                      ? 'Normal (1.0x)'
                      : '${PlayerStoryUtils.formatSleepSpeed(v)}x');
              return Pressable(
                onTap: () => Navigator.of(context).pop(v),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? PlayerColors.goldPale
                        : PlayerColors.warmWhite,
                    border: Border.all(
                      color: isSelected
                          ? PlayerColors.gold
                          : PlayerColors.stone,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Text(
                        label,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: PlayerColors.ink,
                        ),
                      ),
                      const Spacer(),
                      if (isSelected)
                        const Icon(
                          Icons.check,
                          size: 18,
                          color: PlayerColors.gold,
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _LoopSheet extends StatelessWidget {
  const _LoopSheet({required this.currentEnabled});

  final bool currentEnabled;

  @override
  Widget build(BuildContext context) {
    return _SheetShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SheetHandle(),
          Text(
            'Loop',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: PlayerColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Repeat the story when it ends (common and sleep mode).',
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: PlayerColors.inkSoft,
            ),
          ),
          const SizedBox(height: 16),
          ...[false, true].map((value) {
            final isOn = value;
            final isSelected = currentEnabled == value;
            return Pressable(
              onTap: () => Navigator.of(context).pop(value),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? PlayerColors.goldPale
                      : PlayerColors.warmWhite,
                  border: Border.all(
                    color: isSelected ? PlayerColors.gold : PlayerColors.stone,
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Text(
                      isOn ? 'On' : 'Off',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: PlayerColors.ink,
                      ),
                    ),
                    const Spacer(),
                    if (isSelected)
                      const Icon(
                        Icons.check,
                        size: 18,
                        color: PlayerColors.gold,
                      ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _ThetaBackgroundSheet extends StatelessWidget {
  const _ThetaBackgroundSheet({required this.currentIndex});

  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return _SheetShell(
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SheetHandle(),
              Text(
                'Background Sound',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: PlayerColors.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Choose a theta wave track for Sleep Mode.',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: PlayerColors.inkSoft,
                ),
              ),
              const SizedBox(height: 16),
              ...List.generate(PlayerConstants.thetaTracks.length, (index) {
                final track = PlayerConstants.thetaTracks[index];
                final isSelected = index == currentIndex;
                return Pressable(
                  onTap: () => Navigator.of(context).pop(index),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? PlayerColors.goldPale
                          : PlayerColors.warmWhite,
                      border: Border.all(
                        color: isSelected
                            ? PlayerColors.gold
                            : PlayerColors.stone,
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Text(
                          '🎵',
                          style: GoogleFonts.outfit(fontSize: 16),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            track.$1,
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: PlayerColors.ink,
                            ),
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.check,
                            size: 18,
                            color: PlayerColors.gold,
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
