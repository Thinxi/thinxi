import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'home_screen.dart';
import 'explore_screen.dart';
import 'wallet_screen.dart';
import 'settings_screen.dart';

class MillionaireScreen extends StatefulWidget {
  const MillionaireScreen({super.key});

  @override
  State<MillionaireScreen> createState() => _MillionaireScreenState();
}

class _MillionaireScreenState extends State<MillionaireScreen> {
  bool _isLoading = false;
  double userBalance = 0.0;
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
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => _screens[index]),
    );
  }

  @override
  void initState() {
    super.initState();
    _getWalletBalance();
  }

  Future<void> _getWalletBalance() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('wallet')
        .doc('main')
        .get();

    if (doc.exists) {
      setState(() {
        userBalance = (doc.data()?['balance'] ?? 0).toDouble();
      });
    }
  }

  Future<void> _startGame() async {
    if (userBalance < 1.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Not enough balance. Redirecting to Wallet...')),
      );
      await Future.delayed(const Duration(seconds: 2));
      Navigator.pushNamed(context, '/wallet');
      return;
    }

    setState(() => _isLoading = true);

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('wallet')
          .doc('main')
          .update({
        'balance': FieldValue.increment(-1.0),
      });

      await Future.delayed(const Duration(seconds: 3));

      final activeGames = await FirebaseFirestore.instance
          .collection('millionaire_games')
          .where('userId', isEqualTo: uid)
          .where('status', isEqualTo: 'in_progress')
          .get();

      if (activeGames.docs.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('wallet')
            .doc('main')
            .update({
          'balance': FieldValue.increment(1.0),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('You already have an active game. Continue it.')),
        );

        final existingGame = activeGames.docs.first;
        final currentQ = existingGame['currentQuestion'] ?? 1;

        Navigator.pushReplacementNamed(
          context,
          '/millionaire_questions_ui',
          arguments: {'questionNumber': currentQ},
        );
        setState(() => _isLoading = false);
        return;
      }

      await FirebaseFirestore.instance.collection('millionaire_games').add({
        'userId': uid,
        'startTime': Timestamp.now(),
        'currentQuestion': 1,
        'earned': 0,
        'status': 'in_progress',
        'resumeAvailable': true,
      });

      Navigator.pushReplacementNamed(
        context,
        '/millionaire_questions_ui',
        arguments: {'questionNumber': 1},
      );
    } catch (e) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('wallet')
          .doc('main')
          .update({
        'balance': FieldValue.increment(1.0),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error occurred. Balance refunded. $e")),
      );
    }

    setState(() => _isLoading = false);
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
      backgroundColor: Colors.black,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '''
Welcome to Millionaire Mode!

Answer 25 questions. Win up to \$100!

- \$1 entry fee
- Ads before rewards
- Quit anytime, but only get paid at checkpoints (Q5, Q10, Q15...)
''',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _startGame,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pinkAccent,
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 24),
                    ),
                    child: const Text(
                      'Start Game (\$1)',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
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
