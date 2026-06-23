import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:krishikranti/core/meta_analytics_service.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'About Us',
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
            /// APP TITLE / BRANDING
            const Text(
              'Krishi Dealer',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'B2B Agrochemical Platform',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black.withValues(alpha: 0.6),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Divider(color: Colors.grey.shade300, thickness: 1),
            const SizedBox(height: 24),

            /// WELCOME / INTRODUCTION SECTION
            const Text(
              'Welcome to Krishi Dealer by Krishikranti Organics.',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Krishi Dealer is a dedicated B2B platform developed by Krishikranti Organics to simplify bulk purchasing of agricultural inputs for retailers, distributors, wholesalers, and channel partners across India.',
              style: TextStyle(
                fontSize: 15,
                color: Colors.black54,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),

            /// MISSION SECTION
            _buildSectionTitle('Our Mission'),
            const SizedBox(height: 12),
            const Text(
              'Our mission is to make quality agricultural products easily accessible to businesses involved in the agricultural supply chain. Through the Krishi Dealer app, authorized partners can browse products, place bulk orders, track purchases, receive promotional offers, and stay updated with the latest products and schemes offered by Krishikranti Organics.',
              style: TextStyle(
                fontSize: 15,
                color: Colors.black54,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),

            /// COMMITMENT SECTION
            _buildSectionTitle('Our Commitment'),
            const SizedBox(height: 12),
            const Text(
              'We are committed to building long-term relationships with our dealer network by providing reliable products, transparent pricing, and efficient support.',
              style: TextStyle(
                fontSize: 15,
                color: Colors.black54,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Whether you are a retailer, distributor, or wholesale partner, Krishi Dealer is designed to help you grow your business with confidence.',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1B5E20),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 36),

            /// CONTACT & COMPANY INFO CARD
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F8E9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFDCEDC8)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Company Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildContactRow(
                    Icons.business,
                    'Company Name',
                    'Krishikranti Organics',
                  ),
                  const SizedBox(height: 14),
                  _buildClickableContactRow(
                    Icons.email_outlined,
                    'Email Address',
                    'info@krishikrantiorganics.com',
                    () {
                      MetaAnalyticsService.logContactSupport(contactMethod: 'Email About Us');
                      _launchUrl('mailto:info@krishikrantiorganics.com');
                    },
                  ),
                  const SizedBox(height: 14),
                  _buildClickableContactRow(
                    Icons.phone_outlined,
                    'Phone Number',
                    '+91 7471121210',
                    () {
                      MetaAnalyticsService.logContactSupport(contactMethod: 'Phone About Us');
                      _launchUrl('tel:+917471121210');
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF2E7D32),
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF2E7D32), size: 22),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black45,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildClickableContactRow(
    IconData icon,
    String label,
    String value,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFF2E7D32), size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black45,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.blueAccent,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
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
