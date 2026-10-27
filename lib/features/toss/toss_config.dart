import 'dart:math' as math;

/// Single Source of Truth for all magic numbers, physics, animations, and dimensions.
/// Tunable without touching widget or logic code.
class TossConfig {
  const TossConfig._();

  // Animation durations
  static const Duration flipDuration = Duration(milliseconds: 1700);
  static const Duration reducedMotionDuration = Duration(milliseconds: 500);
  static const Duration resultFadeDuration = Duration(milliseconds: 220);
  static const Duration fabPressDuration = Duration(milliseconds: 120);

  // Debounce for persistence
  static const Duration prefsDebounce = Duration(milliseconds: 300);

  // Storage keys
  static const String prefsHeadsKey = 'toss_heads_label';
  static const String prefsTailsKey = 'toss_tails_label';

  // Default labels (empty by default, users can freely input or rely on fallbacks)
  static const String defaultHeadsLabel = '';
  static const String defaultTailsLabel = '';
  static const String fallbackHeadsLabel = 'Heads';
  static const String fallbackTailsLabel = 'Tails';
  static const int maxLabelLength = 40;

  // 3D Perspective & Rotation
  static const double perspective = 0.0012;
  static const int minSpins = 5;
  static const int maxSpins = 8;
  static const double flightWobbleX = 6.0; // +/- px
  static const double flightWobbleZ = 0.08; // +/- rad

  // Stage & Coin Dimensions
  static const double coinWidthFactor = 0.55;
  static const double maxCoinDiameter = 240.0;
  static const double coinThickness = 8.0; // Thickness fake disc spacing
  static const int thicknessLayers = 8;

  // Arc Tweens (TranslateY px) - high dramatic launch apex
  static const double tossApexHeight = -380.0;
  static const double bounce1Height = -22.0;
  static const double bounce2Height = -6.0;
  static const double maxScaleApex = 1.3;

  // Ground Shadow
  static const double shadowMinScale = 0.45;
  static const double shadowMinOpacity = 0.4;
  static const double shadowBlurSigma = 14.0;

  // Floating Action Button
  static const double fabSize = 76.0;
  static const double fabMargin = 20.0;
  static const double fabPressedScale = 0.92;
  static const double scrollBottomPadding = 100.0;

  // Typographic scale
  static const double labelFontSize = 13.0;
  static const double inputFontSize = 16.0;
  static const double resultFontSize = 22.0;
  static const double coinTextMaxFontSize = 44.0;
  static const double resultSlideOffset = 8.0;

  // Helper calculation for target angle
  static double calculateTargetAngle({
    required double currentAngle,
    required bool isHeads,
    required int spins,
  }) {
    final floorMultiple = (currentAngle / (2 * math.pi)).floor() * (2 * math.pi);
    var target = floorMultiple + (spins * 2 * math.pi) + (isHeads ? 0.0 : math.pi);
    if (target <= currentAngle) {
      target += 2 * math.pi;
    }
    return target;
  }
}
