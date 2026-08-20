import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:krishikranti/l10n/app_localizations.dart';
import 'package:krishikranti/core/network/http_service.dart';
import 'package:krishikranti/core/constants/api_constants.dart';
import 'package:krishikranti/core/utils/haptic_util.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:krishikranti/core/profile_service.dart';
import 'package:krishikranti/core/network/auth_service.dart';
import 'package:krishikranti/core/utils/device_utils.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:krishikranti/core/websocket_service.dart';

class PhoneVerifyPage extends StatefulWidget {
  const PhoneVerifyPage({super.key});

  @override
  State<PhoneVerifyPage> createState() => _PhoneVerifyPageState();
}

class _PhoneVerifyPageState extends State<PhoneVerifyPage> {
  final TextEditingController _phoneController = TextEditingController();
  bool _agreedToTerms = false;
  bool _isLoading = false;

  void _sendOtp() async {
    final l10n = AppLocalizations.of(context)!;
    final phoneNumber = _phoneController.text.trim();

    // 1. Validation: Phone length
    if (phoneNumber.length != 10) {
      HapticUtil.error();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.phoneNumberHint),
        ), // Or a more specific error
      );
      return;
    }

    // 2. Validation: Terms checkbox
    if (!_agreedToTerms) {
      HapticUtil.error();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please agree to the Terms & Conditions')),
      );
      return;
    }

    HapticUtil.medium();
    setState(() => _isLoading = true);

    try {
      final response = await HttpService.post(
        ApiConstants.sendOtp,
        body: {'phoneNumber': phoneNumber},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final cooldown = data['cooldown'] ?? 60;
        if (mounted) {
          HapticUtil.success();
          Navigator.pushNamed(
            context,
            '/otp',
            arguments: {'phoneNumber': phoneNumber, 'cooldown': cooldown},
          );
        }
      } else {
        final data = jsonDecode(response.body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? 'Failed to send OTP')),
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

  void loginAsGuest() async {
    HapticUtil.medium();
    setState(() => _isLoading = true);

    try {
      final sendResponse = await HttpService.post(
        ApiConstants.sendOtp,
        body: {'phoneNumber': '9999999999'},
      );

      if (sendResponse.statusCode == 200) {
        final deviceId = await DeviceUtils.getUniqueId();
        final verifyResponse = await HttpService.post(
          ApiConstants.verifyOtp,
          body: {
            'phoneNumber': '9999999999',
            'otp': '123456',
            'deviceId': deviceId
          },
        );

        if (verifyResponse.statusCode == 200) {
          final data = jsonDecode(verifyResponse.body);
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
            Provider.of<ProfileService>(context, listen: false).setGuest(true);
            // Connect WS even for guest (so order status updates still work)
            WebSocketService.instance.connect();
            HapticUtil.success();
            Navigator.of(context).pushReplacementNamed('/dashboard');
          }
        } else {
          final data = jsonDecode(verifyResponse.body);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(data['message'] ?? 'Guest login failed')),
            );
          }
        }
      } else {
        final data = jsonDecode(sendResponse.body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? 'Failed to initialize guest session')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Network error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Stack(
          children: [
            // Layer 1: Green Header Section (With Lesser Semi-Circle)
            ClipPath(
              clipper: HeaderClipper(),
              child: Container(
                height:
                    MediaQuery.of(context).size.height *
                    0.52, // Stretched further down
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
                        width: 120,
                        height: 120,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.welcomeToKrishidealer,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.displayLarge
                            ?.copyWith(fontSize: 32, height: 1.1),
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

            // Floating Back Button
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 16,
              child: GestureDetector(
                onTap: () async {
                  HapticUtil.light();
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('selected_user_type');
                  if (!context.mounted) return;
                  Navigator.of(context)
                      .pushReplacementNamed('/choose-user-type');
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.8),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.6),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 20,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),

            // Layer 2: The Floating Input Card (Overlapping the lesser arc)
            Padding(
              padding: EdgeInsets.only(
                top:
                    MediaQuery.of(context).size.height * 0.48 -
                    50, // Recalibrated overlap
                left: 24,
                right: 24,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ), // More compact padding
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: 0.08,
                      ), // Slightly softer shadow for compact look
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.mobileNumber,
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(fontSize: 17),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 10,
                          ), // Tighter code box
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Text(
                                '🇮🇳',
                                style: TextStyle(fontSize: 16),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '+91',
                                style: Theme.of(
                                  context,
                                ).textTheme.titleLarge?.copyWith(fontSize: 15),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8), // Tighter gap
                        Expanded(
                          child: TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            maxLength: 10,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            style: Theme.of(
                              context,
                            ).textTheme.titleLarge?.copyWith(fontSize: 16),
                            decoration: InputDecoration(
                              hintText: l10n.phoneNumberHint,
                              counterText: "", // Hide the character counter
                              prefixIcon: const Icon(
                                Icons.phone_outlined,
                                color: Colors.grey,
                                size: 18,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 10,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    Row(
                      children: [
                        SizedBox(
                          height: 24,
                          width: 24,
                          child: Checkbox(
                            value: _agreedToTerms,
                            onChanged: (val) {
                              HapticUtil.light();
                              setState(() => _agreedToTerms = val ?? false);
                            },
                            activeColor: const Color(0xFF2E7D32),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.copyWith(fontSize: 13),
                              children: [
                                TextSpan(text: l10n.agreeTo),
                                TextSpan(
                                  text: l10n.termsPrivacyPolicy,
                                  style: Theme.of(context).textTheme.labelLarge
                                      ?.copyWith(
                                        fontSize: 13,
                                        color: const Color(0xFF2E7D32),
                                        decoration: TextDecoration.underline,
                                        fontWeight: FontWeight.bold,
                                      ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () async {
                                      final url = Uri.parse('https://krishikrantiorganics.com/privacy-policy');
                                      if (await canLaunchUrl(url)) {
                                        await launchUrl(url, mode: LaunchMode.externalApplication);
                                      }
                                    },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _sendOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          elevation: 4,
                          shadowColor: const Color(
                            0xFF2E7D32,
                          ).withValues(alpha: 0.4),
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
                                l10n.sendOtp,
                                style: Theme.of(context).textTheme.labelLarge
                                    ?.copyWith(
                                      fontSize: 18,
                                      color: Colors.white,
                                    ),
                              ),
                      ),
                    ),
                    // const SizedBox(height: 16),
                    // SizedBox(
                    //   width: double.infinity,
                    //   height: 54,
                    //   child: OutlinedButton(
                    //     onPressed: _isLoading ? null : _loginAsGuest,
                    //     style: OutlinedButton.styleFrom(
                    //       foregroundColor: const Color(0xFF2E7D32),
                    //       side: const BorderSide(color: Color(0xFF2E7D32), width: 1.5),
                    //       shape: RoundedRectangleBorder(
                    //         borderRadius: BorderRadius.circular(18),
                    //       ),
                    //     ),
                    //     child: Text(
                    //       "Browse as Guest",
                    //       style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    //         fontSize: 18,
                    //         color: const Color(0xFF2E7D32),
                    //         fontWeight: FontWeight.bold,
                    //       ),
                    //     ),
                    //   ),
                    // ),
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
    path.lineTo(0, size.height - 40); // Shorter dip start
    path.quadraticBezierTo(
      size.width / 2,
      size.height + 30, // Flatter, lesser curve
      size.width,
      size.height - 40,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
