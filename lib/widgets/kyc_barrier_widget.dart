import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:krishikranti/core/profile_service.dart';

class KycBarrierWidget extends StatefulWidget {
  final Widget child;

  const KycBarrierWidget({
    super.key,
    required this.child,
  });

  @override
  State<KycBarrierWidget> createState() => _KycBarrierWidgetState();
}

class _KycBarrierWidgetState extends State<KycBarrierWidget> {
  @override
  void initState() {
    super.initState();
    // Refresh profile status on load to see if KYC has been verified/rejected
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProfileService>(context, listen: false).fetchProfileFromServer();
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileService = Provider.of<ProfileService>(context);
    final user = profileService.user;

    // If loading and we don't have user data yet, show a loader
    if (profileService.isLoading && user == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF2E7D32),
          ),
        ),
      );
    }

    // If user's KYC is complete, show the child directly
    if (user != null && user.isKycComplete) {
      return widget.child;
    }

    // Determine the KYC status card to display
    final String status = user?.kycStatus ?? 'pending';
    final bool hasSubmitted = user != null && user.licenceImage != null && user.licenceImage!.isNotEmpty;

    Widget barrierOverlay;

    if (!hasSubmitted) {
      // 1. Not Submitted
      barrierOverlay = _buildStatusCard(
        context,
        icon: Icons.lock_outline_rounded,
        iconColor: const Color(0xFFD32F2F),
        title: "KYC Verification Required",
        description: "To view products, see prices/discounts, or place orders, please complete your shop KYC verification.",
        buttonText: "Verify KYC Now",
        onButtonPressed: () {
          Navigator.pushNamed(context, '/kyc');
        },
      );
    } else if (status == 'rejected') {
      // 2. Rejected
      barrierOverlay = _buildStatusCard(
        context,
        icon: Icons.error_outline_rounded,
        iconColor: const Color(0xFFD32F2F),
        title: "KYC Verification Rejected",
        description: "Your KYC was rejected. Please re-upload valid documents to verify your dealer status.",
        buttonText: "Re-upload KYC Documents",
        onButtonPressed: () {
          Navigator.pushNamed(context, '/kyc');
        },
      );
    } else {
      // 3. Pending/Submitted
      barrierOverlay = _buildStatusCard(
        context,
        icon: Icons.schedule_outlined,
        iconColor: const Color(0xFFF57C00),
        title: "Verification in Progress",
        description: "We are verifying your shop documents. You will get access to products and prices as soon as the admin approves your account.",
        buttonText: "Refresh Status",
        onButtonPressed: () {
          profileService.fetchProfileFromServer();
        },
      );
    }

    return Stack(
      children: [
        // The background content (blurred)
        widget.child,

        // Disable hit testing on background content when barrier is active
        Positioned.fill(
          child: GestureDetector(
            onTap: () {},
            behavior: HitTestBehavior.opaque,
            child: const SizedBox.expand(),
          ),
        ),

        // Glassmorphic Blur and Status card
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
            child: Container(
              color: Colors.black.withOpacity(0.4),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: barrierOverlay,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required String buttonText,
    required VoidCallback onButtonPressed,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 40,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: onButtonPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: Text(
                buttonText,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
