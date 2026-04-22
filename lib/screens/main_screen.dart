import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:krishikranti/l10n/app_localizations.dart';
import 'home_screen.dart';
import 'catalogue_screen.dart';
import 'notification_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomeScreen(),
    const CatalogueScreen(),
    const NotificationScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        height: 65,
        elevation: 10,
        backgroundColor: Colors.white,
        indicatorColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
        destinations: [
          NavigationDestination(
            icon: const Icon(CupertinoIcons.house),
            selectedIcon: const Icon(CupertinoIcons.house_fill, color: Color(0xFF2E7D32)),
            label: l10n.home,
          ),
          NavigationDestination(
            icon: const Icon(CupertinoIcons.square_grid_2x2),
            selectedIcon: const Icon(CupertinoIcons.square_grid_2x2_fill, color: Color(0xFF2E7D32)),
            label: l10n.categories,
          ),
          NavigationDestination(
            icon: const Icon(CupertinoIcons.bell),
            selectedIcon: const Icon(CupertinoIcons.bell_fill, color: Color(0xFF2E7D32)),
            label: l10n.notifications,
          ),
          NavigationDestination(
            icon: const Icon(CupertinoIcons.person),
            selectedIcon: const Icon(CupertinoIcons.person_fill, color: Color(0xFF2E7D32)),
            label: l10n.profile,
          ),
        ],
      ),
    );
  }
}
