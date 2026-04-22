import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  Future<void> _sendEmail(String email) async {
    final Uri launchUri = Uri(
      scheme: 'mailto',
      path: email,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Contact Us',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// TOP SECTION
            const Text(
              'Contact Us',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Let's Talk Business",
              style: TextStyle(
                fontSize: 16,
                color: Colors.black.withValues(alpha: 0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 32),

            /// MAIN CONTACT BLOCK
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade100),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildContactItem(
                    icon: Icons.call_outlined,
                    title: 'WhatsApp / Call',
                    subtitle: '+91 74711 21210',
                    onTap: () => _makePhoneCall('+917471121210'),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Divider(height: 1),
                  ),
                  _buildContactItem(
                    icon: Icons.email_outlined,
                    title: 'Email',
                    subtitle: 'info@krishikrantiorganics.com',
                    onTap: () => _sendEmail('info@krishikrantiorganics.com'),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Divider(height: 1),
                  ),
                  _buildContactItem(
                    icon: Icons.access_time_outlined,
                    title: 'Response Time',
                    subtitle: 'Within 24 business hours',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),

            /// TRUST SIGNAL SECTION
            const Text(
              'Why Trust Us',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 20,
              runSpacing: 20,
              children: [
                _buildTrustItem(Icons.lock_outline, 'Data Private'),
                _buildTrustItem(Icons.verified_outlined, 'CIB&RC Registered'),
                _buildTrustItem(Icons.receipt_long_outlined, 'GST Invoice'),
                _buildTrustItem(Icons.local_shipping_outlined, 'PAN-India Delivery'),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF2E7D32), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 16,
                    color: onTap != null ? const Color(0xFF2E7D32) : Colors.black,
                    fontWeight: FontWeight.bold,
                    decoration: onTap != null ? TextDecoration.underline : null,
                  ),
                ),
              ],
            ),
          ),
          if (onTap != null)
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.black26),
        ],
      ),
    );
  }

  Widget _buildTrustItem(IconData icon, String text) {
    return SizedBox(
      width: 150,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF2E7D32), size: 20),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
