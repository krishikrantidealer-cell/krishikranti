import 'package:flutter/material.dart';
import 'package:krishikranti/l10n/app_localizations.dart';

class PhoneVerifyPage extends StatefulWidget {
  const PhoneVerifyPage({super.key});

  @override
  State<PhoneVerifyPage> createState() => _PhoneVerifyPageState();
}

class _PhoneVerifyPageState extends State<PhoneVerifyPage> {
  final TextEditingController _phoneController = TextEditingController();
  bool _agreedToTerms = false;

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
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 32, height: 1.1),
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
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 17),
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
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 15),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8), // Tighter gap
                        Expanded(
                          child: TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16),
                            decoration: InputDecoration(
                              hintText: l10n.phoneNumberHint,
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
                            onChanged: (val) =>
                                setState(() => _agreedToTerms = val ?? false),
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
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontSize: 13,
                                  ),
                              children: [
                                TextSpan(text: l10n.agreeTo),
                                TextSpan(
                                  text: l10n.termsPrivacyPolicy,
                                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                        fontSize: 13,
                                        decoration: TextDecoration.underline,
                                      ),
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
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            '/otp',
                            arguments: _phoneController.text,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          elevation: 4,
                          shadowColor: const Color(0xFF2E7D32).withValues(alpha: 0.4),
                        ),
                        child: Text(
                          l10n.sendOtp,
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 18, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 50),
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
