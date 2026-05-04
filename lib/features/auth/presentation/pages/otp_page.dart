import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:krishikranti/core/network/auth_service.dart';
import 'package:pinput/pinput.dart';
import 'package:krishikranti/l10n/app_localizations.dart';
import 'package:krishikranti/core/network/http_service.dart';
import 'package:krishikranti/core/constants/api_constants.dart';
import 'dart:convert';
import 'package:krishikranti/core/utils/haptic_util.dart';
import 'package:krishikranti/core/utils/device_utils.dart';
import 'package:provider/provider.dart';
import 'package:krishikranti/core/profile_service.dart';

class OtpPage extends StatefulWidget {
  const OtpPage({super.key});

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final TextEditingController _pinController = TextEditingController();
  final FocusNode _pinFocusNode = FocusNode();
  int _secondsRemaining = 60; // 60 second timer (as per integration plan)
  Timer? _timer;
  bool _isLoading = false;

  void _verifyOtp(String phoneNumber) async {
    final otp = _pinController.text;
    if (otp.length != 6) {
      HapticUtil.error();
      return;
    }

    HapticUtil.medium();
    setState(() => _isLoading = true);

    try {
      final deviceId = await DeviceUtils.getUniqueId();
      final response = await HttpService.post(
        ApiConstants.verifyOtp,
        body: {'phoneNumber': phoneNumber, 'otp': otp, 'deviceId': deviceId},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['accessToken'] != null && data['refreshToken'] != null) {
          await AuthService.saveTokens(
            data['accessToken'],
            data['refreshToken'],
          );
        }
        
        final user = data['user'];
        final bool isProfileComplete = user?['isProfileComplete'] ?? false;
        final bool isKycComplete = user?['isKycComplete'] ?? false;

        await AuthService.saveUserStatus(
          isProfileComplete: isProfileComplete,
          isKycComplete: isKycComplete,
        );

        if (mounted) {
          HapticUtil.success();
          if (!isProfileComplete) {
            Navigator.of(context).pushReplacementNamed('/register');
          } else if (!isKycComplete) {
            Navigator.of(context).pushReplacementNamed('/kyc');
          } else {
            Navigator.of(context).pushReplacementNamed('/dashboard');
          }
        }
      } else {
        final data = jsonDecode(response.body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? 'Invalid OTP')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Network error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _resendOtp(String phoneNumber) async {
    HapticUtil.medium();
    setState(() => _isLoading = true);
    try {
      final response = await HttpService.post(
        ApiConstants.sendOtp,
        body: {'phoneNumber': phoneNumber},
      );
      if (response.statusCode == 200) {
        _startTimer();
        if (mounted) {
          HapticUtil.success();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('OTP Resent Successfully')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _secondsRemaining = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    _pinFocusNode.dispose();
    _timer?.cancel(); // Always cancel the timer to prevent memory leaks
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final String phoneNumber =
        ModalRoute.of(context)?.settings.arguments as String? ?? '9876543210';

    // Premium Pinput Theme (Unified globally)
    final defaultPinTheme = PinTheme(
      width: 50,
      height: 56,
      textStyle: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 22),
      decoration: BoxDecoration(
        color: const Color(
          0xFFF5F5F5,
        ), // Subtle grey background for "Flat" look
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyDecorationWith(
      border: Border.all(color: const Color(0xFF2E7D32), width: 2),
      borderRadius: BorderRadius.circular(10),
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration?.copyWith(
        color: const Color(0xFFE8F5E9),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Stack(
          children: [
            // Layer 1: Green Header Section
            ClipPath(
              clipper: HeaderClipper(),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.50,
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const SizedBox(height: 50),
                      Image.asset(
                        'assets/images/logo.png',
                        width: 100,
                        height: 100,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.welcomeToKrishidealer,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.displayLarge
                            ?.copyWith(fontSize: 30, height: 1.1),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.indiasTrustedPlatform,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Layer 2: The Floating OTP Card
            Padding(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).size.height * 0.38,
                left: 24,
                right: 24,
                bottom: 40,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      l10n.verifyYourNumber,
                      style: Theme.of(
                        context,
                      ).textTheme.headlineMedium?.copyWith(fontSize: 22),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      l10n.enterOtpSentTo(phoneNumber),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // High-End 6-Digit Pinput
                    Pinput(
                      length: 6,
                      controller: _pinController,
                      focusNode: _pinFocusNode,
                      defaultPinTheme: defaultPinTheme,
                      focusedPinTheme: focusedPinTheme,
                      submittedPinTheme: submittedPinTheme,
                      onCompleted: (pin) => _verifyOtp(phoneNumber),
                      hapticFeedbackType: HapticFeedbackType.lightImpact,
                      showCursor: true,
                    ),

                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            if (_secondsRemaining > 0) ...[
                              Text(
                                l10n.resendIn(
                                  _secondsRemaining.toString().padLeft(2, '0'),
                                ),
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: Colors.black45,
                                      fontSize: 13,
                                    ),
                              ),
                            ] else ...[
                              TextButton(
                                onPressed: _isLoading
                                    ? null
                                    : () => _resendOtp(phoneNumber),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  l10n.resendOtp,
                                  style: Theme.of(context).textTheme.labelLarge
                                      ?.copyWith(fontSize: 13),
                                ),
                              ),
                            ],
                            if (_secondsRemaining > 0)
                              const Icon(
                                Icons.refresh,
                                size: 14,
                                color: Colors.black45,
                              ),
                          ],
                        ),
                        TextButton(
                          onPressed: () {
                            HapticUtil.light();
                            Navigator.pop(context);
                          },
                          child: Text(
                            l10n.changeNumber,
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: const Color(0xFF2E7D32),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),

                    // Verify Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : () => _verifyOtp(phoneNumber),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                l10n.verify,
                                style: Theme.of(context).textTheme.labelLarge
                                    ?.copyWith(
                                      fontSize: 18,
                                      color: Colors.white,
                                    ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 80);
    path.quadraticBezierTo(
      size.width / 2,
      size.height + 80, // Deepened the arc further down
      size.width,
      size.height - 80,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
