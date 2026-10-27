import 'package:flutter/material.dart';
import '../toss_config.dart';

class GroundShadow extends StatelessWidget {
  final double scale;
  final double opacity;
  final double diameter;

  const GroundShadow({
    super.key,
    required this.scale,
    required this.opacity,
    required this.diameter,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(diameter, diameter * 0.35),
      painter: _GroundShadowPainter(
        scale: scale,
        opacity: opacity,
      ),
    );
  }
}

class _GroundShadowPainter extends CustomPainter {
  final double scale;
  final double opacity;

  // Cached paint and mask filter
  static final Paint _shadowPaint = Paint()
    ..style = PaintingStyle.fill
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, TossConfig.shadowBlurSigma);

  const _GroundShadowPainter({
    required this.scale,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0.001) return;

    final center = Offset(size.width / 2, size.height / 2);
    final width = (size.width * 0.7) * scale;
    final height = (size.height * 0.4) * scale;

    _shadowPaint.color = Colors.black.withValues(alpha: opacity.clamp(0.0, 1.0));

    final rect = Rect.fromCenter(
      center: center,
      width: width,
      height: height,
    );

    canvas.drawOval(rect, _shadowPaint);
  }

  @override
  bool shouldRepaint(covariant _GroundShadowPainter oldDelegate) {
    return oldDelegate.scale != scale || oldDelegate.opacity != opacity;
  }
}
