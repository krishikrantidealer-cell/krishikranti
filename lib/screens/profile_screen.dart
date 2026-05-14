import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
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
import 'package:krishikranti/core/network/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  void _showLogoutDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    HapticFeedback.heavyImpact();
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: Text(
          l10n.logout,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(l10n.logoutConfirm),
        ),
        actions: [
          CupertinoDialogAction(
            child: Text(l10n.no, style: const TextStyle(color: Colors.blue)),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: Text(l10n.yes),
            onPressed: () async {
              await AuthService.logout();
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
    final theme = Theme.of(context);
    final Color primaryGreen = theme.primaryColor;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Consumer<ProfileService>(
          builder: (context, profile, child) {
            return RefreshIndicator(
              onRefresh: () => profile.fetchProfileFromServer(),
              color: primaryGreen,
              displacement: 40,
              edgeOffset: 80,
              child: CustomScrollView(
                physics: const ClampingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Compact Curved Gradient Header
                        Container(
                          height: 115,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                primaryGreen,
                                primaryGreen.withValues(alpha: 0.8),
                                const Color(0xFF0F5132),
                              ],
                            ),
                            // borderRadius: const BorderRadius.vertical(
                            //   bottom: Radius.circular(36),
                            // ),
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                top: -30,
                                right: -20,
                                child: _BlurredCircle(
                                  size: 140,
                                  color: Colors.white.withValues(alpha: 0.12),
                                ),
                              ),
                              Positioned(
                                bottom: -15,
                                left: -15,
                                child: _BlurredCircle(
                                  size: 90,
                                  color: Colors.black.withValues(alpha: 0.1),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Animated Main Profile Card (Compact)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 60, 16, 0),
                          child: TweenAnimationBuilder<double>(
                            tween: Tween<double>(begin: 0.0, end: 1.0),
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.easeOutQuart,
                            builder: (context, value, child) {
                              return Transform.translate(
                                offset: Offset(0, 20 * (1 - value)),
                                child: Opacity(opacity: value, child: child),
                              );
                            },
                            child: Stack(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: primaryGreen.withValues(
                                          alpha: 0.06,
                                        ),
                                        blurRadius: 25,
                                        offset: const Offset(0, 10),
                                      ),
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.03,
                                        ),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          Container(
                                            width: 60,
                                            height: 60,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              gradient: LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                                colors: [
                                                  primaryGreen.withValues(
                                                    alpha: 0.2,
                                                  ),
                                                  primaryGreen.withValues(
                                                    alpha: 0.05,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          Container(
                                            width: 50,
                                            height: 50,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.white,
                                              border: Border.all(
                                                color: primaryGreen.withValues(
                                                  alpha: 0.2,
                                                ),
                                                width: 2,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: primaryGreen
                                                      .withValues(alpha: 0.12),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 3),
                                                ),
                                              ],
                                            ),
                                            child: Center(
                                              child: Text(
                                                profile.avatarLetter,
                                                style: TextStyle(
                                                  color: primaryGreen,
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.w900,
                                                ),
                                              ),
                                            ),
                                          ),
                                          FutureBuilder<bool>(
                                            future: AuthService.isKycComplete(),
                                            builder: (context, snapshot) {
                                              if (snapshot.data == true) {
                                                return Positioned(
                                                  bottom: 0,
                                                  right: 0,
                                                  child: _VerifiedBadge(
                                                    primaryGreen: primaryGreen,
                                                  ),
                                                );
                                              }
                                              return const SizedBox.shrink();
                                            },
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              profile.name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 17,
                                                fontWeight: FontWeight.w800,
                                                color: Color(0xFF1A1A1A),
                                                letterSpacing: -0.4,
                                                height: 1.1,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.all(
                                                    3,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: primaryGreen
                                                        .withValues(alpha: 0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          4,
                                                        ),
                                                  ),
                                                  child: Icon(
                                                    CupertinoIcons.bag_fill,
                                                    size: 10,
                                                    color: primaryGreen,
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    profile.storeName,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color:
                                                          Colors.grey.shade700,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if (profile.city.isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Icon(
                                                    CupertinoIcons
                                                        .location_solid,
                                                    size: 12,
                                                    color: Colors.grey.shade500,
                                                  ),
                                                  const SizedBox(width: 5),
                                                  Expanded(
                                                    child: Text(
                                                      "${profile.city}${profile.state.isNotEmpty ? ', ${profile.state}' : ''}",
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: Colors
                                                            .grey
                                                            .shade600,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Positioned(
                                  top: 12,
                                  right: 12,
                                  child: _EditPillButton(
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const EditProfileScreen(),
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

                  // Quick Stats Row & Action Lists (Compact)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        FutureBuilder<bool>(
                          future: AuthService.isKycComplete(),
                          builder: (context, snapshot) {
                            if (snapshot.data == true) {
                              return const SizedBox.shrink();
                            }
                            return _ModernKycAlert(l10n: l10n);
                          },
                        ),

                        // --- UNIFIED GENERAL ACTIONS ---
                        _ModernSectionHeader(title: "GENERAL OPTIONS"),
                        _GroupedActionCard(
                          children: [
                            _ActionTile(
                              icon: CupertinoIcons.bag_fill,
                              title: l10n.myOrders,
                              color: Colors.blueAccent,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const MyOrdersScreen(),
                                ),
                              ),
                            ),
                            _ActionTile(
                              icon: CupertinoIcons.cart_fill,
                              title: l10n.cart,
                              color: const Color(0xFF2E7D32),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const CartScreen(),
                                ),
                              ),
                            ),
                            _ActionTile(
                              icon: CupertinoIcons.heart_fill,
                              title: l10n.favorites,
                              color: Colors.redAccent,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const FavoritesScreen(),
                                ),
                              ),
                            ),
                            _ActionTile(
                              icon: CupertinoIcons.globe,
                              title: l10n.language,
                              color: Colors.indigoAccent,
                              onTap: () => Navigator.pushNamed(
                                context,
                                '/language-select',
                              ),
                            ),
                            _ActionTile(
                              icon: CupertinoIcons.phone_fill,
                              title: l10n.contactUs,
                              color: Colors.orangeAccent.shade700,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ContactUsScreen(),
                                ),
                              ),
                            ),
                            _ActionTile(
                              icon: CupertinoIcons.info_circle_fill,
                              title: l10n.aboutUs,
                              color: Colors.teal.shade700,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AboutUsScreen(),
                                ),
                              ),
                              showDivider: false,
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),
                        _LogoutButton(
                          onTap: () => _showLogoutDialog(context),
                          label: l10n.logout,
                        ),
                        const SizedBox(height: 24),
                        Center(
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  CupertinoIcons.leaf_arrow_circlepath,
                                  color: Colors.grey.shade500,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "KRISHI KRANTI • VERSION 2.0.1",
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "Empowering Agri Dealers Across India",
                                style: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ]),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// --- ADVANCED COMPACT UI COMPONENTS ---

class _QuickStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final Color backgroundColor;

  const _QuickStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 14),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: Colors.grey.shade500,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1E1E1E),
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupedActionCard extends StatelessWidget {
  final List<Widget> children;
  const _GroupedActionCard({required this.children});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;
  final bool showDivider;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return _ScaleBtn(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2D2D2D),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    CupertinoIcons.chevron_right,
                    size: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          if (showDivider)
            Padding(
              padding: const EdgeInsets.only(left: 54, right: 16),
              child: Divider(
                height: 1,
                thickness: 0.5,
                color: Colors.black.withValues(alpha: 0.04),
              ),
            ),
        ],
      ),
    );
  }
}

