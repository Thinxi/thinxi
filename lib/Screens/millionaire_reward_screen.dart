import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'home_screen.dart';
import 'explore_screen.dart';
import 'wallet_screen.dart';
import 'settings_screen.dart';

class MillionaireRewardScreen extends StatefulWidget {
  final int questionNumber;
  final bool isCorrect;

  const MillionaireRewardScreen({
    super.key,
    required this.questionNumber,
    required this.isCorrect,
  });

  @override
  State<MillionaireRewardScreen> createState() =>
      _MillionaireRewardScreenState();
}

class _MillionaireRewardScreenState extends State<MillionaireRewardScreen> {
  List<int> checkpoints = [5, 10, 15, 20, 25];
  Map<int, double> rewards = {5: 1.0, 10: 3.5, 15: 9.0, 20: 25.0, 25: 100.0};
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

  Future<void> _claimRewardAndExit(double reward) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('wallet')
          .doc('main')
          .update({
        'balance': FieldValue.increment(reward),
      });

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('transactions')
          .add({
        'type': 'reward',
        'amount': reward,
        'mode': 'Millionaire Mode',
        'question': widget.questionNumber,
        'timestamp': Timestamp.now(),
      });
    }

    Navigator.popUntil(context, ModalRoute.withName('/home'));
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
    return GestureDetector(
      onTap: () async {
        if (!widget.isCorrect) {
          Navigator.popUntil(context, ModalRoute.withName('/home'));
        } else if (widget.questionNumber >= 25) {
          await _claimRewardAndExit(rewards[25]!);
        } else {
          Navigator.pushReplacementNamed(
            context,
            '/millionaire_questions_ui',
            arguments: {
              'questionNumber': widget.questionNumber + 1,
            },
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text('Your Progress'),
          backgroundColor: Colors.black,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                widget.isCorrect ? 'Correct!' : 'Wrong Answer! Game Over',
                style: TextStyle(
                  fontSize: 20,
                  color: widget.isCorrect ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: 25,
                  itemBuilder: (context, index) {
                    int q = index + 1;
                    bool answered = q <= widget.questionNumber;
                    bool correct = q < widget.questionNumber ||
                        (q == widget.questionNumber && widget.isCorrect);

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: !answered
                            ? Colors.grey
                            : correct
                                ? Colors.green
                                : Colors.red,
                        child: Text('$q'),
                      ),
                      title: const Text(
                        'Question',
                        style: TextStyle(color: Colors.white),
                      ),
                      trailing: checkpoints.contains(q)
                          ? Text(
                              '💰 \$${rewards[q]?.toStringAsFixed(2) ?? ""}',
                              style: const TextStyle(color: Colors.white),
                            )
                          : null,
                    );
                  },
                ),
              ),
              if (checkpoints.contains(widget.questionNumber) &&
                  widget.isCorrect)
                ElevatedButton(
                  onPressed: () async {
                    await Future.delayed(const Duration(seconds: 1));
                    await _claimRewardAndExit(
                        rewards[widget.questionNumber] ?? 0);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('✅ Reward Claimed!')),
                    );
                  },
                  child: Text(
                    'Claim \$${rewards[widget.questionNumber]?.toStringAsFixed(2) ?? ""}',
                  ),
                ),
              const SizedBox(height: 12),
              const Text(
                'Tap anywhere to continue',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
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
      ),
    );
  }
}
