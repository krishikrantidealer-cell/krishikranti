import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:krishikranti/screens/edit_profile_screen.dart';
import 'package:krishikranti/screens/my_orders_screen.dart';
import 'package:krishikranti/screens/cart_screen.dart';
import 'package:krishikranti/screens/favorites_screen.dart';
import 'package:krishikranti/screens/about_us_screen.dart';
import 'package:krishikranti/screens/contact_us_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:krishikranti/core/profile_service.dart';
import 'package:provider/provider.dart';
import 'package:krishikranti/l10n/app_localizations.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _showLogoutDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: Text(l10n.logout),
        content: Text(l10n.logoutConfirm),
        actions: [
          CupertinoDialogAction(
            child: Text(l10n.no),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: Text(l10n.yes),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('isLoggedIn', false);
              
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/phone-verify',
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const Color primaryGreen = Color(0xFF2E7D32);
    
    return Consumer<ProfileService>(
      builder: (context, profile, child) {
        return Scaffold(
            backgroundColor: Colors.white,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),

                  /// 🔥 PROFILE CARD (REFINED TYPOGRAPHY & ICON)
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: primaryGreen.withValues(alpha: 0.1),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF66BB6A), primaryGreen],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              /// AVATAR
                              Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.4),
                                    width: 3,
                                  ),
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                    color: Colors.white.withValues(alpha: 0.15),
                                  ),
                                  child: Center(
                                    child: Text(
                                      profile.avatarLetter,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 30,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      profile.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      profile.storeName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.95),
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      profile.phone,
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.85),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _ScaleBtn(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    CupertinoIcons.square_pencil, 
                                    color: primaryGreen, 
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.location_on, size: 16, color: Colors.white),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    profile.fullAddress,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.white, 
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  /// KYC SECTION (BALANCED)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircularPercentIndicator(
                          radius: 28,
                          lineWidth: 7,
                          percent: 0.65,
                          backgroundColor: Colors.grey.shade100,
                          progressColor: primaryGreen,
                          circularStrokeCap: CircularStrokeCap.round,
                          center: const Text("65%", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          animation: true,
                          animationDuration: 1000,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.kycVerification, 
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700, 
                                  fontSize: 16,
                                  color: Color(0xFF212121),
                                ),
                              ),
                              Text(
                                l10n.kycSubtitle, 
                                style: const TextStyle(color: Colors.black54, fontSize: 13),
                              ),
                              const SizedBox(height: 6),
                              _ScaleBtn(
                                onTap: () => Navigator.pushNamed(context, '/ekyc'),
                                child: Container(
                                  width: 140,
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: primaryGreen,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "Complete Now", 
                                        style: TextStyle(
                                          color: Colors.white, 
                                          fontWeight: FontWeight.bold, 
                                          fontSize: 13,
                                        ),
                                      ),
                                      SizedBox(width: 6),
                                      Icon(Icons.arrow_forward, size: 14, color: Colors.white),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Container(width: 4, height: 20, color: primaryGreen),
                      const SizedBox(width: 10),
                      Text(
                        l10n.myAccount, 
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 2.1,
                    children: [
                      _AccountCard(
                        icon: CupertinoIcons.bag_fill,
                        title: l10n.myOrders,
                        color: Colors.blue,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyOrdersScreen())),
                      ),
                      _AccountCard(
                        icon: CupertinoIcons.cart_fill,
                        title: l10n.cart,
                        color: Colors.green,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen())),
                      ),
                      _AccountCard(
                        icon: CupertinoIcons.phone_fill,
                        title: l10n.contactUs,
                        color: Colors.orange,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ContactUsScreen())),
                      ),
                      _AccountCard(
                        icon: CupertinoIcons.info_circle_fill,
                        title: l10n.aboutUs,
                        color: Colors.teal,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutUsScreen())),
                      ),
                      _AccountCard(
                        icon: CupertinoIcons.heart_fill,
                        title: l10n.favorites,
                        color: Colors.red,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritesScreen())),
                      ),
                      _AccountCard(
                        icon: CupertinoIcons.globe,
                        title: l10n.language,
                        color: Colors.deepPurple,
                        onTap: () => Navigator.pushNamed(context, '/language-select'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  /// LOGOUT BUTTON (REFINED)
                  _ScaleBtn(
                    onTap: () => _showLogoutDialog(context),
                    child: Container(
                      width: double.infinity,
                      height: 52,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                        color: Colors.white,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(CupertinoIcons.square_arrow_right, color: Colors.red, size: 18),
                          const SizedBox(width: 10),
                          Text(
                            l10n.logout, 
                            style: const TextStyle(
                              color: Colors.red, 
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AccountCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _AccountCard({required this.icon, required this.title, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return _ScaleBtn(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white, width: 1),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.01), blurRadius: 6)],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600, 
                  color: Color(0xFF2D2D2D),
                ),
              ),
            ),
            Icon(CupertinoIcons.chevron_right, size: 12, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}

class _ScaleBtn extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _ScaleBtn({required this.child, required this.onTap});

  @override
  State<_ScaleBtn> createState() => _ScaleBtnState();
}

class _ScaleBtnState extends State<_ScaleBtn> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    _controller = AnimationController(duration: const Duration(milliseconds: 100), lowerBound: 0.97, upperBound: 1.0, vsync: this);
    _controller.value = 1.0;
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.reverse(),
      onTapUp: (_) => _controller.forward(),
      onTapCancel: () => _controller.forward(),
      onTap: widget.onTap,
      child: ScaleTransition(scale: _controller, child: widget.child),
    );
  }
}
