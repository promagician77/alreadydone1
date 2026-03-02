import 'package:flutter/material.dart';

/// A tappable widget that provides Material splash/highlight feedback on press.
/// Use instead of GestureDetector when you want visible tap feedback (ripple effect).
class Pressable extends StatelessWidget {
  const Pressable({
    super.key,
    required this.onTap,
    required this.child,
    this.borderRadius,
    this.splashColor,
    this.highlightColor,
    this.backgroundColor,
  });

  final VoidCallback? onTap;
  final Widget child;
  final BorderRadius? borderRadius;
  final Color? splashColor;
  final Color? highlightColor;
  /// Background color for Material. Use for solid buttons so ripple shows on top.
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor ?? Colors.transparent,
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius ?? BorderRadius.zero,
        splashColor: splashColor ?? Colors.black.withValues(alpha: 0.12),
        highlightColor: highlightColor ?? Colors.black.withValues(alpha: 0.06),
        focusColor: Colors.transparent,
        hoverColor: Colors.transparent,
        child: child,
      ),
    );
  }
}
