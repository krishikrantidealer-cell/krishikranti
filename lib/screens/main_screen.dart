import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:krishikranti/l10n/app_localizations.dart';
import 'package:krishikranti/core/profile_service.dart';
import 'package:krishikranti/core/notification_provider.dart';
import 'package:provider/provider.dart';
import 'package:krishikranti/features/products/data/repositories/home_repository.dart';
import 'home_screen.dart';
import 'catalogue_screen.dart';
import 'notification_screen.dart';
import 'profile_screen.dart';
import 'package:krishikranti/core/favorite_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  DateTime? _lastBackPressed;

  @override
  void initState() {
    super.initState();
    // CENTRAL SYNC: Fetch the latest profile data as soon as we enter the main app
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ProfileService>().fetchProfileFromServer();
        // Warm up caches for other tabs to ensure instant loading
        final homeRepo = HomeRepository();
        homeRepo.getHomeDiscovery(); // Background fetch
      }
    });
  }

  final Map<int, Widget> _builtPages = {};

  Widget _getPage(int index) {
    if (!_builtPages.containsKey(index)) {
      switch (index) {
        case 0:
          _builtPages[index] = const HomeScreen();
          break;
        case 1:
          _builtPages[index] = const CatalogueScreen();
          break;
        case 2:
          _builtPages[index] = const NotificationScreen();
          break;
        case 3:
          _builtPages[index] = const ProfileScreen();
          break;
        default:
          _builtPages[index] = const SizedBox.shrink();
      }
    }
    return _builtPages[index]!;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) async {
          if (didPop) return;
          if (_selectedIndex != 0) {
            setState(() {
              _selectedIndex = 0;
            });
            return;
          }

          final now = DateTime.now();
          if (_lastBackPressed == null ||
              now.difference(_lastBackPressed!) > const Duration(seconds: 2)) {
            _lastBackPressed = now;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Press back again to exit"),
                duration: Duration(seconds: 2),
              ),
            );
            return;
          }
        },
        child: Scaffold(
          body: IndexedStack(
            index: _selectedIndex,
            children: List.generate(4, (index) {
              // Only build the page if it's the current one or already built
              if (index == _selectedIndex || _builtPages.containsKey(index)) {
                return _getPage(index);
              }
              return const SizedBox.shrink();
            }),
          ),
          bottomNavigationBar: Container(
            height: 64 + MediaQuery.of(context).padding.bottom,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(
                  color: Colors.grey.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Shifting Stretching Background Pill
                  Positioned.fill(
                    child: _SnakeIndicator(
                      selectedIndex: _selectedIndex,
                      itemCount: 4,
                    ),
                  ),
                  Row(
                    children: [
                      _buildAnimatedNavItem(
                        0,
                        CupertinoIcons.house,
                        CupertinoIcons.house_fill,
                        assetPath: 'assets/icons/home.png',
                        activeAssetPath: 'assets/icons/home_fill.png',
                      ),
                      _buildAnimatedNavItem(
                        1,
                        CupertinoIcons.square_grid_2x2,
                        CupertinoIcons.square_grid_2x2_fill,
                        assetPath: 'assets/icons/category.png',
                        activeAssetPath: 'assets/icons/category_fill.png',
                      ),
                      _buildAnimatedNavItem(
                        2,
                        CupertinoIcons.bell,
                        CupertinoIcons.bell_fill,
                        assetPath: 'assets/icons/notification.png',
                        activeAssetPath: 'assets/icons/notification_fill.png',
                      ),
                      _buildAnimatedNavItem(
                        3,
                        CupertinoIcons.person_crop_circle,
                        CupertinoIcons.person_crop_circle_fill,
                        assetPath: 'assets/icons/user.png',
                        activeAssetPath: 'assets/icons/user_fill.png',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedNavItem(
    int index,
    IconData icon,
    IconData selectedIcon, {
    String? assetPath,
    String? activeAssetPath,
  }) {
    final isSelected = _selectedIndex == index;
    const primaryColor = Color(0xFF2E7D32);

    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_selectedIndex != index) {
            HapticFeedback.selectionClick();
            setState(() {
              _selectedIndex = index;
            });
          }
        },
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: _LordiconWrapper(
            index: index,
            isSelected: isSelected,
            color: isSelected ? primaryColor : Colors.black45,
            icon: icon,
            selectedIcon: selectedIcon,
            assetPath: assetPath,
            activeAssetPath: activeAssetPath,
          ),
        ),
      ),
    );
  }
}

