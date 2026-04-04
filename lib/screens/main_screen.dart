import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
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
        indicatorColor: Theme.of(context).primaryColor.withOpacity(0.1),
        destinations: const [
          NavigationDestination(
            icon: Icon(CupertinoIcons.house),
            selectedIcon: Icon(CupertinoIcons.house_fill, color: Color(0xFF2E7D32)),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(CupertinoIcons.square_grid_2x2),
            selectedIcon: Icon(CupertinoIcons.square_grid_2x2_fill, color: Color(0xFF2E7D32)),
            label: 'Catalogue',
          ),
          NavigationDestination(
            icon: Icon(CupertinoIcons.bell),
            selectedIcon: Icon(CupertinoIcons.bell_fill, color: Color(0xFF2E7D32)),
            label: 'Notification',
          ),
          NavigationDestination(
            icon: Icon(CupertinoIcons.person),
            selectedIcon: Icon(CupertinoIcons.person_fill, color: Color(0xFF2E7D32)),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
