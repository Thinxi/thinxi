import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'explore_screen.dart';
import 'wallet_screen.dart';
import 'settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    ExploreScreen(),
    WalletScreen(),
    SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  BottomNavigationBarItem buildCustomIcon(String assetName, String label) {
    return BottomNavigationBarItem(
      icon: Image.asset(
        'assets/images/icons/$assetName',
        width: 26,
        height: 26,
        color: Colors.white54,
      ),
      activeIcon: Image.asset(
        'assets/images/icons/$assetName',
        width: 26,
        height: 26,
        color: Colors.purpleAccent,
      ),
      label: label,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Colors.black,
        selectedItemColor: Colors.purpleAccent,
        unselectedItemColor: Colors.white54,
        type: BottomNavigationBarType.fixed,
        items: [
          buildCustomIcon('home.png', 'Home'),
          buildCustomIcon('explore.png', 'Explore'),
          buildCustomIcon('wallet.png', 'Wallet'),
          buildCustomIcon('setting.png', 'Settings'),
        ],
      ),
    );
  }
}
