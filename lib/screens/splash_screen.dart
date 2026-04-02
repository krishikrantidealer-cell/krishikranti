import 'package:flutter/material.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Navigate to the next screen after a 3-second delay
    Timer(const Duration(seconds: 60), () {
      // For now, let's just clear the splash from the stack
      // and go to what was previously the home screen.
      // Assuming MyHomePage is the next screen.
      Navigator.of(context).pushReplacementNamed('/home');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background with wavy shapes
          CustomPaint(painter: WavyBackgroundPainter(), child: Container()),
          // Logo in the center - cleaned up (no shadow)
          Center(
            child: Image.asset(
              'assets/images/app_logo.png',
              width: 200, // Slightly larger for better scale
              fit: BoxFit.contain,
            ),
          ),
          // Bottom text
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'by krishikranti organices',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2E7D32), // Deep green color
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class WavyBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    // Full screen linear gradient
    final bgRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final bgGradient = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Colors.white, Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
      stops: [0.0, 0.5, 1.0],
    ).createShader(bgRect);

    paint.shader = bgGradient;
    canvas.drawRect(bgRect, paint);

    // Reset paint for atmospheric waves
    paint.shader = null;

    // Top atmospheric glow
    var topPath = Path();
    topPath.addOval(
      Rect.fromLTWH(
        -size.width * 0.2,
        -size.height * 0.1,
        size.width * 1.4,
        size.height * 0.25,
      ),
    );
    paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 40);
    paint.color = const Color(0xFFF1FDF1).withOpacity(0.8);
    canvas.drawPath(topPath, paint);

    // Reset mask filter for main layers
    paint.maskFilter = null;

    // Single subtle atmospheric wave at the bottom
    var path1 = Path();
    path1.moveTo(0, size.height * 0.85);
    path1.quadraticBezierTo(
      size.width * 0.35,
      size.height * 0.80,
      size.width * 0.5,
      size.height * 0.90,
    );
    path1.quadraticBezierTo(
      size.width * 0.65,
      size.height * 1.0,
      size.width,
      size.height * 0.88,
    );
    path1.lineTo(size.width, size.height);
    path1.lineTo(0, size.height);
    path1.close();

    // Slightly more visible, blurred and minorly visible
    paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 35);
    paint.color = const Color.fromARGB(
      255,
      206,
      238,
      206,
    ).withOpacity(0.53); // Improved visibility
    canvas.drawPath(path1, paint);

    // Clear filters for safety
    paint.maskFilter = null;
    paint.shader = null;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
