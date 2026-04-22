import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:krishikranti/l10n/app_localizations.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            // Centered Heading
            Center(
              child: Text(
                l10n.notifications,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Notification List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: const [
                  NotificationItem(
                    icon: CupertinoIcons.bag_fill,
                    title: "New Deals",
                    desc: "Limited time fertilizer discounts available.",
                    accentColor: Colors.green,
                    iconBgColor: Color(0xFFFFE0B2), // Light Orange
                  ),
                  SizedBox(height: 12),
                  NotificationItem(
                    icon: CupertinoIcons.percent,
                    title: "Special Offer",
                    desc: "Get wholesale discounts on selected products.",
                    accentColor: Colors.orange,
                    iconBgColor: Color(0xFFFFF8E1),
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

class NotificationItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;
  final Color accentColor;
  final Color iconBgColor;

  const NotificationItem({
    super.key,
    required this.icon,
    required this.title,
    required this.desc,
    required this.accentColor,
    required this.iconBgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Icon with Circular Background
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 26,
              color: accentColor,
            ),
          ),
          const SizedBox(width: 16),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        // Small Vertical Accent Bar
                        Container(
                          width: 3,
                          height: 16,
                          decoration: BoxDecoration(
                            color: accentColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  desc,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
