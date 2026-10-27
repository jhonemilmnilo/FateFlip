import 'package:flutter/material.dart';
import '../toss_config.dart';

class TossFab extends StatefulWidget {
  final VoidCallback? onPressed;
  final bool isFlipping;

  const TossFab({
    super.key,
    required this.onPressed,
    required this.isFlipping,
  });

  @override
  State<TossFab> createState() => _TossFabState();
}

class _TossFabState extends State<TossFab> with SingleTickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: TossConfig.fabPressDuration,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: TossConfig.fabPressedScale,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails _) {
    if (!widget.isFlipping && widget.onPressed != null) {
      _scaleController.forward();
    }
  }

  void _handleTapUp(TapUpDetails _) {
    if (!widget.isFlipping && widget.onPressed != null) {
      _scaleController.reverse();
    }
  }

  void _handleTapCancel() {
    if (!widget.isFlipping && widget.onPressed != null) {
      _scaleController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEnabled = !widget.isFlipping && widget.onPressed != null;

    return Semantics(
      label: 'Toss the coin',
      button: true,
      enabled: isEnabled,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: SizedBox(
          width: TossConfig.fabSize,
          height: TossConfig.fabSize,
          child: Material(
            elevation: isEnabled ? 6.0 : 0.0,
            shape: const CircleBorder(),
            color: isEnabled
                ? theme.colorScheme.primary
                : theme.colorScheme.primary.withValues(alpha: 0.35),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: isEnabled ? widget.onPressed : null,
              onTapDown: _handleTapDown,
              onTapUp: _handleTapUp,
              onTapCancel: _handleTapCancel,
              child: Center(
                child: Text(
                  'Toss',
                  style: TextStyle(
                    color: isEnabled
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onPrimary.withValues(alpha: 0.5),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
