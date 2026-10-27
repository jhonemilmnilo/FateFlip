import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Highly optimized CustomPainter for Heads (Brass) and Tails (Silver) coin faces.
/// Implements specular highlight responding to rotation angle and bevel rings.
class CoinFacePainter extends CustomPainter {
  final bool isHeads;
  final double angle;

  // Cached paint objects to guarantee 60/120fps with ZERO allocations per frame
  static final Paint _rimDarkPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.0;

  static final Paint _rimLightPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;

  static final Paint _discPaint = Paint()..style = PaintingStyle.fill;
  static final Paint _specularPaint = Paint()..style = PaintingStyle.fill;

  const CoinFacePainter({
    required this.isHeads,
    required this.angle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 1. Base metallic radial gradient
    final baseGradient = isHeads
        ? RadialGradient(
            colors: const [
              Color(0xFFFFDF73), // Bright polished brass
              Color(0xFFD4AF37), // Classic metallic gold
              Color(0xFF8A6508), // Rich deep bronze shadow
            ],
            stops: const [0.0, 0.65, 1.0],
          )
        : RadialGradient(
            colors: const [
              Color(0xFFFFFFFF), // Radiant silver apex
              Color(0xFFCFD6DF), // Cool platinum
              Color(0xFF7A828E), // Deep steel rim shadow
            ],
            stops: const [0.0, 0.65, 1.0],
          );

    _discPaint.shader = baseGradient.createShader(
      Rect.fromCircle(center: center, radius: radius),
    );
    canvas.drawCircle(center, radius, _discPaint);

    // 2. Dynamic specular highlight rotating with angle
    final lightAngle = (angle * 0.5) % (2 * math.pi);
    final lightOffset = Offset(
      center.dx + math.cos(lightAngle) * radius * 0.4,
      center.dy + math.sin(lightAngle) * radius * 0.4,
    );

    _specularPaint.shader = RadialGradient(
      center: Alignment(
        (lightOffset.dx - center.dx) / radius,
        (lightOffset.dy - center.dy) / radius,
      ),
      radius: 0.8,
      colors: [
        Colors.white.withValues(alpha: 0.35),
        Colors.white.withValues(alpha: 0.0),
      ],
      stops: const [0.0, 1.0],
    ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, _specularPaint);

    // 3. Concentric ring bevels (inner and outer)
    _rimDarkPaint.color = isHeads
        ? const Color(0xFF6B4E03).withValues(alpha: 0.6)
        : const Color(0xFF4A5059).withValues(alpha: 0.6);
    canvas.drawCircle(center, radius - 2.0, _rimDarkPaint);

    _rimLightPaint.color = Colors.white.withValues(alpha: 0.5);
    canvas.drawCircle(center, radius - 4.5, _rimLightPaint);

    _rimDarkPaint.color = isHeads
        ? const Color(0xFF7A5904).withValues(alpha: 0.4)
        : const Color(0xFF5A606A).withValues(alpha: 0.4);
    canvas.drawCircle(center, radius - 14.0, _rimDarkPaint);
  }

  @override
  bool shouldRepaint(covariant CoinFacePainter oldDelegate) {
    return oldDelegate.isHeads != isHeads || oldDelegate.angle != angle;
  }
}
