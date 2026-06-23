import 'package:flutter/material.dart';
import '../../../../core/constants/colors.dart';

class AuthBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Gradient 1: Top wave
    final Paint paint1 = Paint()
      ..shader = LinearGradient(
        colors: [
          AppColors.primaryGreen.withOpacity(0.85),
          const Color(0xFF2E7D32).withOpacity(0.6),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.45));

    final Path path1 = Path();
    path1.lineTo(0, size.height * 0.35);
    path1.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.42,
      size.width * 0.5,
      size.height * 0.35,
    );
    path1.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.28,
      size.width,
      size.height * 0.38,
    );
    path1.lineTo(size.width, 0);
    path1.close();
    canvas.drawPath(path1, paint1);

    // Gradient 2: Secondary accent wave slightly behind
    final Paint paint2 = Paint()
      ..shader = LinearGradient(
        colors: [
          AppColors.primaryGreen.withOpacity(0.25),
          const Color(0xFF81C784).withOpacity(0.15),
        ],
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.5));

    final Path path2 = Path();
    path2.lineTo(0, size.height * 0.38);
    path2.quadraticBezierTo(
      size.width * 0.3,
      size.height * 0.46,
      size.width * 0.6,
      size.height * 0.38,
    );
    path2.quadraticBezierTo(
      size.width * 0.85,
      size.height * 0.32,
      size.width,
      size.height * 0.42,
    );
    path2.lineTo(size.width, 0);
    path2.close();
    canvas.drawPath(path2, paint2);

    // Bottom wave accent (optional decorative shape at the bottom)
    final Paint paintBottom = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFFE8F5E9).withOpacity(0.5),
          AppColors.primaryGreen.withOpacity(0.08),
        ],
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
      ).createShader(Rect.fromLTWH(0, size.height * 0.8, size.width, size.height * 0.2));

    final Path pathBottom = Path();
    pathBottom.moveTo(0, size.height);
    pathBottom.lineTo(0, size.height * 0.85);
    pathBottom.quadraticBezierTo(
      size.width * 0.4,
      size.height * 0.82,
      size.width * 0.7,
      size.height * 0.9,
    );
    pathBottom.quadraticBezierTo(
      size.width * 0.88,
      size.height * 0.94,
      size.width,
      size.height * 0.88,
    );
    pathBottom.lineTo(size.width, size.height);
    pathBottom.close();
    canvas.drawPath(pathBottom, paintBottom);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
