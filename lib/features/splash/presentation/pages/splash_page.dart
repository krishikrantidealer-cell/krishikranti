import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'dart:async';
import '../widgets/wavy_painter.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    // Use a post-frame callback to remove the native splash screen
    // once this widget is rendered for a 1:1 smooth transition.
    initialization();

    // Navigate to the next screen (Choose Language)
    Timer(const Duration(seconds: 3), () {
      Navigator.of(context).pushReplacementNamed('/language');
    });
  }

  void initialization() async {
    // This is where you'd perform initial app setup (e.g., loading config)
    // For now, we just remove the native splash screen handoff.
    FlutterNativeSplash.remove();
  }

  @override
  Widget build(BuildContext context) {
    // Making sizes responsive using MediaQuery context
    final size = MediaQuery.of(context).size;
    final logoWidth = size.width * 0.65; // Logo is now 65% of screen width

    return Scaffold(
      body: Stack(
        children: [
          // Background - Pure presentation layer widget
          CustomPaint(painter: WavyBackgroundPainter(), child: Container()),

          // Logo in the center - cleaned up (responsively sized)
          Center(
            child: Image.asset(
              'assets/images/app_logo.png',
              width: logoWidth > 280
                  ? 280
                  : logoWidth, // Capped at 280 for a bolder look
              fit: BoxFit.contain,
            ),
          ),

          // Bottom branding text
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'by krishikranti organices',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2E7D32),
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
