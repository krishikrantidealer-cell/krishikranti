import 'package:flutter/material.dart';

class WavyBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    // Full screen linear gradient (from core theme base colors)
    final bgRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final bgGradient = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.white,
        Color(0xFFE8F5E9),
        Color(0xFFC8E6C9),
      ],
      stops: [0.0, 0.5, 1.0],
    ).createShader(bgRect);
    
    paint.shader = bgGradient;
    canvas.drawRect(bgRect, paint);
    
    // Atmospheric top glow
    paint.shader = null;
    var topPath = Path();
    topPath.addOval(Rect.fromLTWH(-size.width * 0.2, -size.height * 0.1, size.width * 1.4, size.height * 0.25));
    paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 40);
    paint.color = const Color(0xFFF1FDF1).withOpacity(0.8);
    canvas.drawPath(topPath, paint);
    
    // Bottom Wave - single subtle atmospheric glow
    paint.maskFilter = null;
    var path1 = Path();
    path1.moveTo(0, size.height * 0.85);
    path1.quadraticBezierTo(
      size.width * 0.35, size.height * 0.80, 
      size.width * 0.5, size.height * 0.90,
    );
    path1.quadraticBezierTo(
      size.width * 0.65, size.height * 1.0, 
      size.width, size.height * 0.88,
    );
    path1.lineTo(size.width, size.height);
    path1.lineTo(0, size.height);
    path1.close();
    
    paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 35);
    paint.color = const Color.fromARGB(255, 206, 238, 206).withOpacity(0.53);
    canvas.drawPath(path1, paint);
    
    paint.maskFilter = null;
    paint.shader = null;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
