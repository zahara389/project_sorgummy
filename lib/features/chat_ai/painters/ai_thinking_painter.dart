// lib/features/chat_ai/painters/ai_thinking_painter.dart
// CustomPainter untuk animasi AI sedang berpikir.
// Menampilkan 3 partikel bergerak + gelombang sinusoid.

import 'dart:math' as math;
import 'package:flutter/material.dart';

class AIThinkingPainter extends CustomPainter {
  final double animationValue; // 0.0 → 1.0, repeating
  final Color primaryColor;
  final Color secondaryColor;

  AIThinkingPainter({
    required this.animationValue,
    this.primaryColor = const Color(0xFF65B713),
    this.secondaryColor = const Color(0xFFABE14B),
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawWave(canvas, size);
    _drawParticles(canvas, size);
  }

  void _drawWave(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = primaryColor.withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final path = Path();
    const waveCount = 2;
    final waveHeight = size.height * 0.25;
    final offset = animationValue * size.width;

    for (var wave = 0; wave < waveCount; wave++) {
      final opacity = 0.3 - wave * 0.1;
      paint.color = primaryColor.withOpacity(opacity.clamp(0.05, 0.4));
      path.reset();
      final startX = -size.width + offset + wave * 20;
      path.moveTo(startX, size.height / 2);
      for (double x = startX; x < startX + size.width * 2; x += 2) {
        final y = size.height / 2 +
            waveHeight * math.sin((x / size.width) * math.pi * 4 + animationValue * math.pi * 2);
        if (x == startX) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, paint);
    }
  }

  void _drawParticles(Canvas canvas, Size size) {
    const particleCount = 3;
    for (int i = 0; i < particleCount; i++) {
      final phase = (animationValue + i / particleCount) % 1.0;
      final x = size.width * (i + 0.5) / particleCount;
      final y = size.height / 2 +
          math.sin(phase * math.pi * 2) * size.height * 0.2;
      final radius = 4.0 + 2.0 * math.sin(phase * math.pi * 2).abs();
      final opacity = 0.5 + 0.5 * math.sin(phase * math.pi * 2 + i).abs();

      final paint = Paint()
        ..color = (i % 2 == 0 ? primaryColor : secondaryColor).withOpacity(opacity.clamp(0.3, 1.0))
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), radius, paint);

      // Glow ring
      final glowPaint = Paint()
        ..color = primaryColor.withOpacity(opacity * 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(Offset(x, y), radius + 3, glowPaint);
    }
  }

  @override
  bool shouldRepaint(AIThinkingPainter oldDelegate) =>
      oldDelegate.animationValue != animationValue;
}
