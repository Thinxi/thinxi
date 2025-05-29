import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'home_screen.dart';
import 'explore_screen.dart';
import 'wallet_screen.dart';
import 'settings_screen.dart';

class PalModeResultScreen extends StatefulWidget {
  final int score;
  final int totalQuestions;

  const PalModeResultScreen({
    super.key,
    required this.score,
    required this.totalQuestions,
  });

  @override
  State<PalModeResultScreen> createState() => _PalModeResultScreenState();
}

class _PalModeResultScreenState extends State<PalModeResultScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    ExploreScreen(),
    WalletScreen(),
    SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
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
    playResultSound();
  }

  void playResultSound() {
    final isWinner = widget.score >= (widget.totalQuestions * 0.7).round();
    if (isWinner) {
      _audioPlayer.play(AssetSource('audio/reward.mp3'));
    } else {
      _audioPlayer.play(AssetSource('audio/no prize tournament.mp3'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isWinner =
        widget.score >= (widget.totalQuestions * 0.7).round(); // 70% threshold

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '🎉 Game Completed!',
                style: TextStyle(color: Colors.white, fontSize: 28),
              ),
              const SizedBox(height: 30),
              Text(
                'Your Score: ${widget.score} / ${widget.totalQuestions}',
                style: const TextStyle(color: Colors.blueAccent, fontSize: 22),
              ),
              const SizedBox(height: 20),
              Text(
                isWinner
                    ? '✅ You won! You keep your credit.'
                    : '❌ You lost your credit.',
                style: TextStyle(
                  color: isWinner ? Colors.greenAccent : Colors.redAccent,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 30),

              // Simulated Ad Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  children: [
                    Text(
                      '📺 Advertisement',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Ad plays here... (simulate AdMob or show a banner)',
                      style: TextStyle(color: Colors.white38),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isWinner ? Colors.green : Colors.orange,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                ),
                onPressed: () {
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                child: Text(
                  isWinner
                      ? 'Play Again with Credit'
                      : 'Back to Home - Buy New Credit',
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Colors.black,
        selectedItemColor: Colors.purpleAccent,
        unselectedItemColor: Colors.white54,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: ImageIcon(AssetImage('assets/images/icons/home.png')),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: ImageIcon(AssetImage('assets/images/icons/explore.png')),
            label: "Explore",
          ),
          BottomNavigationBarItem(
            icon: ImageIcon(AssetImage('assets/images/icons/wallet.png')),
            label: "Wallet",
          ),
          BottomNavigationBarItem(
            icon: ImageIcon(AssetImage('assets/images/icons/setting.png')),
            label: "Settings",
          ),
        ],
      ),
    );
  }
}
