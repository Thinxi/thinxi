import 'package:flutter/material.dart';
import 'package:thinxi/screens/intro_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:thinxi/screens/home_screen.dart';
import 'package:thinxi/screens/explore_screen.dart';
import 'package:thinxi/screens/wallet_screen.dart';
import 'package:thinxi/screens/settings_screen.dart';

class ClassicGame extends StatefulWidget {
  const ClassicGame({super.key});

  @override
  State<ClassicGame> createState() => _ClassicGameState();
}

class _ClassicGameState extends State<ClassicGame> {
  int _selectedIndex = 0;
  bool isConnecting = false;
  bool hasMatch = false;

  final List<Widget> _screens = [
    const HomeScreen(),
    const ExploreScreen(),
    const WalletScreen(),
    const SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  BottomNavigationBarItem _buildNavItem(String iconName, String label) {
    return BottomNavigationBarItem(
      icon: ImageIcon(AssetImage('assets/images/icons/$iconName.png')),
      label: label,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Classic Mode',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
      body: _selectedIndex == 0
          ? ClassicGameBody(
              isConnecting: isConnecting,
              hasMatch: hasMatch,
              onStartPressed: _startMatchmaking,
            )
          : _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Colors.black,
        selectedItemColor: const Color(0xFFFF007F),
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

  Future<void> _startMatchmaking() async {
    setState(() {
      isConnecting = true;
      hasMatch = false;
    });

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User not authenticated.")),
        );
        setState(() => isConnecting = false);
        return;
      }

      final queueRef = FirebaseFirestore.instance.collection('classic_queue');
      final existingMatch = await queueRef
          .where('waiting', isEqualTo: true)
          .where('uid', isNotEqualTo: uid)
          .limit(1)
          .get();

      if (existingMatch.docs.isNotEmpty) {
        final matchDoc = existingMatch.docs.first;
        await queueRef.doc(matchDoc.id).update({
          'opponent': uid,
          'waiting': false,
          'matchedAt': Timestamp.now(),
        });

        setState(() {
          hasMatch = true;
          isConnecting = false;
        });

        _navigateToIntro();
      } else {
        await queueRef.doc(uid).set({
          'uid': uid,
          'waiting': true,
          'timestamp': Timestamp.now(),
        });

        Future.delayed(const Duration(seconds: 5), () async {
          final doc = await queueRef.doc(uid).get();
          final waiting = doc.data()?['waiting'] ?? true;
          if (!waiting) {
            setState(() {
              hasMatch = true;
              isConnecting = false;
            });
            _navigateToIntro();
          } else {
            setState(() => isConnecting = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("No opponents found. Try again.")),
            );
          }
        });
      }
    } catch (e) {
      setState(() => isConnecting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Server error: $e")),
      );
    }
  }

  void _navigateToIntro() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => IntroScreen(
          title: 'Classic Mode',
          description:
              'Face off against another player in a head-to-head showdown.',
          onStart: () => Navigator.pushNamed(context, '/classic_questions'),
        ),
      ),
    );
  }
}

class ClassicGameBody extends StatelessWidget {
  final bool isConnecting;
  final bool hasMatch;
  final VoidCallback onStartPressed;

  const ClassicGameBody({
    super.key,
    required this.isConnecting,
    required this.hasMatch,
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
              'assets/images/icons/flyer neon.png',
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
              'Face off against another player in a head-to-head showdown. Earn coins for every victory—no direct cash prizes here, but you can swap your coins for real money anytime. It’s a fun, risk-free way to sharpen your skills and grow your winnings!',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
          const SizedBox(height: 20),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              NeonIconItem(
                imagePath: 'assets/images/icons/flamingo neon.png',
                label: 'Flamingo',
              ),
              NeonIconItem(
                imagePath: 'assets/images/icons/idea box neon.png',
                label: 'Ideas',
              ),
              NeonIconItem(
                imagePath: 'assets/images/icons/smily neon.png',
                label: 'Fun',
              ),
              NeonIconItem(
                imagePath: 'assets/images/icons/lollypop neon.png',
                label: 'Sweets',
              ),
            ],
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
            onPressed: isConnecting ? null : onStartPressed,
            child: isConnecting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : const Text(
                    'Start Classic Game',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class NeonIconItem extends StatelessWidget {
  final String imagePath;
  final String label;

  const NeonIconItem({
    super.key,
    required this.imagePath,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white12,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(6.0),
            child: Image.asset(
              imagePath,
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}
