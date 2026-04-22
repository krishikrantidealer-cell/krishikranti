import 'package:flutter/material.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

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
            /// TOP SECTION
            const Text(
              'Krishi Dealer',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'B2B Agrochemical Platform for Dealers',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black.withValues(alpha: 0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Divider(color: Colors.grey.shade300, thickness: 1),
            const SizedBox(height: 32),

            /// SECTION 1: ABOUT
            _buildSectionTitle('About Krishi Dealer'),
            const SizedBox(height: 12),
            const Text(
              'Krishi Dealer by Krishikranti Organics — India\'s trusted B2B platform for agrochemical dealers, pesticide distributors & fertilizer wholesalers. Bulk pricing. High margins. Direct dealership.',
              style: TextStyle(
                fontSize: 15,
                color: Colors.black87,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 32),

            /// SECTION 2: WHO WE ARE
            _buildSectionTitle('Who We Are'),
            const SizedBox(height: 12),
            const Text(
              'Krishi Dealer is the official B2B dealer platform of Krishikranti Organics — built exclusively for agrochemical distributors, pesticide retailers, and fertilizer wholesalers across India.\n\nWe cut out the middlemen. You get better prices, higher margins, and a product range that actually moves — season after season.',
              style: TextStyle(
                fontSize: 15,
                color: Colors.black87,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 32),

            /// SECTION 3: WHAT YOU GET
            _buildSectionTitle('What You Get as a Dealer'),
            const SizedBox(height: 16),
            _buildCheckItem('Insecticides, Fungicides, Herbicides & PGRs'),
            _buildCheckItem('Bio-Pesticides & Organic Agri-inputs'),
            _buildCheckItem('Fertilizers & Micronutrients'),
            _buildCheckItem('Bulk Pricing & Volume Discounts'),
            _buildCheckItem('CIB&RC Registered, Lab-Certified Products'),
            _buildCheckItem('GST Invoice on Every Order'),
            _buildCheckItem('PAN-India Delivery | Dedicated Dealer Support'),
            const SizedBox(height: 32),

            /// SECTION 4: WHY CHOOSE US
            _buildSectionTitle('Why Dealers Choose Us'),
            const SizedBox(height: 20),
            _buildFeatureItem(
              'Higher Margins',
              'Direct-from-brand pricing means more profit per SKU — no unnecessary supply chain markup.',
            ),
            const SizedBox(height: 20),
            _buildFeatureItem(
              'Crop-Ready Portfolio',
              'Products built around India\'s major crops — Rice, Wheat, Cotton, Sugarcane, Soybean, Vegetables & Fruits — across Kharif, Rabi & Zaid seasons.',
            ),
            const SizedBox(height: 20),
            _buildFeatureItem(
              'Compliance You Can Trust',
              'Every product is regulatory-compliant, fully documented with COA and lab reports.',
            ),
            const SizedBox(height: 40),
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

  Widget _buildCheckItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check, color: Color(0xFF2E7D32), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black87,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String title, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          description,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black54,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
