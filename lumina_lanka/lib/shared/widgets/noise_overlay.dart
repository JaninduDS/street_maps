import 'dart:math';
import 'package:flutter/material.dart';

class NoiseOverlay extends StatelessWidget {
  final double opacity;
  final double scale;

  const NoiseOverlay({
    super.key,
    this.opacity = 0.05,
    this.scale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: CustomPaint(
        painter: _NoisePainter(scale: scale),
        size: Size.infinite,
      ),
    );
  }
}

class _NoisePainter extends CustomPainter {
  final double scale;
  final Random _random = Random(42); // Fixed seed for static noise

  _NoisePainter({required this.scale});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // We'll draw many small rectangles to simulate pixel noise
    // A lower density is better for performance, but higher density looks better.
    // Using a step size to control density.
    
    final step = 2.0 * scale; 
    
    for (double x = 0; x < size.width; x += step) {
      for (double y = 0; y < size.height; y += step) {
        if (_random.nextDouble() > 0.5) {
          // Vary opacity slightly for more natural look
          paint.color = Colors.white.withValues(alpha: _random.nextDouble() * 0.5);
          canvas.drawRect(Rect.fromLTWH(x, y, 1.5 * scale, 1.5 * scale), paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
