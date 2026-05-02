import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'dart:async';
import '../widgets/wavy_painter.dart';
import 'package:krishikranti/core/network/http_service.dart';
import 'package:krishikranti/core/constants/api_constants.dart';
import 'package:krishikranti/core/network/auth_service.dart';

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

    // Navigate to the next screen based on auth status
    Timer(const Duration(seconds: 3), () async {
      if (mounted) {
        final loggedIn = await AuthService.isLoggedIn();
        if (mounted) {
          if (loggedIn) {
            final profileDone = await AuthService.isProfileComplete();
            final kycDone = await AuthService.isKycComplete();

            if (mounted) {
              if (!profileDone) {
                Navigator.of(context).pushReplacementNamed('/register');
              } else if (!kycDone) {
                Navigator.of(context).pushReplacementNamed('/kyc');
              } else {
                Navigator.of(context).pushReplacementNamed('/dashboard');
              }
            }
          } else {
            Navigator.of(context).pushReplacementNamed('/language');
          }
        }
      }
    });
  }

  void initialization() async {
    // Proactively "ping" the backend to wake up the Render server
    // This happens while the user is seeing the splash animation.
    HttpService.get(ApiConstants.baseUrl).catchError((_) => null);

    // This is where you'd perform initial app setup (e.g., loading config)
    // For now, we just remove the native splash screen handoff.
    FlutterNativeSplash.remove();
  }

  @override
  Widget build(BuildContext context) {
    // Making sizes responsive using MediaQuery context
    final size = MediaQuery.of(context).size;
    final logoWidth = size.width * 0.65; // Logo is now 65% of screen width

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: Stack(
          children: [
            // Background - Pure presentation layer widget - should be full screen
            CustomPaint(painter: WavyBackgroundPainter(), child: Container()),

            SafeArea(
              minimum: const EdgeInsets.only(bottom: 10),
              child: Stack(
                children: [
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
                        'Krishikranti Organics',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2E7D32),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
