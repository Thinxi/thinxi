import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../services/language_manager.dart';
import 'classic_game.dart';
import 'tournament_home.dart';
import 'pal_mode_game.dart';
import 'settings_screen.dart';
import 'wallet_screen.dart';
import 'explore_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  User? user;
  DocumentSnapshot<Map<String, dynamic>>? userData;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();
      final lang = doc.data()?['language'] ?? 'en';
      if (context.mounted) {
        Provider.of<LanguageManager>(context, listen: false).setLanguage(lang);
      }
      setState(() {
        userData = doc;
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (user == null || userData == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final List<Widget> pages = [
      HomeContent(userData: userData!, user: user!),
      const ExploreScreen(),
      const WalletScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
        selectedItemColor: const Color(0xFFFF007F),
        unselectedItemColor: Colors.white54,
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(
            icon: Image.asset('assets/images/icons/home.png',
                width: 24, height: 24),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Image.asset('assets/images/icons/explore.png',
                width: 24, height: 24),
            label: "Explore",
          ),
          BottomNavigationBarItem(
            icon: Image.asset('assets/images/icons/wallet.png',
                width: 24, height: 24),
            label: "Wallet",
          ),
          BottomNavigationBarItem(
            icon: Image.asset('assets/images/icons/setting.png',
                width: 24, height: 24),
            label: "Settings",
          ),
        ],
      ),
    );
  }
}

class HomeContent extends StatelessWidget {
  final DocumentSnapshot<Map<String, dynamic>> userData;
  final User user;

  const HomeContent({super.key, required this.userData, required this.user});

  @override
  Widget build(BuildContext context) {
    final name = userData.data()?['name'] ??
        user.displayName ??
        user.email?.split('@').first ??
        'No Name';
    final photoUrl = user.photoURL ?? userData.data()?['photoUrl'];
    final score = userData.data()?['score'] ?? 0;
    final coins = userData.data()?['coins'] ?? 0;
    final rank = userData.data()?['rank'] ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.grey,
                    backgroundImage:
                        photoUrl != null && photoUrl.toString().isNotEmpty
                            ? NetworkImage(photoUrl)
                            : null,
                    child: (photoUrl == null || photoUrl.toString().isEmpty)
                        ? Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    name,
                    style: const TextStyle(fontSize: 20, color: Colors.white),
                  ),
                ],
              ),
              const Icon(Icons.signal_cellular_alt, color: Colors.white),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2b5ae6), Color(0xFFff007f)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                StatBox(value: "$score", label: "Points"),
                StatBox(value: "$rank", label: "Rank"),
                StatBox(value: "$coins", label: "Coins"),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Stack(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2b5ae6), Color(0xFFff007f)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Think. Answer. Earn",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      "ANSWER 50 QUESTIONS PER GAME AND WIN 12X THE ENTRANCE MONEY AND 50% OF THE PLAYERS ARE WINNERS",
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        if (coins < 1) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  "Not enough coins to play. Please top up."),
                            ),
                          );
                          return;
                        }

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const ClassicGame()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.3),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                      ),
                      child: const Text(
                        "QUICK GAME",
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 0,
                child: Image.asset(
                  'assets/images/woosh.png',
                  width: 100,
                  height: 100,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                backgroundColor: Colors.blueAccent,
              ),
              onPressed: () {
                if (score < 100) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          "You need at least 100 points to join the tournament."),
                    ),
                  );
                  return;
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const TournamentHome()),
                );
              },
              child: const Text(
                "Join Tournament",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Game Modes",
              style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GameModeItem("classic.png", "Classic", "no PRIZE"),
              GameModeItem("pal_mode.png", "Pal mode", "Play with CREDIT"),
              GameModeItem("tournament.png", "Tournament", "WIN up to 12X"),
              GameModeItem("bitprize.png", "Millionaire", "All or Nothing"),
            ],
          ),
        ],
      ),
    );
  }
}

class StatBox extends StatelessWidget {
  final String value;
  final String label;
  const StatBox({required this.value, required this.label, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 22, color: Colors.white)),
        Text(label,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
      ],
    );
  }
}

class GameModeItem extends StatelessWidget {
  final String image;
  final String title;
  final String subtitle;
  const GameModeItem(this.image, this.title, this.subtitle, {super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (title == "Classic") {
          Navigator.push(
              context, MaterialPageRoute(builder: (_) => const ClassicGame()));
        } else if (title == "Pal mode") {
          Navigator.push(
              context, MaterialPageRoute(builder: (_) => const PalModeGame()));
        } else if (title == "Tournament") {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const TournamentHome()));
        } else if (title == "Millionaire") {
          Navigator.pushNamed(context, '/millionaire');
        }
      },
      child: Column(
        children: [
          Image.asset('assets/images/icons/$image', width: 50, height: 50),
          const SizedBox(height: 5),
          Text(title, style: const TextStyle(color: Colors.white)),
          Text(subtitle,
              style: const TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }
}
