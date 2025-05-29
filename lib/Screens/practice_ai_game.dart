import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:thinxi/screens/reward_dialog.dart';
import 'package:thinxi/helpers/reward_helper.dart';
import 'home_screen.dart';
import 'explore_screen.dart';
import 'wallet_screen.dart';
import 'settings_screen.dart';

class PracticeAIGame extends StatefulWidget {
  const PracticeAIGame({super.key});

  @override
  State<PracticeAIGame> createState() => _PracticeAIGameState();
}

class _PracticeAIGameState extends State<PracticeAIGame> {
  int questionIndex = 0;
  int correctAnswers = 0;
  bool gameEnded = false;
  late List<Map<String, dynamic>> shuffledOptions;
  late int correctAnswerIndex;
  int _selectedIndex = 0;

  final List<Map<String, dynamic>> questions = [
    {
      'question': 'What is the capital of France?',
      'options': ['Paris', 'London', 'Rome', 'Berlin'],
      'answer': 0,
      'difficulty': 2
    },
    {
      'question': 'What is 2 + 2?',
      'options': ['3', '4', '5', '6'],
      'answer': 1,
      'difficulty': 1
    },
    {
      'question': 'Who is the founder of Thinxi?',
      'options': [
        'Steve Jobs',
        'Bill Gates',
        'Hossein Jahanshahi',
        'The Queen'
      ],
      'answer': 2,
      'difficulty': 3
    },
  ];

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
    RewardHelper.trigger("tutorial_classic_game");
    _shuffleOptions();
  }

  void _shuffleOptions() {
    final original = List<String>.from(questions[questionIndex]['options']);
    final correctIndex = questions[questionIndex]['answer'];
    final correctValue = original[correctIndex];
    original.shuffle();
    shuffledOptions =
        List.generate(original.length, (i) => {'text': original[i]});
    correctAnswerIndex = original.indexOf(correctValue);
  }

  void selectAnswer(int selectedIndex) {
    if (selectedIndex == correctAnswerIndex) {
      correctAnswers++;
    }

    if (questionIndex < questions.length - 1) {
      setState(() {
        questionIndex++;
        _shuffleOptions();
      });
    } else {
      setState(() => gameEnded = true);
      rewardUser();
    }
  }

  Future<void> rewardUser() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'coins': FieldValue.increment(100),
    });

    RewardHelper.trigger("tutorial_completed");

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => RewardDialog(
        onFinished: () => Navigator.pushReplacementNamed(context, '/wallet'),
      ),
    );
  }

  void _reportQuestion() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final q = questions[questionIndex];
    await FirebaseFirestore.instance.collection('reported_questions').add({
      'question': q['question'],
      'userId': uid,
      'timestamp': Timestamp.now(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Question reported.")),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (gameEnded) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.emoji_events, color: Colors.yellow, size: 100),
              SizedBox(height: 20),
              Text("You won!",
                  style: TextStyle(color: Colors.white, fontSize: 28)),
              SizedBox(height: 10),
              Text("100 coins added to your wallet!",
                  style: TextStyle(color: Colors.white70, fontSize: 16)),
            ],
          ),
        ),
        bottomNavigationBar: _buildBottomNavBar(),
      );
    }

    final question = questions[questionIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('AI Practice Game'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flag, color: Colors.white),
            onPressed: _reportQuestion,
            tooltip: 'Report Question',
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question['question'],
              style: const TextStyle(color: Colors.white, fontSize: 22),
            ),
            const SizedBox(height: 10),
            Text(
              'Difficulty: ${question['difficulty']}',
              style: const TextStyle(color: Colors.white38, fontSize: 14),
            ),
            const SizedBox(height: 20),
            ...List.generate(shuffledOptions.length, (i) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: ElevatedButton(
                  onPressed: () => selectAnswer(i),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    padding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    shuffledOptions[i]['text'],
                    style: const TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              );
            }),
            const Spacer(),
            Text(
              "Question ${questionIndex + 1} of ${questions.length}",
              style: const TextStyle(color: Colors.white54),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
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
    );
  }
}
