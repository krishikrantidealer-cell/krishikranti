import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'dart:async';
import '../widgets/wavy_painter.dart';
import 'package:krishikranti/core/network/http_service.dart';
import 'package:krishikranti/core/constants/api_constants.dart';
import 'package:krishikranti/core/network/auth_service.dart';
import 'package:krishikranti/core/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:krishikranti/core/dynamic_translation_service.dart';
import 'package:krishikranti/core/update_service.dart';
import 'package:provider/provider.dart';
import 'package:krishikranti/core/profile_service.dart';

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

    // Navigate to the next screen based on auth status and language selection
    Timer(const Duration(seconds: 3), () async {
      if (mounted) {
        // Perform Firebase Remote Config Force/Optional Update check
        final updateType = await UpdateService.checkUpdateStatus();
        if (updateType == UpdateType.force && mounted) {
          UpdateService.showUpdateDialog(context, UpdateType.force);
          return; // Block entry to the app
        }

        final loggedIn = await AuthService.isLoggedIn();

        if (loggedIn) {
          // Proactively fetch latest user profile to verify if blocked/suspended
          try {
            final profileService = Provider.of<ProfileService>(context, listen: false);
            await profileService.fetchProfileFromServer();
          } catch (e) {
            debugPrint("Splash profile fetch error: $e");
          }

          // Check if they were force-logged out during fetch because they are blocked
          final stillLoggedIn = await AuthService.isLoggedIn();
          if (!stillLoggedIn && mounted) {
            Navigator.of(context).pushReplacementNamed('/phone-verify');
            return;
          }

          final profileDone = await AuthService.isProfileComplete();

          if (mounted) {
            if (!profileDone) {
              Navigator.of(context).pushReplacementNamed('/register').then((_) {
                if (updateType == UpdateType.optional && mounted) {
                  UpdateService.showUpdateDialog(context, UpdateType.optional);
                }
              });
            } else {
              // We go directly to dashboard. KYC is no longer mandatory at startup
              // as it can be completed via the Profile section.
              Navigator.of(context).pushReplacementNamed('/dashboard').then((_) {
                if (updateType == UpdateType.optional && mounted) {
                  UpdateService.showUpdateDialog(context, UpdateType.optional);
                }
              });
            }
          }
        } else {
          if (mounted) {
            // Always go to Login flow first. Language selection is bypassed at startup.
            Navigator.of(context).pushReplacementNamed('/phone-verify').then((_) {
              if (updateType == UpdateType.optional && mounted) {
                UpdateService.showUpdateDialog(context, UpdateType.optional);
              }
            });
          }
        }
      }
    });
  }

  void initialization() async {
    // Proactively "ping" the backend to wake up the Render server
    HttpService.get(ApiConstants.baseUrl).catchError((_) => null);

    // Sync Push Notification Token with backend once app is ready
    NotificationService.syncToken();

    // Start background sequential download of all models post-splash
    debugPrint('[Splash] Triggering post-splash background sequential download of all language models.');
    DynamicTranslationService().startBackgroundDownloadOfAllModels();

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
