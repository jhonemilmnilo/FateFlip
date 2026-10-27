import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../toss_config.dart';
import 'coin_face_painter.dart';
import 'ground_shadow.dart';

class CoinView extends StatefulWidget {
  final double diameter;
  final String headsLabel;
  final String tailsLabel;
  final bool isFlipping;
  final double currentAngle;
  final VoidCallback onAnimationComplete;

  const CoinView({
    super.key,
    required this.diameter,
    required this.headsLabel,
    required this.tailsLabel,
    required this.isFlipping,
    required this.currentAngle,
    required this.onAnimationComplete,
  });

  @override
  State<CoinView> createState() => CoinViewState();
}

class CoinViewState extends State<CoinView> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _angleAnimation;
  late Animation<double> _translationYAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _shadowScaleAnimation;
  late Animation<double> _shadowOpacityAnimation;

  double _startAngle = 0.0;
  double _targetAngle = 0.0;
  double _wobbleXSign = 1.0;
  double _wobbleZSign = 1.0;

  bool _bounce1HapticTriggered = false;
  bool _bounce2HapticTriggered = false;

  @override
  void initState() {
    super.initState();
    _startAngle = widget.currentAngle;
    _targetAngle = widget.currentAngle;

    _controller = AnimationController(
      vsync: this,
      duration: TossConfig.flipDuration,
    );

    _controller.addListener(_handleAnimationTick);
    _controller.addStatusListener(_handleStatusChange);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reduced motion support (spec rule 7 & pitfall 13)
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    _controller.duration = disableAnimations
        ? TossConfig.reducedMotionDuration
        : TossConfig.flipDuration;

    _buildAnimations(disableAnimations: disableAnimations);
  }

  void _buildAnimations({required bool disableAnimations}) {

    // A. Flip Angle (rotateX) with realistic rotational inertia:
    // explosive launch spin that naturally decelerates smoothly as it lands
    _angleAnimation = Tween<double>(
      begin: _startAngle,
      end: _targetAngle,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Cubic(0.20, 0.70, 0.25, 1.0),
    ));

    if (disableAnimations) {
      // Simplified flat animation for reduced-motion accessibility
      _translationYAnimation = const AlwaysStoppedAnimation(0.0);
      _scaleAnimation = const AlwaysStoppedAnimation(1.0);
      _shadowScaleAnimation = const AlwaysStoppedAnimation(1.0);
      _shadowOpacityAnimation = const AlwaysStoppedAnimation(0.8);
      return;
    }

    // B. Toss Arc (translateY) with crisp, weighted physics:
    // Launch (44) -> Fall (38) -> First bounce impact & recovery (10) -> Micro-damped settle (8)
    _translationYAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: TossConfig.tossApexHeight)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 44,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: TossConfig.tossApexHeight, end: 0.0)
            .chain(CurveTween(curve: Curves.easeInQuad)),
        weight: 38,
      ),
      // Sharp metallic bounce 1
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: TossConfig.bounce1Height)
            .chain(CurveTween(curve: Curves.easeOutQuad)),
        weight: 5,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: TossConfig.bounce1Height, end: 0.0)
            .chain(CurveTween(curve: Curves.easeInQuad)),
        weight: 5,
      ),
      // Crisp micro-bounce 2
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: TossConfig.bounce2Height)
            .chain(CurveTween(curve: Curves.easeOutQuad)),
        weight: 3,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: TossConfig.bounce2Height, end: 0.0)
            .chain(CurveTween(curve: Curves.easeInQuad)),
        weight: 3,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(0.0),
        weight: 2,
      ),
    ]).animate(_controller);

    // Coin Scale: 1.0 -> 1.3 at apex -> 1.0
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: TossConfig.maxScaleApex)
            .chain(CurveTween(curve: Curves.easeOutQuad)),
        weight: 45,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: TossConfig.maxScaleApex, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInQuad)),
        weight: 37,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: 18,
      ),
    ]).animate(_controller);

    // Ground Shadow Scale: 1.0 -> 0.45 at apex -> 1.0
    _shadowScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: TossConfig.shadowMinScale)
            .chain(CurveTween(curve: Curves.easeOutQuad)),
        weight: 45,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: TossConfig.shadowMinScale, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInQuad)),
        weight: 37,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: 18,
      ),
    ]).animate(_controller);

    // Ground Shadow Opacity: 0.8 -> 0.4 at apex -> 0.8
    _shadowOpacityAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.8, end: TossConfig.shadowMinOpacity)
            .chain(CurveTween(curve: Curves.easeOutQuad)),
        weight: 45,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: TossConfig.shadowMinOpacity, end: 0.8)
            .chain(CurveTween(curve: Curves.easeInQuad)),
        weight: 37,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(0.8),
        weight: 18,
      ),
    ]).animate(_controller);
  }

  void startFlip({
    required double targetAngle,
    required int spins,
    Duration? duration,
  }) {
    _startAngle = widget.currentAngle;
    _targetAngle = targetAngle;

    // Seed wobble direction per toss
    _wobbleXSign = (spins % 2 == 0) ? 1.0 : -1.0;
    _wobbleZSign = (spins % 3 == 0) ? 1.0 : -1.0;
    _bounce1HapticTriggered = false;
    _bounce2HapticTriggered = false;

    final disableAnimations = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    _controller.duration = disableAnimations
        ? TossConfig.reducedMotionDuration
        : (duration ?? TossConfig.flipDuration);

    _buildAnimations(disableAnimations: disableAnimations);

    // Launch Haptics (spec 7.D)
    HapticFeedback.mediumImpact();

    _controller.forward(from: 0.0);
  }

  void _handleAnimationTick() {
    // Light impact haptic on bounces (at roughly t=0.82 and t=0.90)
    final progress = _controller.value;
    if (progress >= 0.82 && !_bounce1HapticTriggered) {
      _bounce1HapticTriggered = true;
      HapticFeedback.lightImpact();
    } else if (progress >= 0.90 && !_bounce2HapticTriggered) {
      _bounce2HapticTriggered = true;
      HapticFeedback.lightImpact();
    }
  }

  void _handleStatusChange(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      HapticFeedback.selectionClick();
      widget.onAnimationComplete();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final diameter = widget.diameter;

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final angle = _angleAnimation.value;
          final translateY = _translationYAnimation.value;
          final scale = _scaleAnimation.value;
          final shadowScale = _shadowScaleAnimation.value;
          final shadowOpacity = _shadowOpacityAnimation.value;

          // Flight wobble (sine curve active during airborne 0..0.82)
          final inFlightProgress = (_controller.value / 0.82).clamp(0.0, 1.0);
          final wobbleFactor = math.sin(inFlightProgress * math.pi);
          final wobbleX = TossConfig.flightWobbleX * wobbleFactor * _wobbleXSign;
          final wobbleZ = TossConfig.flightWobbleZ * wobbleFactor * _wobbleZSign;

          return SizedBox(
            width: diameter,
            height: diameter + 40,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // Ground Shadow
                Positioned(
                  bottom: -15,
                  child: GroundShadow(
                    diameter: diameter,
                    scale: shadowScale,
                    opacity: shadowOpacity,
                  ),
                ),

                // 3D Coin Body with Perspective & Translation
                Positioned(
                  top: 0,
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, TossConfig.perspective) // Perspective FIRST (rule 2)
                      ..translateByDouble(wobbleX, translateY, 0.0, 1.0)
                      ..rotateZ(wobbleZ)
                      ..rotateX(angle) // rotateX flip (rule 7.A)
                      ..scaleByDouble(scale, scale, 1.0, 1.0),
                    child: SizedBox(
                      width: diameter,
                      height: diameter,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // 3D Thickness: Stacked discs along Z axis (spec 6)
                          for (int i = -TossConfig.thicknessLayers ~/ 2;
                              i <= TossConfig.thicknessLayers ~/ 2;
                              i++)
                            Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.identity()
                                ..translateByDouble(
                                  0.0,
                                  0.0,
                                  i * (TossConfig.coinThickness / TossConfig.thicknessLayers),
                                  1.0,
                                ),
                              child: Container(
                                width: diameter - 1,
                                height: diameter - 1,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFF5A4418), // Deep coin rim edge
                                ),
                              ),
                            ),

                          // Coin Face Switching via cos(angle)
                          // cos(angle) >= 0 shows front (Heads), otherwise back (Tails)
                          // Back face is pre-rotated by PI around X so text is never upside down (spec 7.A & pitfall 1)
                          if (math.cos(angle) >= 0)
                            _buildCoinFace(
                              isHeads: true,
                              label: widget.headsLabel,
                              angle: angle,
                              diameter: diameter,
                            )
                          else
                            Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.identity()..rotateX(math.pi),
                              child: _buildCoinFace(
                                isHeads: false,
                                label: widget.tailsLabel,
                                angle: angle,
                                diameter: diameter,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCoinFace({
    required bool isHeads,
    required String label,
    required double angle,
    required double diameter,
  }) {
    final textColor = isHeads ? const Color(0xFF422800) : const Color(0xFF23272E);
    final embossColor = isHeads
        ? Colors.white.withValues(alpha: 0.6)
        : Colors.white.withValues(alpha: 0.8);

    return SizedBox(
      width: diameter,
      height: diameter,
      child: CustomPaint(
        painter: CoinFacePainter(
          isHeads: isHeads,
          angle: angle,
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28.0),
            child: SizedBox(
              width: diameter - 56.0,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: diameter - 56.0,
                  ),
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    softWrap: true,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: TossConfig.coinTextMaxFontSize,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                      height: 1.15,
                      letterSpacing: 0.3,
                      shadows: [
                        Shadow(
                          offset: const Offset(0.0, 1.0),
                          blurRadius: 1.0,
                          color: embossColor,
                        ),
                      ],
                    ),
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
