import 'package:flutter/material.dart';

import '/features/player/presentation/pages/player/player_colors.dart';
import '/widgets/pressable.dart';

class PlayerControls extends StatelessWidget {
  const PlayerControls({
    super.key,
    required this.sleepModeActive,
    required this.isPlaying,
    required this.hasUrl,
    required this.canSkipStory,
    required this.onTogglePlayPause,
    required this.onSkipBackward,
    required this.onSkipForward,
    required this.onSkipToPreviousStory,
    required this.onSkipToNextStory,
  });

  final bool sleepModeActive;
  final bool isPlaying;
  final bool hasUrl;
  final bool canSkipStory;
  final VoidCallback? onTogglePlayPause;
  final VoidCallback? onSkipBackward;
  final VoidCallback? onSkipForward;
  final VoidCallback? onSkipToPreviousStory;
  final VoidCallback? onSkipToNextStory;

  static const _iconPrev = Icons.skip_previous_rounded;
  static const _iconRewind = Icons.fast_rewind_rounded;
  static const _iconPlay = Icons.play_arrow_rounded;
  static const _iconPause = Icons.pause_rounded;
  static const _iconForward = Icons.fast_forward_rounded;
  static const _iconNext = Icons.skip_next_rounded;

  @override
  Widget build(BuildContext context) {
    final controlsOpacity = sleepModeActive ? 0.85 : 1.0;
    final media = MediaQuery.of(context);
    final width = media.size.width;
    final isVeryNarrow = width < 340;
    final isNarrow = width < 360;
    final isCompact = width < 400;
    final primarySize = isVeryNarrow
        ? 44.0
        : (isNarrow ? 50.0 : (isCompact ? 56.0 : 64.0));
    final secondarySize = isVeryNarrow
        ? 32.0
        : (isNarrow ? 36.0 : (isCompact ? 40.0 : 48.0));
    final spacing = isVeryNarrow ? 6.0 : (isNarrow ? 8.0 : (isCompact ? 12.0 : 20.0));
    final sleepSpacing = isVeryNarrow ? 14.0 : (isNarrow ? 18.0 : 32.0);
    final maxRowWidth = isVeryNarrow
        ? (width - 24) * 0.92
        : (isNarrow ? (width - 28) * 0.95 : (width - 32).toDouble());

    final row = sleepModeActive
        ? Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              _ControlButton(
                icon: _iconPrev,
                primary: false,
                onTap: canSkipStory ? onSkipToPreviousStory : (hasUrl ? onSkipBackward : null),
                size: secondarySize,
                sleepModeActive: sleepModeActive,
              ),
              SizedBox(width: sleepSpacing),
              _ControlButton(
                icon: isPlaying ? _iconPause : _iconPlay,
                primary: true,
                onTap: hasUrl ? onTogglePlayPause : null,
                size: primarySize,
                sleepModeActive: sleepModeActive,
              ),
              SizedBox(width: sleepSpacing),
              _ControlButton(
                icon: _iconNext,
                primary: false,
                onTap: canSkipStory ? onSkipToNextStory : (hasUrl ? onSkipForward : null),
                size: secondarySize,
                sleepModeActive: sleepModeActive,
              ),
            ],
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              _ControlButton(
                icon: _iconPrev,
                primary: false,
                onTap: canSkipStory ? onSkipToPreviousStory : (hasUrl ? onSkipBackward : null),
                size: secondarySize,
                sleepModeActive: sleepModeActive,
              ),
              SizedBox(width: spacing),
              _ControlButton(
                icon: _iconRewind,
                primary: false,
                onTap: hasUrl ? onSkipBackward : null,
                size: secondarySize,
                sleepModeActive: sleepModeActive,
              ),
              SizedBox(width: spacing),
              _ControlButton(
                icon: isPlaying ? _iconPause : _iconPlay,
                primary: true,
                onTap: hasUrl ? onTogglePlayPause : null,
                size: primarySize,
                sleepModeActive: sleepModeActive,
              ),
              SizedBox(width: spacing),
              _ControlButton(
                icon: _iconForward,
                primary: false,
                onTap: hasUrl ? onSkipForward : null,
                size: secondarySize,
                sleepModeActive: sleepModeActive,
              ),
              SizedBox(width: spacing),
              _ControlButton(
                icon: _iconNext,
                primary: false,
                onTap: canSkipStory ? onSkipToNextStory : (hasUrl ? onSkipForward : null),
                size: secondarySize,
                sleepModeActive: sleepModeActive,
              ),
            ],
          );

    return Opacity(
      opacity: controlsOpacity,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxRowWidth),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: row,
          ),
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.primary,
    required this.onTap,
    required this.size,
    required this.sleepModeActive,
  });

  final IconData icon;
  final bool primary;
  final VoidCallback? onTap;
  final double size;
  final bool sleepModeActive;

  @override
  Widget build(BuildContext context) {
    final btnSize = size;
    final iconSize = primary
        ? (btnSize * 0.5).clamp(18.0, 32.0)
        : (btnSize * 0.5).clamp(14.0, 24.0);
    final primaryColor =
        sleepModeActive ? PlayerColors.sleepPurple : PlayerColors.gold;
    final secondaryColor = sleepModeActive
        ? Colors.white.withValues(alpha: 0.5)
        : PlayerColors.inkMid;
    final color = primary ? Colors.white : secondaryColor;
    final grayRectColor = sleepModeActive
        ? Colors.white.withValues(alpha: 0.18)
        : PlayerColors.stoneMid;

    return Pressable(
      onTap: onTap,
      borderRadius: primary
          ? BorderRadius.circular(btnSize / 2)
          : BorderRadius.circular(btnSize / 4),
      splashColor:
          (primary ? Colors.white : primaryColor).withValues(alpha: 0.2),
      highlightColor:
          (primary ? Colors.white : primaryColor).withValues(alpha: 0.1),
      child: Container(
        width: btnSize,
        height: btnSize,
        decoration: BoxDecoration(
          color: primary ? primaryColor : grayRectColor,
          shape: primary ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: primary ? null : BorderRadius.circular(btnSize / 4),
          boxShadow: primary
              ? [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.4),
                    blurRadius: sleepModeActive ? 16 : 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: iconSize, color: color),
      ),
    );
  }
}