class _BlurredCircle extends StatelessWidget {
  final double size;
  final Color color;
  const _BlurredCircle({required this.size, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _VerifiedBadge extends StatelessWidget {
  final Color primaryGreen;
  const _VerifiedBadge({required this.primaryGreen});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Icon(
        CupertinoIcons.checkmark_seal_fill,
        color: primaryGreen,
        size: 16,
      ),
    );
  }
}

class _EditPillButton extends StatelessWidget {
  final VoidCallback onTap;
  const _EditPillButton({required this.onTap});
  @override
  Widget build(BuildContext context) {
    return _ScaleBtn(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/icons/edit.png',
              width: 12,
              height: 12,
              color: Colors.grey.shade700,
            ),
            const SizedBox(width: 5),
            Text(
              "Edit",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModernSectionHeader extends StatelessWidget {
  final String title;
  const _ModernSectionHeader({required this.title});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 16, 6, 10),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 12,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: Colors.grey.shade600,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModernKycAlert extends StatelessWidget {
  final dynamic l10n;
  const _ModernKycAlert({required this.l10n});
  @override
  Widget build(BuildContext context) {
    return _ScaleBtn(
      onTap: () => Navigator.pushNamed(context, '/kyc'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFFFF3E0),
              const Color(0xFFFFE0B2).withValues(alpha: 0.7),
            ],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.orange.withValues(alpha: 0.25)),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withValues(alpha: 0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                CupertinoIcons.shield_lefthalf_fill,
                color: Colors.orange,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Identity Verification",
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      color: Color(0xFFE65100),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.kycSubtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFEF6C00),
                      fontWeight: FontWeight.w600,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                CupertinoIcons.chevron_right,
                color: Colors.white,
                size: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  final VoidCallback onTap;
  final String label;
  const _LogoutButton({required this.onTap, required this.label});
  @override
  Widget build(BuildContext context) {
    return _ScaleBtn(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.red.withValues(alpha: 0.15)),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(CupertinoIcons.power, color: Colors.red, size: 16),
              const SizedBox(width: 8),
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
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

class _ScaleBtnState extends State<_ScaleBtn>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.95,
      upperBound: 1.0,
      vsync: this,
    );
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
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _controller.reverse(),
      onTapUp: (_) => _controller.forward(),
      onTapCancel: () => _controller.forward(),
      onTap: widget.onTap,
      child: ScaleTransition(scale: _controller, child: widget.child),
    );
  }
}
