import 'package:flutter/material.dart';

/// A tappable widget that provides Material splash/highlight feedback and
/// optional scale animation on press so the user can see the click.
/// Use instead of GestureDetector when you want visible tap feedback.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.onTap,
    required this.child,
    this.borderRadius,
    this.splashColor,
    this.highlightColor,
    this.backgroundColor,
    this.enableScaleAnimation = true,
    this.scaleDownTo = 0.97,
  });

  final VoidCallback? onTap;
  final Widget child;
  final BorderRadius? borderRadius;
  final Color? splashColor;
  final Color? highlightColor;
  /// Background color for Material. Use for solid buttons so ripple shows on top.
  final Color? backgroundColor;
  /// When true, briefly scales down on press so the tap is visually obvious.
  final bool enableScaleAnimation;
  final double scaleDownTo;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 80),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.scaleDownTo).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent _) {
    if (widget.onTap != null && widget.enableScaleAnimation) {
      _scaleController.forward();
    }
  }

  void _onPointerUp(PointerUpEvent _) {
    if (widget.enableScaleAnimation) {
      _scaleController.reverse();
    }
  }

  void _onPointerCancel(PointerCancelEvent _) {
    if (widget.enableScaleAnimation) {
      _scaleController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = Material(
      color: widget.backgroundColor ?? Colors.transparent,
      borderRadius: widget.borderRadius ?? BorderRadius.zero,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: widget.borderRadius ?? BorderRadius.zero,
        splashColor: widget.splashColor ?? Colors.black.withValues(alpha: 0.12),
        highlightColor: widget.highlightColor ?? Colors.black.withValues(alpha: 0.06),
        focusColor: Colors.transparent,
        hoverColor: Colors.transparent,
        child: widget.child,
      ),
    );
    if (widget.enableScaleAnimation) {
      content = Listener(
        onPointerDown: _onPointerDown,
        onPointerUp: _onPointerUp,
        onPointerCancel: _onPointerCancel,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) => Transform.scale(
            scale: _scaleAnimation.value,
            alignment: Alignment.center,
            child: child,
          ),
          child: content,
        ),
      );
    }
    return content;
  }
}