class _LordiconWrapper extends StatefulWidget {
  final int index;
  final bool isSelected;
  final Color color;
  final IconData icon;
  final IconData selectedIcon;
  final String? assetPath;
  final String? activeAssetPath;

  const _LordiconWrapper({
    required this.index,
    required this.isSelected,
    required this.color,
    required this.icon,
    required this.selectedIcon,
    this.assetPath,
    this.activeAssetPath,
  });

  @override
  State<_LordiconWrapper> createState() => _LordiconWrapperState();
}

class _LordiconWrapperState extends State<_LordiconWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    if (widget.isSelected) _controller.value = 1.0;
  }

  @override
  void didUpdateWidget(_LordiconWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected && !oldWidget.isSelected) {
      _controller.forward(from: 0.0);
    } else if (!widget.isSelected && oldWidget.isSelected) {
      _controller.value = 0.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        double scale = 1.0;
        double rotation = 0.0;
        double translateY = 0.0;

        final t = _controller.value;

        // Custom advanced animations based on icon index
        switch (widget.index) {
          case 0: // Home: Complex Jump + Squash & Stretch
            final jump = math.sin(t * math.pi);
            translateY = -jump * 6;
            double scaleX = 1.0 + (math.sin(t * math.pi * 2) * 0.15);
            double scaleY = 1.0 - (math.sin(t * math.pi * 2) * 0.1);
            rotation = math.sin(t * math.pi) * 0.1;

            return Transform(
              transform: Matrix4.identity()
                ..translate(0.0, translateY)
                ..rotateZ(rotation)
                ..scale(scaleX, scaleY),
              alignment: Alignment.center,
              child: _buildIconContent(),
            );

          case 1: // Catalogue: 3D Tilt + Scale
            rotation = math.sin(t * math.pi) * 0.25;
            scale = 1.0 + (t * 0.15);
            break;

          case 2: // Bell: Realistic Ringing
            rotation = math.sin(t * math.pi * 4) * 0.2 * (1 - t);
            scale = 1.0 + (t * 0.1);
            break;

          case 3: // Profile: Advanced Sway & Pop
            scale = 1.0 + math.sin(t * math.pi) * 0.2;
            rotation = math.sin(t * math.pi * 2) * 0.15;
            translateY = -math.sin(t * math.pi) * 4;
            break;
        }

        return Transform(
          transform: Matrix4.identity()
            ..translate(0.0, translateY)
            ..rotateZ(rotation)
            ..scale(scale),
          alignment: Alignment.center,
          child: _buildIconContent(),
        );
      },
    );
  }

  Widget _buildIconContent() {
    final effectiveAsset = (widget.isSelected && widget.activeAssetPath != null)
        ? widget.activeAssetPath
        : widget.assetPath;

    Widget iconWidget;
    if (effectiveAsset != null) {
      iconWidget = Image.asset(
        effectiveAsset,
        width: 22,
        height: 22,
        color: widget.color,
      );
    } else {
      iconWidget = Icon(
        widget.isSelected ? widget.selectedIcon : widget.icon,
        color: widget.color,
        size: 24,
      );
    }

    if (widget.index == 2) {
      return Consumer<NotificationProvider>(
        builder: (context, provider, child) {
          final count = provider.unreadCount;
          if (count == 0) {
            return iconWidget;
          }
          return Stack(
            clipBehavior: Clip.none,
            children: [
              iconWidget,
              Positioned(
                right: -6,
                top: -6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white,
                      width: 1.5,
                    ),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Center(
                    child: Text(
                      count > 9 ? '9+' : count.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        height: 1.0,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      );
    }

    if (widget.index == 3) {
      return Consumer<FavoriteService>(
        builder: (context, favService, child) {
          final count = favService.favorites.length;
          if (count == 0) {
            return iconWidget;
          }
          return Stack(
            clipBehavior: Clip.none,
            children: [
              iconWidget,
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          );
        },
      );
    }

    return iconWidget;
  }
}

class _SnakeIndicator extends StatefulWidget {
  final int selectedIndex;
  final int itemCount;

  const _SnakeIndicator({
    super.key,
    required this.selectedIndex,
    required this.itemCount,
  });

  @override
  State<_SnakeIndicator> createState() => _SnakeIndicatorState();
}

class _SnakeIndicatorState extends State<_SnakeIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _prevIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 400,
      ), // Slightly longer for silkiness
    );
    _controller.value = 1.0;
    _prevIndex = widget.selectedIndex;
  }

  @override
  void didUpdateWidget(_SnakeIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedIndex != oldWidget.selectedIndex) {
      _prevIndex = oldWidget.selectedIndex;
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = constraints.maxWidth / widget.itemCount;

        return RepaintBoundary(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final t = _controller.value;
              final isMovingRight = widget.selectedIndex > _prevIndex;

              // Curves for true snake effect: leading edge stretches early, trailing follows
              final leadingT = Curves.easeOutCubic.transform(t);
              final trailingT = Curves.easeInCubic.transform(t);

              const baseWidth = 48.0;
              final prevCenter = _getCenter(_prevIndex, itemWidth);
              final destCenter = _getCenter(widget.selectedIndex, itemWidth);

              double leftEdge, rightEdge;

              if (isMovingRight) {
                // Moving Right: Right edge is leading
                leftEdge =
                    (prevCenter - baseWidth / 2) +
                    (destCenter - prevCenter) * trailingT;
                rightEdge =
                    (prevCenter + baseWidth / 2) +
                    (destCenter - prevCenter) * leadingT;
              } else {
                // Moving Left: Left edge is leading
                leftEdge =
                    (prevCenter - baseWidth / 2) +
                    (destCenter - prevCenter) * leadingT;
                rightEdge =
                    (prevCenter + baseWidth / 2) +
                    (destCenter - prevCenter) * trailingT;
              }

              final currentCenter = (leftEdge + rightEdge) / 2;
              final currentWidth = rightEdge - leftEdge;

              // Fade logic: Subtle light background (0.1) that becomes even lighter (0.05) while moving
              final stretchT = math.sin(t * math.pi);
              final alpha = (0.1 - (stretchT * 0.05)).clamp(0.05, 0.1);

              return CustomPaint(
                painter: _SnakePainter(
                  center: currentCenter,
                  width: currentWidth,
                  alpha: alpha,
                  color: const Color(0xFF2E7D32),
                ),
                size: Size(constraints.maxWidth, constraints.maxHeight),
              );
            },
          ),
        );
      },
    );
  }

  double _getCenter(int index, double itemWidth) {
    return (itemWidth * index) + (itemWidth / 2);
  }
}

class _SnakePainter extends CustomPainter {
  final double center;
  final double width;
  final double alpha;
  final Color color;

  _SnakePainter({
    required this.center,
    required this.width,
    required this.alpha,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: alpha)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // Optional: Add a subtle shadow for a "floating" premium feel
    if (alpha > 0.8) {
      final shadowPaint = Paint()
        ..color = color.withValues(alpha: 0.1)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(center, size.height / 2 + 2),
            width: width,
            height: 48,
          ),
          const Radius.circular(24),
        ),
        shadowPaint,
      );
    }

    final rrect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(center, size.height / 2),
        width: width,
        height: 48,
      ),
      const Radius.circular(24),
    );

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(_SnakePainter oldDelegate) {
    return oldDelegate.center != center ||
        oldDelegate.width != width ||
        oldDelegate.alpha != alpha;
  }
}
