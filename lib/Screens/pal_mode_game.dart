import 'package:flutter/material.dart';
import 'package:thinxi/screens/intro_screen.dart';
import 'package:thinxi/screens/pal_mode_questions_ui.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'home_screen.dart';
import 'explore_screen.dart';
import 'wallet_screen.dart';
import 'settings_screen.dart';

class PalModeGame extends StatefulWidget {
  const PalModeGame({super.key});

  @override
  State<PalModeGame> createState() => _PalModeGameState();
}

class _PalModeGameState extends State<PalModeGame> {
  int _selectedIndex = 0;
  bool isLoading = false;

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
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => _screens[index]),
    );
  }

  BottomNavigationBarItem _buildNavItem(String iconName, String label) {
    return BottomNavigationBarItem(
      icon: Image.asset(
        'assets/images/icons/$iconName.png',
        width: 26,
        height: 26,
        color: Colors.white54,
      ),
      activeIcon: Image.asset(
        'assets/images/icons/$iconName.png',
        width: 26,
        height: 26,
        color: Colors.purpleAccent,
      ),
      label: label,
    );
  }

  Future<void> _startPalGame() async {
    setState(() => isLoading = true);

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User not authenticated.")),
      );
      setState(() => isLoading = false);
      return;
    }

    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);

    final snapshot = await userRef.get();
    final credits = snapshot.data()?['credit'] ?? 0;

    if (credits < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No Pal Credits available.")),
      );
      setState(() => isLoading = false);
      return;
    }

    await userRef.update({'credit': credits - 1});

    final gameId = 'PAL-${DateTime.now().millisecondsSinceEpoch}';

    try {
      await FirebaseFirestore.instance
          .collection('pal_mode_sessions')
          .doc(gameId)
          .set({
        'userId': uid,
        'startTime': DateTime.now(),
        'status': 'active',
        'refunded': false,
        'creditUsed': true,
      });

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => IntroScreen(
            title: 'Pal Mode',
            description:
                'Play a mini-tournament with 50 questions in 10 minutes.',
            onStart: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PalModeQuestionsScreen(
                    userId: uid,
                    gameId: gameId,
                  ),
                ),
              );
            },
          ),
        ),
      );
    } catch (e) {
      await userRef.update({'credit': credits});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Server error. Credit refunded. $e")),
      );
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Pal Mode',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
      body: _selectedIndex == 0
          ? PalModeBody(
              isLoading: isLoading,
              onStartPressed: _startPalGame,
            )
          : _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Colors.black,
        selectedItemColor: Colors.purpleAccent,
        unselectedItemColor: Colors.white54,
        type: BottomNavigationBarType.fixed,
        items: [
          _buildNavItem('home', 'Home'),
          _buildNavItem('explore', 'Explore'),
          _buildNavItem('wallet', 'Wallet'),
          _buildNavItem('setting', 'Settings'),
        ],
      ),
    );
  }
}

class PalModeBody extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onStartPressed;

  const PalModeBody({
    super.key,
    required this.isLoading,
    required this.onStartPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 16),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Image.asset(
              'assets/images/icons/pal box neon .png',
              fit: BoxFit.cover,
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Join the game on Thinxi’s dime—no upfront cost to you! You get exactly one “credit” match unless you keep winning.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: const Color(0xFF3B41C5),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: isLoading ? null : onStartPressed,
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : const Text(
                    'Start',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
